import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/study_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'curved_bottom_sheet.dart';
import 'toast_feedback.dart';

/// Unified Curved Creation & Editing Bottom Sheet for Decks and Subjects.
class QuickCreateSheet extends StatefulWidget {
  final int initialTab;
  final Deck? existingDeck;
  final Subject? existingSubject;

  const QuickCreateSheet({
    super.key,
    this.initialTab = 0,
    this.existingDeck,
    this.existingSubject,
  });

  static Future<void> show(
    BuildContext context, {
    int initialTab = 0,
    Deck? existingDeck,
    Subject? existingSubject,
  }) {
    String title = 'Create Workspace Item';
    String subtitle = 'Organize your study materials with color-blocked Bento themes';
    if (existingDeck != null) {
      title = 'Edit Deck';
      subtitle = 'Update deck title, subject category, or surface palette';
    } else if (existingSubject != null) {
      title = 'Edit Subject';
      subtitle = 'Customize subject name and color-blocked surface theme';
    }

    return CurvedBottomSheet.show<void>(
      context: context,
      title: title,
      subtitle: subtitle,
      child: QuickCreateSheet(
        initialTab: existingSubject != null ? 1 : initialTab,
        existingDeck: existingDeck,
        existingSubject: existingSubject,
      ),
    );
  }

  @override
  State<QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends State<QuickCreateSheet> {
  late int _activeTab; // 0 = Deck, 1 = Subject
  late final TextEditingController _deckTitleCtrl;
  late final TextEditingController _deckDescCtrl;
  late final TextEditingController _quickSubNameCtrl;
  late final TextEditingController _subjectNameCtrl;

  String? _selectedSubjectId;
  bool _showInlineQuickSubject = false;
  late int _selectedDeckColor;
  late int _selectedSubjectColor;
  bool _isSaving = false;

  bool get _isEditingDeck => widget.existingDeck != null;
  bool get _isEditingSubject => widget.existingSubject != null;
  bool get _isCreatingNew => !_isEditingDeck && !_isEditingSubject;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.existingSubject != null ? 1 : widget.initialTab;

    final repo = StudyRepository.instance;
    final deck = widget.existingDeck;
    final subject = widget.existingSubject;

    _deckTitleCtrl = TextEditingController(text: deck?.title ?? '');
    _deckDescCtrl = TextEditingController(text: deck?.description ?? '');
    _quickSubNameCtrl = TextEditingController();
    _subjectNameCtrl = TextEditingController(text: subject?.name ?? '');

    if (deck != null && deck.subjectId.isNotEmpty) {
      _selectedSubjectId = deck.subjectId;
    } else if (repo.subjects.isNotEmpty) {
      _selectedSubjectId = repo.subjects.first.id;
    }

    _showInlineQuickSubject = repo.subjects.isEmpty;
    _selectedDeckColor = deck?.colorValue ?? AppColors.themeRoyalIndigo;
    _selectedSubjectColor = subject?.colorValue ?? AppColors.themeSageEmerald;
  }

  @override
  void dispose() {
    _deckTitleCtrl.dispose();
    _deckDescCtrl.dispose();
    _quickSubNameCtrl.dispose();
    _subjectNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSaveDeck() async {
    if (_isSaving) return;
    final title = _deckTitleCtrl.text.trim();
    if (title.isEmpty) {
      ToastFeedback.showError(context, 'Please enter a deck title.');
      return;
    }

    final repo = StudyRepository.instance;
    final quickSubInput = _quickSubNameCtrl.text.trim();
    if (_showInlineQuickSubject && repo.subjects.isNotEmpty && quickSubInput.isEmpty) {
      ToastFeedback.showError(
        context,
        'Please enter a new subject name or select an existing subject.',
      );
      return;
    }

    setState(() => _isSaving = true);
    String targetSubjectId = _selectedSubjectId ?? '';

    if (repo.subjects.isEmpty || (_showInlineQuickSubject && quickSubInput.isNotEmpty)) {
      final quickName = quickSubInput.isEmpty ? 'Computer Science' : quickSubInput;
      final createdSub = await repo.addSubject(
        name: quickName,
        colorValue: _selectedDeckColor,
      );
      if (createdSub != null) {
        targetSubjectId = createdSub.id;
      }
    }

    if (!mounted) return;
    ToastFeedback.showSuccess(
      context,
      _isEditingDeck ? 'Deck "$title" updated!' : 'Deck "$title" created and synced!',
    );
    Navigator.of(context).pop();

    if (_isEditingDeck) {
      await repo.updateDeck(
        deckId: widget.existingDeck!.id,
        title: title,
        description: _deckDescCtrl.text.trim(),
        subjectId: targetSubjectId,
        colorValue: _selectedDeckColor,
      );
    } else {
      await repo.addDeck(
        title: title,
        description: _deckDescCtrl.text.trim(),
        subjectId: targetSubjectId,
        colorValue: _selectedDeckColor,
      );
    }
  }

  Future<void> _handleSaveSubject() async {
    if (_isSaving) return;
    final name = _subjectNameCtrl.text.trim();
    if (name.isEmpty) {
      ToastFeedback.showError(context, 'Please enter a subject name.');
      return;
    }

    setState(() => _isSaving = true);
    final repo = StudyRepository.instance;

    ToastFeedback.showSuccess(
      context,
      _isEditingSubject
          ? 'Subject "$name" updated!'
          : 'Subject "$name" created and synced!',
    );
    Navigator.of(context).pop();

    if (_isEditingSubject) {
      await repo.updateSubject(
        subjectId: widget.existingSubject!.id,
        name: name,
        colorValue: _selectedSubjectColor,
      );
    } else {
      await repo.addSubject(
        name: name,
        colorValue: _selectedSubjectColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isCreatingNew) ...[
          _buildSegmentedSwitcher(),
          const SizedBox(height: 22),
        ],
        if (_activeTab == 0) _buildDeckForm() else _buildSubjectForm(),
      ],
    );
  }

