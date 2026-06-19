import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/services/igdb_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'online_search_screen.g.dart';

// --- STATE MANAGEMENT ---

// This provider will hold the results of our API search.
// It's an AsyncNotifier because fetching data is an asynchronous operation.
@riverpod
class ApiSearch extends _$ApiSearch {
  @override
  FutureOr<List<ApiGame>> build() {
    // Initially, there are no results.
    return [];
  }

  // This method will be called to trigger a search.
  Future<void> searchGames(String query) async {
    // Set the state to loading
    state = const AsyncValue.loading();
    // Fetch the games and update the state with the result or an error.
    state = await AsyncValue.guard(() {
      return IGDBService().searchGames(query);
    });
  }
}

// --- UI ---

class OnlineSearchScreen extends ConsumerStatefulWidget {
  const OnlineSearchScreen({super.key});

  @override
  ConsumerState<OnlineSearchScreen> createState() => _OnlineSearchScreenState();
}

class _OnlineSearchScreenState extends ConsumerState<OnlineSearchScreen> {
  // A "debouncer" is used to prevent firing off an API search on every single keystroke.
  // It waits until the user has stopped typing for a moment.
  Timer? _debouncer;

  @override
  void dispose() {
    _debouncer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debouncer?.isActive ?? false) _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 500), () {
      // After 500ms of no typing, trigger the search.
      ref.read(apiSearchProvider.notifier).searchGames(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(apiSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for a game online...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: searchResults.when(
        // --- DATA STATE ---
        data: (games) {
          if (games.isEmpty) {
            return const Center(child: Text('Start typing to search for games.'));
          }
          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return SearchResultTile(game: game);
            },
          );
        },
        // --- LOADING STATE ---
        loading: () => const Center(child: CircularProgressIndicator()),
        // --- ERROR STATE ---
        error: (err, stack) => Center(child: Text('An error occurred: $err')),
      ),
    );
  }
}

// A dedicated widget for a single search result item.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.game});

  final ApiGame game;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: CachedNetworkImage(
            imageUrl: game.coverUrl,
            fit: BoxFit.cover,
            // A simple placeholder while the image loads
            placeholder: (context, url) => Container(color: Colors.grey.shade800),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
      title: Text(game.title),
      subtitle: Text(game.platforms, maxLines: 1),
      onTap: () {
        // When tapped, pop the screen and return the selected game data.
        Navigator.of(context).pop(game);
      },
    );
  }
}