import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserSettingsService {
  final Box _box;
  UserSettingsService(this._box);

  // --- USER NAME METHODS (Unchanged) ---
  String getUserName() {
    return _box.get('userName', defaultValue: 'Gamer');
  }

  Future<void> setUserName(String name) async {
    await _box.put('userName', name);
  }

  // --- NEW THEME METHODS ---
  // Reads the theme preference. Defaults to true (dark mode) if not set.
  bool isDarkMode() {
    return _box.get('isDarkMode', defaultValue: true);
  }

  // Writes the theme preference.
  Future<void> setDarkMode(bool isDark) async {
    await _box.put('isDarkMode', isDark);
  }
// --- END OF NEW THEME METHODS ---
}

// This provider gives other parts of our app access to the service.
final userSettingsServiceProvider = Provider<UserSettingsService>((ref) {
  final box = Hive.box('userSettings');
  return UserSettingsService(box);
});

// The userNameProvider remains unchanged.
final userNameProvider = StateProvider<String>((ref) {
  final settingsService = ref.watch(userSettingsServiceProvider);
  return settingsService.getUserName();
});