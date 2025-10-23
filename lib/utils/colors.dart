import 'package:flutter/material.dart';

class AppColors {
  // Primary Purple Color (consistent across both themes)
  static const Color primaryPurple = Color(0xFF9333EA);

  // Statistics Purple Color (from Statistiques card)
  static const Color statisticsPurple = Color(0xFF673AB7);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFF5F5F5);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF1F2937);
  static const Color lightIconColor = Color(0xFF374151);
  static const Color lightButtonHover = Color(0xFFA855F7);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0A192F);
  static const Color darkCardBackground = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFE5E7EB);
  static const Color darkIconColor = Color(0xFFD1D5DB);
  static const Color darkButtonHover = Color(0xFFB366F0);

  // Glass Effect Colors
  static const Color glassEffectLight = Color(
    0x4DFFFFFF,
  ); // White with 30% opacity
  static const Color glassEffectDark = Color(
    0x4D000000,
  ); // Black with 30% opacity

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF9333EA),
    Color(0xFF7C3AED),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0A192F),
    Color(0xFF1E293B),
  ];
}
