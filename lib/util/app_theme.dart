import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF004B40),
        brightness: Brightness.light,
      ).copyWith(
        surface: Colors.white,
        onSurface: const Color(0xFF222222),
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF222222),
        surfaceTintColor: Color(0xFF004B40),
        elevation: 0,
      ),
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStatePropertyAll(Color(0xFF004B40)),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0BB38A),
        secondary: Color(0xFF4FD1B4),
        surface: Color(0xFF121212),
        onSurface: Color(0xFFE6E6E6),
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        foregroundColor: Color(0xFFEFEFEF),
        surfaceTintColor: Color(0xFF0BB38A),
        elevation: 0,
      ),
      cardColor: const Color(0xFF171717),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStatePropertyAll(
          const Color(0xFF0BB38A).withValues(alpha: 0.85),
        ),
      ),
      useMaterial3: true,
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1A1A1A),
      ),
    );
  }
}
