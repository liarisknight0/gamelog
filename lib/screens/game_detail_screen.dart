import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/game_provider.dart';
import 'package:gamelog/screens/add_edit_game_screen.dart';

class GameDetailScreen extends ConsumerWidget {
  final Game game;
  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider so if we edit the game, this screen updates instantly
    ref.watch(gameListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers:[
          // --- 1. THE TOP IMAGE WITH GRADIENT FADE ---
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children:[
                  Hero(
                    tag: 'game-image-${game.key}',
                    child: game.coverUrl != null
                        ? CachedNetworkImage(
                      imageUrl: game.coverUrl!,
                      fit: BoxFit.cover,
                    )
                        : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                  // The Gradient overlay (Seamless blend into background)
                  Positioned(
                    bottom: -1, // -1 prevents a tiny 1px line glitch
                    left: 0,
                    right: 0,
                    height: 150,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors:[
                            Colors.transparent,
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions:[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddEditGameScreen(game: game)),
                ),
              ),
            ],
          ),

          // --- 2. THE CONTENT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Expanded(
                        child: Text(
                          game.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (game.rating != null && game.rating! > 0)
                        _buildRatingCircle(game.rating!),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${game.platform}  •  ${game.genre}",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                  ),

                  const SizedBox(height: 24),

                  // Physical/Digital Badge
                  Row(
                    children:[
                      Icon(
                        game.isPhysical == true ? Icons.album : Icons.cloud_download,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        game.isPhysical == true ? "Physical Copy" : "Digital Library",
                        style: const TextStyle(color: Colors.grey),
                      )
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  Text("Summary", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    (game.summary != null && game.summary!.isNotEmpty)
                        ? game.summary!
                        : "No summary available for this game.",
                    style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade300),
                  ),

                  // Gaming Journal (Notes) if they exist
                  if (game.notes != null && game.notes!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text("My Notes", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        game.notes!,
                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStatusPicker(context, ref),
        label: Text("Change Status: ${_getStatusText(game.status)}"),
        icon: const Icon(Icons.swap_horiz),
      ),
    );
  }

  Widget _buildRatingCircle(double rating) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
      ),
      child: Text(
        (rating / 10).toStringAsFixed(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 18),
      ),
    );
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.nowPlaying: return 'Playing';
      case GameStatus.notStarted: return 'Planned';
      case GameStatus.beaten: return 'Beaten';
      case GameStatus.paused: return 'Paused';
      case GameStatus.dropped: return 'Dropped';
      case GameStatus.backlog: return 'Backlog';
    }
  }

  void _showStatusPicker(BuildContext context, WidgetRef ref) {
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
                title: Text(_getStatusText(status)),
                trailing: game.status == status ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  ref.read(gameListProvider.notifier).updateGameStatus(game, status);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}