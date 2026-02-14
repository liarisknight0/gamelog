import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_settings_provider.g.dart';

// This is the raw class that talks to the Hive database. It stays the same.
class UserSettingsService {
  final Box _box;
  UserSettingsService(this._box);

  String getUserName() {
    return _box.get('userName', defaultValue: 'Gamer');
  }

  Future<void> setUserName(String name) async {
    await _box.put('userName', name);
  }

  bool isDarkMode() {
    return _box.get('isDarkMode', defaultValue: true);
  }

  Future<void> setDarkMode(bool isDark) async {
    await _box.put('isDarkMode', isDark);
  }
}

// This provider creates a single instance of our service for the whole app.
@Riverpod(keepAlive: true)
UserSettingsService userSettingsService(UserSettingsServiceRef ref) {
  final box = Hive.box('userSettings');
  return UserSettingsService(box);
}


// This provider manages the user's name so the UI can update when it changes.
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