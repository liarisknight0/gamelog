import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gamelog/models/game.dart';
import 'package:hive_flutter/hive_flutter.dart';

// The master list of ALL games.
final gameListProvider = StateNotifierProvider<GameNotifier, List<Game>>((ref) {
  return GameNotifier();
});

// --- REFINED PROVIDERS BASED ON NEW WORKFLOW ---

// COLLECTION: All owned games that are NOT beaten.
final collectionProvider = Provider<List<Game>>((ref) {
  final allGames = ref.watch(gameListProvider);
  return allGames.where((game) =>
  game.status != GameStatus.beaten &&
      game.status != GameStatus.backlog // Backlog is now a pure wishlist
  ).toList();
});

// NOW PLAYING: Only the game(s) with the 'nowPlaying' status.
final nowPlayingProvider = Provider<List<Game>>((ref) {
  final allGames = ref.watch(gameListProvider);
  return allGames.where((game) => game.status == GameStatus.nowPlaying).toList();
});

// ARCHIVE: Only 'beaten' or 'dropped' games.
final archiveProvider = Provider<List<Game>>((ref) {
  final allGames = ref.watch(gameListProvider);
  return allGames.where((game) =>
  game.status == GameStatus.beaten ||
      game.status == GameStatus.dropped
  ).toList();
});

// BACKLOG (WISHLIST): Only games with the 'backlog' status.
final backlogProvider = Provider<List<Game>>((ref) {
  final allGames = ref.watch(gameListProvider);
  return allGames.where((game) => game.status == GameStatus.backlog).toList();
});

// --- SEARCH PROVIDERS (Unchanged) ---
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<Game>>((ref) {
  final allGames = ref.watch(gameListProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isEmpty) {
    return [];
  }

  return allGames.where((game) {
    return game.title.toLowerCase().contains(query.toLowerCase());
  }).toList();
});

// --- GAME NOTIFIER (Unchanged from last correct version) ---
class GameNotifier extends StateNotifier<List<Game>> {
  GameNotifier() : super(Hive.box<Game>('games').values.toList());
  final _gameBox = Hive.box<Game>('games');

  void refreshGames() {
    state = _gameBox.values.toList();
  }

  void addGame(Game game) {
    _gameBox.add(game);
    refreshGames();
  }

  void deleteGame(Game game) {
    game.delete();
    refreshGames();
  }

  void updateGame(Game updatedGame) {
    updatedGame.save();
    refreshGames();
  }

  void updateGameStatus(Game game, GameStatus newStatus) {
    game.status = newStatus;
    game.save();
    refreshGames();
  }
}