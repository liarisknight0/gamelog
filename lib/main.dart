import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- Ensure this import is present for SystemChrome
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/theme_provider.dart';
import 'package:gamelog/screens/main_screen.dart';
import 'package:gamelog/screens/onboarding_screen.dart';
import 'package:gamelog/themes/app_themes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final bool hasSeenOnboarding;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- THESE LINES ARE CRITICAL FOR EDGE-TO-EDGE DISPLAY ---
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Makes status bar transparent
    systemNavigationBarColor: Colors.transparent, // Makes nav bar transparent
    statusBarIconBrightness: Brightness.light, // Adjust based on your app's main color scheme
    systemNavigationBarIconBrightness: Brightness.light, // Adjust based on your app's bottom nav content
  ));
  // ---------------------------------------------------------

  await Hive.initFlutter();
  Hive.registerAdapter(GameAdapter());
  Hive.registerAdapter(GameStatusAdapter());
  await Hive.openBox<Game>('games');
  await Hive.openBox('userSettings');

  final prefs = await SharedPreferences.getInstance();
  hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(const ProviderScope(child: GameLogApp()));
}

class GameLogApp extends ConsumerWidget {
  const GameLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'GameLog',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: hasSeenOnboarding ? const MainScreen() : const OnboardingScreen(),
    );
  }
}