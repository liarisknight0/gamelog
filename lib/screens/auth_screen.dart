import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/screens/main_screen.dart';
import 'package:gamelog/services/cloud_sync_service.dart';
import 'package:gamelog/widgets/loading_overlay.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  // Helper to navigate to main screen and CLEAR history
  void _navigateToMainScreen(BuildContext context) {
    if (context.mounted) {
      // pushAndRemoveUntil deletes the 'Back' history
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _handleGoogleSignInAndImport(BuildContext context, WidgetRef ref) async {
    // 1. Show Loading while signing in
    LoadingOverlay.show(context);

    try {
      final cloudSync = ref.read(cloudSyncServiceProvider);
      final account = await cloudSync.signInWithGoogle(context);

      // 2. IMPORTANT: Hide Loading IMMEDIATELY after sign-in attempt
      LoadingOverlay.hide();

      if (account != null && context.mounted) {
        // Show a small message so the user knows what's happening during the wait
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in successful. Checking for backups...')),
        );

        // 3. The 10-Second Delay (As requested)
        await Future.delayed(const Duration(seconds: 10));

        if (!context.mounted) return;

        // 4. Now Show the Dialog (Screen is clear)
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
                  Navigator.of(dialogCtx).pop();
                  _navigateToMainScreen(context);
                },
                child: const Text('No, Start Fresh'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogCtx).pop(); // Close dialog first

                  // Show loading again strictly for the download part
                  LoadingOverlay.show(context);
                  await cloudSync.downloadBackupFromDrive(context);
                  LoadingOverlay.hide();

                  if (context.mounted) {
                    _navigateToMainScreen(context);
                  }
                },
                child: const Text('Yes, Import Data'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Safety net: ensure loading is hidden if anything crashes
      LoadingOverlay.hide();
      debugPrint("Auth Error: $e");
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

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                  ),
                  label: const Text('Sign in with Google'),
                  onPressed: () => _handleGoogleSignInAndImport(context, ref),
                ),
              ),
              const SizedBox(height: 24),

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