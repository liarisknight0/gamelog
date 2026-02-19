import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/screens/main_screen.dart';
import 'package:gamelog/services/cloud_sync_service.dart';
import 'package:gamelog/widgets/loading_overlay.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  // Helper to navigate to the main screen after an action
  void _navigateToMainScreen(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  // Handles Google Sign-In and then immediately prompts for Drive import
  Future<void> _handleGoogleSignInAndImport(BuildContext context, WidgetRef ref) async {
    LoadingOverlay.show(context); // Show loading spinner

    try {
      final cloudSync = ref.read(cloudSyncServiceProvider);
      final account = await cloudSync.signInWithGoogle(context);

      if (account != null) {
        // User signed in. Now, prompt to import from Drive.
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('Import from Google Drive?'),
              content: const Text(
                  'Would you like to download your GameLog backup from Google Drive now? This will replace your current local data.'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop(); // Dismiss dialog
                    _navigateToMainScreen(context); // Go to main screen without import
                  },
                  child: const Text('No, Start Fresh'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop(); // Dismiss dialog
                    LoadingOverlay.show(context); // Show loading again for download
                    await cloudSync.downloadBackupFromDrive(context);
                    LoadingOverlay.hide();
                    _navigateToMainScreen(context); // Go to main screen after import
                  },
                  child: const Text('Yes, Import Data'),
                ),
              ],
            ),
          );
        }
      }
    } finally {
      LoadingOverlay.hide(); // Hide loading spinner in case of error or cancellation
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo or Icon
              Icon(
                Icons.gamepad_outlined,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to GameLog!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to sync your game library or continue as a guest.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: Image.asset(
                    'assets/images/google_logo.png', // Add a Google logo asset
                    height: 24,
                  ),
                  label: const Text('Sign in with Google'),
                  onPressed: () => _handleGoogleSignInAndImport(context, ref),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Continue as Guest Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => _navigateToMainScreen(context),
                  child: const Text('Continue as Guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}