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

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Game> games = ref.watch(archiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        actions: [
          const SyncIndicator(),
          const SortMenu(),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search All Games',
            onPressed: () {
              // This is the line with the corrected context
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: games.isEmpty
          ? const EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'Archive is Empty',
        message: "Games you've beaten will appear here.",
      )
          : ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Dismissible(
            key: ValueKey(game.key),
            background: Container(
              color: Colors.orange,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20.0),
              child: const Icon(Icons.playlist_add, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.blue,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.play_circle_outline, color: Colors.white),
            ),
            onDismissed: (direction) {
              HapticFeedback.mediumImpact();
              if (direction == DismissDirection.startToEnd) { // Right -> Backlog
                ref.read(gameListProvider.notifier).updateGameStatus(game, GameStatus.backlog);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} moved to Backlog')));
              } else { // Left -> Now Playing
                ref.read(gameListProvider.notifier).updateGameStatus(game, GameStatus.nowPlaying);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} moved to Now Playing')));
              }
            },
            child: GameCard(game: game),
          );
        },
      ),
    );
  }
}