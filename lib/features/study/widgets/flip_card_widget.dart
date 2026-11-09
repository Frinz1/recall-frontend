import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/algorithms/sm2_engine.dart';
import '../../../core/models/flashcard_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class FlipCardWidget extends StatelessWidget {
  final Flashcard card;
  final bool isFlipped;
  final VoidCallback onFlip;
  final int currentIndex;
  final int totalCards;

  const FlipCardWidget({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.onFlip,
    this.currentIndex = 1,
    this.totalCards = 1,
  });

  String _resolveTypeBadgeLabel(FlashcardType type) {
    switch (type) {
      case FlashcardType.definition:
        return 'DEFINITION';
      case FlashcardType.codeSnippet:
        return 'CODE';
      case FlashcardType.standard:
        return 'CONCEPT';
    }
  }

  IconData _resolveTypeIcon(FlashcardType type) {
    switch (type) {
      case FlashcardType.definition:
        return Icons.menu_book_rounded;
      case FlashcardType.codeSnippet:
        return Icons.code_rounded;
      case FlashcardType.standard:
        return Icons.school_rounded;
    }
  }

  Color _resolveStatusDotColor(Flashcard c) {
    if (c.isNewCard) return AppColors.accentCyan;
    switch (c.masteryStatus) {
      case CardMasteryStatus.mastered:
        return AppColors.success;
      case CardMasteryStatus.reviewing:
        return AppColors.primaryLight;
      case CardMasteryStatus.learning:
        return AppColors.warning;
    }
  }

  String _resolveStatusLabel(Flashcard c) {
    if (c.isNewCard) return 'NEW';
    switch (c.masteryStatus) {
      case CardMasteryStatus.mastered:
        return 'MASTERED';
      case CardMasteryStatus.reviewing:
        return 'REVIEWING';
      case CardMasteryStatus.learning:
        return 'LEARNING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingBehind = (totalCards - currentIndex).clamp(0, 2);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onFlip();
      },
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // 3D Stacked Deck Illusion (2nd card behind)
          if (remainingBehind >= 2)
            Positioned(
              top: 18,
              left: 24,
              right: 24,
              bottom: -16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface1.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.borderSubtle.withValues(alpha: 0.42),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          // 3D Stacked Deck Illusion (1st card behind)
          if (remainingBehind >= 1)
            Positioned(
              top: 9,
              left: 12,
              right: 12,
              bottom: -8,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface1.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.borderSubtle.withValues(alpha: 0.72),
                    width: 1.2,
                  ),
                ),
              ),
            ),

          // Active 3D Matrix4 Flipping Card
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            tween: Tween<double>(begin: 0.0, end: isFlipped ? 1.0 : 0.0),
            builder: (context, val, child) {
              final clampedVal = val.clamp(0.0, 1.0);
              final angle = clampedVal * pi;
              final isBack = angle > (pi / 2);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: isBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildBackContent(),
                      )
                    : _buildFrontContent(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrontContent() {
    final isCode = card.cardType == FlashcardType.codeSnippet;
    final dotColor = _resolveStatusDotColor(card);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 340),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardFrontStart, AppColors.cardFrontEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Glowing Top Accent Bar
            Container(
              width: double.infinity,
              height: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.accentCyan],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Header Row: Clean Educational Badge + Circular 36x36 Flip Hint Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.isDarkMode
                                ? AppColors.bgSurface2.withValues(alpha: 0.85)
                                : AppColors.bgSurface1.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.isDarkMode
                                  ? AppColors.borderSubtle
                                  : AppColors.borderSubtle.withValues(alpha: 0.8),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: AppColors.isDarkMode ? 0.20 : 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _resolveTypeIcon(card.cardType),
                                size: 14,
                                color: dotColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${_resolveTypeBadgeLabel(card.cardType)} • ${_resolveStatusLabel(card)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.38),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.autorenew_rounded,
                            size: 18,
                            color: AppColors.isDarkMode ? AppColors.primaryLight : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Center Hero Area: Open space for crisp question prompt
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 12,
                    ),
                    child: isCode
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bgCanvas.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              card.question,
                              textAlign: TextAlign.left,
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 18,
                                height: 1.45,
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary,
                              ),
                            ),
                          )
                        : Text(
                            card.question,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.38,
                              color: AppColors.isDarkMode ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                  ),

                  // Bottom Footer Row: Topic #tags + Centered Translucent Pill
                  if (card.tags.isNotEmpty) ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: card.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.accentCyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: AppTypography.badge.copyWith(
                              color: AppColors.accentCyan,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flip_rounded,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Tap anywhere to reveal answer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.badge.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackContent() {
    final isCode = card.cardType == FlashcardType.codeSnippet;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 340),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardBackStart, AppColors.cardBackEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.55),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Glowing Emerald Top Accent Bar
            Container(
              width: double.infinity,
              height: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.accentCyan],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Header Row: VERIFIED ANSWER pill + Ease/Review Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.45),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'VERIFIED ANSWER',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.isDarkMode
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.isDarkMode
                                ? Colors.white.withValues(alpha: 0.12)
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          'EF ${card.easeFactor.toStringAsFixed(2)} • ${card.timesReviewed}× reviewed',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Center Hero Area: Crisp, high-contrast answer typography
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 8,
                    ),
                    child: Text(
                      card.answer,
                      textAlign: isCode ? TextAlign.left : TextAlign.center,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.isDarkMode ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        height: 1.45,
                        fontFamily: isCode ? 'monospace' : null,
                      ),
                    ),
                  ),

                  // Key Insight Callout (when card.explanation.isNotEmpty)
                  if (card.explanation.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.isDarkMode
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.accentCyan.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.lightbulb_rounded,
                              size: 16,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              card.explanation,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
