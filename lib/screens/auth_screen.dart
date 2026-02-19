import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/screens/main_screen.dart';
import 'package:gamelog/services/cloud_sync_service.dart';
import 'package:gamelog/widgets/loading_overlay.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  // Handle Google Login
  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    LoadingOverlay.show(context);

    try {
      final cloudSync = ref.read(cloudSyncServiceProvider);
      final account = await cloudSync.signInWithGoogle(context);

      LoadingOverlay.hide(); // Hide spinner immediately

      if (account != null && context.mounted) {
        // Navigate IMMEDIATELY to MainScreen
        // Pass 'checkDriveBackup: true' to trigger the 10s delayed popup
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainScreen(checkDriveBackup: true),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      LoadingOverlay.hide();
      debugPrint("Auth Error: $e");
    }
  }

  // Handle Guest Mode
  void _continueAsGuest(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      // Guest mode: checkDriveBackup is false (default)
      MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
    );
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
                  onPressed: () => _handleGoogleSignIn(context, ref),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => _continueAsGuest(context),
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