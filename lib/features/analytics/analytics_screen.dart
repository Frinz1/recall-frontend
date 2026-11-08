import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../study/study_session_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyRepository.instance,
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final weakCards = repo.weakCards;
        final retention = repo.overallRetentionRate;
        final totalCards = repo.totalCardsCount;
        final mastered = repo.totalMasteredCardsCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Learning Analytics', style: AppTypography.titleLarge),
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
                          subtitle: '$mastered of $totalCards cards',
                          color: AppColors.primaryLight,
                          icon: Icons.military_tech_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dynamic 7-Day Consistency Heatmap Grid
                  _buildConsistencyCard(repo),

                  const SizedBox(height: 28),

                  // WEAKNESS DETECTION RADAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weakness Radar', style: AppTypography.titleMedium),
                          Text(
                            'Cards where recall failure rate is ≥ 40%',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
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
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Zero Weak Spots Detected', style: AppTypography.titleMedium),
                                SizedBox(height: 2),
                                Text(
                                  'Your recall across all active decks is above threshold.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...weakCards.map((card) {
                      final deck = repo.getDeckById(card.deckId);
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
                                      builder: (_) => StudySessionScreen(deck: deck),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }),

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

    String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
    final activeDates = <String>{};

    for (final log in repo.reviewLogs) {
      activeDates.add(dateKey(log.timestamp));
    }
    for (final c in repo.allCards) {
      if (c.lastReviewedDate != null) {
        activeDates.add(dateKey(c.lastReviewedDate!));
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
              const Text('Weekly Study Consistency', style: AppTypography.titleMedium),
              Row(
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final dayDate = startOfWeek.add(Duration(days: i));
              final isCompleted = activeDates.contains(dateKey(dayDate));
              final isToday = i == currentWeekdayIndex;

              return Column(
                children: [
                  Container(
                    width: 38,
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
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday ? AppColors.accentCyan : AppColors.textMuted,
                    ),
                  ),
                ],
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
          const Text('SM-2 Memory Interval Distribution', style: AppTypography.titleMedium),
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
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            Text('$count cards', style: AppTypography.badge.copyWith(color: color)),
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

  double allCardsCountSafeRatio(int count, int total) {
    if (total <= 0 || count <= 0) return 0.0;
    return (count / total).clamp(0.0, 1.0);
  }
}
