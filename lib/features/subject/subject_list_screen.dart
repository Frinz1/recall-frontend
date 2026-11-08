import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state_view.dart';
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
            title: const Text('Subject Categories', style: AppTypography.titleLarge),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Create Subject',
                onPressed: () => _openSubjectDialog(context),
              ),
            ],
          ),
          body: subjects.isEmpty
              ? EmptyStateView(
                  icon: Icons.auto_stories_outlined,
                  title: 'No Subjects Yet',
                  description: 'Create academic subjects to organize your study materials.',
                  ctaLabel: 'Add First Subject',
                  onCtaPressed: () => _openSubjectDialog(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final sub = subjects[index];
                    final subDecks = repo.decks.where((d) => d.subjectId == sub.id).toList();
                    final deckCount = subDecks.length;
                    final cardCount = subDecks.fold(0, (sum, d) => sum + d.totalCards);
                    final resolvedIcon = AppColors.resolveSubjectIcon(sub.name);
                    final monogram = AppColors.getSubjectMonogram(sub.name);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Color(sub.colorValue).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(sub.colorValue).withValues(alpha: 0.28),
                                Color(sub.colorValue).withValues(alpha: 0.10),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Color(sub.colorValue).withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: resolvedIcon != null
                                ? Icon(
                                    resolvedIcon,
                                    color: Color(sub.colorValue),
                                    size: 22,
                                  )
                                : Text(
                                    monogram,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Color(sub.colorValue),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(sub.name, style: AppTypography.titleMedium),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '$deckCount ${deckCount == 1 ? 'deck' : 'decks'} • $cardCount ${cardCount == 1 ? 'card' : 'cards'}',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              tooltip: 'Edit Subject',
                              onPressed: () => _openSubjectDialog(context, existing: sub),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              tooltip: 'Delete Subject',
                              onPressed: () async {
                                await StudyRepository.instance.deleteSubject(sub.id);
                                if (context.mounted) {
                                  ToastFeedback.showInfo(
                                    context,
                                    'Subject "${sub.name}" removed.',
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _openSubjectDialog(BuildContext context, {Subject? existing}) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int selectedColor = existing?.colorValue ?? 0xFF6366F1;
    final colorOptions = [
      0xFF6366F1, // Indigo
      0xFF38BDF8, // Sky Cyan
      0xFF10B981, // Emerald
      0xFFA855F7, // Purple
      0xFFF59E0B, // Amber
      0xFFEF4444, // Rose
      0xFFEC4899, // Pink
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgSurface1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              title: Text(
                isEditing ? 'Edit Subject' : 'New Subject',
                style: AppTypography.titleLarge,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SUBJECT NAME', style: AppTypography.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Pharmacology, Discrete Math, Law',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('THEME COLOR', style: AppTypography.labelMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colorOptions.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(c).withValues(alpha: 0.45),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check_rounded, size: 18, color: Colors.white),
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
                  label: isEditing ? 'Save Changes' : 'Create',
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ToastFeedback.showError(context, 'Please enter a subject name.');
                      return;
                    }

                    Navigator.of(ctx).pop();
                    if (isEditing) {
                      await StudyRepository.instance.updateSubject(
                        subjectId: existing.id,
                        name: name,
                        colorValue: selectedColor,
                      );
                      if (context.mounted) {
                        ToastFeedback.showSuccess(context, 'Subject "$name" updated.');
                      }
                    } else {
                      await StudyRepository.instance.addSubject(
                        name: name,
                        colorValue: selectedColor,
                      );
                      if (context.mounted) {
                        ToastFeedback.showSuccess(context, 'Subject "$name" created and synced.');
                      }
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
}
