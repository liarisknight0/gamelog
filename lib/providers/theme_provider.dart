import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gamelog/providers/user_settings_provider.dart'; // We need access to the service

// This provider will hold the current theme mode.
// We change it to a more specific type to access our service.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  // We provide the UserSettingsService to the ThemeNotifier's constructor.
  final settingsService = ref.watch(userSettingsServiceProvider);
  return ThemeNotifier(settingsService);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Store a reference to the settings service.
  final UserSettingsService _settingsService;

  // Constructor now reads the initial theme from the service.
  ThemeNotifier(this._settingsService)
      : super(_settingsService.isDarkMode() ? ThemeMode.dark : ThemeMode.light);

  // The toggle method now also saves the new preference.
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    // Write the new value to our Hive box via the service.
    _settingsService.setDarkMode(state == ThemeMode.dark);
  }
}