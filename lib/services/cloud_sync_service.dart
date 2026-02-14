import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class CloudSyncService {
  static final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope], // Only access the app's own folder
  );

  /// Sign in and Sync from Drive
  static Future<void> syncFromCloud() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return;

    final httpClient = (await _googleSignIn.authenticatedClient())!;
    final googleDriveApi = drive.DriveApi(httpClient);

    // 1. Find the backup file in the hidden 'appDataFolder'
    final fileList = await googleDriveApi.files.list(
      q: "name = 'gamelog_backup.json'",
      spaces: 'appDataFolder',
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final driveFile = fileList.files!.first;
      // 2. Download and overwrite local Hive data (Careful: This replaces local data)
      // Logic for merging local/cloud goes here
    }
  }

  /// Upload current Hive box to Google Drive
  static Future<void> uploadToCloud() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return;

    final httpClient = (await _googleSignIn.authenticatedClient())!;
    final googleDriveApi = drive.DriveApi(httpClient);

    // Convert Hive to JSON (use the logic from our BackupService)
    // Upload as a 'Media' object to Google Drive
  }
}