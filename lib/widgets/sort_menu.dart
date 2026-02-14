import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/providers/game_provider.dart';

class SortMenu extends ConsumerWidget {
  const SortMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current sort option to show a "check" next to it
    final currentSort = ref.watch(gameSortProvider);

    return PopupMenuButton<GameSortOption>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Sort Games',
      onSelected: (GameSortOption option) {
        ref.read(gameSortProvider.notifier).setSort(option);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<GameSortOption>>[
        PopupMenuItem<GameSortOption>(
          value: GameSortOption.dateAdded,
          child: Row(
            children: [
              Icon(Icons.calendar_today,
                  color: currentSort == GameSortOption.dateAdded ? Colors.purple : Colors.grey),
              const SizedBox(width: 12),
              const Text('Date Added'),
              if (currentSort == GameSortOption.dateAdded) ...[
                const Spacer(),
                const Icon(Icons.check, size: 16, color: Colors.purple),
              ]
            ],
          ),
        ),
        PopupMenuItem<GameSortOption>(
          value: GameSortOption.alphabetical,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha,
                  color: currentSort == GameSortOption.alphabetical ? Colors.purple : Colors.grey),
              const SizedBox(width: 12),
              const Text('A - Z'),
              if (currentSort == GameSortOption.alphabetical) ...[
                const Spacer(),
                const Icon(Icons.check, size: 16, color: Colors.purple),
              ]
            ],
          ),
        ),
        PopupMenuItem<GameSortOption>(
          value: GameSortOption.rating,
          child: Row(
            children: [
              Icon(Icons.star_outline,
                  color: currentSort == GameSortOption.rating ? Colors.purple : Colors.grey),
              const SizedBox(width: 12),
              const Text('Highest Rated'),
              if (currentSort == GameSortOption.rating) ...[
                const Spacer(),
                const Icon(Icons.check, size: 16, color: Colors.purple),
              ]
            ],
          ),
        ),
      ],
    );
  }
}