import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/sync_status_provider.dart'; // <--- NEW IMPORT
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the service
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  return FirebaseSyncService(ref);
});

class FirebaseSyncService {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  StreamSubscription? _remoteSubscription;

  FirebaseSyncService(this._ref);

  // --- 1. AUTH ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Update UI Status
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
      startListeningToCloud();

      return userCredential.user;
    } catch (e) {
      print("Firebase Sign In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    _remoteSubscription?.cancel();
    await _googleSignIn.signOut();
    await _auth.signOut();
    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.hidden);
  }

  // --- 2. LISTENER (Cloud -> Local) ---

  void startListeningToCloud() {
    final user = _auth.currentUser;
    if (user == null) {
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.hidden);
      return;
    }

    _remoteSubscription?.cancel();
    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);

    _remoteSubscription = _db
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .snapshots()
        .listen((snapshot) async {

      // Briefly show blue syncing status
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.syncing);

      final box = Hive.box<Game>('games');
      bool localStateChanged = false;

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
          localStateChanged = true;

        } else if (change.type == DocumentChangeType.removed) {
          final existingKey = box.keys.firstWhere(
                  (k) => box.get(k)?.id == gameId,
              orElse: () => null
          );
          if (existingKey != null) {
            await box.delete(existingKey);
            localStateChanged = true;
          }
        }
      }

      if (localStateChanged) {
        _ref.read(gameListProvider.notifier).refresh();
      }

      // Set back to Green
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
    }, onError: (e) {
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
    });
  }

  // --- 3. PUSH (Local -> Cloud) ---

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

    await batch.commit();
    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
    startListeningToCloud();
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