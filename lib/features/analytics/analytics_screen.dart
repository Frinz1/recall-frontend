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
          body: SingleChildScrollView(
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
                        value: totalCards > 0 ? '${((mastered / totalCards) * 100).round()}%' : '0%',
                        subtitle: '$mastered of $totalCards cards',
                        color: AppColors.primaryLight,
                        icon: Icons.military_tech_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 7-Day Consistency Heatmap Grid
                _buildConsistencyCard(repo.studyStreakDays),

                const SizedBox(height: 28),

                // WEAKNESS DETECTION RADAR (The Star Academic Feature)
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
                      borderRadius: BorderRadius.circular(16),
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
                              const Text('Zero Weak Spots Detected', style: AppTypography.titleMedium),
                              const SizedBox(height: 2),
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
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
                          Text(card.question, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                          const SizedBox(height: 6),
                          Text(
                            'Deck: ${deck?.title ?? "General"} • Ease factor: ${card.easeFactor}',
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
                                  MaterialPageRoute(
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
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildConsistencyCard(int streakDays) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
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
                  Text('$streakDays day streak', style: AppTypography.badge.copyWith(color: Colors.orange)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isCompleted = i < streakDays.clamp(0, 7);
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.primary : AppColors.bgSurface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted ? AppColors.primaryLight : AppColors.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted ? Icons.check_rounded : Icons.remove_rounded,
                        size: 18,
                        color: isCompleted ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(days[i], style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalDistributionCard(List<Flashcard> allCards) {
    final int learning = allCards.where((c) => c.intervalDays <= 1).length;
    final int review1to6 = allCards.where((c) => c.intervalDays > 1 && c.intervalDays <= 6).length;
    final int mature = allCards.where((c) => c.intervalDays > 6).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Memory Retention Curve Distribution', style: AppTypography.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Based on SM-2 mathematical intervals',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          _intervalRow('Short-Term (≤ 1 day)', learning, allCards.length, AppColors.ratingAgain),
          const SizedBox(height: 10),
          _intervalRow('Intermediate (2–6 days)', review1to6, allCards.length, AppColors.ratingHard),
          const SizedBox(height: 10),
          _intervalRow('Long-Term Memory (> 6 days)', mature, allCards.length, AppColors.ratingEasy),
        ],
      ),
    );
  }

  Widget _intervalRow(String label, int count, int total, Color color) {
    final fraction = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
            Text('$count cards (${(fraction * 100).round()}%)',
                style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.bgSurface2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
