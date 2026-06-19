import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart'; // <-- ADD THIS IMPORT
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/screens/add_edit_game_screen.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search all games...',
            border: InputBorder.none,
          ),
          onChanged: (query) {
            ref.read(searchQueryProvider.notifier).setQuery(query);
          },
        ),
      ),
      body: searchResults.isEmpty && ref.watch(searchQueryProvider).isNotEmpty
          ? const Center(child: Text('No games found.'))
          : ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final game = searchResults[index];
          return ListTile(
            title: Text(game.title),
            subtitle: Text('${game.platform} - ${_getStatusText(game.status)}'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditGameScreen(game: game),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.nowPlaying: return 'Now Playing';
      case GameStatus.notStarted: return 'Backlog (Not Started)';
      case GameStatus.beaten: return 'Archive (Beaten)';
      case GameStatus.paused: return 'Backlog (Paused)';
      case GameStatus.dropped: return 'Backlog (Dropped)';
      case GameStatus.backlog: return 'Backlog';

    }
  }
}