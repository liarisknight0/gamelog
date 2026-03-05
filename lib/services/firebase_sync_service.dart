import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/sync_status_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the service
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  return FirebaseSyncService(ref);
});

// Provider to manage the GoogleSignIn instance
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    serverClientId: '421278333318-amhl723jpfum122u69i9tsm91707k6lh.apps.googleusercontent.com',
    scopes: const ['email'],
  );
});

// Provider to manage the current GoogleSignInAccount
final googleSignInAccountProvider = StateProvider<GoogleSignInAccount?>((ref) => null);

class FirebaseSyncService {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription? _remoteSubscription;

  FirebaseSyncService(this._ref);

  // --- 1. AUTHENTICATION ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    final googleSignIn = _ref.read(googleSignInProvider);
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
        return null;
      }

      _ref.read(googleSignInAccountProvider.notifier).state = googleUser;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
      // Main.dart handles starting the listener via authStateChanges stream

      return userCredential.user;
    } catch (e) {
      debugPrint("Firebase Sign In Error: $e");
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
      return null;
    }
  }

  Future<User?> signInSilently() async {
    final googleSignIn = _ref.read(googleSignInProvider);
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
      if (googleUser == null) return null;

      _ref.read(googleSignInAccountProvider.notifier).state = googleUser;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
      return userCredential.user;
    } catch (e) {
      debugPrint("Firebase Silent Sign In Error: $e");
      return null;
    }
  }

  // --- THE BULLETPROOF LOGOUT METHOD ---
  Future<void> signOut() async {
    final googleSignIn = _ref.read(googleSignInProvider);

    stopListeningToCloud();

    // 1. Try to sever Google connection, but DON'T let it crash the app if it fails
    try {
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
    } catch (e) {
      debugPrint("Google Disconnect Error (Safe to ignore): $e");
    }

    // 2. CRITICAL: Force Firebase to sign out. This MUST run.
    await _auth.signOut();

    // 3. Clear the UI states securely
    _ref.invalidate(googleSignInAccountProvider);
    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.hidden);
  }

  // --- 2. REAL-TIME LISTENER (Cloud -> Local Hive) ---

  void startListeningToCloud() {
    final user = _auth.currentUser;
    if (user == null) {
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.hidden);
      return;
    }

    _remoteSubscription?.cancel();
    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);

    debugPrint("Starting Cloud Listener for user: ${user.uid}");

    _remoteSubscription = _db
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .snapshots()
        .listen((snapshot) async {

      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.syncing);

      final box = Hive.box<Game>('games');

      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final String gameId = data['id'];

        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final cloudGame = Game.fromMap(data);

          final existingKey = box.keys.firstWhere(
                  (k) => box.get(k)?.id == gameId,
              orElse: () => null
          );

          if (existingKey != null) {
            await box.put(existingKey, cloudGame);
          } else {
            await box.add(cloudGame);
          }
        } else if (change.type == DocumentChangeType.removed) {
          final existingKey = box.keys.firstWhere(
                  (k) => box.get(k)?.id == gameId,
              orElse: () => null
          );
          if (existingKey != null) {
            await box.delete(existingKey);
          }
        }
      }

      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
    }, onError: (e) {
      debugPrint("Cloud Listen Error: $e");
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
    });
  }

  void stopListeningToCloud() {
    _remoteSubscription?.cancel();
    _remoteSubscription = null;
    debugPrint("Stopped Cloud Listener.");
  }

  // --- 3. PUSH (Local Hive -> Cloud Firestore) ---

  Future<void> migrateAndSyncLocalData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.syncing);

    final box = Hive.box<Game>('games');
    final batch = _db.batch();

    for (var game in box.values) {
      if (game.id.isEmpty) {
        game.id = const Uuid().v4();
        game.save();
      }
      final docRef = _db.collection('users').doc(user.uid).collection('games').doc(game.id);
      batch.set(docRef, _gameToMap(game), SetOptions(merge: true));
    }

    try {
      await batch.commit();
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
    } catch (e) {
      debugPrint("Migration to Cloud Error: $e");
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
    }
  }

  Future<void> saveGameToCloud(Game game) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.syncing);

    if (game.id.isEmpty) {
      game.id = const Uuid().v4();
      game.save();
    }

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('games')
          .doc(game.id)
          .set(_gameToMap(game), SetOptions(merge: true));
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
    } catch (e) {
      debugPrint("Save to Cloud Error: $e");
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
    }
  }

  Future<void> deleteGameFromCloud(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.syncing);

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('games')
          .doc(gameId)
          .delete();
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
    } catch (e) {
      debugPrint("Delete from Cloud Error: $e");
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
    }
  }

  Map<String, dynamic> _gameToMap(Game game) {
    return {
      'id': game.id,
      'title': game.title,
      'platform': game.platform,
      'genre': game.genre,
      'status': game.status.index,
      'dateAdded': game.dateAdded.toIso8601String(),
      'coverUrl': game.coverUrl,
      'summary': game.summary,
      'rating': game.rating,
      'notes': game.notes,
      'isPhysical': game.isPhysical,
      'progress': game.progress,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}