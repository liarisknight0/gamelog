import 'dart:convert';
import 'package:http/http.dart' as http;

// This class represents the data we get back from the API search.
class ApiGame {
  final String title;
  final String coverUrl;
  final String summary;
  final String platforms;
  final String genres;
  final double rating;

  ApiGame({
    required this.title,
    required this.coverUrl,
    required this.summary,
    required this.platforms,
    required this.genres,
    required this.rating,
  });
}


class IGDBService {
  // TODO: Get these from https://dev.twitch.tv/console later
  static const String _clientId = 'YOUR_CLIENT_ID_HERE';
  static const String _accessToken = 'YOUR_ACCESS_TOKEN_HERE';

  // If keys are missing, we use Mock Data so the app works during development
  bool get _useMockData => _clientId == 'YOUR_CLIENT_ID_HERE';

  Future<List<ApiGame>> searchGames(String query) async {
    if (query.trim().isEmpty) return [];

    if (_useMockData) {
      // This simulates a network delay so we can test loading spinners.
      await Future.delayed(const Duration(milliseconds: 700));
      // Return fake data for UI building.
      return [
        ApiGame(
          title: "The Witcher 3: Wild Hunt (Mock)",
          coverUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big/co1wz4.jpg",
          summary: "The Witcher 3: Wild Hunt is a story-driven open world RPG set in a visually stunning fantasy universe full of meaningful choices and impactful consequences.",
          platforms: "PC, PlayStation 4, Xbox One",
          genres: "RPG, Adventure",
          rating: 92.0,
        ),
        ApiGame(
          title: "Cyberpunk 2077 (Mock)",
          coverUrl: "https://images.igdb.com/igdb/image/upload/t_cover_big/co1r7f.jpg",
          summary: "Cyberpunk 2077 is an open-world, action-adventure story set in Night City, a megalopolis obsessed with power, glamour and body modification.",
          platforms: "PC, PlayStation 5, Xbox Series X/S",
          genres: "RPG, Action",
          rating: 72.0,
        ),
      ];
    }

    // --- THIS IS THE REAL API LOGIC THAT WILL RUN WHEN YOU ADD KEYS ---
    final url = Uri.parse('https://api.igdb.com/v4/games');
    final response = await http.post(
      url,
      headers: {
        'Client-ID': _clientId,
        'Authorization': 'Bearer $_accessToken',
      },
      body: 'fields name, cover.url, genres.name, platforms.name, summary, total_rating; search "$query"; limit 15;',
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      // Convert the raw JSON into our clean ApiGame objects
      return data.map((gameJson) {
        final coverMap = gameJson['cover'] as Map<String, dynamic>?;
        final coverUrl = coverMap?['url']?.toString().replaceFirst('t_thumb', 't_cover_big') ?? '';

        final platformsList = (gameJson['platforms'] as List?)?.map((p) => p['name'].toString()).toList() ?? [];
        final genresList = (gameJson['genres'] as List?)?.map((g) => g['name'].toString()).toList() ?? [];

        return ApiGame(
          title: gameJson['name'] ?? 'No Title',
          coverUrl: 'https:$coverUrl',
          summary: gameJson['summary'] ?? 'No summary available.',
          platforms: platformsList.take(2).join(', '), // Show max 2 platforms
          genres: genresList.take(2).join(', '), // Show max 2 genres
          rating: (gameJson['total_rating'] as double?) ?? 0.0,
        );
      }).toList();
    } else {
      // If the API fails, throw an error so we can show it in the UI.
      throw Exception('Failed to load games from IGDB. Status code: ${response.statusCode}');
    }
  }
}