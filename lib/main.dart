import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/theme_provider.dart';
import 'package:gamelog/screens/auth_screen.dart';
import 'package:gamelog/screens/main_screen.dart';
import 'package:gamelog/screens/onboarding_screen.dart';
import 'package:gamelog/services/firebase_sync_service.dart';
import 'package:gamelog/providers/sync_status_provider.dart';
import 'package:gamelog/themes/app_themes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global flag for onboarding status
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSync();
    });
  }

  Future<void> _initSync() async {
    final firebaseSyncService = ref.read(firebaseSyncServiceProvider);

    await firebaseSyncService.signInSilently();
    // ---------------------------------

    // Listen for Firebase Auth state changes
    firebaseSyncService.authStateChanges.listen((user) {
      if (user != null) {
        firebaseSyncService.startListeningToCloud();
        ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.synced);
      } else {
        firebaseSyncService.stopListeningToCloud();
        ref.read(syncStatusNotifierProvider.notifier).setStatus(SyncState.hidden);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final firebaseUser = ref.watch(firebaseSyncServiceProvider).currentUser;

    Widget initialScreen;
    if (!hasSeenOnboarding) {
      initialScreen = const OnboardingScreen();
    } else if (firebaseUser != null) {
      initialScreen = const MainScreen();
    } else {
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