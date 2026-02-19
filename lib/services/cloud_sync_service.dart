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

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: const [drive.DriveApi.driveAppdataScope],
  );
});

final googleSignInAccountProvider =
StateProvider<GoogleSignInAccount?>((ref) => null);

class CloudSyncService {
  final Ref _ref;

  const CloudSyncService(this._ref);

  Future<http.Client?> _getAuthenticatedHttpClient(BuildContext context) async {
    final GoogleSignInAccount? account = _ref.read(googleSignInAccountProvider);

    // ignore: unnecessary_null_comparison
    if (account == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to Google first.')),
        );
      }
      return null;
    }

    try {
      final authHeaders = await account.authHeaders;
      return GoogleAuthHttpClient(authHeaders);
    } catch (e) {
      debugPrint('Failed to obtain auth headers: $e');
      return null;
    }
  }

  Future<GoogleSignInAccount?> signInWithGoogle(BuildContext context) async {
    final googleSignIn = _ref.read(googleSignInProvider);
    try {
      final account = await googleSignIn.signIn();
      _ref.read(googleSignInAccountProvider.notifier).state = account;
      return account;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _ref.read(googleSignInAccountProvider.notifier).state = null;
      return null;
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    final googleSignIn = _ref.read(googleSignInProvider);
    try {
      final account = await googleSignIn.signInSilently();
      _ref.read(googleSignInAccountProvider.notifier).state = account;
      return account;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOutGoogle() async {
    final googleSignIn = _ref.read(googleSignInProvider);
    await googleSignIn.signOut();
    _ref.read(googleSignInAccountProvider.notifier).state = null;
  }

  Future<void> uploadBackupToDrive(BuildContext context) async {
    final httpClient = await _getAuthenticatedHttpClient(context);
    if (httpClient == null) return;

    final driveApi = drive.DriveApi(httpClient);
    final box = Hive.box<Game>('games');

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

    const fileName = 'gamelog_backup.json';
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));

    try {
      final files = await driveApi.files.list(
        q: "name = '$fileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (files.files != null && files.files!.isNotEmpty) {
        final fileId = files.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: drive.Media(
            Stream.value(jsonBytes),
            jsonBytes.length,
            contentType: 'application/json',
          ),
        );
      } else {
        await driveApi.files.create(
          drive.File()
            ..name = fileName
            ..parents = const ['appDataFolder'],
          uploadMedia: drive.Media(
            Stream.value(jsonBytes),
            jsonBytes.length,
            contentType: 'application/json',
          ),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup uploaded to Google Drive')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload backup: $e')),
        );
      }
    }
  }

  Future<void> downloadBackupFromDrive(BuildContext context) async {
    final httpClient = await _getAuthenticatedHttpClient(context);
    if (httpClient == null) return;

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

      // NOTE: We DO NOT box.clear() anymore. We merge.
      int addedCount = 0;

      for (final item in decoded) {
        final String newTitle = item['title'] ?? 'Unknown';
        final String newPlatform = item['platform'] ?? 'Unknown';

        // --- DUPLICATE CHECK LOGIC ---
        // Check if we already have a game with the same Title AND Platform.
        // We trim spaces and use lowerCase to be safe (e.g. "Halo " vs "Halo").
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
              dateAdded: DateTime.parse(
                item['dateAdded'] ?? DateTime.now().toIso8601String(),
              ),
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Complete: $addedCount new games added.')),
        );
      }
    } catch (e) {
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