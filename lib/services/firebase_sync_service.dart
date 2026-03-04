import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:gamelog/models/game.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the service
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  return FirebaseSyncService();
});

class FirebaseSyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- 1. AUTHENTICATION (Google -> Firebase Bridge) ---

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      // A. Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // B. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // C. Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // D. Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Firebase Sign In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // --- 2. DATA MIGRATION (Crucial for v1.0 -> v2.0 update) ---

  /// Loops through local Hive games. If they don't have an ID, give them one.
  /// Then syncs them to Firebase immediately.
  Future<void> migrateAndSyncLocalData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final box = Hive.box<Game>('games');
    final batch = _db.batch(); // Efficient bulk write
    bool needsCommit = false;

    for (var game in box.values) {
      // 1. Assign ID if missing (Migration)
      if (game.id.isEmpty) {
        game.id = const Uuid().v4();
        game.save(); // Save the new ID to local Hive
      }

      // 2. Prepare for Cloud Upload
      final docRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('games')
          .doc(game.id); // Use the UUID as the document ID

      batch.set(docRef, _gameToMap(game), SetOptions(merge: true));
      needsCommit = true;
    }

    if (needsCommit) {
      await batch.commit();
      print("Migration: Synced ${box.length} games to Firebase.");
    }
  }

  // --- 3. REAL-TIME SYNC (The Magic) ---

  /// Saves a single game to Firebase (Call this when adding/editing)
  Future<void> saveGameToCloud(Game game) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Ensure ID exists
    if (game.id.isEmpty) {
      game.id = const Uuid().v4();
      game.save();
    }

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .doc(game.id)
        .set(_gameToMap(game), SetOptions(merge: true));
  }

  /// Deletes a game from Firebase
  Future<void> deleteGameFromCloud(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .doc(gameId)
        .delete();
  }

  // --- HELPERS ---

  Map<String, dynamic> _gameToMap(Game game) {
    return {
      'id': game.id,
      'title': game.title,
      'platform': game.platform,
      'genre': game.genre,
      'status': game.status.index, // Store Enum as Int
      'dateAdded': game.dateAdded.toIso8601String(),
      'coverUrl': game.coverUrl,
      'summary': game.summary,
      'rating': game.rating,
      'notes': game.notes,
      'isPhysical': game.isPhysical,
      'progress': game.progress,
      'lastUpdated': FieldValue.serverTimestamp(), // Helps with conflict resolution later
    };
  }
}