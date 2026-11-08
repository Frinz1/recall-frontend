import 'package:flutter/material.dart';

/// Semantic Design Tokens for Recall — Palette A: Midnight Slate & Warm Gold.
class AppColors {
  AppColors._();

  // Surface Tiers (Midnight Navy Slate — Zero Flat Black)
  static const Color bgCanvas = Color(0xFF0F172A); // Deep Midnight Slate
  static const Color bgSurface1 = Color(0xFF1E293B); // Elevated Cool Slate Card
  static const Color bgSurface2 = Color(0xFF263349); // Interactive Pill / Input Box
  static const Color bgSurfaceElevated = Color(0xFF334155); // High-Elevation Modal / Chip
  static const Color bgCard = Color(0xFF1E293B); // Primary Container Surface

  // Border & Dividers (Crisp Slate Borders + 3D Lip)
  static const Color borderSubtle = Color(0xFF334155);
  static const Color borderHover = Color(0xFF475569);
  static const Color borderFocus = Color(0xFF38BDF8); // Sky Cyan Focus

  // Brand Primaries (Warm Gold + Sky Cyan Accents)
  static const Color primary = Color(0xFFFFB800); // Warm Gold CTA
  static const Color primaryLight = Color(0xFFFFCA38);
  static const Color primaryDark = Color(0xFFD99B00); // 3D Button Bottom Lip
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
  static const Color textPrimary = Color(0xFFF8FAFC); // Crisp Alabaster White
  static const Color textSecondary = Color(0xFFCBD5E1); // Soft Slate Silver
  static const Color textMuted = Color(0xFF94A3B8); // Muted Cool Grey
  static const Color textInverse = Color(0xFF0F172A); // Deep Slate on Gold

  // Spaced Repetition Rating Colors
  static const Color ratingAgain = Color(0xFFEF4444);
  static const Color ratingHard = Color(0xFFF59E0B);
  static const Color ratingGood = Color(0xFF38BDF8);
  static const Color ratingEasy = Color(0xFF10B981);

  /// Smart domain-aware icon resolver for any subject name across all disciplines.
  /// Returns null when a 2-letter monogram avatar is cleaner than a generic icon.
  static IconData? resolveSubjectIcon(String subjectName) {
    final s = subjectName.trim().toLowerCase();
    if (s.contains('net') || s.contains('cloud') || s.contains('web') || s.contains('routing')) {
      return Icons.hub_rounded;
    }
    if (s.contains('data') || s.contains('sql') || s.contains('storage')) {
      return Icons.dns_rounded;
    }
    if (s.contains('algo') || s.contains('code') || s.contains('prog') || s.contains('dev')) {
      return Icons.terminal_rounded;
    }
    if (s.contains('os') || s.contains('operat') || s.contains('sys') || s.contains('arch')) {
      return Icons.memory_rounded;
    }
    if (s.contains('sec') || s.contains('cyber') || s.contains('crypt')) {
      return Icons.shield_outlined;
    }
    if (s.contains('math') || s.contains('calc') || s.contains('stat') || s.contains('algeb')) {
      return Icons.functions_rounded;
    }
    if (s.contains('med') || s.contains('nurs') || s.contains('anat') || s.contains('health')) {
      return Icons.medical_services_outlined;
    }
    if (s.contains('bio') || s.contains('chem') || s.contains('sci') || s.contains('phys')) {
      return Icons.biotech_rounded;
    }
    if (s.contains('law') || s.contains('legal') || s.contains('crim') || s.contains('pol')) {
      return Icons.balance_rounded;
    }
    if (s.contains('bus') || s.contains('econ') || s.contains('fin') || s.contains('acct')) {
      return Icons.insights_rounded;
    }
    if (s.contains('hist') || s.contains('geo') || s.contains('soc') || s.contains('phil')) {
      return Icons.public_rounded;
    }
    if (s.contains('eng') || s.contains('lang') || s.contains('lit') || s.contains('vocab')) {
      return Icons.translate_rounded;
    }
    if (s.contains('art') || s.contains('des') || s.contains('arch')) {
      return Icons.palette_outlined;
    }
    if (s.contains('psych') || s.contains('mind') || s.contains('cogn')) {
      return Icons.psychology_outlined;
    }
    // For any other custom subject, return null so we render a clean 2-letter monogram!
    return null;
  }

  /// Generates a clean 1-2 character monogram (e.g. "Operating Systems" -> "OS", "Nursing" -> "NU").
  static String getSubjectMonogram(String subjectName) {
    final trimmed = subjectName.trim();
    if (trimmed.isEmpty) return 'S';
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return trimmed.length >= 2
        ? trimmed.substring(0, 2).toUpperCase()
        : trimmed[0].toUpperCase();
  }
}
