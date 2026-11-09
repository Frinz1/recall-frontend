import 'package:flutter/material.dart';
import 'theme_service.dart';

/// Semantic Design Tokens for Recall.
/// Supports both Clean White & Two-Tone Light Mode (Default) and Midnight Slate Mode.
class AppColors {
  AppColors._();

  static bool get isDarkMode => ThemeService.instance.isDarkMode;

  // Surface Tiers
  static Color get bgCanvas =>
      isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF7F5F0); // Midnight Slate vs Soothing Alabaster Linen
  static Color get bgSurface1 =>
      isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF); // Cool Slate Card vs Crisp White Card
  static Color get bgSurface2 =>
      isDarkMode ? const Color(0xFF263349) : const Color(0xFFEDE9DF); // Interactive Pill / Soft Warm Ivory
  static Color get bgSurfaceElevated =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFFFFFFF); // High-Elevation Modal / Chip
  static Color get bgCard =>
      isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF); // Primary Container Surface

  // Border & Dividers
  static Color get borderSubtle =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFE7E3DA); // Warm hairline border
  static Color get borderHover =>
      isDarkMode ? const Color(0xFF475569) : const Color(0xFFD6D0C4);
  static Color get borderFocus =>
      isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7); // Sky Cyan Focus

  // Brand Primaries (Warm Gold + Sky Cyan Accents)
  static const Color primary = Color(0xFFFFB800);
  static const Color primaryLight = Color(0xFFFFCA38);
  static const Color primaryDark = Color(0xFFD99B00); // 3D Button Bottom Lip
  static const Color primaryGlow = Color(0x33FFB800);

  // Secondary & Accents
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentPurple = Color(0xFFA855F7);

  // Functional Status Colors
  static const Color success = Color(0xFF10B981); // Mastered / Easy
  static Color get successSurface =>
      isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Hard / Review soon
  static Color get warningSurface =>
      isDarkMode ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444); // Again / Forgot
  static Color get dangerSurface =>
      isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6); // Good / Normal
  static Color get infoSurface =>
      isDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);

  // Typography Contrast Tiers
  static Color get textPrimary =>
      isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF1A1D20); // Alabaster vs Deep Charcoal Espresso
  static Color get textSecondary =>
      isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF4A4E54); // Silver vs Warm Slate
  static Color get textMuted =>
      isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF71767E); // Cool Grey vs Muted Neutral
  static Color get textInverse =>
      isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF1A1D20); // High contrast text on primary gold

  // Spaced Repetition Rating Colors
  static const Color ratingAgain = Color(0xFFEF4444);
  static const Color ratingHard = Color(0xFFF59E0B);
  static const Color ratingGood = Color(0xFF38BDF8);
  static const Color ratingEasy = Color(0xFF10B981);

  // Hero, Review Card & Sculpted Dock Tokens
  static const Color heroSurfaceStart = Color(0xFF1E1B4B);
  static const Color heroSurfaceEnd = Color(0xFF312E81);
  static const Color heroTextMuted = Color(0xFFC7D2FE);
  static const Color cradleStart = Color(0xFF6366F1);
  static const Color cradleEnd = Color(0xFF10B981);
  static Color get cardFrontStart =>
      isDarkMode ? const Color(0xFF162038) : const Color(0xFFFFFFFF);
  static Color get cardFrontEnd =>
      isDarkMode ? const Color(0xFF11182B) : const Color(0xFFF7F5F0);
  static Color get cardBackStart =>
      isDarkMode ? const Color(0xFF132A2E) : const Color(0xFFF0FDF4);
  static Color get cardBackEnd =>
      isDarkMode ? const Color(0xFF0F1F2E) : const Color(0xFFDCFCE7);

  // Elevation Shadow Helpers
  static List<BoxShadow> get cardShadow => isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  // Google OAuth Emblem Tokens
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleRed = Color(0xFFEA4335);

  // 6 Vibrant Color-Blocked Bento Themes
  static const int themeSageEmerald = 0xFF2D6A4F;
  static const int themeRoyalIndigo = 0xFF4338CA;
  static const int themeSoftLavender = 0xFF7E22CE;
  static const int themeElectricOcean = 0xFF0369A1;
  static const int themeWarmAmber = 0xFFB45309;
  static const int themeRoseCoral = 0xFFBE123C;

  static const List<({int value, String label})> bentoThemeOptions = [
    (value: themeSageEmerald, label: 'Sage'),
    (value: themeRoyalIndigo, label: 'Indigo'),
    (value: themeSoftLavender, label: 'Lavender'),
    (value: themeElectricOcean, label: 'Ocean'),
    (value: themeWarmAmber, label: 'Amber'),
    (value: themeRoseCoral, label: 'Coral'),
  ];

  /// Generates a strategic Color-Blocked Bento surface gradient.
  /// Light Mode: Soft, pastel/milky whisper surface tints with crisp dark text.
  /// Dark Mode: Rich, deep jewel tones with alabaster text.
  static LinearGradient resolveBentoGradient(int colorValue) {
    final rgb = colorValue & 0xFFFFFF;
    if (isDarkMode) {
      if (rgb == (themeSageEmerald & 0xFFFFFF) || rgb == 0x10B981 || rgb == 0x059669) {
        return const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeRoyalIndigo & 0xFFFFFF) || rgb == 0x6366F1 || rgb == 0x4F46E5) {
        return const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeSoftLavender & 0xFFFFFF) || rgb == 0xA855F7 || rgb == 0x9333EA) {
        return const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeElectricOcean & 0xFFFFFF) ||
          rgb == 0x3B82F6 ||
          rgb == 0x38BDF8 ||
          rgb == 0x06B6D4) {
        return const LinearGradient(
          colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeWarmAmber & 0xFFFFFF) || rgb == 0xF59E0B || rgb == 0xD97706) {
        return const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeRoseCoral & 0xFFFFFF) ||
          rgb == 0xEF4444 ||
          rgb == 0xEC4899 ||
          rgb == 0xE11D48) {
        return const LinearGradient(
          colors: [Color(0xFF881337), Color(0xFFBE123C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }

      final base = Color(0xFF000000 | rgb);
      final hsl = HSLColor.fromColor(base);
      final darkStart = hsl.withLightness((hsl.lightness * 0.42).clamp(0.16, 0.32)).toColor();
      final richEnd = hsl.withLightness((hsl.lightness * 0.65).clamp(0.28, 0.48)).toColor();
      return LinearGradient(
        colors: [darkStart, richEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Light Mode: Whisper pastel surface tints (Pale Sage, Soft Lilac, Ice Blue, Warm Amber, Rose, Soft Indigo)
      if (rgb == (themeSageEmerald & 0xFFFFFF) || rgb == 0x10B981 || rgb == 0x059669) {
        return const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeRoyalIndigo & 0xFFFFFF) || rgb == 0x6366F1 || rgb == 0x4F46E5) {
        return const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeSoftLavender & 0xFFFFFF) || rgb == 0xA855F7 || rgb == 0x9333EA) {
        return const LinearGradient(
          colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeElectricOcean & 0xFFFFFF) ||
          rgb == 0x3B82F6 ||
          rgb == 0x38BDF8 ||
          rgb == 0x06B6D4) {
        return const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeWarmAmber & 0xFFFFFF) || rgb == 0xF59E0B || rgb == 0xD97706) {
        return const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      if (rgb == (themeRoseCoral & 0xFFFFFF) ||
          rgb == 0xEF4444 ||
          rgb == 0xEC4899 ||
          rgb == 0xE11D48) {
        return const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }

      final base = Color(0xFF000000 | rgb);
      final hsl = HSLColor.fromColor(base);
      final lightStart = hsl.withLightness(0.97).withSaturation((hsl.saturation * 0.45).clamp(0.20, 0.55)).toColor();
      final lightEnd = hsl.withLightness(0.91).withSaturation((hsl.saturation * 0.55).clamp(0.25, 0.65)).toColor();
      return LinearGradient(
        colors: [lightStart, lightEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  /// Resolves a high-contrast accent tint for borders, icons, and progress bars on a Bento surface.
  static Color resolveBentoAccent(int colorValue) {
    final rgb = colorValue & 0xFFFFFF;
    if (isDarkMode) {
      if (rgb == (themeSageEmerald & 0xFFFFFF) || rgb == 0x10B981) {
        return const Color(0xFF6EE7B7);
      }
      if (rgb == (themeRoyalIndigo & 0xFFFFFF) || rgb == 0x6366F1) {
        return const Color(0xFFA5B4FC);
      }
      if (rgb == (themeSoftLavender & 0xFFFFFF) || rgb == 0xA855F7) {
        return const Color(0xFFD8B4FE);
      }
      if (rgb == (themeElectricOcean & 0xFFFFFF) ||
          rgb == 0x3B82F6 ||
          rgb == 0x38BDF8 ||
          rgb == 0x06B6D4) {
        return const Color(0xFF7DD3FC);
      }
      if (rgb == (themeWarmAmber & 0xFFFFFF) || rgb == 0xF59E0B) {
        return const Color(0xFFFCD34D);
      }
      if (rgb == (themeRoseCoral & 0xFFFFFF) || rgb == 0xEF4444 || rgb == 0xEC4899) {
        return const Color(0xFFFDA4AF);
      }
      final base = Color(0xFF000000 | rgb);
      final hsl = HSLColor.fromColor(base);
      return hsl.withLightness(0.75).toColor();
    } else {
      // Light Mode: Rich, saturated anchor accent
      if (rgb == (themeSageEmerald & 0xFFFFFF) || rgb == 0x10B981) {
        return const Color(0xFF059669);
      }
      if (rgb == (themeRoyalIndigo & 0xFFFFFF) || rgb == 0x6366F1) {
        return const Color(0xFF4F46E5);
      }
      if (rgb == (themeSoftLavender & 0xFFFFFF) || rgb == 0xA855F7) {
        return const Color(0xFF7E22CE);
      }
      if (rgb == (themeElectricOcean & 0xFFFFFF) ||
          rgb == 0x3B82F6 ||
          rgb == 0x38BDF8 ||
          rgb == 0x06B6D4) {
        return const Color(0xFF0284C7);
      }
      if (rgb == (themeWarmAmber & 0xFFFFFF) || rgb == 0xF59E0B) {
        return const Color(0xFFD97706);
      }
      if (rgb == (themeRoseCoral & 0xFFFFFF) || rgb == 0xEF4444 || rgb == 0xEC4899) {
        return const Color(0xFFE11D48);
      }
      final base = Color(0xFF000000 | rgb);
      final hsl = HSLColor.fromColor(base);
      return hsl.withLightness(0.40).toColor();
    }
  }

  // Bento Card Typographic & Component Tokens
  static Color bentoTextPrimary([int? colorValue]) =>
      isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF1A1D20);
  static Color bentoTextSecondary([int? colorValue]) =>
      isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF4A4E54);
  static Color bentoTextMuted([int? colorValue]) =>
      isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF71767E);

  static Color bentoBorderColor(int colorValue) =>
      resolveBentoAccent(colorValue).withValues(alpha: isDarkMode ? 0.42 : 0.32);

  // Neutral Translucent / Dark Pods for Status Tags
  static Color get bentoPodBackground =>
      isDarkMode ? Colors.black.withValues(alpha: 0.32) : Colors.white.withValues(alpha: 0.72);
  static Color get bentoPodBorder =>
      isDarkMode ? Colors.white.withValues(alpha: 0.16) : const Color(0xFF1A1D20).withValues(alpha: 0.10);
  static Color get bentoPodText =>
      isDarkMode ? Colors.white : const Color(0xFF1A1D20);

  // Top-Right Launch Action Button Tokens
  static Color bentoLaunchButtonBg([int? colorValue]) =>
      isDarkMode ? Colors.white.withValues(alpha: 0.20) : Colors.white;
  static Color bentoLaunchButtonBorder([int? colorValue]) =>
      isDarkMode ? Colors.white.withValues(alpha: 0.28) : const Color(0xFFE7E3DA);
  static Color bentoLaunchButtonIcon([int? colorValue]) =>
      isDarkMode ? Colors.white : const Color(0xFF1A1D20);

  // Progress Bar Tokens
  static Color bentoProgressTrackBg([int? colorValue]) =>
      isDarkMode ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.08);
  static Color bentoProgressBarColor(int colorValue) =>
      isDarkMode ? Colors.white : resolveBentoAccent(colorValue);

  /// Smart domain-aware icon resolver for any subject name across all disciplines.
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
    if (s.contains('med') || s.contains('nurs') || s.contains('anat') || s.contains('health') || s.contains('pharm')) {
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
    return null;
  }

  /// Generates a clean 1-2 character monogram.
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
