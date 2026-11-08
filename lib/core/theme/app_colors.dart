import 'package:flutter/material.dart';

/// Semantic Design Tokens for the Recall Design System.
/// Strictly typed surface tiers, border tokens, and domain status colors.
class AppColors {
  AppColors._();

  // Surface Tiers
  static const Color bgCanvas = Color(0xFF090D16);
  static const Color bgSurface1 = Color(0xFF111827);
  static const Color bgSurface2 = Color(0xFF1F2937);
  static const Color bgSurfaceElevated = Color(0xFF283548);
  static const Color bgCard = Color(0xFF131D2E);

  // Border & Dividers
  static const Color borderSubtle = Color(0xFF263345);
  static const Color borderHover = Color(0xFF3B4D66);
  static const Color borderFocus = Color(0xFF6366F1);

  // Brand Primaries (Indigo / Electric Violet)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryGlow = Color(0x336366F1);

  // Secondary & Accents
  static const Color accentCyan = Color(0xFF06B6D4);
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
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInverse = Color(0xFF0F172A);

  // Spaced Repetition Rating Colors
  static const Color ratingAgain = Color(0xFFEF4444);
  static const Color ratingHard = Color(0xFFF59E0B);
  static const Color ratingGood = Color(0xFF3B82F6);
  static const Color ratingEasy = Color(0xFF10B981);
}
