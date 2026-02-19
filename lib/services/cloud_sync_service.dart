import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/sync_status_provider.dart'; // <--- NEW IMPORT

/// Custom HTTP client that injects Google auth headers
class GoogleAuthHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  GoogleAuthHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

/// GoogleSignIn provider
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: const [drive.DriveApi.driveAppdataScope],
  );
});

/// Holds the signed-in Google account
final googleSignInAccountProvider =
StateProvider<GoogleSignInAccount?>((ref) => null);

class CloudSyncService {
  final Ref _ref;

  const CloudSyncService(this._ref);

  /// INTERNAL: Returns authenticated client without UI feedback (for AutoSync)
  Future<http.Client?> _getHttpClient() async {
    final GoogleSignInAccount? account = _ref.read(googleSignInAccountProvider);

    // ignore: unnecessary_null_comparison
    if (account == null)

    try {
      final authHeaders = await account.authHeaders;
      if (authHeaders == null) return null;
      return GoogleAuthHttpClient(authHeaders);
    } catch (e) {
      debugPrint('Auth header error: $e');
      return null;
    }
  }

  // --- AUTHENTICATION ---

  Future<GoogleSignInAccount?> signInWithGoogle(BuildContext context) async {
    final googleSignIn = _ref.read(googleSignInProvider);
    try {
      final account = await googleSignIn.signIn();
      _ref.read(googleSignInAccountProvider.notifier).state = account;

      if (account != null) {
        // If sign-in success, assume synced or ready to sync
        _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
      }
      return account;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $e')),
        );
      }
      return null;
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    final googleSignIn = _ref.read(googleSignInProvider);
    try {
      final account = await googleSignIn.signInSilently();
      _ref.read(googleSignInAccountProvider.notifier).state = account;

      if (account != null) {
        _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
      }
      return account;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOutGoogle() async {
    final googleSignIn = _ref.read(googleSignInProvider);
    await googleSignIn.signOut();
    _ref.read(googleSignInAccountProvider.notifier).state = null;
    // Hide the sync icon when signed out
    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.hidden);
  }

  // --- AUTO SYNC (Background) ---

  /// Uploads data silently. Updates SyncStatus (Blue -> Green/Red).
  Future<void> autoSync() async {
    final account = _ref.read(googleSignInAccountProvider);
    // If not signed in, do nothing (or hide status)
    if (account == null) {
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.hidden);
      return;
    }

    // 1. Set Status: SYNCING (Blue)
    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.syncing);

    final httpClient = await _getHttpClient();
    if (httpClient == null) {
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
      return;
    }

    try {
      final driveApi = drive.DriveApi(httpClient);
      final box = Hive.box<Game>('games');

      // Prepare Data
      final data = box.values.map((game) {
        return {
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
        };
      }).toList();

      final String jsonString = jsonEncode(data);
      const fileName = 'gamelog_backup.json';
      const mimeType = 'application/json';
      final Uint8List fileBytes = utf8.encode(jsonString);

      // Check for existing file
      final files = await driveApi.files.list(
        q: "name = '$fileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      final media = drive.Media(
        Stream.value(fileBytes),
        fileBytes.length,
        contentType: mimeType,
      );

      if (files.files != null && files.files!.isNotEmpty) {
        // Update existing
        final fileId = files.files!.first.id!;
        await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
      } else {
        // Create new
        await driveApi.files.create(
          drive.File()..name = fileName..parents = const ['appDataFolder'],
          uploadMedia: media,
        );
      }

      // 2. Set Status: SYNCED (Green)
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);

    } catch (e) {
      debugPrint("Auto Sync Error: $e");
      // 3. Set Status: UNSYNCED (Red)
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
    }
  }

  // --- MANUAL METHODS (For Profile Screen) ---

  Future<void> uploadBackupToDrive(BuildContext context) async {
    // Reuse the autoSync logic, but add UI feedback
    await autoSync();

    if (context.mounted) {
      final status = _ref.read(syncStatusNotifierProvider);
      if (status == SyncState.synced) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup uploaded to Google Drive!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Check your connection.')),
        );
      }
    }
  }

  Future<void> downloadBackupFromDrive(BuildContext context) async {
    // Set status to syncing while downloading
    _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.syncing);

    final httpClient = await _getHttpClient();
    if (httpClient == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to Google first.')),
        );
      }
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
      return;
    }

    final driveApi = drive.DriveApi(httpClient);
    const fileName = 'gamelog_backup.json';

    try {
      final files = await driveApi.files.list(
        q: "name = '$fileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (files.files == null || files.files!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup found on Google Drive')),
          );
        }
        // Nothing found is technically "synced" (nothing to fetch)
        _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
        return;
      }

      final fileId = files.files!.first.id!;
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final decoded = jsonDecode(utf8.decode(bytes)) as List<dynamic>;
      final box = Hive.box<Game>('games');
      int addedCount = 0;

      // SMART MERGE LOGIC
      for (final item in decoded) {
        final String newTitle = item['title'] ?? 'Unknown';
        final String newPlatform = item['platform'] ?? 'Unknown';

        final bool exists = box.values.any((existingGame) =>
        existingGame.title.trim().toLowerCase() == newTitle.trim().toLowerCase() &&
            existingGame.platform == newPlatform
        );

        if (!exists) {
          await box.add(
            Game(
              title: newTitle,
              platform: newPlatform,
              genre: item['genre'] ?? 'Unknown',
              status: GameStatus.values[item['status'] ?? 0],
              dateAdded: DateTime.parse(item['dateAdded'] ?? DateTime.now().toIso8601String()),
              coverUrl: item['coverUrl'],
              summary: item['summary'],
              rating: (item['rating'] as num?)?.toDouble(),
              notes: item['notes'],
              isPhysical: item['isPhysical'] ?? false,
              progress: (item['progress'] as num?)?.toDouble() ?? 0.0,
            ),
          );
          addedCount++;
        }
      }

      _ref.read(gameListProvider.notifier).refresh();
      // Set Status: SYNCED (Green)
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Complete: $addedCount new games added.')),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      _ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.unsynced);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download backup: $e')),
        );
      }
    }
  }
}

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref);
});