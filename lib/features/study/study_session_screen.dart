import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/algorithms/sm2_engine.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/confetti_burst.dart';
import 'widgets/flip_card_widget.dart';

class StudySessionScreen extends StatefulWidget {
  final Deck deck;
  final bool onlyDueCards;

  const StudySessionScreen({
    super.key,
    required this.deck,
    this.onlyDueCards = false,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  late List<Flashcard> _sessionCards;
  int _currentIndex = 0;
  bool _isFlipped = false;
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;
  int _comboStreak = 0;
  String? _sessionId;
  late DateTime _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    final repo = StudyRepository.instance;
    final activeDeck = repo.getDeckById(widget.deck.id) ?? widget.deck;
    if (widget.onlyDueCards) {
      _sessionCards = activeDeck.cards.where((c) {
        if (!repo.includeNewInDue && c.isNewCard) return false;
        return c.isDue;
      }).toList();
      if (_sessionCards.isEmpty) {
        _sessionCards = List<Flashcard>.from(activeDeck.cards)
          ..sort((a, b) {
            final aMastered = a.masteryStatus == CardMasteryStatus.mastered;
            final bMastered = b.masteryStatus == CardMasteryStatus.mastered;
            if (aMastered != bMastered) {
              return aMastered ? 1 : -1;
            }
            return a.easeFactor.compareTo(b.easeFactor);
          });
      }
    } else {
      _sessionCards = List<Flashcard>.from(activeDeck.cards)
        ..sort((a, b) {
          final aMastered = a.masteryStatus == CardMasteryStatus.mastered;
          final bMastered = b.masteryStatus == CardMasteryStatus.mastered;
          if (aMastered != bMastered) {
            return aMastered ? 1 : -1;
          }
          return a.easeFactor.compareTo(b.easeFactor);
        });
    }

    if (repo.shuffleStudyCards && _sessionCards.length > 1) {
      _sessionCards.shuffle();
    }

    repo.startStudySession(widget.deck.id).then((id) {
      if (mounted) {
        _sessionId = id;
      }
    });
  }

  void _handleRating(RecallRating rating) {
    HapticFeedback.mediumImpact();
    final currentCard = _sessionCards[_currentIndex];

    // Record via SM-2 Engine
    StudyRepository.instance.recordCardReview(
      deckId: widget.deck.id,
      cardId: currentCard.id,
      rating: rating,
    );

    switch (rating) {
      case RecallRating.again:
        _againCount++;
        _comboStreak = 0;
        break;
      case RecallRating.hard:
        _hardCount++;
        _comboStreak = 0;
        break;
      case RecallRating.good:
        _goodCount++;
        _comboStreak++;
        break;
      case RecallRating.easy:
        _easyCount++;
        _comboStreak++;
        break;
    }

    if (_currentIndex < _sessionCards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  /// Dynamically calculates the exact SM-2 interval preview for a given rating on the current card.
  String _previewIntervalLabel(Flashcard card, RecallRating rating) {
    final result = SM2Engine.calculateNextReview(
      rating: rating,
      currentRepetitions: card.repetitions,
      currentIntervalDays: card.intervalDays,
      currentEaseFactor: card.easeFactor,
    );
    if (rating == RecallRating.again) {
      return '1d • Reset';
    }
    return '${result.intervalDays}d';
  }

  void _showCompletionDialog() {
    final total = _sessionCards.length;
    final durationSec = DateTime.now().difference(_sessionStartTime).inSeconds;
    StudyRepository.instance.completeStudySession(
      sessionId: _sessionId,
      cardsReviewed: total,
      correctCount: _goodCount + _easyCount,
      durationSeconds: durationSec < 1 ? 1 : durationSec,
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final retention = total > 0
            ? (((_goodCount + _easyCount) / total) * 100).round()
            : 100;

        return ConfettiBurst(
          child: AlertDialog(
            backgroundColor: AppColors.bgSurface1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.borderSubtle),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Session Complete!', style: AppTypography.titleLarge),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You reviewed $total flashcards in ${durationSec < 60 ? '${durationSec}s' : '${(durationSec / 60).ceil()}m'}. Your recall accuracy for this session is $retention%.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricCol('Again', '$_againCount', AppColors.ratingAgain),
                      _metricCol('Hard', '$_hardCount', AppColors.ratingHard),
                      _metricCol('Good', '$_goodCount', AppColors.ratingGood),
                      _metricCol('Easy', '$_easyCount', AppColors.ratingEasy),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              AppButton(
                label: 'Continue',
                isExpanded: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.metricMedium.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deck.title)),
        body: const Center(child: Text('No cards available in this deck.')),
      );
    }

    final currentCard = _sessionCards[_currentIndex];
    final progress = (_currentIndex + 1) / _sessionCards.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deck.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium,
            ),
            Text(
              'Card ${_currentIndex + 1} of ${_sessionCards.length}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (_comboStreak >= 2)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_comboStreak× Combo!',
                    style: AppTypography.badge.copyWith(color: Colors.orange, fontSize: 11),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.bgSurface2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              // Live Session Scoreboard Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _hudChip('Again', _againCount, AppColors.ratingAgain),
                    _hudChip('Hard', _hardCount, AppColors.ratingHard),
                    _hudChip('Good', _goodCount, AppColors.ratingGood),
                    _hudChip('Easy', _easyCount, AppColors.ratingEasy),
                  ],
                ),
              ),

              // Proportioned 3D Card Stack Area
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.06, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<String>(currentCard.id),
                        child: FlipCardWidget(
                          card: currentCard,
                          isFlipped: _isFlipped,
                          currentIndex: _currentIndex + 1,
                          totalCards: _sessionCards.length,
                          onFlip: () {
                            setState(() {
                              _isFlipped = !_isFlipped;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Action Area (3D Reveal Button or Dynamic SM-2 Rating Buttons)
              if (!_isFlipped)
                AppButton(
                  label: 'Show Answer',
                  isExpanded: true,
                  icon: Icons.visibility_outlined,
                  onPressed: () {
                    setState(() {
                      _isFlipped = true;
                    });
                  },
                )
              else
                _buildRatingBar(currentCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hudChip(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
        ),
        Text(
          '$count',
          style: AppTypography.badge.copyWith(color: AppColors.textPrimary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRatingBar(Flashcard currentCard) {
    return Row(
      children: [
        _buildRatingButton(
          rating: RecallRating.again,
          intervalText: _previewIntervalLabel(currentCard, RecallRating.again),
          color: AppColors.ratingAgain,
        ),
        const SizedBox(width: 8),
        _buildRatingButton(
          rating: RecallRating.hard,
          intervalText: _previewIntervalLabel(currentCard, RecallRating.hard),
          color: AppColors.ratingHard,
        ),
        const SizedBox(width: 8),
        _buildRatingButton(
          rating: RecallRating.good,
          intervalText: _previewIntervalLabel(currentCard, RecallRating.good),
          color: AppColors.ratingGood,
        ),
        const SizedBox(width: 8),
        _buildRatingButton(
          rating: RecallRating.easy,
          intervalText: _previewIntervalLabel(currentCard, RecallRating.easy),
          color: AppColors.ratingEasy,
        ),
      ],
    );
  }

  Widget _buildRatingButton({
    required RecallRating rating,
    required String intervalText,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleRating(rating),
        child: Container(
          padding: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.bgSurface1,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.65), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  intervalText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.badge.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rating.label,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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
