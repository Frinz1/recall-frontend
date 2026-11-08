import 'package:flutter/material.dart';

/// Semantic Design Tokens for Recall — Solid Warm Honey & Obsidian System.
/// Extracted from Google Stitch specifications.
class AppColors {
  AppColors._();

  // Surface Tiers
  static const Color bgCanvas = Color(0xFF121316); // Deep Obsidian
  static const Color bgSurface1 = Color(0xFF1A1C21); // Slate Card Surface
  static const Color bgSurface2 = Color(0xFF22252C);
  static const Color bgSurfaceElevated = Color(0xFF282B33);
  static const Color bgCard = Color(0xFF1A1C21);

  // Border & Dividers
  static const Color borderSubtle = Color(0xFF282B33);
  static const Color borderHover = Color(0xFF3B404D);
  static const Color borderFocus = Color(0xFFFFB800); // Honey Accent

  // Brand Primaries (Warm Honey Gold)
  static const Color primary = Color(0xFFFFB800); // Honey Gold
  static const Color primaryLight = Color(0xFFFFCA38);
  static const Color primaryDark = Color(0xFFE5A600);
  static const Color primaryGlow = Color(0x33FFB800);

  // Secondary & Accents
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentPurple = Color(0xFFA855F7);

  // Functional Status Colors
  static const Color success = Color(0xFF10B981); // Mastered / Easy
  static const Color successSurface = Color(0xFF064E3B);
  static const Color warning = Color(0xFFF59E0B); // Hard / Review soon
  static const Color warningSurface = Color(0xFF78350F);
  static const Color danger = Color(0xFFEF4444); // Again / Forgot
  static const Color dangerSurface = Color(0xFF7F1D1D);
  static const Color info = Color(0xFF3B82F6); // Good / Normal
  static const Color infoSurface = Color(0xFF1E3A8A);

  // Typography Contrast Tiers
  static const Color textPrimary = Color(0xFFFAF9F5); // Warm White
  static const Color textSecondary = Color(0xFF9E9EA7); // Warm Sand / Grey
  static const Color textMuted = Color(0xFF737380);
  static const Color textInverse = Color(0xFF121316); // Charcoal on Honey

  // Spaced Repetition Rating Colors
  static const Color ratingAgain = Color(0xFFEF4444);
  static const Color ratingHard = Color(0xFFF59E0B);
  static const Color ratingGood = Color(0xFF3B82F6);
  static const Color ratingEasy = Color(0xFF10B981);
}
