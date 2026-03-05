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
    // This widget assumes it will only be built when games are present.
    // It provides generic swipe actions (Archive / Backlog).
    // Note: It's usually better to have specific swipe logic per screen
    // (like we did in home_screen and archive_screen), but if you use
    // this as a generic fallback, this logic is safe.

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
            child: const Row(
              children:[
                Icon(Icons.archive, color: Colors.white),
                SizedBox(width: 10),
                Text('Archive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          secondaryBackground: Container(
            color: Colors.orange,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:[
                Text('Backlog', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Icon(Icons.playlist_add, color: Colors.white),
              ],
            ),
          ),
          onDismissed: (direction) {
            HapticFeedback.mediumImpact();
            // --- FIX: Use GameRepository instead of Notifier ---
            final gameRepo = ref.read(gameRepositoryProvider);

            if (direction == DismissDirection.startToEnd) {
              // Right -> Archive
              gameRepo.updateGameStatus(game, GameStatus.beaten);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} archived')));
            } else {
              // Left -> Backlog
              gameRepo.updateGameStatus(game, GameStatus.backlog);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} moved to Backlog')));
            }
            // ---------------------------------------------------
          },
          child: GameCard(game: game),
        );
      },
    );
  }
}