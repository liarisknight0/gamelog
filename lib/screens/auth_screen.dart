import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/screens/main_screen.dart';
// import 'package:gamelog/services/cloud_sync_service.dart'; // REMOVE old drive service
import 'package:gamelog/services/firebase_sync_service.dart'; // <--- NEW Firebase Service
import 'package:gamelog/widgets/loading_overlay.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  /// Handles Google Sign-In via Firebase
  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    LoadingOverlay.show(context);

    try {
      final firebaseSync = ref.read(firebaseSyncServiceProvider);

      // 1. Attempt to Sign In
      final user = await firebaseSync.signInWithGoogle();

      // 2. Check if successful
      if (user != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed in successfully! Preparing your library...')),
          );
        }

        // 3. MIGRATE & SYNC
        // This is the critical step: It checks your local Hive games.
        // If they lack IDs, it assigns them. Then it uploads everything to Firestore.
        await firebaseSync.migrateAndSyncLocalData();

        LoadingOverlay.hide();

        // 4. Navigate to Main App
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
          );
        }
      } else {
        // User cancelled login
        LoadingOverlay.hide();
      }
    } catch (e) {
      LoadingOverlay.hide();
      debugPrint("Auth Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $e")),
        );
      }
    }
  }

  /// Continues without logging in (Offline Mode)
  void _continueAsGuest(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
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
              // App Logo
              Icon(
                Icons.gamepad_outlined,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // Welcome Text
              Text(
                'Welcome to GameLog!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to enable real-time cloud sync across all your devices.',
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
                    'assets/images/google_logo.png',
                    height: 24,
                  ),
                  label: const Text('Sign in with Google'),
                  onPressed: () => _handleGoogleSignIn(context, ref),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        width: 1
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Guest Button
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