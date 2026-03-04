import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // <--- NEW IMPORT

part 'game.g.dart';

@HiveType(typeId: 1)
enum GameStatus {
  @HiveField(0) backlog,
  @HiveField(1) notStarted,
  @HiveField(2) nowPlaying,
  @HiveField(3) paused,
  @HiveField(4) beaten,
  @HiveField(5) dropped,
}

@HiveType(typeId: 0)
class Game extends HiveObject {
  // --- NEW: Unique ID for Firebase ---
  @HiveField(11)
  String id;
  // -----------------------------------

  @HiveField(0) String title;
  @HiveField(1) String platform;
  @HiveField(2) String genre;
  @HiveField(3) GameStatus status;
  @HiveField(4) DateTime dateAdded;
  @HiveField(5) String? coverUrl;
  @HiveField(6) String? summary;
  @HiveField(7) double? rating;
  @HiveField(8) String? notes;
  @HiveField(9) bool? isPhysical;
  @HiveField(10) double? progress;

  Game({
    String? id, // Optional in constructor
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
  }) : id = id ?? const Uuid().v4(); // If ID is empty, generate a new one automatically
}