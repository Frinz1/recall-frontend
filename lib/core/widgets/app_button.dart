import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isExpanded;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isExpanded = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.bgSurface2;
        fg = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.borderSubtle);
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primaryLight;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case AppButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: AppColors.bgSurface2.withOpacity(0.5),
      disabledForegroundColor: AppColors.textMuted,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      minimumSize: const Size(48, 48), // 48dp minimum accessible touch target
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderSide,
      ),
    );

    Widget content;
    if (isLoading) {
      content = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.titleMedium.copyWith(color: fg, fontSize: 14)),
        ],
      );
    } else {
      content = Text(label, style: AppTypography.titleMedium.copyWith(color: fg, fontSize: 14));
    }

    final btn = ElevatedButton(
      style: buttonStyle,
      onPressed: isLoading ? null : onPressed,
      child: content,
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}
