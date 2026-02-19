import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gamelog/models/game.dart';

class BackupService {
  /// EXPORT: Converts all Hive games to JSON and shares it
  static Future<void> exportBackup(BuildContext context) async {
    try {
      final box = Hive.box<Game>('games');

      final List<Map<String, dynamic>> jsonData = box.values.map((game) {
        return {
          'title': game.title,
          'platform': game.platform,
          'genre': game.genre,
          'status': game.status.index,
          'dateAdded': game.dateAdded.toIso8601String(),
          'coverUrl': game.coverUrl,
          'summary': game.summary,
          'rating': game.rating,
          'notes': game.notes,
          'isPhysical': game.isPhysical,
          'progress': game.progress,
        };
      }).toList();

      final String jsonString = jsonEncode(jsonData);
      final directory = await getTemporaryDirectory();

      // Use a unique name with date so user can keep multiple backups
      final String fileName = 'GameLog_Backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)], text: 'My GameLog Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  /// IMPORT: Picks file, reads bytes, and performs SMART MERGE
  static Future<void> importBackup(BuildContext context, Function onComplete) async {
    try {
      // 1. Open File Picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,    // CRITICAL: Load into memory for Drive/Cloud compatibility
      );

      if (result != null && result.files.first.bytes != null) {
        // 2. Read bytes directly from memory
        Uint8List fileBytes = result.files.first.bytes!;
        String content = utf8.decode(fileBytes);
        List<dynamic> jsonData = jsonDecode(content);

        final box = Hive.box<Game>('games');
        int addedCount = 0;

        // 3. Smart Merge Logic
        for (var item in jsonData) {
          final String newTitle = item['title'] ?? 'Unknown';
          final String newPlatform = item['platform'] ?? 'Unknown';

          // Check for existing game with same Title AND Platform
          final bool exists = box.values.any((existingGame) =>
          existingGame.title.trim().toLowerCase() == newTitle.trim().toLowerCase() &&
              existingGame.platform == newPlatform
          );

          if (!exists) {
            final game = Game(
              title: newTitle,
              platform: newPlatform,
              genre: item['genre'] ?? 'Unknown',
              status: GameStatus.values[item['status'] ?? 0],
              dateAdded: DateTime.parse(item['dateAdded'] ?? DateTime.now().toIso8601String()),
              coverUrl: item['coverUrl'],
              summary: item['summary'],
              rating: (item['rating'] as num?)?.toDouble(),
              notes: item['notes'],
              isPhysical: item['isPhysical'] ?? false,
              progress: (item['progress'] as num?)?.toDouble() ?? 0.0,
            );
            await box.add(game);
            addedCount++;
          }
        }

        onComplete(); // Refresh Riverpod state

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import Complete: $addedCount new games added.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Import Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import failed: Check file format.')),
        );
      }
    }
  }
}