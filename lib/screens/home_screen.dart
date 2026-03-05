import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/screens/search_screen.dart';
import 'package:gamelog/widgets/empty_state_widget.dart';
import 'package:gamelog/widgets/game_card.dart';
import 'package:gamelog/widgets/sort_menu.dart';
import 'package:gamelog/widgets/sync_indicator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the filtered and sorted provider for Now Playing games
    final List<Game> games = ref.watch(nowPlayingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions:[
          const SyncIndicator(),
          const SortMenu(),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search All Games',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: games.isEmpty
          ? const EmptyStateWidget(
        icon: Icons.gamepad_outlined,
        title: 'Ready to Play?',
        message: "Games you are actively playing will appear here. Move one from your Backlog or use the '+' button to add one.",
      )
          : ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Dismissible(
            key: ValueKey(game.key),
            // Swipe Right -> Archive
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
            // Swipe Left -> Backlog
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
              final gameRepo = ref.read(gameRepositoryProvider);

              if (direction == DismissDirection.startToEnd) {
                // Swipe Right -> Archive
                gameRepo.updateGameStatus(game, GameStatus.beaten);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} archived')));
              } else {
                // Swipe Left -> Backlog
                gameRepo.updateGameStatus(game, GameStatus.backlog);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} moved to Backlog')));
              }
            },
            child: GameCard(game: game),
          );
        },
      ),
    );
  }
}