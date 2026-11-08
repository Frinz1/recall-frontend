import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/flashcard_model.dart';
import '../../../core/widgets/app_badge.dart';

class FlipCardWidget extends StatelessWidget {
  final Flashcard card;
  final bool isFlipped;
  final VoidCallback onFlip;

  const FlipCardWidget({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFlip,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.0, end: isFlipped ? 1.0 : 0.0),
        builder: (context, val, child) {
          // Angle in radians (0 to pi)
          final angle = val * pi;
          final isBack = angle > (pi / 2);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi), // mirror flip back
                    child: _buildBackContent(),
                  )
                : _buildFrontContent(),
          );
        },
      ),
    );
  }

  Widget _buildFrontContent() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 380),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBadge.forMasteryStatus(card.masteryStatus),
              if (card.isDue) AppBadge.dueToday(),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              card.question,
              style: AppTypography.titleLarge.copyWith(fontSize: 20, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Tap card to reveal answer',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackContent() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 380),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ANSWER',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryLight,
                  letterSpacing: 1.2,
                ),
              ),
              if (card.isWeakCard) AppBadge.weakCard(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.answer,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  if (card.explanation.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface1,
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: AppColors.primary, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Key Concept Explanation:',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.explanation,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (card.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: card.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$tag',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'How well did you remember this?',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
