import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/widgets/game_card.dart';

class GameListView extends ConsumerWidget {
  final List<Game> games;
  const GameListView({super.key, required this.games});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The if(games.isEmpty) check has been removed.
    // This widget now assumes it will only be built when games are present.
    return ListView.builder(
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return Dismissible(
          key: ValueKey(game.key),
          background: Container(
            color: Colors.green,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20.0),
            child: const Icon(Icons.archive, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.orange, // Changed to orange for Backlog
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.playlist_add, color: Colors.white),
          ),
          onDismissed: (direction) {
            HapticFeedback.mediumImpact();
            if (direction == DismissDirection.startToEnd) { // Right -> Archive
              ref.read(gameListProvider.notifier).updateGameStatus(game, GameStatus.beaten);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} archived')));
            } else { // Left -> Backlog
              ref.read(gameListProvider.notifier).updateGameStatus(game, GameStatus.backlog);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} moved to Backlog')));
            }
          },
          child: GameCard(game: game),
        );
      },
    );
  }
}