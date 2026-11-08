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
                  icon: Icons.category_outlined,
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
                    final deckCount = repo.decks.where((d) => d.subjectId == sub.id).length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Material(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(sub.colorValue).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(sub.colorValue)),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.folder_special_rounded,
                                color: Color(sub.colorValue),
                                size: 22,
                              ),
                            ),
                          ),
                          title: Text(sub.name, style: AppTypography.titleMedium),
                          subtitle: Text(
                            '$deckCount flashcard decks',
                            style: AppTypography.bodySmall,
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
      0xFF3B82F6, // Blue
      0xFF10B981, // Emerald
      0xFFA855F7, // Purple
      0xFFF59E0B, // Amber
      0xFFEF4444, // Rose
      0xFF06B6D4, // Cyan
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
              title: Text(
                isEditing ? 'Edit Subject' : 'New Subject',
                style: AppTypography.titleLarge,
              ),
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
                      hintText: 'e.g. Cybersecurity, Calculus',
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
