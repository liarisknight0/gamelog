import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gamelog/models/game.dart';

class BackupService {
  /// EXPORT: Converts all Hive games to JSON and opens the Share Sheet
  static Future<void> exportBackup(BuildContext context) async {
    try {
      final box = Hive.box<Game>('games');

      // Convert Hive objects to a list of Maps
      final List<Map<String, dynamic>> jsonData = box.values.map((game) {
        return {
          'title': game.title,
          'platform': game.platform,
          'genre': game.genre,
          'status': game.status.index, // Enum to Int
          'dateAdded': game.dateAdded.toIso8601String(),
          'coverUrl': game.coverUrl,
          'summary': game.summary,
          'rating': game.rating,
        };
      }).toList();

      final String jsonString = jsonEncode(jsonData);

      // Save to a temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/gamelog_backup.json');
      await file.writeAsString(jsonString);

      // Open System Share Sheet
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My GameLog Backup - ${DateTime.now().toString().split(' ')[0]}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  /// IMPORT: Picks a JSON file and adds the games to Hive
  static Future<void> importBackup(BuildContext context, Function onComplete) async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> jsonData = jsonDecode(content);

        final box = Hive.box<Game>('games');

        // 2. Parse and Add to Hive
        for (var item in jsonData) {
          final game = Game(
            title: item['title'],
            platform: item['platform'],
            genre: item['genre'],
            status: GameStatus.values[item['status']], // Int back to Enum
            dateAdded: DateTime.parse(item['dateAdded']),
            coverUrl: item['coverUrl'],
            summary: item['summary'],
            rating: item['rating']?.toDouble(),
          );
          await box.add(game);
        }

        onComplete(); // Refresh the UI
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: Invalid file or data.')),
        );
      }
    }
  }
}