import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'user_settings_provider.g.dart';

/// This service handles the direct communication with the Hive database.
class UserSettingsService {
  final Box _box;
  UserSettingsService(this._box);

  // --- User Name Methods ---
  String getUserName() {
    return _box.get('userName', defaultValue: 'Gamer');
  }

  Future<void> setUserName(String name) async {
    await _box.put('userName', name);
  }

  // --- Theme Methods ---
  bool isDarkMode() {
    return _box.get('isDarkMode', defaultValue: true);
  }

  Future<void> setDarkMode(bool isDark) async {
    await _box.put('isDarkMode', isDark);
  }

  // --- Profile Image Methods ---
  String? getProfileImagePath() {
    return _box.get('profileImagePath');
  }

  Future<void> setProfileImagePath(String? path) async {
    await _box.put('profileImagePath', path);
  }
}

/// This provider creates a single instance of our service for the whole app.
@Riverpod(keepAlive: true)
UserSettingsService userSettingsService(Ref ref) {
  final box = Hive.box('userSettings');
  return UserSettingsService(box);
}

/// This provider manages the user's name so the UI can update when it changes.
@Riverpod(keepAlive: true)
class UserName extends _$UserName {
  @override
  String build() {
    return ref.watch(userSettingsServiceProvider).getUserName();
  }

  void updateName(String newName) {
    ref.read(userSettingsServiceProvider).setUserName(newName);
    state = newName;
  }
}

/// This provider manages the profile image path.
/// It allows the UI to reactively display the new photo as soon as it's picked.
@Riverpod(keepAlive: true)
class ProfileImage extends _$ProfileImage {
  @override
  String? build() {
    return ref.watch(userSettingsServiceProvider).getProfileImagePath();
  }

  void updateImage(String? path) {
    ref.read(userSettingsServiceProvider).setProfileImagePath(path);
    state = path;
  }
}