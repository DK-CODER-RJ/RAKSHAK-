import 'package:flutter/material.dart';

class AppColors {
  // Primary Action Colors
  static const Color primaryGreen = Color(0xFF1EBB53); // Vibrant Green

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0FDF4); // Very light green
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);

  // Status
  static const Color warning = Color(0xFFFFCC00);
  static const Color error =
      Color(0xFFFF3B30); // Kept for functional error states, but not primary UI

  // Safety Theme Colors
  static const Color safetyRed = Color(0xFFD32F2F);
  static const Color safetyBackground = Color(0xFF1A0A0A);
  static const Color safetySurface = Color(0xFF2C1111);

  // Premium Theme Colors
  static const Color premiumGold = Color(0xFFFFD700);
  static const Color premiumBackground = Color(0xFF0D0D0D);
  static const Color premiumSurface = Color(0xFF1A1A1A);
}
