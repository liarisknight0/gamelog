import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart'; // Make sure this is imported to use GameStatus
import 'package:gamelog/screens/add_edit_game_screen.dart';
import 'package:gamelog/screens/archive_screen.dart';
import 'package:gamelog/screens/backlog_screen.dart';
import 'package:gamelog/screens/collection_screen.dart';
import 'package:gamelog/screens/home_screen.dart';
import 'package:gamelog/screens/profile_screen.dart';
import 'package:gamelog/screens/support_screen.dart';
// import 'package:flutter/services.dart'; // This is no longer needed here, moved to main.dart
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

    if (appOpenCount < 5) return;

    final lastPopupDateString = prefs.getString('lastSupportPopupDate');
    if (lastPopupDateString != null) {
      final lastPopupDate = DateTime.parse(lastPopupDateString);
      if (DateTime.now().difference(lastPopupDate).inDays < 30) return;
    }

    if (mounted) _showSupportDialog(context);
  }

  void _showSupportDialog(BuildContext context) async {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSupportPopupDate', DateTime.now().toIso8601String());
  }

  void _showAddGameMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          // Ensure padding from the bottom system navigation bar.
          // Setting just `bottom: true` or `top: false, bottom: true` is often enough.
          // The `Container` inside will then respect this padding.
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
      // The SystemChrome in main.dart handles drawing behind bars.
      // This SafeArea handles padding for content within the Scaffold's body itself.
      body: SafeArea(
        top: false, // AppBar takes care of top padding
        bottom: false, // BottomNavigationBar takes care of bottom padding
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