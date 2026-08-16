import 'package:flutter/material.dart';

/// Centralized color palette for the EV Route Planner app.
///
/// Keeping every color in one place makes it trivial to re-theme the
/// app or keep light/dark variants in sync.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ---- Brand greens (from the Figma splash design) ----
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color lightGreenBg = Color(0xFFE8F5E9);
  static const Color paleGreenBlob = Color(0xFFDCEFDE);

  // ---- Feature chip accents ----
  static const Color chipYellow = Color(0xFFFFC107); // Fast Charging
  static const Color chipBlue = Color(0xFF2E88E6); // Smart Routes
  static const Color chipLeaf = Color(0xFF43A047); // Eco Score

  // ---- Neutrals - Light theme ----
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7FAF7);
  static const Color textDark = Color(0xFF1B3A1E);
  static const Color textMuted = Color(0xFF6B8F71);
  static const Color textFaint = Color(0xFFA9C4AD);
  static const Color dividerLight = Color(0xFFDDEEDE);

  // ---- Neutrals - Dark theme ----
  static const Color darkBackground = Color(0xFF0E1912);
  static const Color darkSurface = Color(0xFF16241A);
  static const Color darkBlob = Color(0xFF1C2E20);
  static const Color textLight = Color(0xFFEAF3EB);
  static const Color textMutedDark = Color(0xFF8FB396);

  // ---- Status colors ----
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);

  // ---- Form fields (login / sign-up) ----
  static const Color inputFillLight = Color(0xFFF3F5F4);
  static const Color inputFillDark = Color(0xFF1C2A20);
  static const Color inputHintLight = Color(0xFF9AA79C);
  static const Color inputHintDark = Color(0xFF7C9382);

  // ---- Shared shadow ----
  static Color cardShadow(Brightness brightness) => brightness == Brightness.dark
      ? Colors.black.withValues(alpha: 0.4)
      : primaryGreen.withValues(alpha: 0.08);
}
