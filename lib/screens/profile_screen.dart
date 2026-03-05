import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';

import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/user_settings_provider.dart';
import 'package:gamelog/screens/about_screen.dart';
import 'package:gamelog/screens/app_settings_screen.dart';
import 'package:gamelog/screens/support_screen.dart';
import 'package:gamelog/screens/auth_screen.dart';
import 'package:gamelog/services/firebase_sync_service.dart';
import 'package:gamelog/widgets/profile_menu_widgets.dart';
import 'package:gamelog/widgets/loading_overlay.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

  Widget _buildStatsDashboard(BuildContext context, int total, int beaten, int playing) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          ),
          boxShadow:[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:[
          _buildStatColumn(context, Icons.collections_bookmark_rounded, Theme.of(context).colorScheme.primary, total.toString(), 'Total'),
          Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
          _buildStatColumn(context, Icons.emoji_events_rounded, Colors.amber.shade600, beaten.toString(), 'Beaten'),
          Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
          _buildStatColumn(context, Icons.play_circle_filled_rounded, Colors.green.shade500, playing.toString(), 'Playing'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, IconData icon, Color iconColor, String count, String label) {
    return Column(
      children:[
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // --- FIX: ROBUST LOGOUT LOGIC ---
  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    final syncService = ref.read(firebaseSyncServiceProvider);

    LoadingOverlay.show(context);
    try {
      if (syncService.currentUser != null) {
        try {
          // Attempt final sync, but don't let it crash the logout if Firebase is down
          await syncService.migrateAndSyncLocalData();
        } catch (syncError) {
          debugPrint("Final sync failed, proceeding with logout: $syncError");
        }
        await syncService.signOut();
      }
    } catch (e) {
      debugPrint('Error during Firebase signout: $e');
    } finally {
      // THIS WILL NOW RUN NO MATTER WHAT HAPPENS ABOVE
      await Hive.box<Game>('games').clear(); // Wipe offline data
      ref.invalidate(gameListProvider); // Reset UI

      LoadingOverlay.hide();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localUserName = ref.watch(userNameProvider);
    final localProfilePath = ref.watch(profileImageProvider);

    final allGamesAsync = ref.watch(gameListProvider);
    final allGames = allGamesAsync.value ??[];

    final totalGames = allGames.length;
    final beatenGames = allGames.where((g) => g.status == GameStatus.beaten).length;
    final playingGames = allGames.where((g) => g.status == GameStatus.nowPlaying).length;

    final syncService = ref.watch(firebaseSyncServiceProvider);
    final firebaseUser = syncService.currentUser;
    final isGoogleSignedIn = firebaseUser != null;

    final displayString = isGoogleSignedIn
        ? (firebaseUser.displayName ?? localUserName)
        : localUserName;

    ImageProvider? avatarImage;
    if (isGoogleSignedIn && firebaseUser.photoURL != null) {
      avatarImage = NetworkImage(firebaseUser.photoURL!);
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

          Center(
            child: GestureDetector(
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
                  if (!isGoogleSignedIn)
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

          Center(
            child: Text(
              displayString,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          if (isGoogleSignedIn && firebaseUser.email != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  firebaseUser.email!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 32),

          _buildStatsDashboard(context, totalGames, beatenGames, playingGames),

          const SizedBox(height: 32),
          const Divider(indent: 16, endIndent: 16),

          const SectionTitle(title: 'Cloud Sync'),
          if (!isGoogleSignedIn)
            ProfileMenuItem(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Sign in with Google',
              onTap: () => ref.read(firebaseSyncServiceProvider).signInWithGoogle(),
            )
          else
            ProfileMenuItem(
              icon: Icons.sync,
              title: 'Force Resync Library',
              onTap: () async {
                LoadingOverlay.show(context);
                await ref.read(firebaseSyncServiceProvider).migrateAndSyncLocalData();
                LoadingOverlay.hide();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Library synced with Cloud.')),
                  );
                }
              },
            ),

          const Divider(indent: 16, endIndent: 16),

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

          ProfileMenuItem(
            icon: Icons.logout,
            title: isGoogleSignedIn ? 'Log out' : 'Log out (Guest)',
            textColor: Colors.red,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: Text(
                      isGoogleSignedIn
                          ? 'Logging out will remove all games from this device. They are safely backed up in your account.'
                          : 'You are a Guest. Logging out will PERMANENTLY DELETE your local library.'
                  ),
                  actions:[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _performLogout(context, ref);
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