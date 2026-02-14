import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/providers/theme_provider.dart';
import 'package:gamelog/widgets/profile_menu_widgets.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- FIX 1: Watch the new provider ---
    final currentThemeMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          const SectionTitle(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark theme'),
            value: currentThemeMode == ThemeMode.dark,
            onChanged: (isDarkMode) {
              // --- FIX 2: Call the notifier method on the new provider ---
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
            secondary: const Icon(Icons.brightness_6_outlined),
          ),
        ],
      ),
    );
  }
}