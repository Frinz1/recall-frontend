import 'package:flutter/material.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/quick_create_sheet.dart';
import '../../core/widgets/toast_feedback.dart';

class SubjectListScreen extends StatelessWidget {
  const SubjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyRepository.instance,
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final subjects = repo.subjects;

        return Scaffold(
          appBar: AppBar(
            title: Text('Subject Categories', style: AppTypography.titleLarge),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.bgSurface1,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 17, color: AppColors.primary),
                  label: Text(
                    'New Subject',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () => QuickCreateSheet.show(context, initialTab: 1),
                ),
              ),
            ],
          ),
          body: subjects.isEmpty
              ? EmptyStateView(
                  icon: Icons.auto_stories_outlined,
                  title: 'No Subjects Yet',
                  description:
                      'Create academic subjects with color-blocked Bento themes to organize your decks.',
                  ctaLabel: 'Add First Subject',
                  onCtaPressed: () => QuickCreateSheet.show(context, initialTab: 1),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final sub = subjects[index];
                    final subDecks = repo.decks.where((d) => d.subjectId == sub.id).toList();
                    final deckCount = subDecks.length;
                    final cardCount = subDecks.fold(0, (sum, d) => sum + d.totalCards);
                    final masteredCount = subDecks.fold(0, (sum, d) => sum + d.masteredCount);
                    final dueCount = subDecks.fold(0, (sum, d) => sum + d.scheduledDueCount);
                    final progressValue = cardCount == 0 ? 0.0 : (masteredCount / cardCount);
                    final progressPct = (progressValue * 100).round();

                    final resolvedIcon = AppColors.resolveSubjectIcon(sub.name);
                    final monogram = AppColors.getSubjectMonogram(sub.name);
                    final accent = AppColors.resolveBentoAccent(sub.colorValue);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.resolveBentoGradient(sub.colorValue),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.42),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Status Pill (Left) + Edit / Delete / Arrow Actions (Right)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: dueCount > 0 ? AppColors.primaryLight : accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          dueCount > 0
                                              ? '$dueCount due today'
                                              : '$deckCount ${deckCount == 1 ? 'deck' : 'decks'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.badge.copyWith(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => QuickCreateSheet.show(
                                      context,
                                      initialTab: 1,
                                      existingSubject: sub,
                                    ),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await StudyRepository.instance.deleteSubject(sub.id);
                                      if (context.mounted) {
                                        ToastFeedback.showInfo(
                                          context,
                                          'Subject "${sub.name}" removed.',
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white70,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => QuickCreateSheet.show(
                                      context,
                                      initialTab: 1,
                                      existingSubject: sub,
                                    ),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.30),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.north_east_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Center(
                                  child: resolvedIcon != null
                                      ? Icon(resolvedIcon, color: Colors.white, size: 24)
                                      : Text(
                                          monogram,
                                          style: AppTypography.titleMedium.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.name,
                                      style: AppTypography.displayMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 19,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$deckCount ${deckCount == 1 ? 'deck' : 'decks'} • $cardCount ${cardCount == 1 ? 'flashcard' : 'flashcards'}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.white.withValues(alpha: 0.84),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Progress • $progressPct%',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.badge.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '$masteredCount/$cardCount mastered',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 8,
                              backgroundColor: Colors.black.withValues(alpha: 0.28),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
