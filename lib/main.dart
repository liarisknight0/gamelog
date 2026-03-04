import 'package:firebase_core/firebase_core.dart'; // <--- NEW: Required for Firebase
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/theme_provider.dart';
import 'package:gamelog/screens/auth_screen.dart';
import 'package:gamelog/screens/main_screen.dart';
import 'package:gamelog/screens/onboarding_screen.dart';
import 'package:gamelog/services/cloud_sync_service.dart';
import 'package:gamelog/themes/app_themes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global flag for onboarding status
late final bool hasSeenOnboarding;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. Initialize Firebase ---
  // This connects your app to the google-services.json file
  await Firebase.initializeApp();

  // --- 2. System UI Configuration ---
  // Makes status bar and nav bar transparent for edge-to-edge design
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
    // Attempt to silently sign in the user in the background
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    // This updates the googleSignInAccountProvider state if a user is found
    await ref.read(cloudSyncServiceProvider).signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final googleAccount = ref.watch(googleSignInAccountProvider);

    // --- ROUTING LOGIC ---
    Widget initialScreen;
    if (!hasSeenOnboarding) {
      // 1. First time user -> Onboarding
      initialScreen = const OnboardingScreen();
    } else if (googleAccount != null) {
      // 2. Returning user, signed in -> Main App
      initialScreen = const MainScreen();
    } else {
      // 3. Returning user, NOT signed in -> Login/Guest Screen
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