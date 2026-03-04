import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/widgets/game_card.dart'; // <--- Import the premium card

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search your collection...',
            border: InputBorder.none,
          ),
          onChanged: (val) {
            // Use the method we defined in the Notifier
            ref.read(searchQueryProvider.notifier).setQuery(val);
          },
        ),
      ),
      body: searchResults.isEmpty && query.isNotEmpty
          ? Center(
        child: Text(
          'No games found matching "$query".',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      )
          : ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          // --- UPGRADE: Use the premium GameCard! ---
          return GameCard(game: searchResults[index]);
        },
      ),
    );
  }
}