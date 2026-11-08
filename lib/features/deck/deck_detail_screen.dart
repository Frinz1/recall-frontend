import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/toast_feedback.dart';
import '../quiz/quiz_screen.dart';
import '../study/study_session_screen.dart';
import 'card_editor_dialog.dart';

class DeckDetailScreen extends StatelessWidget {
  final String deckId;

  const DeckDetailScreen({super.key, required this.deckId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyRepository.instance,
      builder: (context, _) {
        final deck = StudyRepository.instance.getDeckById(deckId);

        if (deck == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Deck not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: Icon(
                  deck.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: deck.isFavorite ? Colors.amber : AppColors.textMuted,
                ),
                tooltip: deck.isFavorite ? 'Remove from Starred' : 'Pin to Starred Decks',
                onPressed: () {
                  final nextState = !deck.isFavorite;
                  StudyRepository.instance.toggleFavoriteDeck(deck.id);
                  if (nextState) {
                    ToastFeedback.showSuccess(
                      context,
                      '"${deck.title}" pinned to Starred Decks.',
                    );
                  } else {
                    ToastFeedback.showInfo(
                      context,
                      '"${deck.title}" removed from Starred.',
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Deck',
                onPressed: () => _openEditDeckDialog(context, deck),
              ),
              if (deck.cards.any((c) => c.timesReviewed > 0))
                IconButton(
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  tooltip: 'Reset Deck Study Progress',
                  onPressed: () => _confirmResetDeck(context, deck),
                ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add Card',
                onPressed: () => _openCardEditorDialog(context, deck.id),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 4,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Color(deck.colorValue),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          if (deck.isFavorite) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    'STARRED',
                                    style: AppTypography.badge.copyWith(
                                      color: Colors.amber,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(deck.title, style: AppTypography.displayMedium),
                      if (deck.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(deck.description, style: AppTypography.bodyMedium),
                      ],
                      const SizedBox(height: 16),
                      _buildDeckStatsBar(deck),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: deck.dueCardsCount > 0
                                  ? 'Study Cards (${deck.dueCardsCount} Ready)'
                                  : 'Review All (${deck.totalCards})',
                              icon: Icons.play_arrow_rounded,
                              variant: AppButtonVariant.primary,
                              onPressed: deck.cards.isEmpty
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => StudySessionScreen(
                                            deck: deck,
                                            onlyDueCards: deck.dueCardsCount > 0,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            label: 'Quiz',
                            icon: Icons.quiz_outlined,
                            variant: AppButtonVariant.secondary,
                            onPressed: deck.cards.isEmpty
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => QuizScreen(deck: deck),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CARDS IN DECK (${deck.cards.length})',
                              style: AppTypography.labelMedium),
                          TextButton.icon(
                            onPressed: () => _openCardEditorDialog(context, deck.id),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Card', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (deck.cards.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.layers_clear_outlined,
                    title: 'No Cards Yet',
                    description: 'Start building this deck by adding your first flashcard.',
                    ctaLabel: 'Add First Card',
                    onCtaPressed: () => _openCardEditorDialog(context, deck.id),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final card = deck.cards[index];
                        return _buildCardItem(context, deck.id, card);
                      },
                      childCount: deck.cards.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeckStatsBar(Deck deck) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('Total', '${deck.totalCards}', AppColors.textPrimary),
          _divider(),
          _statCol('New', '${deck.newCardsCount}', AppColors.accentCyan),
          _divider(),
          _statCol('Due Today', '${deck.scheduledDueCount}', AppColors.danger),
          _divider(),
          _statCol('Mastered', '${deck.masteredCount}', AppColors.success),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.metricMedium.copyWith(color: color, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.borderSubtle,
    );
  }

  Widget _buildCardItem(BuildContext context, String deckId, Flashcard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: card.isScheduledDue
              ? AppColors.danger.withValues(alpha: 0.5)
              : (card.isNewCard
                  ? AppColors.accentCyan.withValues(alpha: 0.35)
                  : AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (card.isNewCard)
                AppBadge.newCard()
              else ...[
                AppBadge.forMasteryStatus(card.masteryStatus),
                const SizedBox(width: 6),
                if (card.isScheduledDue)
                  AppBadge.dueToday()
                else
                  AppBadge.scheduledIn(card.intervalDays),
              ],
              const Spacer(),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                tooltip: 'Edit Flashcard',
                onPressed: () => _openCardEditorDialog(context, deckId, existingCard: card),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                tooltip: 'Delete Flashcard',
                onPressed: () {
                  StudyRepository.instance.deleteCard(deckId: deckId, cardId: card.id);
                  ToastFeedback.showInfo(context, 'Flashcard deleted.');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(card.question, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            card.answer,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (card.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: card.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$tag',
                    style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  card.isNewCard
                      ? 'Not studied yet • Ready for first review (${card.cardType.label})'
                      : 'Reviewed ${card.timesReviewed}x • Next interval: ${card.intervalDays}d • Ease: ${card.easeFactor.toStringAsFixed(2)}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openCardEditorDialog(BuildContext context, String deckId, {Flashcard? existingCard}) {
    showDialog<void>(
      context: context,
      builder: (_) => CardEditorDialog(deckId: deckId, existingCard: existingCard),
    );
  }

  void _openEditDeckDialog(BuildContext context, Deck deck) {
    final titleCtrl = TextEditingController(text: deck.title);
    final descCtrl = TextEditingController(text: deck.description);
    final repo = StudyRepository.instance;
    String selectedSub = deck.subjectId.isNotEmpty
        ? deck.subjectId
        : (repo.subjects.isNotEmpty ? repo.subjects.first.id : '');
    int selectedColor = deck.colorValue;
    final colorOptions = [
      0xFF3B82F6,
      0xFF6366F1,
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
            final subjects = repo.subjects;
            final hasSelected = subjects.any((s) => s.id == selectedSub);
            if (!hasSelected && subjects.isNotEmpty) {
              selectedSub = subjects.first.id;
            }

            return AlertDialog(
              backgroundColor: AppColors.bgSurface1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              title: const Text('Edit Deck', style: AppTypography.titleLarge),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Deck Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Subject Category', style: AppTypography.labelMedium),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSub,
                        dropdownColor: AppColors.bgSurface2,
                        items: subjects.map((s) {
                          return DropdownMenuItem(value: s.id, child: Text(s.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedSub = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Deck Color', style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: colorOptions.map((c) {
                        final isSelected = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Save Changes',
                  onPressed: () async {
                    final t = titleCtrl.text.trim();
                    if (t.isEmpty) {
                      ToastFeedback.showError(context, 'Deck title cannot be empty.');
                      return;
                    }
                    Navigator.of(ctx).pop();
                    await repo.updateDeck(
                      deckId: deck.id,
                      title: t,
                      description: descCtrl.text.trim(),
                      subjectId: selectedSub,
                      colorValue: selectedColor,
                    );
                    if (context.mounted) {
                      ToastFeedback.showSuccess(context, 'Deck "$t" updated!');
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

  void _confirmResetDeck(BuildContext context, Deck deck) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text('Reset Study Progress?', style: AppTypography.titleLarge),
        content: Text(
          'This will reset all ${deck.totalCards} cards in "${deck.title}" back to New (0 reviews) so you can study the deck fresh from the beginning. Your cards will not be deleted.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Reset Progress',
            onPressed: () async {
              Navigator.of(ctx).pop();
              await StudyRepository.instance.resetDeckProgress(deck.id);
              if (context.mounted) {
                ToastFeedback.showSuccess(context, 'Progress reset for "${deck.title}".');
              }
            },
          ),
        ],
      ),
    );
  }
}
