// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userSettingsServiceHash() =>
    r'8cbe89f3bce024d2950e9cc9f7e62f8b3bfdab36';

/// See also [userSettingsService].
@ProviderFor(userSettingsService)
final userSettingsServiceProvider = Provider<UserSettingsService>.internal(
  userSettingsService,
  name: r'userSettingsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userSettingsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserSettingsServiceRef = ProviderRef<UserSettingsService>;
String _$userNameHash() => r'91e0c080d454d3a605ae367a2946b4a1e83cff17';

/// See also [UserName].
@ProviderFor(UserName)
final userNameProvider = NotifierProvider<UserName, String>.internal(
  UserName.new,
  name: r'userNameProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserName = Notifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
