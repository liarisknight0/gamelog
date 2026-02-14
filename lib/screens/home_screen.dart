import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/screens/search_screen.dart';
import 'package:gamelog/widgets/empty_state_widget.dart';
import 'package:gamelog/widgets/game_card.dart';
import 'package:gamelog/widgets/sort_menu.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Game> games = ref.watch(nowPlayingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
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
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20.0),
              child: const Icon(Icons.archive, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.orange,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.playlist_add, color: Colors.white),
            ),
            onDismissed: (direction) {
              HapticFeedback.mediumImpact();
              if (direction == DismissDirection.startToEnd) {
                ref.read(gameListProvider.notifier).updateGameStatus(game, GameStatus.beaten);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} archived')));
              } else {
                ref.read(gameListProvider.notifier).updateGameStatus(game, GameStatus.backlog);
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