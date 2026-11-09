import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isEnabled => !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color bottomLip;
    Color borderColor;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = AppColors.textInverse;
        bottomLip = AppColors.primaryDark;
        borderColor = AppColors.primaryLight.withValues(alpha: 0.35);
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.bgSurface2;
        fg = AppColors.textPrimary;
        bottomLip = AppColors.isDarkMode
            ? const Color(0xFF151E2E)
            : const Color(0xFFD6D0C4);
        borderColor = AppColors.borderSubtle;
        break;
      case AppButtonVariant.outline:
        bg = AppColors.bgSurface1;
        fg = AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFD97706);
        bottomLip = AppColors.isDarkMode
            ? AppColors.primary.withValues(alpha: 0.55)
            : const Color(0xFFD97706).withValues(alpha: 0.35);
        borderColor = AppColors.isDarkMode ? AppColors.primary : const Color(0xFFD97706);
        break;
      case AppButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        bottomLip = const Color(0xFFB91C1C);
        borderColor = const Color(0xFFF87171);
        break;
    }

    if (!_isEnabled) {
      bg = AppColors.bgSurface2.withValues(alpha: 0.5);
      fg = AppColors.textMuted;
      bottomLip = AppColors.borderSubtle.withValues(alpha: 0.4);
      borderColor = AppColors.borderSubtle.withValues(alpha: 0.4);
    }

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (widget.icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    } else {
      content = Text(
        widget.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.titleMedium.copyWith(
          color: fg,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final pressOffset = (_isPressed && _isEnabled) ? 3.0 : 0.0;
    final lipDepth = (_isPressed && _isEnabled) ? 1.0 : 4.0;

    final buttonWidget = GestureDetector(
      onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: _isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(top: pressOffset),
        padding: EdgeInsets.only(bottom: lipDepth),
        decoration: BoxDecoration(
          color: bottomLip,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          constraints: const BoxConstraints(minHeight: 46),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (widget.isExpanded) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }
    return buttonWidget;
  }
}
