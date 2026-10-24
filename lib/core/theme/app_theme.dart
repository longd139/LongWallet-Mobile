import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF334155);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color expenseRed = Color(0xFFEF4444);
  static const Color incomeGreen = Color(0xFF10B981);
  static const Color transferBlue = Color(0xFF3B82F6);

  // Light theme colors
  static const Color primaryLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0F172A);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryEmerald,
      secondary: transferBlue,
      surface: surfaceDark,
      error: expenseRed,
      onSurface: Colors.white,
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      thickness: 0,
      space: 0,
    ),
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardDark.withOpacity(0.5)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryEmerald, width: 2),
      ),
      labelStyle: const TextStyle(color: textMuted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceDark,
      surfaceTintColor: Colors.transparent,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: primaryLight,
    colorScheme: const ColorScheme.light(
      primary: primaryEmerald,
      secondary: transferBlue,
      surface: surfaceLight,
      error: expenseRed,
      onSurface: textDark,
      onPrimary: Colors.white,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFF1F5F9),
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardTheme(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderLight),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      iconTheme: IconThemeData(color: textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryEmerald, width: 2),
      ),
      labelStyle: const TextStyle(color: textMutedLight),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceLight,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
