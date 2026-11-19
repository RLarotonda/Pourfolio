import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF100D12);
  static const surface = Color(0xFF1C1420);
  static const wine = Color(0xFF722B4A);
  static const gold = Color(0xFFC19A72);
  static const text = Color(0xFFF5F0EB);
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'DMSans',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: wine,
      surface: surface,
      onPrimary: background,
      onSurface: text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: gold),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: Color(0xFF351B32),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
