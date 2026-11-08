import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/toast_feedback.dart';

class CardEditorDialog extends StatefulWidget {
  final String deckId;
  final Flashcard? existingCard;

  const CardEditorDialog({
    super.key,
    required this.deckId,
    this.existingCard,
  });

  @override
  State<CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<CardEditorDialog> {
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final TextEditingController _explanationController;
  late final TextEditingController _tagsController;
  late FlashcardType _cardType;

  bool get _isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();
    final card = widget.existingCard;
    _questionController = TextEditingController(text: card?.question ?? '');
    _answerController = TextEditingController(text: card?.answer ?? '');
    _explanationController = TextEditingController(text: card?.explanation ?? '');
    _tagsController = TextEditingController(text: card?.tags.join(', ') ?? '');
    _cardType = card?.cardType ?? FlashcardType.standard;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    final q = _questionController.text.trim();
    final a = _answerController.text.trim();

    if (q.isEmpty || a.isEmpty) {
      ToastFeedback.showError(context, 'Please enter both question and answer.');
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    Navigator.of(context).pop();

    if (_isEditing) {
      await StudyRepository.instance.updateCard(
        deckId: widget.deckId,
        cardId: widget.existingCard!.id,
        question: q,
        answer: a,
        explanation: _explanationController.text.trim(),
        tags: tags,
        cardType: _cardType,
      );
      if (mounted) {
        ToastFeedback.showSuccess(context, 'Flashcard updated!');
      }
    } else {
      await StudyRepository.instance.addCardToDeck(
        deckId: widget.deckId,
        question: q,
        answer: a,
        explanation: _explanationController.text.trim(),
        tags: tags,
        cardType: _cardType,
      );
      if (mounted) {
        ToastFeedback.showSuccess(context, 'Flashcard added to deck!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgSurface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Flashcard' : 'Create Flashcard',
                    style: AppTypography.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Card Type', style: AppTypography.labelMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: FlashcardType.values.map((type) {
                          final selected = _cardType == type;
                          return ChoiceChip(
                            label: Text(
                              type.label,
                              style: AppTypography.badge.copyWith(
                                color: selected ? AppColors.bgCanvas : AppColors.textSecondary,
                              ),
                            ),
                            selected: selected,
                            onSelected: (_) => setState(() => _cardType = type),
                            backgroundColor: AppColors.bgSurface2,
                            selectedColor: AppColors.primary,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: selected ? AppColors.primary : AppColors.borderSubtle,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _questionController,
                        label: 'Front / Question *',
                        hint: 'e.g., What is the purpose of BGP routing?',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _answerController,
                        label: 'Back / Answer *',
                        hint: 'e.g., Exchanging routing information between Autonomous Systems.',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _explanationController,
                        label: 'Detailed Concept Explanation (Optional)',
                        hint: 'Additional context shown after flip or in quiz...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _tagsController,
                        label: 'Tags (Comma-separated)',
                        hint: 'e.g., Networking, Internet, L3',
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: _isEditing ? 'Update Card' : 'Save Card',
                      variant: AppButtonVariant.primary,
                      onPressed: _saveCard,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bgSurface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
