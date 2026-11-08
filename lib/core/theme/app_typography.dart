import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Modular typography scale with optical line-heights and tabular numbers for metrics.
class AppTypography {
  AppTypography._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.45,
    color: AppColors.textMuted,
  );

  static const TextStyle metricLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  static const TextStyle metricMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );
}
