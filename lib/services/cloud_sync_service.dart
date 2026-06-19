import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class CloudSyncService {
  static final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  static Future<void> syncFromCloud() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return;

    final httpClient = (await _googleSignIn.authenticatedClient())!;
    final googleDriveApi = drive.DriveApi(httpClient);

    // Placeholder for search logic
    await googleDriveApi.files.list(
      q: "name = 'gamelog_backup.json'",
      spaces: 'appDataFolder',
    );
  }

  static Future<void> uploadToCloud() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return;

    final httpClient = (await _googleSignIn.authenticatedClient())!;
    // ignore: unused_local_variable
    final googleDriveApi = drive.DriveApi(httpClient);

    // Future implementation: Convert Hive to JSON and upload
  }
}