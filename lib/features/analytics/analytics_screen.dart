import 'package:flutter/material.dart';
import '../../core/algorithms/sm2_engine.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_service.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/mechanics_sheet.dart';
import '../study/study_session_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([StudyRepository.instance, ThemeService.instance]),
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final weakCards = repo.weakCards;
        final retention = repo.overallRetentionRate;
        final totalCards = repo.totalCardsCount;
        final mastered = repo.totalMasteredCardsCount;

        return Scaffold(
          appBar: AppBar(
            title: Text('Learning Analytics', style: AppTypography.titleLarge),
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.bgSurface1,
            onRefresh: () => repo.fetchAllFromCloud(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Retention Rate',
                          value: '${retention.toStringAsFixed(1)}%',
                          subtitle: 'SM-2 successful recall',
                          color: AppColors.success,
                          icon: Icons.psychology_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Mastery Level',
                          value: totalCards > 0
                              ? '${((mastered / totalCards) * 100).round()}%'
                              : '0%',
                          subtitle: '$mastered of $totalCards ${totalCards == 1 ? 'card' : 'cards'}',
                          color: AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFD97706),
                          icon: Icons.military_tech_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4-Stage Mastery Funnel Card
                  _buildLearningFunnelCard(repo),

                  const SizedBox(height: 24),

                  // Dynamic 7-Day Consistency Heatmap Grid
                  _buildConsistencyCard(repo),

                  const SizedBox(height: 28),

                  // WEAKNESS DETECTION RADAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weakness Radar', style: AppTypography.titleMedium),
                            Text(
                              'Cards with ≥2 reviews and failure rate ≥ 40% (or EF < 1.9)',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => MechanicsSheet.showWeaknessRadarRules(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface1,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.help_outline_rounded, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rules',
                                    style: AppTypography.badge.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.dangerSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${weakCards.length} at risk',
                              style: AppTypography.badge.copyWith(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Diagnostic Practice Clinic: Drill cards here for targeted review. Complete scheduled sessions in the Main Deck to graduate concepts to Mastery.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (weakCards.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Zero Weak Spots Detected', style: AppTypography.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  'No persistent weak spots found. Concepts are flagged after at least 2 reviews with a failure rate ≥ 40% or low ease factor.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _WeakCardsSection(weakCards: weakCards, repo: repo),

                  const SizedBox(height: 24),
                  // SM-2 Spaced Repetition Distribution
                  _buildIntervalDistributionCard(repo.allCards),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.metricLarge.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  /// Dynamically checks which days of the current week (Mon..Sun) have recorded study activity.
  Widget _buildConsistencyCard(StudyRepository repo) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final currentWeekdayIndex = now.weekday - 1; // 0 = Mon, 6 = Sun
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: currentWeekdayIndex));

    String dateKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final activeDates = <String>{...repo.cloudActiveReviewDates};

    for (final log in repo.reviewLogs) {
      activeDates.add(dateKey(log.timestamp.toLocal()));
    }
    for (final c in repo.allCards) {
      if (c.timesReviewed > 0 && c.lastReviewedDate != null) {
        activeDates.add(dateKey(c.lastReviewedDate!.toLocal()));
      }
    }
    // If streakDays > 0 from cloud, mark consecutive days ending today
    if (repo.studyStreakDays > 0 && activeDates.isEmpty) {
      for (int s = 0; s < repo.studyStreakDays.clamp(0, 7); s++) {
        activeDates.add(dateKey(now.subtract(Duration(days: s))));
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Weekly Study Consistency',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${repo.studyStreakDays} day streak',
                    style: AppTypography.badge.copyWith(color: Colors.orange),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (i) {
              final dayDate = startOfWeek.add(Duration(days: i));
              final isCompleted = activeDates.contains(dateKey(dayDate));
              final isToday = i == currentWeekdayIndex;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: isCompleted ? AppColors.primary : AppColors.bgSurface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.primaryLight
                                : (isToday ? AppColors.accentCyan : AppColors.borderSubtle),
                            width: isToday ? 1.8 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : (isToday ? Icons.circle_outlined : Icons.remove_rounded),
                            size: isCompleted ? 20 : 14,
                            color: isCompleted
                                ? AppColors.textInverse
                                : (isToday ? AppColors.accentCyan : AppColors.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isToday ? AppColors.accentCyan : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalDistributionCard(List<Flashcard> allCards) {
    final total = allCards.isEmpty ? 1 : allCards.length;
    final shortTerm = allCards.where((c) => c.intervalDays <= 1).length;
    final mediumTerm = allCards.where((c) => c.intervalDays > 1 && c.intervalDays <= 6).length;
    final longTerm = allCards.where((c) => c.intervalDays > 6).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SM-2 Memory Interval Distribution', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tracks cards moving from short-term to long-term retention',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          _buildBarRow('Short-Term (≤ 1d)', shortTerm, total, AppColors.warning),
          const SizedBox(height: 12),
          _buildBarRow('Intermediate (2–6d)', mediumTerm, total, AppColors.accentCyan),
          const SizedBox(height: 12),
          _buildBarRow('Mature Memory (7d+)', longTerm, total, AppColors.success),
        ],
      ),
    );
  }

  Widget _buildBarRow(String label, int count, int total, Color color) {
    final ratio = allCardsCountSafeRatio(count, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text('$count ${count == 1 ? 'card' : 'cards'}', style: AppTypography.badge.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.bgSurface2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningFunnelCard(StudyRepository repo) {
    final allCards = repo.allCards;
    final total = allCards.isEmpty ? 1 : allCards.length;
    final newCount = allCards.where((c) => c.timesReviewed == 0).length;
    final learningCount = allCards.where((c) => c.timesReviewed > 0 && c.masteryStatus == CardMasteryStatus.learning).length;
    final reviewingCount = allCards.where((c) => c.masteryStatus == CardMasteryStatus.reviewing).length;
    final masteredCount = allCards.where((c) => c.masteryStatus == CardMasteryStatus.mastered).length;

    final progressPct = allCards.isEmpty
        ? 0
        : (((learningCount * 0.25) + (reviewingCount * 0.60) + (masteredCount * 1.0)) / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '4-Stage Mastery Funnel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$progressPct% Progress',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Visual progression from initial learning to permanent retention',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (newCount > 0)
                    Expanded(
                      flex: newCount,
                      child: Container(color: AppColors.textMuted.withValues(alpha: 0.35)),
                    ),
                  if (learningCount > 0)
                    Expanded(
                      flex: learningCount,
                      child: Container(color: AppColors.accentCyan),
                    ),
                  if (reviewingCount > 0)
                    Expanded(
                      flex: reviewingCount,
                      child: Container(color: AppColors.primary),
                    ),
                  if (masteredCount > 0)
                    Expanded(
                      flex: masteredCount,
                      child: Container(color: AppColors.success),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildFunnelStagePill('New', '$newCount', AppColors.textMuted)),
              Expanded(child: _buildFunnelStagePill('Learning', '$learningCount', AppColors.accentCyan)),
              Expanded(child: _buildFunnelStagePill('Reviewing', '$reviewingCount', AppColors.primary)),
              Expanded(child: _buildFunnelStagePill('Mastered', '$masteredCount', AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStagePill(String stage, String count, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              count,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          stage,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  double allCardsCountSafeRatio(int count, int total) {
    if (total <= 0 || count <= 0) return 0.0;
    return (count / total).clamp(0.0, 1.0);
  }
}

class _WeakCardsSection extends StatefulWidget {
  final List<Flashcard> weakCards;
  final StudyRepository repo;

  const _WeakCardsSection({
    required this.weakCards,
    required this.repo,
  });

  @override
  State<_WeakCardsSection> createState() => _WeakCardsSectionState();
}

class _WeakCardsSectionState extends State<_WeakCardsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Flashcard>.from(widget.weakCards)
      ..sort((a, b) {
        final failCompare = b.failureRate.compareTo(a.failureRate);
        if (failCompare != 0) return failCompare;
        return a.easeFactor.compareTo(b.easeFactor);
      });

    final displayList = (_showAll || sorted.length <= 8)
        ? sorted
        : sorted.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sorted.length > 8) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _showAll
                        ? 'Showing all ${sorted.length} struggling concepts'
                        : 'Prioritizing top 8 of ${sorted.length} critical concepts',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.isDarkMode ? AppColors.primaryLight : const Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _showAll ? 'Show Top 8' : 'Show All (${sorted.length})',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ...displayList.map((card) {
          final deck = widget.repo.getDeckById(card.deckId);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppBadge.weakCard(),
                    Text(
                      '${(card.failureRate * 100).round()}% fail rate',
                      style: AppTypography.badge.copyWith(color: AppColors.danger),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  card.question,
                  style: AppTypography.titleMedium.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Deck: ${deck?.title ?? "General"} • Ease factor: ${card.easeFactor.toStringAsFixed(2)}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                if (deck != null)
                  AppButton(
                    label: 'Drill This Card Now',
                    icon: Icons.bolt_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StudySessionScreen(
                            deck: deck,
                            targetCardId: card.id,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
