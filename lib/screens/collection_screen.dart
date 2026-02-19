import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/screens/search_screen.dart';
import 'package:gamelog/widgets/empty_state_widget.dart';
import 'package:gamelog/widgets/game_card.dart';
import 'package:gamelog/widgets/sort_menu.dart';
import 'package:gamelog/widgets/sync_indicator.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Game> games = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          const SyncIndicator(),
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
        message: "All the Games you own appear here.",
      )
          : ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return GameCard(game: game);

        },
      ),
    );
  }
}