  Widget _buildSegmentedSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentPill(
              index: 0,
              icon: Icons.style_rounded,
              label: 'New Deck',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildSegmentPill(
              index: 1,
              icon: Icons.local_offer_rounded,
              label: 'New Subject',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentPill({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.badge.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckForm() {
    final subjects = StudyRepository.instance.subjects;
    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('DECK TITLE'),
        const SizedBox(height: 8),
        TextField(
          controller: _deckTitleCtrl,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: _roundedInputDecoration(
            hint: 'e.g., Distributed Systems, TCP/IP & BGP Routing',
            prefixIcon: Icons.layers_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('DESCRIPTION (OPTIONAL)'),
        const SizedBox(height: 8),
        TextField(
          controller: _deckDescCtrl,
          maxLines: 2,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: _roundedInputDecoration(
            hint: 'Core concepts, RFC protocols, or exam chapters covered...',
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _buildFieldLabel('SUBJECT CATEGORY')),
            if (subjects.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showInlineQuickSubject = !_showInlineQuickSubject),
                child: Text(
                  _showInlineQuickSubject ? 'Select Existing' : '+ Quick Subject',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (subjects.isEmpty || _showInlineQuickSubject)
          TextField(
            controller: _quickSubNameCtrl,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: _roundedInputDecoration(
              hint: 'New subject name (e.g., Cybersecurity, Pharmacology)',
              prefixIcon: Icons.create_new_folder_outlined,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((s) {
              final isSelected = _selectedSubjectId == s.id;
              final accent = AppColors.resolveBentoAccent(s.colorValue);
              final icon = AppColors.resolveSubjectIcon(s.name);
              return GestureDetector(
                onTap: () => setState(() => _selectedSubjectId = s.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.resolveBentoGradient(s.colorValue) : null,
                    color: isSelected ? null : AppColors.bgSurface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? accent : AppColors.borderSubtle,
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null)
                        Icon(
                          icon,
                          size: 15,
                          color: isSelected ? AppColors.textPrimary : accent,
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.badge.copyWith(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        _buildFieldLabel('CARD SURFACE THEME PALETTE'),
        const SizedBox(height: 10),
        _buildPaletteSelector(
          selectedValue: _selectedDeckColor,
          onSelect: (val) => setState(() => _selectedDeckColor = val),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: _isEditingDeck ? 'Save Changes' : 'Create Deck',
          icon: _isEditingDeck ? Icons.check_rounded : Icons.add_rounded,
          isExpanded: true,
          isLoading: _isSaving,
          onPressed: _handleSaveDeck,
        ),
      ],
    );
  }

  Widget _buildSubjectForm() {
    final previewName = _subjectNameCtrl.text.trim().isEmpty
        ? 'Cybersecurity & Cryptography'
        : _subjectNameCtrl.text.trim();
    final previewIcon = AppColors.resolveSubjectIcon(previewName);
    final previewMonogram = AppColors.getSubjectMonogram(previewName);
    final accent = AppColors.resolveBentoAccent(_selectedSubjectColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('SUBJECT NAME'),
        const SizedBox(height: 8),
        TextField(
          controller: _subjectNameCtrl,
          onChanged: (_) => setState(() {}),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: _roundedInputDecoration(
            hint: 'e.g., Cybersecurity, Pharmacology, Calculus',
            prefixIcon: Icons.category_outlined,
          ),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('SURFACE THEME PALETTE'),
        const SizedBox(height: 10),
        _buildPaletteSelector(
          selectedValue: _selectedSubjectColor,
          onSelect: (val) => setState(() => _selectedSubjectColor = val),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('LIVE BENTO CARD PREVIEW'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.resolveBentoGradient(_selectedSubjectColor),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: previewIcon != null
                      ? Icon(previewIcon, color: Colors.white, size: 22)
                      : Text(
                          previewMonogram,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      previewName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Color-blocked Bento subject surface',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.north_east_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: _isEditingSubject ? 'Save Subject' : 'Create Subject',
          icon: _isEditingSubject ? Icons.check_rounded : Icons.add_rounded,
          isExpanded: true,
          isLoading: _isSaving,
          onPressed: _handleSaveSubject,
        ),
      ],
    );
  }

  Widget _buildPaletteSelector({
    required int selectedValue,
    required ValueChanged<int> onSelect,
  }) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.35,
      children: AppColors.bentoThemeOptions.map((option) {
        final isSelected = (selectedValue & 0xFFFFFF) == (option.value & 0xFFFFFF);
        final accent = AppColors.resolveBentoAccent(option.value);
        return GestureDetector(
          onTap: () => onSelect(option.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.resolveBentoGradient(option.value),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.white : accent.withValues(alpha: 0.35),
                width: isSelected ? 2.2 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.badge.copyWith(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        fontSize: 11,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _roundedInputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 19, color: AppColors.textMuted)
          : null,
      filled: true,
      fillColor: AppColors.bgSurface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
