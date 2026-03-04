import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/services/igdb_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shimmer/shimmer.dart';

part 'online_search_screen.g.dart';

@riverpod
class ApiSearch extends _$ApiSearch {
  @override
  FutureOr<List<ApiGame>> build() {
    return[];
  }

  Future<void> searchGames(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return IGDBService().searchGames(query);
    });
  }
}

class OnlineSearchScreen extends ConsumerStatefulWidget {
  const OnlineSearchScreen({super.key});

  @override
  ConsumerState<OnlineSearchScreen> createState() => _OnlineSearchScreenState();
}

class _OnlineSearchScreenState extends ConsumerState<OnlineSearchScreen> {
  Timer? _debouncer;

  @override
  void dispose() {
    _debouncer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debouncer?.isActive ?? false) _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 500), () {
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
        data: (games) {
          if (games.isEmpty) {
            return const Center(child: Text('Start typing to search for games.'));
          }
          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              return SearchResultTile(game: games[index]);
            },
          );
        },
        // --- PREMIUM SHIMMER LOADER ---
        loading: () => ListView.builder(
          itemCount: 8, // Show 8 skeleton items
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            highlightColor: Theme.of(context).colorScheme.surface,
            child: ListTile(
              leading: Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              title: Container(
                  height: 14,
                  color: Colors.white,
                  margin: const EdgeInsets.only(right: 50)
              ),
              subtitle: Container(
                  height: 10,
                  color: Colors.white,
                  margin: const EdgeInsets.only(right: 150, top: 8)
              ),
            ),
          ),
        ),
        // ----------------------------------------
        error: (err, stack) => Center(child: Text('An error occurred: $err')),
      ),
    );
  }
}

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.game});

  final ApiGame game;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 50,
        height: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: CachedNetworkImage(
            imageUrl: game.coverUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey.shade800),
            errorWidget: (context, url, error) => const Icon(Icons.videogame_asset),
          ),
        ),
      ),
      title: Text(game.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(game.platforms, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {
        Navigator.of(context).pop(game);
      },
    );
  }
}