import 'package:hive/hive.dart';

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
  @HiveField(0) String title;
  @HiveField(1) String platform;
  @HiveField(2) String genre;
  @HiveField(3) GameStatus status;
  @HiveField(4) DateTime dateAdded;
  @HiveField(5) String? coverUrl;
  @HiveField(6) String? summary;
  @HiveField(7) double? rating;

  // --- NEW FIELDS ADDED FOR PRE-RELEASE ---
  @HiveField(8) String? notes;        // For the Gaming Journal
  @HiveField(9) bool? isPhysical;     // Physical vs Digital
  @HiveField(10) double? progress;    // 0.0 to 1.0 for the progress bar

  Game({
    required this.title,
    required this.platform,
    required this.genre,
    required this.status,
    required this.dateAdded,
    this.coverUrl,
    this.summary,
    this.rating,
    this.notes,
    this.isPhysical = false, // Defaults to Digital
    this.progress = 0.0,
  });
}