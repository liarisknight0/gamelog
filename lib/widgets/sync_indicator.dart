import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/providers/sync_status_provider.dart';
import 'package:gamelog/services/firebase_sync_service.dart'; // <--- UPDATED

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusNotifierProvider);

    if (status == SyncState.hidden) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String tooltip;
    bool isSpinning = false;

    switch (status) {
      case SyncState.synced:
        icon = Icons.cloud_done_outlined;
        color = Colors.green;
        tooltip = "Data Synced";
        break;
      case SyncState.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = "Syncing...";
        isSpinning = true;
        break;
      case SyncState.unsynced:
        icon = Icons.cloud_off_outlined;
        color = Colors.red;
        tooltip = "Not Synced (Tap to Retry)";
        break;
      default:
        return const SizedBox.shrink();
    }

    Widget iconWidget = Icon(icon, color: color);

    if (isSpinning) {
      iconWidget = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: color)
      );
    }

    return IconButton(
      icon: iconWidget,
      tooltip: tooltip,
      onPressed: () {
        if (status == SyncState.unsynced) {
          // Retry logic: Trigger migration/sync again
          ref.read(firebaseSyncServiceProvider).migrateAndSyncLocalData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retrying Sync...')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tooltip), duration: const Duration(seconds: 1)),
          );
        }
      },
    );
  }
}