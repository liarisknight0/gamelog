import 'package:gamelog/models/game.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// This line is mandatory for the generator to work
part 'game_provider.g.dart';

@Riverpod(keepAlive: true)
class GameList extends _$GameList {
  late Box<Game> _box;

  @override
  List<Game> build() {
    // Initialize the box and return the current list of games
    _box = Hive.box<Game>('games');
    return _box.values.toList();
  }

  // Updates the state with whatever is currently in the Hive database
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

// --- FILTERED PROVIDERS (Computed States) ---

@riverpod
List<Game> collection(CollectionRef ref) {
  final allGames = ref.watch(gameListProvider);
  return allGames.where((game) =>
  game.status != GameStatus.beaten &&
      game.status != GameStatus.backlog
  ).toList();
}

@riverpod
List<Game> nowPlaying(NowPlayingRef ref) {
  final allGames = ref.watch(gameListProvider);
  return allGames.where((game) => game.status == GameStatus.nowPlaying).toList();
}

@riverpod
List<Game> archive(ArchiveRef ref) {
  final allGames = ref.watch(gameListProvider);
  return allGames.where((game) =>
  game.status == GameStatus.beaten ||
      game.status == GameStatus.dropped
  ).toList();
}

@riverpod
List<Game> backlog(BacklogRef ref) {
  final allGames = ref.watch(gameListProvider);
  return allGames.where((game) => game.status == GameStatus.backlog).toList();
}

// --- SEARCH LOGIC ---

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

@riverpod
List<Game> searchResults(SearchResultsRef ref) {
  final allGames = ref.watch(gameListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.trim().isEmpty) return [];

  return allGames.where((game) {
    return game.title.toLowerCase().contains(query);
  }).toList();
}