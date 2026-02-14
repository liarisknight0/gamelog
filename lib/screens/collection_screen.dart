import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/screens/search_screen.dart';
import 'package:gamelog/widgets/empty_state_widget.dart';
import 'package:gamelog/widgets/game_card.dart';
import 'package:gamelog/widgets/sort_menu.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Game> games = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          const SortMenu(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: games.isEmpty
          ? const EmptyStateWidget(
        icon: Icons.collections_bookmark_outlined,
        title: 'Your Collection is Empty',
        message: "Games you own appear here. Add one from your Backlog or use the '+' button.",
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
              child: const Icon(Icons.play_circle_outline, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.green,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.archive, color: Colors.white),
            ),
            onDismissed: (direction) {
              HapticFeedback.mediumImpact();
              if (direction == DismissDirection.startToEnd) { // Swipe Right -> Now Playing
                ref.read(gameListProvider.notifier).updateGameStatus(game, GameStatus.nowPlaying);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} moved to Now Playing')));
              } else { // Swipe Left -> Archive
                ref.read(gameListProvider.notifier).updateGameStatus(game, GameStatus.beaten);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} archived')));
              }
            },
            child: GameCard(game: game),
          );
        },
      ),
    );
  }
}