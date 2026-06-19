import 'package:flutter/material.dart';
import 'package:gamelog/providers/user_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

// We create a Notifier that holds the ThemeMode state.
// keepAlive ensures the theme doesn't reset when you change pages.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    // Read the initial theme from our settings service.
    final settingsService = ref.watch(userSettingsServiceProvider);
    return settingsService.isDarkMode() ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    final settingsService = ref.read(userSettingsServiceProvider);
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      settingsService.setDarkMode(false);
    } else {
      state = ThemeMode.dark;
      settingsService.setDarkMode(true);
    }
  }
}