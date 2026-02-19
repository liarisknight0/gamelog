import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelog/models/game.dart';
import 'package:gamelog/providers/theme_provider.dart';
import 'package:gamelog/screens/auth_screen.dart'; // <--- NEW IMPORT
import 'package:gamelog/screens/main_screen.dart';
import 'package:gamelog/screens/onboarding_screen.dart';
import 'package:gamelog/services/cloud_sync_service.dart';
import 'package:gamelog/themes/app_themes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This will be our entry point widget.
late final bool hasSeenOnboarding;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Hive.initFlutter();
  Hive.registerAdapter(GameAdapter());
  Hive.registerAdapter(GameStatusAdapter());
  await Hive.openBox<Game>('games');
  await Hive.openBox('userSettings');

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
  Future<void> _checkSignInStatus() async {
    // Attempt silent sign-in if the user was previously signed in
    await ref.read(cloudSyncServiceProvider).signInSilently();
    // This will update googleSignInAccountProvider, which widgets can watch
  }

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final googleAccount = ref.watch(googleSignInAccountProvider); // Watch the Google account status

    Widget initialScreen;
    if (!hasSeenOnboarding) {
      initialScreen = const OnboardingScreen();
    } else if (googleAccount != null) {
      // If signed in, go directly to MainScreen
      initialScreen = const MainScreen();
    } else {
      // If onboarding seen, but not signed in (or explicitly chose guest), go to AuthScreen
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