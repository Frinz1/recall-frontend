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
                onPressed: () {
                  StudyRepository.instance.toggleFavoriteDeck(deck.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add Card',
                onPressed: () => _openAddCardDialog(context, deck.id),
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
                      Container(
                        height: 4,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Color(deck.colorValue),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(deck.title, style: AppTypography.displayMedium),
                      const SizedBox(height: 6),
                      Text(deck.description, style: AppTypography.bodyMedium),
                      const SizedBox(height: 16),
                      _buildDeckStatsBar(deck),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Study Cards (${deck.dueCardsCount} Due)',
                              icon: Icons.play_arrow_rounded,
                              variant: AppButtonVariant.primary,
                              onPressed: deck.cards.isEmpty
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
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
                                      MaterialPageRoute(
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
                            onPressed: () => _openAddCardDialog(context, deck.id),
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
                    onCtaPressed: () => _openAddCardDialog(context, deck.id),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          _statCol('Due Now', '${deck.dueCardsCount}', AppColors.danger),
          _divider(),
          _statCol('Mastered', '${deck.masteredCount}', AppColors.success),
          _divider(),
          _statCol('Mastery', '${deck.masteryPercentage.round()}%', AppColors.primaryLight),
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
          color: card.isDue ? AppColors.danger.withOpacity(0.5) : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBadge.forMasteryStatus(card.masteryStatus),
              if (card.isDue) AppBadge.dueToday(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Reviewed ${card.timesReviewed}x (Interval: ${card.intervalDays}d • Ease: ${card.easeFactor})',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddCardDialog(BuildContext context, String deckId) {
    showDialog(
      context: context,
      builder: (_) => CardEditorDialog(deckId: deckId),
    );
  }
}
