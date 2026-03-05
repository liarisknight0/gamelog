import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/services/firebase_sync_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_provider.g.dart';

/// 1. THE SORTING STATE
enum GameSortOption { alphabetical, dateAdded, rating }

@Riverpod(keepAlive: true)
class GameSort extends _$GameSort {
  @override
  GameSortOption build() => GameSortOption.dateAdded;
  void setSort(GameSortOption option) => state = option;
}

// --- NEW: A simple class for interacting with the database ---
// This is not a provider. It just holds the logic.
class GameRepository {
  final Box<Game> _box = Hive.box('games');
  final FirebaseSyncService _syncService;

  GameRepository(this._syncService);

  void addGame(Game game) {
    _box.add(game);
    _syncService.saveGameToCloud(game);
  }

  void deleteGame(Game game) {
    final idToDelete = game.id;
    game.delete();
    if (idToDelete.isNotEmpty) {
      _syncService.deleteGameFromCloud(idToDelete);
    }
  }

  void updateGameStatus(Game game, GameStatus newStatus) {
    game.status = newStatus;
    game.save();
    _syncService.saveGameToCloud(game);
  }
}

// --- NEW: Provider for the repository ---
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final syncService = ref.watch(firebaseSyncServiceProvider);
  return GameRepository(syncService);
});


// --- NEW MASTER LIST: A STREAM PROVIDER ---
// This provider listens to the Hive box for any changes and automatically
// updates the UI. This breaks the infinite loop.
@Riverpod(keepAlive: true)
Stream<List<Game>> gameList(GameListRef ref) {
  final box = Hive.box<Game>('games');
  // box.watch() returns a stream that fires whenever the box changes
  return box.watch().map((event) => box.values.toList());
}
// --- END NEW MASTER LIST ---


/// HELPER FOR SORTING
List<Game> _applySort(List<Game> list, GameSortOption option) {
  final sortedList = List<Game>.from(list);
  switch (option) {
    case GameSortOption.alphabetical:
      sortedList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case GameSortOption.rating:
      sortedList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      break;
    case GameSortOption.dateAdded:
      sortedList.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      break;
  }
  return sortedList;
}

/// FILTERED & SORTED PROVIDERS
// They now watch the new `gameListProvider` which is a stream.
// Riverpod handles the `AsyncValue` (loading, data, error) automatically.

@riverpod
List<Game> collection(Ref ref) {
  final gameListAsync = ref.watch(gameListProvider);
  return gameListAsync.maybeWhen(
    data: (games) {
      final sortOption = ref.watch(gameSortProvider);
      return _applySort(games, sortOption);
    },
    orElse: () =>[], // Return empty list on loading/error
  );
}

@riverpod
List<Game> nowPlaying(Ref ref) {
  final gameListAsync = ref.watch(gameListProvider);
  return gameListAsync.maybeWhen(
    data: (games) {
      final sortOption = ref.watch(gameSortProvider);
      final filtered = games.where((g) => g.status == GameStatus.nowPlaying).toList();
      return _applySort(filtered, sortOption);
    },
    orElse: () =>[],
  );
}

@riverpod
List<Game> archive(Ref ref) {
  final gameListAsync = ref.watch(gameListProvider);
  return gameListAsync.maybeWhen(
    data: (games) {
      final sortOption = ref.watch(gameSortProvider);
      final filtered = games.where((g) => g.status == GameStatus.beaten || g.status == GameStatus.dropped).toList();
      return _applySort(filtered, sortOption);
    },
    orElse: () =>[],
  );
}

@riverpod
List<Game> backlog(Ref ref) {
  final gameListAsync = ref.watch(gameListProvider);
  return gameListAsync.maybeWhen(
    data: (games) {
      final sortOption = ref.watch(gameSortProvider);
      final filtered = games.where((g) => g.status == GameStatus.backlog).toList();
      return _applySort(filtered, sortOption);
    },
    orElse: () =>[],
  );
}

/// SEARCH LOGIC
// We need to update this to watch the new async provider too

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

@riverpod
List<Game> searchResults(Ref ref) {
  final gameListAsync = ref.watch(gameListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) return [];

  return gameListAsync.maybeWhen(
    data: (games) {
      return games.where((g) => g.title.toLowerCase().contains(query)).toList();
    },
    orElse: () =>[],
  );
}