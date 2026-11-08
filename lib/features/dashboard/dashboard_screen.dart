import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
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
  final VoidCallback? onNavigateToSettings;

  const DashboardScreen({
    super.key,
    required this.onNavigateToDecks,
    this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyRepository.instance,
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final totalDue = repo.totalDueCardsCount;
        final scheduledDue = repo.totalScheduledDueCount;
        final newCount = repo.totalNewCardsCount;
        final weakCards = repo.weakCards;
        final decks = repo.decks;
        final subjects = repo.subjects;
        final reviewedToday = repo.reviewedTodayCount;
        final dailyGoal = repo.dailyGoalCards;

        // Recommend deck: prioritize Starred decks with due cards, then highest due count
        Deck? priorityDeck;
        if (decks.isNotEmpty) {
          final sorted = List<Deck>.from(decks)
            ..sort((a, b) {
              if (a.isFavorite != b.isFavorite) {
                return a.isFavorite ? -1 : 1;
              }
              return b.dueCardsCount.compareTo(a.dueCardsCount);
            });
          priorityDeck = sorted.firstWhere(
            (d) => d.dueCardsCount > 0,
            orElse: () => sorted.first,
          );
        }

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
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
                    child: Icon(Icons.bolt_rounded, color: AppColors.bgCanvas, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Recall', style: AppTypography.displayMedium),
              ],
            ),
            actions: [
              // Streak Pill
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.orange,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${repo.studyStreakDays}d streak',
                      style: AppTypography.badge.copyWith(color: Colors.orange),
                    ),
                  ],
                ),
              ),
              if (onNavigateToSettings != null)
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  tooltip: 'Settings & Preferences',
                  onPressed: onNavigateToSettings,
                ),
              const SizedBox(width: 8),
            ],
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
                  // Daily Readiness Hero Banner
                  _buildHeroBanner(
                    context,
                    totalDue: totalDue,
                    scheduledDue: scheduledDue,
                    newCount: newCount,
                    priorityDeck: priorityDeck,
                    hasNoDecks: decks.isEmpty,
                    reviewedToday: reviewedToday,
                    dailyGoal: dailyGoal,
                  ),

                  const SizedBox(height: 20),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          label: scheduledDue > 0 ? 'Due Today' : 'New Cards',
                          value: scheduledDue > 0 ? '$scheduledDue' : '$newCount',
                          color: scheduledDue > 0
                              ? AppColors.danger
                              : (newCount > 0 ? AppColors.accentCyan : AppColors.success),
                          icon: scheduledDue > 0
                              ? Icons.access_time_rounded
                              : Icons.auto_awesome_rounded,
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

                  const SizedBox(height: 24),

                  // Weakness Quick Alert (if any weak cards)
                  if (weakCards.isNotEmpty) ...[
                    _buildWeaknessAlertBanner(context, weakCards.length),
                    const SizedBox(height: 24),
                  ],

                  // Subjects Section (Quick Create & Manage Subjects)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subjects', style: AppTypography.titleLarge),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _openQuickCreateSubjectDialog(context),
                            icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                            label: const Text(
                              'New Subject',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            tooltip: 'Manage All Subjects',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const SubjectListScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (subjects.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.category_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No subjects yet', style: AppTypography.titleMedium),
                                SizedBox(height: 2),
                                Text(
                                  'Create a subject category (e.g. Networking, Calculus) to organize your decks.',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _openQuickCreateSubjectDialog(context),
                            child: const Text(
                              '+ Add',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: subjects.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final sub = subjects[index];
                          final count = decks.where((d) => d.subjectId == sub.id).length;
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const SubjectListScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(sub.colorValue).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Color(sub.colorValue),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    sub.name,
                                    style: AppTypography.labelMedium.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '($count)',
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Active Decks Carousel / List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Active Decks', style: AppTypography.titleLarge),
                      TextButton(
                        onPressed: onNavigateToDecks,
                        child: const Text(
                          'View All',
                          style: TextStyle(color: AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (decks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.style_outlined,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          const Text('No Flashcard Decks Yet', style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          const Text(
                            'Create your first deck in the Decks tab to start studying with SM-2 spaced repetition.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          AppButton(
                            label: 'Create Your First Deck',
                            icon: Icons.add_rounded,
                            onPressed: onNavigateToDecks,
                          ),
                        ],
                      ),
                    )
                  else
                    ...decks.take(4).map((deck) {
                      final subtitleParts = <String>['${deck.totalCards} cards'];
                      if (deck.newCardsCount > 0) {
                        subtitleParts.add('${deck.newCardsCount} new');
                      }
                      if (deck.scheduledDueCount > 0) {
                        subtitleParts.add('${deck.scheduledDueCount} due today');
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: deck.isFavorite
                                ? Colors.amber.withValues(alpha: 0.45)
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Material(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Color(deck.colorValue).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Color(deck.colorValue).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Icon(Icons.style_rounded, color: Color(deck.colorValue)),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    deck.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium.copyWith(fontSize: 15),
                                  ),
                                ),
                                if (deck.isFavorite) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                                ],
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitleParts.join(' • '),
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
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
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(
    BuildContext context, {
    required int totalDue,
    required int scheduledDue,
    required int newCount,
    required Deck? priorityDeck,
    required bool hasNoDecks,
    required int reviewedToday,
    required int dailyGoal,
  }) {
    final goalProgress = dailyGoal > 0 ? (reviewedToday / dailyGoal).clamp(0.0, 1.0) : 0.0;

    String headline;
    String subtext;
    if (hasNoDecks) {
      headline = 'Ready to Start Studying?';
      subtext =
          'Your workspace is clean (0 decks). Create a Subject and Flashcard Deck to begin your spaced repetition schedule.';
    } else if (scheduledDue > 0) {
      headline = '$scheduledDue Cards Due Today';
      subtext = newCount > 0
          ? 'Plus $newCount new cards ready to learn. Reviewing right when intervals expire maximizes long-term memory.'
          : 'Reviewing cards right when they hit the forgetting threshold yields 92% higher retention.';
    } else if (newCount > 0 && totalDue > 0) {
      headline = '$newCount New Cards Ready to Learn';
      subtext =
          'Complete your first pass on these new flashcards to schedule their SM-2 spaced repetition intervals.';
    } else {
      headline = 'All Caught Up For Today!';
      subtext =
          'Outstanding work maintaining your streak. Explore your decks or test your knowledge with a quiz.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DAILY SM-2 SCHEDULE',
                  style: AppTypography.badge.copyWith(
                    fontSize: 10,
                    color: AppColors.bgCanvas,
                  ),
                ),
              ),
              Text(
                'Daily Goal: $reviewedToday / $dailyGoal',
                style: AppTypography.badge.copyWith(
                  fontSize: 11,
                  color: const Color(0xFFC7D2FE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: AppTypography.displayMedium.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: AppTypography.bodyMedium.copyWith(color: const Color(0xFFC7D2FE)),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goalProgress,
              minHeight: 6,
              backgroundColor: Colors.black.withValues(alpha: 0.28),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (totalDue > 0 && priorityDeck != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Start Smart Review (${priorityDeck.title})',
              icon: Icons.play_arrow_rounded,
              isExpanded: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudySessionScreen(
                      deck: priorityDeck,
                      onlyDueCards: true,
                    ),
                  ),
                );
              },
            ),
          ] else if (hasNoDecks) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Create First Subject & Deck',
              icon: Icons.add_circle_outline_rounded,
              isExpanded: true,
              onPressed: onNavigateToDecks,
            ),
          ],
        ],
      ),
    );
  }

  void _openQuickCreateSubjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int selectedColor = 0xFF6366F1;
    final colorOptions = [
      0xFF6366F1,
      0xFF3B82F6,
      0xFF10B981,
      0xFFA855F7,
      0xFFF59E0B,
      0xFFEF4444,
      0xFF06B6D4,
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgSurface1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              title: const Text('Create New Subject', style: AppTypography.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'e.g. Cybersecurity, Operating Systems',
                      filled: true,
                      fillColor: AppColors.bgSurface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Theme Color', style: AppTypography.labelMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colorOptions.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check, size: 16, color: Colors.white),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Create Subject',
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ToastFeedback.showError(context, 'Please enter a subject name.');
                      return;
                    }
                    Navigator.of(ctx).pop();
                    await StudyRepository.instance.addSubject(
                      name: name,
                      colorValue: selectedColor,
                    );
                    if (context.mounted) {
                      ToastFeedback.showSuccess(context, 'Subject "$name" saved to cloud!');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
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
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
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
