import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/providers/game_provider.dart'; // Needed to refresh games after import
import 'package:gamelog/screens/main_screen.dart'; // To navigate after actions
import 'package:gamelog/services/backup_service.dart'; // To handle import action

class WelcomeDialog extends ConsumerWidget {
  const WelcomeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Welcome to GameLog!'),
      content: const SingleChildScrollView( // Use SingleChildScrollView for longer content
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Thanks for purchasing GameLog! We're thrilled to have you."),
            SizedBox(height: 16),
            Text("Your journey to conquer your backlog starts now. Expect exciting new features like:"),
            SizedBox(height: 8),
            Text("- In-depth Stats Dashboard"),
            Text("- Automatic Cloud Sync"),
            Text("- HowLongToBeat Integration"),
            Text("- And much more coming soon!"),
            SizedBox(height: 16),
            Text("GameLog will only get better with your support and suggestions."),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // "Start New Collection" simply dismisses the dialog and goes to MainScreen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          },
          child: const Text('Start New Collection'),
        ),
        FilledButton(
          onPressed: () async {
            // "Import Collection" triggers the backup service
            // The `onComplete` callback will navigate to MainScreen after import
            Navigator.of(context).pop(); // Dismiss the dialog first
            await BackupService.importBackup(context, () {
              ref.read(gameListProvider.notifier).refresh(); // Refresh state
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              }
            });
          },
          child: const Text('Import Collection'),
        ),
      ],
    );
  }
}