import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart'; // Needed to clear data on logout

import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/user_settings_provider.dart';
import 'package:gamelog/screens/about_screen.dart';
import 'package:gamelog/screens/app_settings_screen.dart';
import 'package:gamelog/screens/support_screen.dart';
import 'package:gamelog/screens/auth_screen.dart'; // Needed for logout navigation
import 'package:gamelog/services/cloud_sync_service.dart';
import 'package:gamelog/widgets/profile_menu_widgets.dart';
import 'package:gamelog/widgets/loading_overlay.dart'; // Needed for logout spinner

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Opens a dialog to change the user's local display name.
  void _showChangeNameDialog(BuildContext context, WidgetRef ref) {
    final currentName = ref.read(userNameProvider);
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Account Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New Name',
            hintText: 'Enter your name...',
          ),
        ),
        actions:[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                ref.read(userNameProvider.notifier).updateName(newName);
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  /// Opens the gallery to pick a new local profile picture.
  Future<void> _pickProfileImage(WidgetRef ref, BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      ref.read(profileImageProvider.notifier).updateImage(image.path);
    }
  }

  /// Builds the stat box for total games.
  Widget _buildTotalGamesStat(int count, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Icon(Icons.collections_bookmark,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'Total Games Added: $count',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Master Logout Logic
  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    final googleAccount = ref.read(googleSignInAccountProvider);

    LoadingOverlay.show(context);
    try {
      if (googleAccount != null) {
        // 1. Auto-Sync to Drive before logging out to ensure safety
        await ref.read(cloudSyncServiceProvider).autoSync();
        // 2. Sign out of Google
        await ref.read(cloudSyncServiceProvider).signOutGoogle();
      }

      // 3. Clear local Hive database so the next user starts fresh
      await Hive.box<Game>('games').clear();
      ref.read(gameListProvider.notifier).refresh();

      // 4. Navigate back to Auth Screen
      LoadingOverlay.hide();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      LoadingOverlay.hide();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local Data
    final localUserName = ref.watch(userNameProvider);
    final localProfilePath = ref.watch(profileImageProvider);
    final totalGames = ref.watch(gameListProvider).length;

    // Google Data
    final googleAccount = ref.watch(googleSignInAccountProvider);
    final isGoogleSignedIn = googleAccount != null;

    // --- DYNAMIC OVERRIDES ---
    // If signed in, use Google name. Otherwise, use local name.
    final displayString = isGoogleSignedIn
        ? (googleAccount.displayName ?? localUserName)
        : localUserName;

    // Determine the Avatar Image
    ImageProvider? avatarImage;
    if (isGoogleSignedIn && googleAccount.photoUrl != null) {
      avatarImage = NetworkImage(googleAccount.photoUrl!);
    } else if (localProfilePath != null && File(localProfilePath).existsSync()) {
      avatarImage = FileImage(File(localProfilePath));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        children:[
          const SizedBox(height: 30),

          // --- PROFILE PICTURE SECTION ---
          Center(
            child: GestureDetector(
              // Disable local image picker if using Google Account photo
              onTap: isGoogleSignedIn
                  ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Using Google Profile Picture')))
                  : () => _pickProfileImage(ref, context),
              child: Stack(
                children:[
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Icon(Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  if (!isGoogleSignedIn) // Only show camera icon for guests
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- USER NAME ---
          Center(
            child: Text(
              displayString,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // Display email under name if signed in
          if (isGoogleSignedIn)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  googleAccount.email,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // --- STATS BOX ---
          _buildTotalGamesStat(totalGames, context),

          const SizedBox(height: 24),
          const Divider(indent: 16, endIndent: 16),

          // --- CLOUD SYNC SECTION ---
          const SectionTitle(title: 'Cloud Sync'),
          if (!isGoogleSignedIn)
            ProfileMenuItem(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Sign in with Google',
              onTap: () => ref.read(cloudSyncServiceProvider).signInWithGoogle(context),
            )
          else ...[
            ProfileMenuItem(
              icon: Icons.cloud_upload_outlined,
              title: 'Force Upload to Drive',
              onTap: () => ref.read(cloudSyncServiceProvider).uploadBackupToDrive(context),
            ),
            ProfileMenuItem(
              icon: Icons.cloud_download_outlined,
              title: 'Force Download from Drive',
              onTap: () async {
                await ref.read(cloudSyncServiceProvider).downloadBackupFromDrive(context);
                ref.read(gameListProvider.notifier).refresh();
              },
            ),
          ],

          const Divider(indent: 16, endIndent: 16),

          // --- SETTINGS SECTION ---
          const SectionTitle(title: 'Settings'),
          ProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'App Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AppSettingsScreen()),
              );
            },
          ),

          // Only show local name changer if NOT signed into Google
          if (!isGoogleSignedIn) ...[
            const SectionTitle(title: 'Account'),
            ProfileMenuItem(
              icon: Icons.badge_outlined,
              title: 'Change account name',
              onTap: () => _showChangeNameDialog(context, ref),
            ),
          ],

          const SectionTitle(title: 'GameLog'),
          ProfileMenuItem(
            icon: Icons.info_outline,
            title: 'About GameLog',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AboutScreen()),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.rocket_launch_outlined,
            title: 'Support & Feature Drop',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const SupportScreen()),
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(indent: 16, endIndent: 16),

          // --- MASTER LOGOUT ---
          ProfileMenuItem(
            icon: Icons.logout,
            title: isGoogleSignedIn ? 'Save & Log out' : 'Log out (Guest)',
            textColor: Colors.red,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: Text(
                      isGoogleSignedIn
                          ? 'Your games will be automatically synced to Google Drive before logging out. This will clear your games from this device.'
                          : 'You are currently a Guest. Logging out will clear your local library. Make sure you exported a manual backup!'
                  ),
                  actions:[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Close Dialog
                        _performLogout(context, ref); // Execute Master Logout
                      },
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}