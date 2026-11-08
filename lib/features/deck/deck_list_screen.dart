import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/toast_feedback.dart';
import 'deck_detail_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  String? _selectedSubjectId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyRepository.instance,
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final subjects = repo.subjects;

        var filteredDecks = repo.decks.where((deck) {
          if (_selectedSubjectId != null && deck.subjectId != _selectedSubjectId) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return deck.title.toLowerCase().contains(q) ||
                deck.description.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Decks & Library', style: AppTypography.titleLarge),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Create New Deck',
                onPressed: () => _openCreateDeckDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search decks or topics...',
                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.bgSurface1,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),

              // Subject Filter Chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  children: [
                    _buildChip(
                      label: 'All Subjects',
                      isSelected: _selectedSubjectId == null,
                      onTap: () => setState(() => _selectedSubjectId = null),
                    ),
                    ...subjects.map((sub) {
                      return _buildChip(
                        label: sub.name,
                        isSelected: _selectedSubjectId == sub.id,
                        onTap: () => setState(() => _selectedSubjectId = sub.id),
                      );
                    }),
                  ],
                ),
              ),

              // Deck List or Empty State
              Expanded(
                child: filteredDecks.isEmpty
                    ? EmptyStateView(
                        icon: Icons.search_off_rounded,
                        title: 'No Decks Found',
                        description: _searchQuery.isNotEmpty
                            ? 'No decks match "$_searchQuery".'
                            : 'No flashcard decks in this subject category.',
                        ctaLabel: 'Create Deck',
                        onCtaPressed: () => _openCreateDeckDialog(context),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: filteredDecks.length,
                        itemBuilder: (context, index) {
                          final deck = filteredDecks[index];
                          return _buildDeckCard(context, deck);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: AppTypography.badge.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.bgSurface1,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCard(BuildContext context, Deck deck) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeckDetailScreen(deckId: deck.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(deck.colorValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.title, style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          deck.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      deck.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: deck.isFavorite ? Colors.amber : AppColors.textMuted,
                    ),
                    onPressed: () {
                      StudyRepository.instance.toggleFavoriteDeck(deck.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress and metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${deck.totalCards} cards',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  if (deck.dueCardsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${deck.dueCardsCount} due today',
                        style: AppTypography.badge.copyWith(color: AppColors.danger),
                      ),
                    )
                  else
                    Text(
                      'All caught up!',
                      style: AppTypography.badge.copyWith(color: AppColors.success),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deck.cards.isEmpty ? 0.0 : (deck.masteredCount / deck.cards.length),
                  backgroundColor: AppColors.bgSurface2,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateDeckDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final repo = StudyRepository.instance;
    String selectedSub = repo.subjects.first.id;
    int selectedColor = 0xFF6366F1;

    showDialog(
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
              title: const Text('Create New Deck', style: AppTypography.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Deck Title',
                      hintText: 'e.g., Computer Architecture',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What concepts are covered?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Subject', style: AppTypography.labelMedium),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedSub,
                    dropdownColor: AppColors.bgSurface2,
                    items: repo.subjects.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedSub = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Create',
                  onPressed: () {
                    final t = titleCtrl.text.trim();
                    if (t.isEmpty) return;
                    repo.addDeck(
                      title: t,
                      description: descCtrl.text.trim(),
                      subjectId: selectedSub,
                      colorValue: selectedColor,
                    );
                    Navigator.of(ctx).pop();
                    ToastFeedback.showSuccess(context, 'Deck "$t" created!');
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
