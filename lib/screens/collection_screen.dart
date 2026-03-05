import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/providers/selection_provider.dart'; // <--- NEW IMPORT
import 'package:gamelog/screens/search_screen.dart';
import 'package:gamelog/widgets/empty_state_widget.dart';
import 'package:gamelog/widgets/game_card.dart';
import 'package:gamelog/widgets/sort_menu.dart';
import 'package:gamelog/widgets/sync_indicator.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  /// The dialog that asks the user where to move the selected games
  void _showBatchMoveDialog(BuildContext context, WidgetRef ref, Set<String> selectedIds, List<Game> allGames) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: GameStatus.values.map((status) {
              return ListTile(
                title: Text("Move to ${_getStatusText(status)}"),
                onTap: () {
                  final gameRepo = ref.read(gameRepositoryProvider);
                  // Loop through all selected IDs and update their status
                  for (final id in selectedIds) {
                    final game = allGames.firstWhere((g) => g.id == id);
                    gameRepo.updateGameStatus(game, status);
                  }

                  // Clear selection state and close dialog
                  ref.read(isSelectionModeProvider.notifier).state = false;
                  ref.read(selectedGamesProvider.notifier).state = {};
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Moved ${selectedIds.length} games to ${_getStatusText(status)}')),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// The dialog to confirm batch deletion
  void _showBatchDeleteDialog(BuildContext context, WidgetRef ref, Set<String> selectedIds, List<Game> allGames) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Multiple Games?'),
        content: Text('Are you sure you want to permanently delete ${selectedIds.length} games?'),
        actions:[
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
            onPressed: () {
              final gameRepo = ref.read(gameRepositoryProvider);
              for (final id in selectedIds) {
                final game = allGames.firstWhere((g) => g.id == id);
                gameRepo.deleteGame(game);
              }

              ref.read(isSelectionModeProvider.notifier).state = false;
              ref.read(selectedGamesProvider.notifier).state = {};
              Navigator.of(ctx).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${selectedIds.length} games')),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.nowPlaying: return 'Now Playing';
      case GameStatus.notStarted: return 'Not Started';
      case GameStatus.beaten: return 'Beaten';
      case GameStatus.paused: return 'Paused';
      case GameStatus.dropped: return 'Dropped';
      case GameStatus.backlog: return 'Backlog';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameListAsync = ref.watch(collectionProvider); // Assuming CollectionProvider returns AsyncValue now

    // --- SELECTION STATE ---
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedGames = ref.watch(selectedGamesProvider);

    return Scaffold(
      appBar: isSelectionMode
          ? AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(isSelectionModeProvider.notifier).state = false;
            ref.read(selectedGamesProvider.notifier).state = {};
          },
        ),
        title: Text('${selectedGames.length} Selected'),
        actions:[
          // Select All Button
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: 'Select All',
            onPressed: () {
              // We need to get the actual list of games to select them all
              // We do a quick read of the raw data list
              final allRawGamesAsync = ref.read(gameListProvider);
              allRawGamesAsync.whenData((allGamesList) {
                final allIds = allGamesList.map((g) => g.id).toSet();
                ref.read(selectedGamesProvider.notifier).state = allIds;
              });
            },
          ),
          // Batch Move Button
          IconButton(
            icon: const Icon(Icons.drive_file_move_rounded),
            tooltip: 'Move to...',
            onPressed: selectedGames.isEmpty ? null : () {
              final allRawGamesAsync = ref.read(gameListProvider);
              allRawGamesAsync.whenData((allGamesList) {
                _showBatchMoveDialog(context, ref, selectedGames, allGamesList);
              });
            },
          ),
          // Batch Delete Button
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
            tooltip: 'Delete Selected',
            onPressed: selectedGames.isEmpty ? null : () {
              final allRawGamesAsync = ref.read(gameListProvider);
              allRawGamesAsync.whenData((allGamesList) {
                _showBatchDeleteDialog(context, ref, selectedGames, allGamesList);
              });
            },
          ),
        ],
      )
          : AppBar(
        title: const Text('My Collection'),
        actions:[
          // Manual entry into selection mode via icon
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: 'Select Multiple',
            onPressed: () {
              ref.read(isSelectionModeProvider.notifier).state = true;
            },
          ),
          const SyncIndicator(),
          const SortMenu(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: gameListAsync.isEmpty
          ? const EmptyStateWidget(
        icon: Icons.collections_bookmark_outlined,
        title: 'Your Collection is Empty',
        message: "Games you own appear here. Add one from your Backlog or use the '+' button.",
      )
          : ListView.builder(
        itemCount: gameListAsync.length,
        itemBuilder: (context, index) {
          return GameCard(game: gameListAsync[index]);
        },
      ),
    );
  }
}