import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF138A4B);
  static const Color backgroundLight = Color(0xFFF5FAF7);
  static const Color accentLightGreen = Color(0xFFE3F5E9);
  static const Color darkText = Color(0xFF173B2A);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color subtitleGrey = Color(0xFF6C757D);
  static const Color borderGrey = Color(0xFFE0E0E0);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        surface: pureWhite,
        background: backgroundLight,
      ),
      fontFamily: 'Roboto', // Fallback to standard Flutter font
      appBarTheme: const AppBarTheme(
        backgroundColor: pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: pureWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: pureWhite,
        elevation: 8,
        indicatorColor: accentLightGreen,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 26);
          }
          return const IconThemeData(color: Colors.grey, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.normal,
            fontSize: 12,
          );
        }),
      ),
    );
  }
}
