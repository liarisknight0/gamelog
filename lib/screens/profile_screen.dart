import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/user_settings_provider.dart';
import 'package:gamelog/screens/about_screen.dart';
import 'package:gamelog/screens/app_settings_screen.dart';
import 'package:gamelog/screens/support_screen.dart';
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
  Future<void> _pickProfileImage(WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    // Pick an image from the local gallery
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress slightly to save space
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
              onTap: () => _pickProfileImage(ref),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: profilePath != null
                        ? FileImage(File(profilePath))
                        : null,
                    child: profilePath == null
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

          // --- MENU SECTIONS ---
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
            icon: Icons.rocket_launch_outlined, // Changed to a roadmap/rocket icon
            title: 'Support & Feature Drop', // Updated Title
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
                          // Logout logic would go here
                          Navigator.of(ctx).pop();
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