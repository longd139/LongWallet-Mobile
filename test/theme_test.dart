import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:longwallet/core/theme/app_theme.dart';
import 'package:longwallet/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme Tests', () {
    test('darkTheme has correct brightness and background colors', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, AppTheme.primaryDark);
      expect(AppTheme.darkTheme.colorScheme.surface, AppTheme.surfaceDark);
    });

    test('lightTheme has correct brightness and background colors', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppTheme.primaryLight);
      expect(AppTheme.lightTheme.colorScheme.surface, AppTheme.surfaceLight);
      expect(AppTheme.lightTheme.colorScheme.primary, AppTheme.primaryEmerald);
    });
  });

  group('ThemeProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeProvider initializes with dark mode by default', () {
      final themeProvider = ThemeProvider();
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
    });

    test('toggleTheme toggles from dark to light and back to dark', () async {
      final themeProvider = ThemeProvider();
      expect(themeProvider.isDarkMode, isTrue);

      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, isFalse);

      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
    });

    test('setThemeMode updates themeMode and isDarkMode correctly', () async {
      final themeProvider = ThemeProvider();

      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, isFalse);

      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, isTrue);
    });
  });
}
