import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/flashcard_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';

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
              left: 22,
              right: 22,
              bottom: -16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface1.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.borderSubtle.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          // 3D Stacked Deck Illusion (1st card behind)
          if (remainingBehind >= 1)
            Positioned(
              top: 9,
              left: 11,
              right: 11,
              bottom: -8,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface1.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.borderSubtle.withValues(alpha: 0.75),
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
                  ..setEntry(3, 2, 0.0012)
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header Bar
            Row(
              children: [
                if (card.isNewCard)
                  AppBadge.newCard()
                else
                  AppBadge.forMasteryStatus(card.masteryStatus),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    card.cardType.label,
                    style: AppTypography.badge.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                if (card.isScheduledDue) AppBadge.dueToday(),
              ],
            ),

            const SizedBox(height: 18),

            // Framed Question Prompt Box (Eliminates awkward floating whitespace)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 165),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.bgCanvas.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: isCode ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCode ? Icons.terminal_rounded : Icons.help_outline_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'QUESTION PROMPT',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    card.question,
                    textAlign: isCode ? TextAlign.left : TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 20,
                      height: 1.4,
                      fontFamily: isCode ? 'monospace' : null,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tags + Card Memory Metadata Strip
            if (card.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: card.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface2,
                      borderRadius: BorderRadius.circular(8),
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

            // Interactive Bottom Flip Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSurface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        card.isNewCard
                            ? 'First study pass'
                            : 'Reviewed ${card.timesReviewed}× • Ease ${card.easeFactor.toStringAsFixed(2)}',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.flip_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        'Tap to flip',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.65),
            width: 1.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Answer Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'ANSWER',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (card.isWeakCard)
                  AppBadge.weakCard()
                else
                  Text(
                    'Tap to flip back ↻',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Compact Question Echo (So you still see the question while reading the answer!)
            Text(
              'Q: ${card.question}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 12),

            // Framed Answer Box
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.bgCanvas.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                card.answer,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  height: 1.45,
                  fontFamily: isCode ? 'monospace' : null,
                ),
              ),
            ),

            if (card.explanation.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppColors.accentCyan, width: 3.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: AppColors.accentCyan,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'KEY TAKEAWAY',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.accentCyan,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.explanation,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            Center(
              child: Text(
                'Rate how well you remembered this below ↓',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
