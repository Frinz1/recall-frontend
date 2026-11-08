import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ToastFeedback {
  ToastFeedback._();

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.successSurface,
      borderColor: AppColors.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: AppColors.dangerSurface,
      borderColor: AppColors.danger,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.infoSurface,
      borderColor: AppColors.info,
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
