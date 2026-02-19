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

/// Custom HTTP client that injects Google auth headers
class GoogleAuthHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  GoogleAuthHttpClient(this._headers); // Added const constructor where applicable

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

/// GoogleSignIn provider
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: const [drive.DriveApi.driveAppdataScope], // Use const
  );
});

/// Holds the signed-in Google account
final googleSignInAccountProvider =
StateProvider<GoogleSignInAccount?>((ref) => null);

class CloudSyncService {
  final Ref _ref;

  const CloudSyncService(this._ref); // Added const constructor

  /// Returns an authenticated HTTP client for Google APIs
  Future<http.Client?> _getAuthenticatedHttpClient(
      BuildContext context) async {
    final GoogleSignInAccount? account = _ref.read(googleSignInAccountProvider);

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
      if (authHeaders == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get Google authentication headers.')),
          );
        }
        return null;
      }
      return GoogleAuthHttpClient(authHeaders);
    } catch (e) {
      debugPrint('Failed to obtain auth headers: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get Google authentication headers: $e')), // Include error in message
        );
      }
      return null;
    }
  }

  /// Interactive Google sign-in
  Future<GoogleSignInAccount?> signInWithGoogle(
      BuildContext context) async {
    final googleSignIn = _ref.read(googleSignInProvider);

    try {
      final account = await googleSignIn.signIn();
      _ref.read(googleSignInAccountProvider.notifier).state = account;

      if (account == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In cancelled.')),
        );
      }

      return account;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _ref.read(googleSignInAccountProvider.notifier).state = null;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $e')),
        );
      }
      return null;
    }
  }

  /// Silent sign-in
  Future<GoogleSignInAccount?> signInSilently() async {
    final googleSignIn = _ref.read(googleSignInProvider);

    try {
      final account = await googleSignIn.signInSilently();
      _ref.read(googleSignInAccountProvider.notifier).state = account;
      return account;
    } catch (e) {
      debugPrint('Silent sign-in error: $e');
      _ref.read(googleSignInAccountProvider.notifier).state = null;
      return null;
    }
  }

  /// Sign out
  Future<void> signOutGoogle() async {
    final googleSignIn = _ref.read(googleSignInProvider);
    await googleSignIn.signOut();
    _ref.read(googleSignInAccountProvider.notifier).state = null;
    debugPrint('Google user signed out');
  }

  /// Upload Hive data to Google Drive appDataFolder
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
            ..parents = const ['appDataFolder'], // Use const for list
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
      debugPrint('Upload error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload backup: $e')),
        );
      }
    }
  }

  /// Download backup and restore Hive data
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
      await box.clear();

      for (final item in decoded) {
        await box.add(
          Game(
            title: item['title'] ?? 'Unknown',
            platform: item['platform'] ?? 'Unknown',
            genre: item['genre'] ?? 'Unknown',
            status: GameStatus.values[item['status'] ?? 0],
            dateAdded: DateTime.parse(
              item['dateAdded'] ??
                  DateTime.now().toIso8601String(),
            ),
            coverUrl: item['coverUrl'],
            summary: item['summary'],
            rating: (item['rating'] as num?)?.toDouble(),
            notes: item['notes'],
            isPhysical: item['isPhysical'] ?? false,
            progress: (item['progress'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }

      _ref.read(gameListProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Games restored from Google Drive')),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download backup: $e')),
        );
      }
    }
  }
}

/// Provider for CloudSyncService
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(ref);
});