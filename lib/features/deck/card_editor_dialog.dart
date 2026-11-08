import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/curved_bottom_sheet.dart';
import '../../core/widgets/toast_feedback.dart';

class CardEditorDialog extends StatefulWidget {
  final String deckId;
  final Flashcard? existingCard;

  const CardEditorDialog({
    super.key,
    required this.deckId,
    this.existingCard,
  });

  static Future<void> show(
    BuildContext context, {
    required String deckId,
    Flashcard? existingCard,
  }) {
    final isEditing = existingCard != null;
    return CurvedBottomSheet.show<void>(
      context: context,
      title: isEditing ? 'Edit Flashcard' : 'Create Flashcard',
      subtitle: isEditing
          ? 'Refine question, answer, or explanation for SM-2 review'
          : 'Add a new spaced-repetition card to this deck',
      child: CardEditorDialog(
        deckId: deckId,
        existingCard: existingCard,
      ),
    );
  }

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

    ToastFeedback.showSuccess(
      context,
      _isEditing ? 'Flashcard updated!' : 'Flashcard added to deck!',
    );
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
    } else {
      await StudyRepository.instance.addCardToDeck(
        deckId: widget.deckId,
        question: q,
        answer: a,
        explanation: _explanationController.text.trim(),
        tags: tags,
        cardType: _cardType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CARD TYPE', style: AppTypography.labelMedium),
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
                borderRadius: BorderRadius.circular(12),
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
          label: 'FRONT / QUESTION *',
          hint: 'e.g., What is the purpose of BGP routing?',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _answerController,
          label: 'BACK / ANSWER *',
          hint: 'e.g., Exchanging routing information between Autonomous Systems.',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _explanationController,
          label: 'DETAILED CONCEPT EXPLANATION (OPTIONAL)',
          hint: 'Additional context shown after flip or in quiz...',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _tagsController,
          label: 'TAGS (COMMA-SEPARATED)',
          hint: 'e.g., Networking, Internet, L3',
          maxLines: 1,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: _isEditing ? 'Update Flashcard' : 'Save Flashcard',
          icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
          variant: AppButtonVariant.primary,
          isExpanded: true,
          onPressed: _saveCard,
        ),
      ],
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
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bgSurface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
