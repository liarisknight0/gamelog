import 'package:flutter/material.dart';

// Define a common color palette based on your inspiration
class AppColors {
  static const primaryPurple = Color(0xFF7A6BFE);
  static const lightPurple = Color(0xFFE8E5FF);
  static const darkBackground = Color(0xFF1A1A1A);
  static const darkSurface = Color(0xFF2C2C2C);
  static const darkAppBar = Color(0xFF222222);
  static const lightBackground = Color(0xFFF7F7FA);
  static const lightSurface = Colors.white;
}

// THEME DATA FOR THE LIGHT MODE
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  primaryColor: AppColors.primaryPurple,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightSurface,
    elevation: 1,
    iconTheme: IconThemeData(color: Colors.black87),
    titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
    color: AppColors.lightSurface,
    elevation: 1,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryPurple,
    foregroundColor: Colors.white,
  ),
  // --- THIS IS THE CORRECTED LINE ---
  cardTheme: CardThemeData(
    elevation: 0.5,
    color: AppColors.lightSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  colorScheme: const ColorScheme.light().copyWith(
    primary: AppColors.primaryPurple,
    secondary: AppColors.lightPurple,
    onPrimary: Colors.white,
    surface: AppColors.lightSurface,
  ),
);


// THEME DATA FOR THE DARK MODE (our existing theme, now formalized)
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  primaryColor: AppColors.primaryPurple,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkAppBar,
    elevation: 0,
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
    color: AppColors.darkAppBar,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryPurple,
    foregroundColor: Colors.white,
  ),
  // --- THIS IS THE SECOND CORRECTED LINE ---
  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  colorScheme: const ColorScheme.dark().copyWith(
    primary: AppColors.primaryPurple,
    secondary: AppColors.lightPurple,
    onPrimary: Colors.white,
    surface: AppColors.darkSurface,
  ),
);