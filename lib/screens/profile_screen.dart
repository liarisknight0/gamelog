import 'dart:io'; // Required for FileImage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Required for ImagePicker
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/user_settings_provider.dart';
import 'package:gamelog/screens/about_screen.dart';
import 'package:gamelog/screens/app_settings_screen.dart';
import 'package:gamelog/screens/support_screen.dart';
import 'package:gamelog/services/cloud_sync_service.dart'; // <--- IMPORTANT: New import for Cloud Sync
import 'package:gamelog/widgets/profile_menu_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Opens a dialog to change the user's display name.
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
        actions: [
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

  /// Opens the gallery to pick a new profile picture.
  Future<void> _pickProfileImage(WidgetRef ref, BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress slightly to save space
    );

    if (image != null) {
      ref.read(profileImageProvider.notifier).updateImage(image.path);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selection cancelled.')),
        );
      }
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
        children: [
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final profilePath = ref.watch(profileImageProvider);
    final totalGames = ref.watch(gameListProvider).length;
    final googleAccount = ref.watch(googleSignInAccountProvider); // <--- Watch Google Account

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 30),

          // --- PROFILE PICTURE SECTION ---
          Center(
            child: GestureDetector(
              onTap: () => _pickProfileImage(ref, context), // Pass context
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: profilePath != null && File(profilePath).existsSync() // Check if file exists
                        ? FileImage(File(profilePath))
                        : null,
                    child: profilePath == null || !File(profilePath).existsSync()
                        ? Icon(Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
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
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 24),

          // --- STATS BOX ---
          _buildTotalGamesStat(totalGames, context),

          const SizedBox(height: 24),
          const Divider(indent: 16, endIndent: 16),

          // --- NEW: Google Sync Section ---
          const SectionTitle(title: 'Cloud Sync'),
          googleAccount == null
              ? ProfileMenuItem(
            icon: Icons.person_add_alt_1_outlined,
            title: 'Sign in with Google',
            onTap: () => ref.read(cloudSyncServiceProvider).signInWithGoogle(context),
          )
              : Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundImage: googleAccount.photoUrl != null
                      ? NetworkImage(googleAccount.photoUrl!)
                      : null, // Placeholder if no photoUrl
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  child: googleAccount.photoUrl == null
                      ? const Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
                ),
                title: Text(googleAccount.displayName ?? 'Google User'),
                subtitle: Text(googleAccount.email),
              ),
              ProfileMenuItem(
                icon: Icons.cloud_upload_outlined,
                title: 'Upload to Drive Now',
                onTap: () => ref.read(cloudSyncServiceProvider).uploadBackupToDrive(context),
              ),
              ProfileMenuItem(
                icon: Icons.cloud_download_outlined,
                title: 'Download from Drive Now',
                // When downloading, we should refresh the main game list
                onTap: () async {
                  await ref.read(cloudSyncServiceProvider).downloadBackupFromDrive(context);
                  ref.read(gameListProvider.notifier).refresh(); // Important to refresh UI after download
                },
              ),
              ProfileMenuItem(
                icon: Icons.logout,
                title: 'Sign out of Google',
                textColor: Colors.orange,
                onTap: () => ref.read(cloudSyncServiceProvider).signOutGoogle(),
              ),
            ],
          ),
          const Divider(indent: 16, endIndent: 16),
          // --- END NEW Google Sync Section ---

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

          const SectionTitle(title: 'Account'),
          ProfileMenuItem(
            icon: Icons.badge_outlined,
            title: 'Change account name',
            onTap: () => _showChangeNameDialog(context, ref),
          ),

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

          ProfileMenuItem(
            icon: Icons.logout,
            title: 'Log out',
            textColor: Colors.red,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out of GameLog?'),
                  actions: [
                    TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop()
                    ),
                    TextButton(
                        child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          // TODO: Implement actual app-level logout logic here (e.g., clear all user data, navigate to login)
                          Navigator.of(ctx).pop(); // Close dialog
                          // Consider navigating to a login/onboarding screen or clearing all app state
                        }
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