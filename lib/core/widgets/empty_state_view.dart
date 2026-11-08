import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.bgSurface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle, width: 1.5),
              ),
              child: Icon(icon, size: 36, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: ctaLabel!,
                onPressed: onCtaPressed,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
