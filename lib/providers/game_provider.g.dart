// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$collectionHash() => r'aa49b069517eecc6e5b5771ed441481c6a13d233';

/// 4. FILTERED & SORTED PROVIDERS
/// These are what the UI screens (Collection, Backlog, etc.) actually use.
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
String _$nowPlayingHash() => r'23b7e5b7330c0e32a1d384aa7a70da3a8615c1a2';

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
String _$archiveHash() => r'46a6ac9aab16199496110743c74e2c69ae3b0232';

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
String _$backlogHash() => r'794829c909ccd23f729015cdfee783c89839a5c1';

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
String _$searchResultsHash() => r'db4eb205b25dbb0293bd21f67997166c35706829';

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
String _$gameListHash() => r'85482473afb61da89f7d603990b6c344913f30bf';

/// 2. THE MASTER LIST
/// Manages the raw data coming directly from Hive.
///
/// Copied from [GameList].
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

/// 5. SEARCH LOGIC
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
