import 'package:flutter/material.dart';

/// RAKSHAK App Theme — Centralized theme configuration.
/// Light, clean aesthetic matching the "Vigilance Prime" design system.
class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color secondaryGreen = Color(0xFF388E3C);
  static const Color tertiaryBlue = Color(0xFF1976D2);
  static const Color surfaceWhite = Color(0xFFF9F9F9);
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1C1C);
  static const Color textSecondary = Color(0xFF757575);
  static const Color cardWhite = Colors.white;

  static ThemeData get lightTheme => _buildLightTheme();
  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.light,
        primary: primaryRed,
        secondary: secondaryGreen,
        tertiary: tertiaryBlue,
        surface: surfaceWhite,
      ),
      scaffoldBackgroundColor: backgroundGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed, foregroundColor: Colors.white,
          elevation: 0, minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? secondaryGreen : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? secondaryGreen.withValues(alpha: 0.3) : Colors.grey[300]),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    // TODO: Implement dark theme if needed
    return _buildLightTheme();
  }
}
