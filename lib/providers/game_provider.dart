import 'package:gamelog/models/game.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mandatory for code generation
part 'game_provider.g.dart';

/// 1. THE SORTING STATE
/// Defines how we want to organize our lists.
enum GameSortOption { alphabetical, dateAdded, rating }

@Riverpod(keepAlive: true)
class GameSort extends _$GameSort {
  @override
  GameSortOption build() => GameSortOption.dateAdded; // Default sort

  void setSort(GameSortOption option) => state = option;
}

/// 2. THE MASTER LIST
/// Manages the raw data coming directly from Hive.
@Riverpod(keepAlive: true)
class GameList extends _$GameList {
  late Box<Game> _box;

  @override
  List<Game> build() {
    _box = Hive.box<Game>('games');
    return _box.values.toList();
  }

  /// Refreshes the state from the database.
  /// Call this after manual Hive operations or imports.
  void refresh() {
    state = _box.values.toList();
  }

  void addGame(Game game) {
    _box.add(game);
    refresh();
  }

  void deleteGame(Game game) {
    game.delete();
    refresh();
  }

  void updateGameStatus(Game game, GameStatus newStatus) {
    game.status = newStatus;
    game.save();
    refresh();
  }
}

/// 3. HELPER FOR SORTING
/// A private utility to sort lists based on user preference.
List<Game> _applySort(List<Game> list, GameSortOption option) {
  final sortedList = List<Game>.from(list);
  switch (option) {
    case GameSortOption.alphabetical:
      sortedList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case GameSortOption.rating:
    // Sort by rating descending (highest first)
      sortedList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      break;
    case GameSortOption.dateAdded:
    // Sort by date added descending (newest first)
      sortedList.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      break;
  }
  return sortedList;
}

/// 4. FILTERED & SORTED PROVIDERS
/// These are what the UI screens (Collection, Backlog, etc.) actually use.

@riverpod
List<Game> collection(Ref ref) {
  final allGames = ref.watch(gameListProvider);
  final sortOption = ref.watch(gameSortProvider);

  List<Game> filtered = allGames;

  return _applySort(filtered, sortOption);
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
  final games = ref.watch(gameListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.trim().isEmpty) return [];

  return games.where((game) {
    return game.title.toLowerCase().contains(query);
  }).toList();
}