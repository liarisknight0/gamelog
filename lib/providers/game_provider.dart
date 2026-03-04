import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/services/firebase_sync_service.dart'; // <--- Using Firebase now
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Mandatory for code generation
part 'game_provider.g.dart';

/// 1. THE SORTING STATE
enum GameSortOption { alphabetical, dateAdded, rating }

@Riverpod(keepAlive: true)
class GameSort extends _$GameSort {
  @override
  GameSortOption build() => GameSortOption.dateAdded;

  void setSort(GameSortOption option) => state = option;
}

/// 2. THE MASTER LIST
@Riverpod(keepAlive: true)
class GameList extends _$GameList {
  late Box<Game> _box;

  @override
  List<Game> build() {
    _box = Hive.box<Game>('games');
    return _box.values.toList();
  }

  /// Refreshes the state from the database.
  void refresh() {
    state = _box.values.toList();
  }

  void addGame(Game game) {
    _box.add(game);
    refresh();
    // PUSH TO FIREBASE
    ref.read(firebaseSyncServiceProvider).saveGameToCloud(game);
  }

  void deleteGame(Game game) {
    final String idToDelete = game.id; // Capture ID before delete
    game.delete();
    refresh();
    // DELETE FROM FIREBASE
    if (idToDelete.isNotEmpty) {
      ref.read(firebaseSyncServiceProvider).deleteGameFromCloud(idToDelete);
    }
  }

  void updateGameStatus(Game game, GameStatus newStatus) {
    game.status = newStatus;
    game.save();
    refresh();
    // PUSH UPDATE TO FIREBASE
    ref.read(firebaseSyncServiceProvider).saveGameToCloud(game);
  }
}

/// 3. HELPER FOR SORTING
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

/// 4. FILTERED & SORTED PROVIDERS

@riverpod
List<Game> collection(Ref ref) {
  final allGames = ref.watch(gameListProvider);
  final sortOption = ref.watch(gameSortProvider);
  // Collection shows ALL games now (Master List)
  return _applySort(allGames, sortOption);
}

@riverpod
List<Game> nowPlaying(Ref ref) {
  final allGames = ref.watch(gameListProvider);
  final sortOption = ref.watch(gameSortProvider);
  final filtered = allGames.where((game) => game.status == GameStatus.nowPlaying).toList();
  return _applySort(filtered, sortOption);
}

@riverpod
List<Game> archive(Ref ref) {
  final allGames = ref.watch(gameListProvider);
  final sortOption = ref.watch(gameSortProvider);
  final filtered = allGames.where((game) =>
  game.status == GameStatus.beaten ||
      game.status == GameStatus.dropped
  ).toList();
  return _applySort(filtered, sortOption);
}

@riverpod
List<Game> backlog(Ref ref) {
  final allGames = ref.watch(gameListProvider);
  final sortOption = ref.watch(gameSortProvider);
  final filtered = allGames.where((game) => game.status == GameStatus.backlog).toList();
  return _applySort(filtered, sortOption);
}

/// 5. SEARCH LOGIC

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

@riverpod
List<Game> searchResults(Ref ref) {
  final allGames = ref.watch(gameListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.trim().isEmpty) return [];

  return allGames.where((game) {
    return game.title.toLowerCase().contains(query);
  }).toList();
}