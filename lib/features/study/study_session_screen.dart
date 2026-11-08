import 'package:flutter/material.dart';
import '../../core/algorithms/sm2_engine.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
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
  String? _sessionId;
  late DateTime _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    final repo = StudyRepository.instance;
    if (widget.onlyDueCards) {
      _sessionCards = widget.deck.cards.where((c) {
        if (!repo.includeNewInDue && c.isNewCard) return false;
        return c.isDue;
      }).toList();
      if (_sessionCards.isEmpty) {
        _sessionCards = List.from(widget.deck.cards);
      }
    } else {
      _sessionCards = List.from(widget.deck.cards);
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
        break;
      case RecallRating.hard:
        _hardCount++;
        break;
      case RecallRating.good:
        _goodCount++;
        break;
      case RecallRating.easy:
        _easyCount++;
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

  void _showCompletionDialog() {
    final total = _sessionCards.length;
    final durationSec = DateTime.now().difference(_sessionStartTime).inSeconds;
    StudyRepository.instance.completeStudySession(
      sessionId: _sessionId,
      cardsReviewed: total,
      correctCount: _goodCount + _easyCount,
      durationSeconds: durationSec < 1 ? 1 : durationSec,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final retention = total > 0
            ? (((_goodCount + _easyCount) / total) * 100).round()
            : 100;

        return AlertDialog(
          backgroundColor: AppColors.bgSurface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.success, size: 28),
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
                'Great work! You reviewed $total flashcards. Your recall retention for this session is $retention%.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface2,
                  borderRadius: BorderRadius.circular(12),
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
              label: 'Done',
              isExpanded: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deck.title, style: AppTypography.titleMedium),
            Text(
              'Card ${_currentIndex + 1} of ${_sessionCards.length}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FlipCardWidget(
                    card: currentCard,
                    isFlipped: _isFlipped,
                    onFlip: () {
                      setState(() {
                        _isFlipped = !_isFlipped;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!_isFlipped)
                AppButton(
                  label: 'Reveal Answer',
                  isExpanded: true,
                  icon: Icons.visibility_outlined,
                  onPressed: () {
                    setState(() {
                      _isFlipped = true;
                    });
                  },
                )
              else
                _buildRatingBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar() {
    return Row(
      children: [
        _buildRatingButton(
          rating: RecallRating.again,
          intervalText: '10m',
          color: AppColors.ratingAgain,
        ),
        const SizedBox(width: 8),
        _buildRatingButton(
          rating: RecallRating.hard,
          intervalText: '1d',
          color: AppColors.ratingHard,
        ),
        const SizedBox(width: 8),
        _buildRatingButton(
          rating: RecallRating.good,
          intervalText: '3d',
          color: AppColors.ratingGood,
        ),
        const SizedBox(width: 8),
        _buildRatingButton(
          rating: RecallRating.easy,
          intervalText: '7d',
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
      child: InkWell(
        onTap: () => _handleRating(rating),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                intervalText,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rating.label,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
