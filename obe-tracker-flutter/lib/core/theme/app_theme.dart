import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // BUP Brand Colors
  static const Color primaryGreen = Color(0xFF006B3F);   // BUP dark green
  static const Color primaryLight = Color(0xFF00A86B);   // lighter green
  static const Color accent = Color(0xFFFFCC00);          // gold accent
  static const Color surface = Color(0xFFF8FAF9);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Attainment Level Colors
  static const Color l3Color = Color(0xFF16A34A);  // green
  static const Color l2Color = Color(0xFF2563EB);  // blue
  static const Color l1Color = Color(0xFFF59E0B);  // amber
  static const Color l0Color = Color(0xFFDC2626);  // red

  static Color attainmentColor(String level) => switch (level) {
        'L3' => l3Color,
        'L2' => l2Color,
        'L1' => l1Color,
        _ => l0Color,
      };

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: primaryLight,
      tertiary: accent,
      surface: surface,
      error: error,
      brightness: Brightness.light,
    ),
    
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111827),
      titleTextStyle: TextStyle(
        
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle( fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: primaryGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle( fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(space: 1, thickness: 1, color: Color(0xFFE5E7EB)),
    navigationDrawerTheme: const NavigationDrawerThemeData(
      backgroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
      bodyLarge: TextStyle(fontSize: 15, color: Color(0xFF374151)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF374151)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
    ),
  );
}
