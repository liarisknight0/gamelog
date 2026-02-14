// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userSettingsServiceHash() =>
    r'bad7ec154bac8fcfcf4b791ac23d7ad709c3d205';

/// This provider creates a single instance of our service for the whole app.
///
/// Copied from [userSettingsService].
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

/// This provider manages the user's name so the UI can update when it changes.
///
/// Copied from [UserName].
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
String _$profileImageHash() => r'5e21e12f2c49a929d8e82150adace0624f859215';

/// This provider manages the profile image path.
/// It allows the UI to reactively display the new photo as soon as it's picked.
///
/// Copied from [ProfileImage].
@ProviderFor(ProfileImage)
final profileImageProvider = NotifierProvider<ProfileImage, String?>.internal(
  ProfileImage.new,
  name: r'profileImageProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$profileImageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileImage = Notifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
