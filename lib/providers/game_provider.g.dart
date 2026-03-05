// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gameListHash() => r'9b5ce9d23b204fd3bbbdaf25c9014643351b1460';

/// See also [gameList].
@ProviderFor(gameList)
final gameListProvider = StreamProvider<List<Game>>.internal(
  gameList,
  name: r'gameListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$gameListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GameListRef = StreamProviderRef<List<Game>>;
String _$collectionHash() => r'50b00ecd01450d3f227fbbfabc99456e5789daea';

/// FILTERED & SORTED PROVIDERS
///
/// Copied from [collection].
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
String _$nowPlayingHash() => r'7386fbd54317ec2016dda30bbe37ae8313c4684f';

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
String _$archiveHash() => r'25b5c8fe3bcd06351ff5981d4079b65b22f2b141';

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
String _$backlogHash() => r'240106712ed762dfb70b5505e0b4c7d21bd32fc5';

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
String _$searchResultsHash() => r'8d69fe7c618a4a07339bde727b5ce930b7b0a062';

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
String _$gameSortHash() => r'e9394c60f5284242c10f0fafb568a191a5db961f';

/// See also [GameSort].
@ProviderFor(GameSort)
final gameSortProvider = NotifierProvider<GameSort, GameSortOption>.internal(
  GameSort.new,
  name: r'gameSortProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$gameSortHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GameSort = Notifier<GameSortOption>;
String _$searchQueryHash() => r'3c36752ee11b18a9f1e545eb1a7209a7222d91c9';

/// SEARCH LOGIC
///
/// Copied from [SearchQuery].
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
