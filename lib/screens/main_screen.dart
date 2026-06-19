import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/screens/add_edit_game_screen.dart';
import 'package:gamelog/screens/archive_screen.dart';
import 'package:gamelog/screens/backlog_screen.dart';
import 'package:gamelog/screens/collection_screen.dart';
import 'package:gamelog/screens/home_screen.dart';
import 'package:gamelog/screens/profile_screen.dart';
import 'package:gamelog/screens/support_screen.dart';
import 'package:gamelog/services/backup_service.dart'; // <--- NEW IMPORT
import 'package:shared_preferences/shared_preferences.dart';

// Default to index 2 (Now Playing).
final mainScreenIndexProvider = StateProvider<int>((ref) => 2);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAppStartupLogic();
    });
  }

  Future<void> _handleAppStartupLogic() async {
    final prefs = await SharedPreferences.getInstance();
    int appOpenCount = prefs.getInt('appOpenCount') ?? 0;
    appOpenCount++;
    await prefs.setInt('appOpenCount', appOpenCount);

    // --- NEW: Backup Reminder Logic ---
    // Show backup reminder every 10 opens after the first 5
    if (appOpenCount > 5 && appOpenCount % 10 == 0) {
      final lastBackupReminderDateString = prefs.getString('lastBackupReminderDate');
      if (lastBackupReminderDateString != null) {
        final lastReminderDate = DateTime.parse(lastBackupReminderDateString);
        // Only show if it hasn't been shown recently (e.g., within 7 days)
        if (DateTime.now().difference(lastReminderDate).inDays < 7) {
          // If already shown recently, skip for now.
        } else {
          if (mounted) _showBackupReminderDialog(context);
        }
      } else {
        // If never shown, show it.
        if (mounted) _showBackupReminderDialog(context);
      }
      // Update last reminder date regardless of whether dialog was shown, to prevent spam
      await prefs.setString('lastBackupReminderDate', DateTime.now().toIso8601String());
    }
    // --- END NEW Backup Reminder Logic ---

    // Existing Support Dialog Logic
    if (appOpenCount < 5) return; // Keep this check to separate support from backup

    final lastPopupDateString = prefs.getString('lastSupportPopupDate');
    if (lastPopupDateString != null) {
      final lastPopupDate = DateTime.parse(lastPopupDateString);
      if (DateTime.now().difference(lastPopupDate).inDays < 30) return;
    }

    if (mounted) _showSupportDialog(context);
    await prefs.setString('lastSupportPopupDate', DateTime.now().toIso8601String()); // Moved this line here
  }

  // --- NEW: Backup Reminder Dialog ---
  void _showBackupReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Don\'t Lose Your Games!'),
        content: const Text(
            "It looks like you've been using GameLog a lot. Don't forget to export a backup of your collection to Google Drive or email!"
        ),
        actions: [
          TextButton(
            child: const Text('Later'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            child: const Text('Export Now'),
            onPressed: () {
              Navigator.of(ctx).pop();
              BackupService.exportBackup(context); // Trigger the export
            },
          ),
        ],
      ),
    );
  }
  // --- END NEW Backup Reminder Dialog ---

  void _showSupportDialog(BuildContext context) async { // Removed await prefs.setString... from here
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enjoying GameLog?'),
        content: const Text(
            "We're always working to make GameLog better! Explore our roadmap or suggest a new feature."
        ),
        actions: [
          TextButton(
            child: const Text('Maybe Later'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            child: const Text('Explore & Support'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
          ),
        ],
      ),
    );
    // await prefs.setString('lastSupportPopupDate', DateTime.now().toIso8601String()); // Moved up
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
      const HomeScreen(),
      const ArchiveScreen(),
      const ProfileScreen(),
    ];

    final fabVisible = selectedIndex < 4; // Hide on Profile

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: screens[selectedIndex],
      ),

      floatingActionButton: fabVisible
          ? FloatingActionButton(
        onPressed: () => _showAddGameMenu(context),
        child: const Icon(Icons.add),
      )
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