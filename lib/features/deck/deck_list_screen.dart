import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/quick_create_sheet.dart';
import '../../core/widgets/toast_feedback.dart';
import '../subject/subject_list_screen.dart';
import 'deck_detail_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  String? _selectedSubjectId;
  bool _onlyStarred = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyRepository.instance,
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final subjects = repo.subjects;
        final activeSubjectId = (_selectedSubjectId != null &&
                subjects.any((s) => s.id == _selectedSubjectId))
            ? _selectedSubjectId
            : null;

        final filteredDecks = repo.decks.where((deck) {
          if (_onlyStarred && !deck.isFavorite) {
            return false;
          }
          if (activeSubjectId != null && deck.subjectId != activeSubjectId) {
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
            titleSpacing: 20,
            title: const Text('My Decks & Library', style: AppTypography.titleLarge),
            actions: [
              // Single clean 'Subjects' button in AppBar (No redundant + Deck or + Subject buttons)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.bgSurface1,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  icon: const Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: AppColors.primaryLight,
                  ),
                  label: Text(
                    'Subjects',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SubjectListScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),

              // Filter Chips (No redundant + New Subject ActionChip)
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  children: [
                    _buildChip(
                      label: 'All Decks',
                      isSelected: !_onlyStarred && activeSubjectId == null,
                      onTap: () => setState(() {
                        _onlyStarred = false;
                        _selectedSubjectId = null;
                      }),
                    ),
                    _buildChip(
                      label: 'Starred',
                      icon: Icons.star_rounded,
                      isSelected: _onlyStarred,
                      onTap: () => setState(() {
                        _onlyStarred = !_onlyStarred;
                      }),
                    ),
                    ...subjects.map((sub) {
                      return _buildChip(
                        label: sub.name,
                        isSelected: activeSubjectId == sub.id,
                        onTap: () => setState(() {
                          _selectedSubjectId =
                              activeSubjectId == sub.id ? null : sub.id;
                        }),
                      );
                    }),
                  ],
                ),
              ),

              // Deck List or Empty State
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.bgSurface1,
                  onRefresh: () => repo.fetchAllFromCloud(),
                  child: filteredDecks.isEmpty
                      ? EmptyStateView(
                          icon: _onlyStarred ? Icons.star_outline_rounded : Icons.style_outlined,
                          title: _onlyStarred ? 'No Starred Decks Yet' : 'No Decks Found',
                          description: _onlyStarred
                              ? 'Tap the star icon on any deck card to pin it to the top of your library.'
                              : (_searchQuery.isNotEmpty
                                  ? 'No decks match "$_searchQuery".'
                                  : 'Create a subject and your first flashcard deck to start studying.'),
                          ctaLabel: _onlyStarred ? 'Show All Decks' : 'Create New Deck',
                          onCtaPressed: _onlyStarred
                              ? () => setState(() => _onlyStarred = false)
                              : () => QuickCreateSheet.show(context, initialTab: 0),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          itemCount: filteredDecks.length,
                          itemBuilder: (context, index) {
                            final deck = filteredDecks[index];
                            return _buildBentoDeckCard(context, deck, repo);
                          },
                        ),
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
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icon != null
            ? Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.bgCanvas : AppColors.primaryLight,
              )
            : null,
        label: Text(
          label,
          style: AppTypography.badge.copyWith(
            color: isSelected ? AppColors.bgCanvas : AppColors.textSecondary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.bgSurface1,
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.bgCanvas,
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

  Widget _buildBentoDeckCard(BuildContext context, Deck deck, StudyRepository repo) {
    final accent = AppColors.resolveBentoAccent(deck.colorValue);
    final masteryPct = deck.masteryPercentage.round();
    final progressValue = deck.cards.isEmpty ? 0.0 : (deck.masteredCount / deck.cards.length);

    Subject? subject;
    for (final s in repo.subjects) {
      if (s.id == deck.subjectId) {
        subject = s;
        break;
      }
    }

    String statusLabel;
    if (deck.scheduledDueCount > 0) {
      statusLabel = '${deck.scheduledDueCount} due today';
    } else if (deck.newCardsCount > 0) {
      statusLabel = '${deck.newCardsCount} new';
    } else if (deck.totalCards == 0) {
      statusLabel = '0 cards • New deck';
    } else {
      statusLabel = 'All caught up';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppColors.resolveBentoGradient(deck.colorValue),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: deck.isFavorite
              ? AppColors.primaryLight.withValues(alpha: 0.85)
              : accent.withValues(alpha: 0.42),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DeckDetailScreen(deckId: deck.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status Pill (Left) & Star + Edit + Delete + Circular Arrow (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: deck.scheduledDueCount > 0
                                    ? AppColors.primaryLight
                                    : accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusLabel,
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
                        // Star Toggle
                        GestureDetector(
                          onTap: () {
                            final next = !deck.isFavorite;
                            StudyRepository.instance.toggleFavoriteDeck(deck.id);
                            if (next) {
                              ToastFeedback.showSuccess(
                                context,
                                '"${deck.title}" pinned to top of decks!',
                              );
                            } else {
                              ToastFeedback.showInfo(
                                context,
                                '"${deck.title}" unpinned.',
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
                            child: Icon(
                              deck.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: deck.isFavorite ? AppColors.primaryLight : Colors.white70,
                            ),
                          ),
                        ),
                        // Edit Deck via QuickCreateSheet
                        GestureDetector(
                          onTap: () => QuickCreateSheet.show(context, existingDeck: deck),
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
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Delete Deck
                        GestureDetector(
                          onTap: () async {
                            await StudyRepository.instance.deleteDeck(deck.id);
                            if (context.mounted) {
                              ToastFeedback.showInfo(context, 'Deck "${deck.title}" deleted.');
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
                              size: 17,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        // Top-Right Circular Arrow Action Button
                        Container(
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
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (subject != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.badge.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Deck Title & Description
                Text(
                  deck.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  deck.description.isEmpty
                      ? 'Spaced repetition flashcard collection (${deck.totalCards} cards)'
                      : deck.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 16),

                // Mastery Progress Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Progress • $masteryPct%',
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
                        '${deck.totalCards} cards • ${deck.masteredCount} mastered',
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
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.black.withValues(alpha: 0.28),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
