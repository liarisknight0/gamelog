import 'dart:convert';
import 'package:http/http.dart' as http;

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
  // Replace these with your actual credentials from the Twitch Console
  static const String _clientId = '84mpd4dwjm9492rxhlefn7wu66gpzo';
  static const String _clientSecret = '4oihmsmzvqof085ppyg053f6qv5o4c';

  String? _accessToken;

  /// STEP 1: Get the VIP Pass (Access Token)
  Future<void> _getAccessToken() async {
    // If we already have a token, don't ask for a new one
    if (_accessToken != null) return;

    final url = Uri.parse(
        'https://id.twitch.tv/oauth2/token?client_id=$_clientId&client_secret=$_clientSecret&grant_type=client_credentials'
    );

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
    } else {
      throw Exception('Failed to get Access Token');
    }
  }

  /// STEP 2: Use the Token to Search Games
  Future<List<ApiGame>> searchGames(String query) async {
    if (query.trim().isEmpty) return [];

    // Ensure we have a token before proceeding
    await _getAccessToken();

    final url = Uri.parse('https://api.igdb.com/v4/games');

    final response = await http.post(
      url,
      headers: {
        'Client-ID': _clientId,
        'Authorization': 'Bearer $_accessToken', // Capitalisation matters!
      },
      // This is the BODY mentioned in your docs.
      // We ask for specific fields and search by the query.
      body: 'fields name, cover.url, genres.name, platforms.name, summary, total_rating; search "$query"; limit 15;',
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((gameJson) {
        final coverMap = gameJson['cover'] as Map<String, dynamic>?;
        // Big cover art looks better on mobile
        final coverUrl = coverMap?['url']?.toString().replaceFirst('t_thumb', 't_cover_big') ?? '';

        final platformsList = (gameJson['platforms'] as List?)?.map((p) => p['name'].toString()).toList() ?? [];
        final genresList = (gameJson['genres'] as List?)?.map((g) => g['name'].toString()).toList() ?? [];

        return ApiGame(
          title: gameJson['name'] ?? 'No Title',
          coverUrl: coverUrl.isNotEmpty ? 'https:$coverUrl' : '',
          summary: gameJson['summary'] ?? 'No summary available.',
          platforms: platformsList.take(2).join(', '),
          genres: genresList.take(2).join(', '),
          rating: (gameJson['total_rating'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } else if (response.statusCode == 401) {
      // If token expired, clear it and try one more time
      _accessToken = null;
      return searchGames(query);
    } else {
      throw Exception('IGDB API Error: ${response.statusCode}');
    }
  }
}