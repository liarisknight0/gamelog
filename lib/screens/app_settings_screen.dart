import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/theme_provider.dart';
import 'package:gamelog/services/backup_service.dart';
import 'package:gamelog/widgets/profile_menu_widgets.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          // --- APPEARANCE ---
          const SectionTitle(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark theme'),
            value: currentThemeMode == ThemeMode.dark,
            onChanged: (isDarkMode) {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
            secondary: const Icon(Icons.brightness_6_outlined),
          ),

          const Divider(),

          // --- BACKUP & RESTORE ---
          const SectionTitle(title: 'Data Management'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Backup'),
            subtitle: const Text('Save your library to Google Drive or Email'),
            onTap: () => BackupService.exportBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore games from a previous backup file'),
            onTap: () {
              BackupService.importBackup(context, () {
                // Refresh the game list provider after import
                ref.read(gameListProvider.notifier).refresh();
              });
            },
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Note: Importing a backup adds games to your current list. It does not delete existing data.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}