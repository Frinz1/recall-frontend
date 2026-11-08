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
        final subjects = repo.subjects;

        // Recommend deck with most due cards
        Deck? priorityDeck;
        if (decks.isNotEmpty) {
          final sorted = List<Deck>.from(decks)
            ..sort((a, b) => b.dueCardsCount.compareTo(a.dueCardsCount));
          priorityDeck = sorted.first;
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
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 17),
                    const SizedBox(width: 4),
                    Text(
                      '${repo.studyStreakDays}d',
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
                icon: const Icon(Icons.logout_rounded, size: 20),
                tooltip: 'Sign Out',
                onPressed: () {
                  AuthService.instance.logout();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Readiness Hero Banner
                _buildHeroBanner(context, totalDue, priorityDeck, decks.isEmpty),

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
                            Icons.tune_rounded,
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
                              color: Color(deck.colorValue).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Color(deck.colorValue).withValues(alpha: 0.5)),
                            ),
                            child: Icon(Icons.style_rounded, color: Color(deck.colorValue)),
                          ),
                          title: Text(
                            deck.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(fontSize: 15),
                          ),
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
        );
      },
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    int totalDue,
    Deck? priorityDeck,
    bool hasNoDecks,
  ) {
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
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasNoDecks
                ? 'Ready to Start Studying?'
                : (totalDue > 0
                    ? '$totalDue Flashcards Due for Review'
                    : 'All Caught Up For Today!'),
            style: AppTypography.displayMedium.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            hasNoDecks
                ? 'Your workspace is clean (0 decks). Create a Subject and Flashcard Deck to begin your spaced repetition schedule.'
                : (totalDue > 0
                    ? 'Reviewing cards right when they hit the forgetting threshold yields 92% higher retention.'
                    : 'Outstanding work maintaining your streak. Feel free to explore your decks or test your knowledge with a quiz.'),
            style: AppTypography.bodyMedium.copyWith(color: const Color(0xFFC7D2FE)),
          ),
          if (totalDue > 0 && priorityDeck != null) ...[
            const SizedBox(height: 18),
            AppButton(
              label: 'Start Smart Review (${priorityDeck.title})',
              icon: Icons.play_arrow_rounded,
              isExpanded: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudySessionScreen(
                      deck: priorityDeck!,
                      onlyDueCards: true,
                    ),
                  ),
                );
              },
            ),
          ] else if (hasNoDecks) ...[
            const SizedBox(height: 18),
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
