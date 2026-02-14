// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$collectionHash() => r'd2d7c3e4752efd9938c6470f436bc08aec42793e';

/// See also [collection].
@ProviderFor(collection)
final collectionProvider = AutoDisposeProvider<List<Game>>.internal(
  collection,
  name: r'collectionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$collectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CollectionRef = AutoDisposeProviderRef<List<Game>>;
String _$nowPlayingHash() => r'8b92fa0a982b499b2064e939966f52cd15a9f765';

/// See also [nowPlaying].
@ProviderFor(nowPlaying)
final nowPlayingProvider = AutoDisposeProvider<List<Game>>.internal(
  nowPlaying,
  name: r'nowPlayingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$nowPlayingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NowPlayingRef = AutoDisposeProviderRef<List<Game>>;
String _$archiveHash() => r'ff7393828e1191c32a18e08e5f28ac406a5a12c5';

/// See also [archive].
@ProviderFor(archive)
final archiveProvider = AutoDisposeProvider<List<Game>>.internal(
  archive,
  name: r'archiveProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$archiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ArchiveRef = AutoDisposeProviderRef<List<Game>>;
String _$backlogHash() => r'c622e4e0b5128ca9c220ffb7015e8bc436a1aad7';

/// See also [backlog].
@ProviderFor(backlog)
final backlogProvider = AutoDisposeProvider<List<Game>>.internal(
  backlog,
  name: r'backlogProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$backlogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BacklogRef = AutoDisposeProviderRef<List<Game>>;
String _$searchResultsHash() => r'3921fc17063c517dbeda4560e66e4feaa0caaf3d';

/// See also [searchResults].
@ProviderFor(searchResults)
final searchResultsProvider = AutoDisposeProvider<List<Game>>.internal(
  searchResults,
  name: r'searchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SearchResultsRef = AutoDisposeProviderRef<List<Game>>;
String _$gameListHash() => r'85482473afb61da89f7d603990b6c344913f30bf';

/// See also [GameList].
@ProviderFor(GameList)
final gameListProvider = NotifierProvider<GameList, List<Game>>.internal(
  GameList.new,
  name: r'gameListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$gameListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GameList = Notifier<List<Game>>;
String _$searchQueryHash() => r'3c36752ee11b18a9f1e545eb1a7209a7222d91c9';

/// See also [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
  SearchQuery.new,
  name: r'searchQueryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchQuery = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
