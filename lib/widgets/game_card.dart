import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/screens/add_edit_game_screen.dart';
import 'package:gamelog/screens/game_detail_screen.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // For formatting the date

class GameCard extends StatelessWidget {
  final Game game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias, // Ensures the image corners are rounded
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha:0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => GameDetailScreen(game: game)),
          );
        },
        onLongPress: () {
          HapticFeedback.heavyImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => AddEditGameScreen(game: game)),
          );
        },
        child: SizedBox(
          height: 140, // A fixed height creates a clean, uniform list
          child: Row(
            children: [
              // --- LEFT SIDE: GAME COVER ---
              SizedBox(
                width: 100,
                height: double.infinity,
                child: _buildCoverImage(),
              ),

              // --- RIGHT SIDE: GAME DETAILS ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Platform & Genre
                      Text(
                        "${game.platform} • ${game.genre}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(), // Pushes the bottom row down
                      // Status and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Added: ${DateFormat.yMMMd().format(game.dateAdded)}",
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                          _buildStatusChip(),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildCoverImage() {
    // If we have a URL, show the network image.
    if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: game.coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade800,
          child: const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    }
    // Otherwise, show a placeholder.
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(game.status).withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(game.status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(game.status),
        ),
      ),
    );
  }

  String _getStatusText(GameStatus status) {
    // Using shorter, punchier text for the small chip
    switch (status) {
      case GameStatus.nowPlaying: return 'PLAYING';
      case GameStatus.notStarted: return 'PLANNED';
      case GameStatus.beaten: return 'BEATEN';
      case GameStatus.paused: return 'PAUSED';
      case GameStatus.dropped: return 'DROPPED';
      case GameStatus.backlog: return 'WISHLIST';
    }
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.nowPlaying: return Colors.blue.shade700;
      case GameStatus.beaten: return Colors.green.shade700;
      case GameStatus.paused: return Colors.orange.shade700;
      case GameStatus.dropped: return Colors.red.shade700;
      default: return Colors.grey.shade700;
    }
  }
}