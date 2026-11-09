import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'curved_bottom_sheet.dart';

/// Interactive Game Mechanics & Rules Bottom Sheets for Recall.
/// Guides users through Spaced Repetition levels, progress calculation, and Weakness Radar graduation.
class MechanicsSheet {
  MechanicsSheet._();

  static void showDeckMasteryRules(BuildContext context) {
    CurvedBottomSheet.show<void>(
      context: context,
      title: 'Deck Mastery Mechanics',
      subtitle: 'How your flashcard progress and mastery levels are calculated.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStageRow(
            level: 'Level 0',
            label: 'New Concept',
            progressWeight: '0% Progress',
            color: AppColors.textMuted,
            icon: Icons.fiber_new_rounded,
            desc: 'A freshly created flashcard waiting for its first study session.',
          ),
          const SizedBox(height: 12),
          _buildStageRow(
            level: 'Level 1',
            label: 'Learning Stage',
            progressWeight: '25% Progress',
            color: AppColors.accentCyan,
            icon: Icons.menu_book_rounded,
            desc: 'You pressed "Again" on this card. Your correct-answer streak resets to 0 and the card comes back tomorrow.',
          ),
          const SizedBox(height: 12),
          _buildStageRow(
            level: 'Level 2',
            label: 'Reviewing Stage',
            progressWeight: '60% Progress',
            color: AppColors.primary,
            icon: Icons.autorenew_rounded,
            desc: '1 to 3 correct answers in a row (Hard, Good, or Easy). Intervals grow: 1 day, then 6 days, then longer.',
          ),
          const SizedBox(height: 12),
          _buildStageRow(
            level: 'Level 3',
            label: 'Mastered Concept',
            progressWeight: '100% Progress',
            color: AppColors.success,
            icon: Icons.verified_rounded,
            desc: '4 correct answers in a row, with the 4th rated Good or Easy. Mastered cards leave the Weakness Radar and are rescheduled at most 180 days out.',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningSurface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Penalty Rule: Pressing "Again" resets the card back to Level 1 so you can drill and reinforce it tomorrow.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static void showWeaknessRadarRules(BuildContext context) {
    CurvedBottomSheet.show<void>(
      context: context,
      title: 'Weakness Radar Mechanics',
      subtitle: 'How persistent learning bottlenecks are detected and conquered.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRuleItem(
            stepNumber: '1',
            title: 'Sample Size Gate (≥ 2 Reviews)',
            desc:
                'Cards are never flagged as a weakness on your first review. You must encounter the concept at least twice to distinguish initial unfamiliarity from true difficulty.',
            icon: Icons.filter_2_rounded,
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 14),
          _buildRuleItem(
            stepNumber: '2',
            title: 'Failure Trigger (≥ 40% Fail Rate or EF < 1.9)',
            desc:
                'If you forget a card 40% or more of the time, or your Ease Factor drops below 1.9, the radar automatically flags it as a high-risk bottleneck.',
            icon: Icons.warning_amber_rounded,
            accentColor: AppColors.danger,
          ),
          const SizedBox(height: 14),
          _buildRuleItem(
            stepNumber: '3',
            title: 'Graduation (Mastery Auto-Clear)',
            desc:
                'Mastered concepts automatically graduate off the radar. For struggling concepts, practicing them in the Main Deck or drilling here lowers your failure rate and clears the bottleneck!',
            icon: Icons.check_circle_outline_rounded,
            accentColor: AppColors.success,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSurface2.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.accentCyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pedagogical Triage: The radar prioritizes the top 8 most critical concepts by default to protect you from study fatigue and cognitive overload.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static Widget _buildStageRow({
    required String level,
    required String label,
    required String progressWeight,
    required Color color,
    required IconData icon,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$level • $label',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        progressWeight,
                        style: AppTypography.badge.copyWith(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildRuleItem({
    required String stepNumber,
    required String title,
    required String desc,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$stepNumber. $title',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
