import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'game.g.dart';

@HiveType(typeId: 1)
enum GameStatus {
  @HiveField(0)
  backlog,

  @HiveField(1)
  notStarted,

  @HiveField(2)
  nowPlaying,

  @HiveField(3)
  paused,

  @HiveField(4)
  beaten,

  @HiveField(5)
  dropped,
}

@HiveType(typeId: 0)
class Game extends HiveObject {
  // --- Field 11: Unique ID for Firebase Sync ---
  @HiveField(11)
  String id;

  @HiveField(0)
  String title;

  @HiveField(1)
  String platform;

  @HiveField(2)
  String genre;

  @HiveField(3)
  GameStatus status;

  @HiveField(4)
  DateTime dateAdded;

  @HiveField(5)
  String? coverUrl;

  @HiveField(6)
  String? summary;

  @HiveField(7)
  double? rating;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  bool? isPhysical;

  @HiveField(10)
  double? progress;

  Game({
    String? id, // Optional: if null, we generate one
    required this.title,
    required this.platform,
    required this.genre,
    required this.status,
    required this.dateAdded,
    this.coverUrl,
    this.summary,
    this.rating,
    this.notes,
    this.isPhysical = false,
    this.progress = 0.0,
  }) : id = id ?? const Uuid().v4(); // Auto-generate UUID if not provided

  // --- Factory to create a Game from Firebase Map ---
  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      title: map['title'] ?? 'Unknown',
      platform: map['platform'] ?? 'Unknown',
      genre: map['genre'] ?? 'Unknown',
      // Safely convert Integer (Firebase) -> Enum (Flutter)
      status: (map['status'] != null &&
          map['status'] is int &&
          map['status'] >= 0 &&
          map['status'] < GameStatus.values.length)
          ? GameStatus.values[map['status']]
          : GameStatus.backlog, // Fallback
      dateAdded: DateTime.tryParse(map['dateAdded'] ?? '') ?? DateTime.now(),
      coverUrl: map['coverUrl'],
      summary: map['summary'],
      rating: (map['rating'] as num?)?.toDouble(),
      notes: map['notes'],
      isPhysical: map['isPhysical'] ?? false,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}