import 'package:flutter_riverpod/flutter_riverpod.dart';

// True if the user is currently selecting multiple games
final isSelectionModeProvider = StateProvider<bool>((ref) => false);

// Holds the unique IDs of the selected games
final selectedGamesProvider = StateProvider<Set<String>>((ref) => {});