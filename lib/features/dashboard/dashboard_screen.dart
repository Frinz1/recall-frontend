import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/toast_feedback.dart';
import '../deck/deck_detail_screen.dart';
import '../study/study_session_screen.dart';
import '../subject/subject_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToDecks;

  const DashboardScreen({super.key, required this.onNavigateToDecks});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyRepository.instance,
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final totalDue = repo.totalDueCardsCount;
        final weakCards = repo.weakCards;
        final decks = repo.decks;

        // Recommend deck with most due cards
        Deck? priorityDeck;
        if (decks.isNotEmpty) {
          final sorted = List<Deck>.from(decks)
            ..sort((a, b) => b.dueCardsCount.compareTo(a.dueCardsCount));
          priorityDeck = sorted.first;
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Recall', style: AppTypography.displayMedium),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${repo.studyStreakDays}d streak',
                      style: AppTypography.badge.copyWith(color: Colors.orange),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: repo.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryLight,
                        ),
                      )
                    : const Icon(Icons.cloud_sync_rounded, size: 20),
                tooltip: 'Sync with Cloud',
                onPressed: repo.isSyncing
                    ? null
                    : () async {
                        await repo.fetchAllFromCloud();
                        if (context.mounted) {
                          ToastFeedback.showInfo(context, 'Synced with Recall Cloud.');
                        }
                      },
              ),
              IconButton(
                icon: const Icon(Icons.category_outlined, size: 20),
                tooltip: 'Manage Subjects',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubjectListScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20),
                tooltip: 'Sign Out',
                onPressed: () {
                  AuthService.instance.logout();
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Readiness Hero Banner
                _buildHeroBanner(context, totalDue, priorityDeck),

                const SizedBox(height: 24),

                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        label: 'Due Cards',
                        value: '$totalDue',
                        color: totalDue > 0 ? AppColors.danger : AppColors.success,
                        icon: Icons.access_time_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        label: 'Mastered',
                        value: '${repo.totalMasteredCardsCount}',
                        color: AppColors.success,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        label: 'Retention',
                        value: '${repo.overallRetentionRate.round()}%',
                        color: AppColors.primaryLight,
                        icon: Icons.psychology_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Weakness Quick Alert (if any weak cards)
                if (weakCards.isNotEmpty) ...[
                  _buildWeaknessAlertBanner(context, weakCards.length),
                  const SizedBox(height: 28),
                ],

                // Active Decks Carousel / List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active Decks', style: AppTypography.titleLarge),
                    TextButton(
                      onPressed: onNavigateToDecks,
                      child: const Text('View All', style: TextStyle(color: AppColors.primaryLight)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...decks.take(3).map((deck) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Material(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(deck.colorValue).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(deck.colorValue).withOpacity(0.5)),
                          ),
                          child: Icon(Icons.style_rounded, color: Color(deck.colorValue)),
                        ),
                        title: Text(deck.title, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${deck.totalCards} cards • ${deck.dueCardsCount} due',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DeckDetailScreen(deckId: deck.id),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, int totalDue, Deck? priorityDeck) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('DAILY SM-2 SCHEDULE', style: AppTypography.badge.copyWith(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalDue > 0
                ? '$totalDue Flashcards Due for Review'
                : 'All Caught Up For Today!',
            style: AppTypography.displayMedium.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            totalDue > 0
                ? 'Reviewing cards right when they hit the forgetting threshold yields 92% higher retention.'
                : 'Outstanding work maintaining your streak. Feel free to explore new decks or test your knowledge with a quiz.',
            style: AppTypography.bodyMedium.copyWith(color: const Color(0xFFC7D2FE)),
          ),
          if (totalDue > 0 && priorityDeck != null) ...[
            const SizedBox(height: 18),
            AppButton(
              label: 'Start Smart Review (${priorityDeck.title})',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudySessionScreen(
                      deck: priorityDeck,
                      onlyDueCards: true,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.metricMedium.copyWith(color: color, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildWeaknessAlertBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3F1119),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weakness Radar Alert',
                    style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '$count concepts have high failure rates. Check Learning Analytics to drill them.',
                  style: AppTypography.bodySmall.copyWith(color: const Color(0xFFFECDD3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
