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
  final String? imageAsset;

  /// Set to false when the empty state is placed inside a parent that already scrolls
  /// (e.g. Dashboard, Deck Overview). A nested scroll view would swallow the swipe gesture.
  final bool scrollable;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCtaPressed,
    this.imageAsset = 'assets/images/empty_decks_3d.jpg',
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageAsset != null)
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    imageAsset!,
                    width: 116,
                    height: 116,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                  ),
                ),
              )
            else
              _buildFallbackIcon(),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 20),
              AppButton(
                label: ctaLabel!,
                icon: Icons.add_rounded,
                onPressed: onCtaPressed,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
    );

    if (!scrollable) return Center(child: content);

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.bgSurface2,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
      ),
      child: Icon(icon, size: 36, color: AppColors.textSecondary),
    );
  }
}
