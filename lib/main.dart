import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/theme_provider.dart';
import 'package:gamelog/screens/auth_screen.dart';
import 'package:gamelog/screens/main_screen.dart';
import 'package:gamelog/screens/onboarding_screen.dart';
import 'package:gamelog/services/firebase_sync_service.dart'; // <--- NEW SERVICE
import 'package:gamelog/themes/app_themes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final bool hasSeenOnboarding;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. Initialize Firebase ---
  await Firebase.initializeApp();

  // --- 2. System UI Configuration ---
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // --- 3. Initialize Hive Database ---
  await Hive.initFlutter();
  Hive.registerAdapter(GameAdapter());
  Hive.registerAdapter(GameStatusAdapter());
  await Hive.openBox<Game>('games');
  await Hive.openBox('userSettings');

  // --- 4. Load Preferences ---
  final prefs = await SharedPreferences.getInstance();
  hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(const ProviderScope(child: GameLogApp()));
}

class GameLogApp extends ConsumerStatefulWidget {
  const GameLogApp({super.key});

  @override
  ConsumerState<GameLogApp> createState() => _GameLogAppState();
}

class _GameLogAppState extends ConsumerState<GameLogApp> {
  @override
  void initState() {
    super.initState();
    _initSync();
  }

  Future<void> _initSync() async {
    // Check if user is already signed in to Firebase
    // If yes, turn on the listener to pull down cloud changes
    final syncService = ref.read(firebaseSyncServiceProvider);

    if (syncService.currentUser != null) {
      syncService.startListeningToCloud();
    }

    // Also listen for future login/logout events to start/stop sync
    syncService.authStateChanges.listen((user) {
      if (user != null) {
        syncService.startListeningToCloud();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final firebaseUser = ref.watch(firebaseSyncServiceProvider).currentUser;

    // --- ROUTING LOGIC ---
    Widget initialScreen;
    if (!hasSeenOnboarding) {
      initialScreen = const OnboardingScreen();
    } else if (firebaseUser != null) {
      // Logged in via Firebase -> Main App
      initialScreen = const MainScreen();
    } else {
      // Returning user, not logged in -> Auth Screen
      initialScreen = const AuthScreen();
    }

    return MaterialApp(
      title: 'GameLog',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}