import 'package:flutter/material.dart';

// Define a common color palette
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
  cardTheme: CardThemeData(
    elevation: 0.5,
    color: AppColors.lightSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  // --- MODERN FLOATING SNACKBAR ---
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 6,
    insetPadding: const EdgeInsets.all(16),
    backgroundColor: AppColors.primaryPurple,
    contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  // ---------------------------------
  colorScheme: const ColorScheme.light().copyWith(
    primary: AppColors.primaryPurple,
    secondary: AppColors.lightPurple,
    onPrimary: Colors.white,
    surface: AppColors.lightSurface,
  ),
);

// THEME DATA FOR THE DARK MODE
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
  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  // --- MODERN FLOATING SNACKBAR ---
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 6,
    insetPadding: const EdgeInsets.all(16),
    backgroundColor: AppColors.primaryPurple,
    contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  // ---------------------------------
  colorScheme: const ColorScheme.dark().copyWith(
    primary: AppColors.primaryPurple,
    secondary: AppColors.lightPurple,
    onPrimary: Colors.white,
    surface: AppColors.darkSurface,
  ),
);