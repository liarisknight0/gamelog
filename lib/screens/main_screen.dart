import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart'; // Needed for refresh
import 'package:gamelog/screens/add_edit_game_screen.dart';
import 'package:gamelog/screens/archive_screen.dart';
import 'package:gamelog/screens/backlog_screen.dart';
import 'package:gamelog/screens/collection_screen.dart';
import 'package:gamelog/screens/home_screen.dart';
import 'package:gamelog/screens/profile_screen.dart';
import 'package:gamelog/screens/support_screen.dart';
import 'package:gamelog/services/backup_service.dart';
import 'package:gamelog/services/cloud_sync_service.dart'; // Needed for Drive download
import 'package:gamelog/widgets/loading_overlay.dart'; // Needed for spinner
import 'package:shared_preferences/shared_preferences.dart';

final mainScreenIndexProvider = StateProvider<int>((ref) => 2); // 2 = Now Playing

class MainScreen extends ConsumerStatefulWidget {
  final bool checkDriveBackup; // New flag to trigger the delayed check

  const MainScreen({super.key, this.checkDriveBackup = false});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAppStartupLogic();

      // If we came from Google Login, start the 10s timer
      if (widget.checkDriveBackup) {
        _scheduleDriveBackupCheck();
      }
    });
  }

  // --- NEW: Delayed Drive Check Logic ---
  Future<void> _scheduleDriveBackupCheck() async {
    // 1. Wait 10 seconds while user enjoys the app
    await Future.delayed(const Duration(seconds: 10));

    if (!mounted) return;

    // 2. Show the Import Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Import from Google Drive?'),
        content: const Text(
            'We noticed you just signed in. Would you like to download your backup from Google Drive? This will replace your current local data.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('No, Keep Fresh'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop(); // Close dialog

              // Perform Download
              LoadingOverlay.show(context);
              await ref.read(cloudSyncServiceProvider).downloadBackupFromDrive(context);
              ref.read(gameListProvider.notifier).refresh(); // Refresh UI
              LoadingOverlay.hide();
            },
            child: const Text('Yes, Import Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAppStartupLogic() async {
    final prefs = await SharedPreferences.getInstance();
    int appOpenCount = prefs.getInt('appOpenCount') ?? 0;
    appOpenCount++;
    await prefs.setInt('appOpenCount', appOpenCount);

    // Backup Reminder (Local Export)
    if (appOpenCount > 5 && appOpenCount % 10 == 0) {
      if (mounted) _showBackupReminderDialog(context);
    }

    // Support Dialog
    if (appOpenCount < 5) return;
    final lastPopupDateString = prefs.getString('lastSupportPopupDate');
    if (lastPopupDateString != null) {
      final lastPopupDate = DateTime.parse(lastPopupDateString);
      if (DateTime.now().difference(lastPopupDate).inDays < 30) return;
    }
    if (mounted) _showSupportDialog(context);
  }

  void _showBackupReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Don\'t Lose Your Games!'),
        content: const Text("Don't forget to export a backup of your collection!"),
        actions: [
          TextButton(child: const Text('Later'), onPressed: () => Navigator.of(ctx).pop()),
          FilledButton(
            child: const Text('Export Now'),
            onPressed: () {
              Navigator.of(ctx).pop();
              BackupService.exportBackup(context);
            },
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enjoying GameLog?'),
        content: const Text("Explore our roadmap or suggest a new feature."),
        actions: [
          TextButton(child: const Text('Maybe Later'), onPressed: () => Navigator.of(ctx).pop()),
          FilledButton(
            child: const Text('Explore & Support'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen()));
            },
          ),
        ],
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSupportPopupDate', DateTime.now().toIso8601String());
  }

  void _showAddGameMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: const Text('Add to Backlog'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AddEditGameScreen(defaultStatus: GameStatus.backlog),
                    ));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Add to Now Playing'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AddEditGameScreen(defaultStatus: GameStatus.nowPlaying),
                    ));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Add to Archive'),
                  subtitle: const Text('For a game you already beat'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AddEditGameScreen(defaultStatus: GameStatus.beaten),
                    ));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);
    final List<Widget> screens = [
      const CollectionScreen(),
      const BacklogScreen(),
      const HomeScreen(), // This is "Now Playing" (Index 2)
      const ArchiveScreen(),
      const ProfileScreen(),
    ];
    final fabVisible = selectedIndex < 4;

    return Scaffold(
      body: SafeArea(top: false, bottom: false, child: screens[selectedIndex]),
      floatingActionButton: fabVisible
          ? FloatingActionButton(onPressed: () => _showAddGameMenu(context), child: const Icon(Icons.add))
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(mainScreenIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark_outlined), label: 'Collection'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Backlog'),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad_outlined), label: 'Now Playing'),
          BottomNavigationBarItem(icon: Icon(Icons.archive_outlined), label: 'Archive'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}