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

class BacklogScreen extends ConsumerWidget {
  const BacklogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the filtered and sorted provider for the backlog
    final List<Game> games = ref.watch(backlogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Backlog'),
        actions: [
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
        icon: Icons.playlist_add_check,
        title: 'Backlog Clear!',
        message: "This is your wishlist of games to play. Use the '+' button to add a game you're interested in.",
      )
          : ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Dismissible(
            key: ValueKey(game.key),
            background: Container(
              color: Colors.blue,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20.0),
              child: const Row( // Added Row for text and icon
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Start Playing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            secondaryBackground: Container(
              color: Colors.green,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Row( // Added Row for text and icon
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Archive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 10),
                  Icon(Icons.archive, color: Colors.white),
                ],
              ),
            ),
            onDismissed: (direction) {
              HapticFeedback.mediumImpact();
              final gameRepo = ref.read(gameRepositoryProvider);

              if (direction == DismissDirection.startToEnd) { // Swipe Right -> Now Playing
                gameRepo.updateGameStatus(game, GameStatus.nowPlaying);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} moved to Now Playing')));
              } else { // Swipe Left -> Archive
                gameRepo.updateGameStatus(game, GameStatus.beaten);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} moved to Archive')));
              }
            },
            child: GameCard(game: game),
          );
        },
      ),
    );
  }
}