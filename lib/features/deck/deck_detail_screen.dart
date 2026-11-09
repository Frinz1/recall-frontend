import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/curved_bottom_sheet.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/mechanics_sheet.dart';
import '../../core/widgets/quick_create_sheet.dart';
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
            title: Text('Deck Overview', style: AppTypography.titleLarge),
            actions: [
              IconButton(
                icon: Icon(
                  deck.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: deck.isFavorite
                      ? (AppColors.isDarkMode ? AppColors.primaryLight : AppColors.primary)
                      : AppColors.textMuted,
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
                onPressed: () => QuickCreateSheet.show(context, existingDeck: deck),
              ),
              if (deck.cards.any((c) => c.timesReviewed > 0))
                IconButton(
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  tooltip: 'Reset Deck Study Progress',
                  onPressed: () => _confirmResetDeck(context, deck),
                ),
              const SizedBox(width: 8),
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
                      // Color-Blocked Bento Deck Header Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.resolveBentoGradient(deck.colorValue),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.bentoBorderColor(deck.colorValue),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: AppColors.isDarkMode ? 0.28 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => MechanicsSheet.showDeckMasteryRules(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.bentoPodBackground,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.bentoPodBorder),
                                      boxShadow: AppColors.isDarkMode
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${deck.graduatedProgressPercentage.round()}% PROGRESS',
                                          style: AppTypography.badge.copyWith(
                                            color: AppColors.bentoPodText,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.help_outline_rounded,
                                          size: 13,
                                          color: AppColors.bentoPodText.withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (deck.isFavorite) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.bentoPodBackground,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.bentoPodBorder),
                                      boxShadow: AppColors.isDarkMode
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 12,
                                          color: AppColors.isDarkMode
                                              ? AppColors.primaryLight
                                              : AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'STARRED',
                                          style: AppTypography.badge.copyWith(
                                            color: AppColors.isDarkMode
                                                ? AppColors.primaryLight
                                                : AppColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              deck.title,
                              style: AppTypography.displayMedium.copyWith(
                                color: AppColors.bentoTextPrimary(deck.colorValue),
                              ),
                            ),
                            if (deck.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                deck.description,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.bentoTextSecondary(deck.colorValue),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _buildDeckStatsBar(deck),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Graduated Mastery Progress',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.bentoTextSecondary(deck.colorValue),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                                Text(
                                  '${deck.graduatedProgressPercentage.round()}% • ${deck.masteredCount}/${deck.totalCards} mastered',
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.bentoTextPrimary(deck.colorValue),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: deck.graduatedProgress,
                                minHeight: 8,
                                backgroundColor: AppColors.bentoProgressTrackBg(),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  deck.graduatedProgress >= 1.0
                                      ? AppColors.success
                                      : AppColors.bentoProgressBarColor(deck.colorValue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
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
                          Text(
                            'CARDS IN DECK (${deck.cards.length})',
                            style: AppTypography.labelMedium,
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.bgSurface1,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                            onPressed: () => CardEditorDialog.show(context, deckId: deck.id),
                            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                            label: Text(
                              'Add Card',
                              style: AppTypography.badge.copyWith(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
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
                    onCtaPressed: () => CardEditorDialog.show(context, deckId: deck.id),
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
        color: AppColors.bentoPodBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bentoPodBorder),
        boxShadow: AppColors.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('Total', '${deck.totalCards}', AppColors.bentoTextPrimary(deck.colorValue)),
          _divider(),
          _statCol('New', '${deck.newCardsCount}', AppColors.accentCyan),
          _divider(),
          _statCol(
            'Due Today',
            '${deck.scheduledDueCount}',
            AppColors.isDarkMode ? AppColors.primaryLight : AppColors.primary,
          ),
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
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.bentoPodText.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.18)
          : AppColors.borderSubtle,
    );
  }

  Widget _buildCardItem(BuildContext context, String deckId, Flashcard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
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
                  AppBadge.scheduledIn(card.displayIntervalDays),
              ],
              const Spacer(),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                tooltip: 'Edit Flashcard',
                onPressed: () => CardEditorDialog.show(
                  context,
                  deckId: deckId,
                  existingCard: card,
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
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
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  card.isNewCard
                      ? 'Not studied yet • Ready for first review (${card.cardType.label})'
                      : 'Reviewed ${card.timesReviewed}x • Next interval: ${card.displayIntervalDays}d${card.displayIntervalDays >= 180 ? ' (Max)' : ''} • Ease: ${card.easeFactor.toStringAsFixed(2)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmResetDeck(BuildContext context, Deck deck) {
    CurvedBottomSheet.show<void>(
      context: context,
      title: 'Reset Study Progress?',
      subtitle: 'Restore all ${deck.totalCards} ${deck.totalCards == 1 ? 'card' : 'cards'} in "${deck.title}" to unstudied state',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This will reset all cards in "${deck.title}" back to New (0 reviews) so you can study the deck fresh from the beginning. Your flashcards will not be deleted.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Reset Deck Progress',
            icon: Icons.restart_alt_rounded,
            isExpanded: true,
            onPressed: () async {
              Navigator.of(context).pop();
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
