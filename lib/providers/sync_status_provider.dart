import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_status_provider.g.dart';

enum SyncState {
  hidden,   // User not signed in
  synced,   // Green: All good
  syncing,  // Blue: Uploading/Downloading
  unsynced, // Red: Local changes not yet on cloud (or error)
}

@Riverpod(keepAlive: true)
class SyncStatusNotifier extends _$SyncStatusNotifier {
  @override
  SyncState build() {
    return SyncState.hidden; // Default
  }

  void setStatus(SyncState newStatus) {
    state = newStatus;
  }
}