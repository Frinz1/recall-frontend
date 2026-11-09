import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/confetti_burst.dart';

class QuizScreen extends StatefulWidget {
  final Deck deck;

  const QuizScreen({super.key, required this.deck});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Flashcard> _quizCards;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _answered = false;
  late List<String> _currentOptions;
  late int _correctOptionIndex;

  @override
  void initState() {
    super.initState();
    _quizCards = List.from(widget.deck.cards)..shuffle(Random());
    if (_quizCards.isNotEmpty) {
      _loadQuestion();
    }
  }

  void _loadQuestion() {
    _answered = false;
    _selectedOptionIndex = null;

    final currentCard = _quizCards[_currentIndex];
    final allOtherCards = StudyRepository.instance.allCards
        .where((c) => c.id != currentCard.id)
        .toList()
      ..shuffle(Random());

    final options = <String>[currentCard.answer];
    for (final other in allOtherCards) {
      if (options.length >= 4) break;
      if (!options.contains(other.answer) && other.answer.trim().isNotEmpty) {
        options.add(other.answer);
      }
    }

    const fallbackDistractors = <String>[
      'Uses a stateless broadcast mechanism without acknowledgment or flow control.',
      'Requires O(n²) sequential traversal across unindexed heap blocks.',
      'Relies on symmetric key exchange over an unencrypted transport channel.',
      'Executes synchronously on the main thread while blocking I/O interrupts.',
      'Stores volatile state in L1 cache without write-ahead transaction logging.',
    ];
    for (final fallback in fallbackDistractors) {
      if (options.length >= 4) break;
      if (!options.contains(fallback)) {
        options.add(fallback);
      }
    }

    // Shuffle options so correct answer is at a randomized index
    options.shuffle(Random());
    _currentOptions = options;
    _correctOptionIndex = options.indexOf(currentCard.answer);
  }

  void _selectOption(int index) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
      if (index == _correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _quizCards.length - 1) {
      setState(() {
        _currentIndex++;
        _loadQuestion();
      });
    } else {
      _showQuizResults();
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _quizCards.shuffle(Random());
      _loadQuestion();
    });
  }

  void _showQuizResults() {
    final total = _quizCards.length;
    final percentage = total > 0 ? ((_score / total) * 100).round() : 0;
    final isSuccess = percentage >= 70;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfettiBurst(
        child: AlertDialog(
          backgroundColor: AppColors.bgSurface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: AppColors.borderSubtle),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.successSurface : AppColors.warningSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isSuccess ? AppColors.success : AppColors.warning).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSuccess ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                  color: isSuccess ? AppColors.success : AppColors.warning,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? 'Quiz Completed!' : 'Keep Practicing!',
                style: AppTypography.titleLarge.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '$_score of $total questions answered correctly',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACCURACY SCORE', style: AppTypography.badge.copyWith(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text('$percentage%', style: AppTypography.titleLarge.copyWith(color: isSuccess ? AppColors.success : AppColors.warning, fontSize: 24, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isSuccess ? AppColors.success : AppColors.warning).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        percentage == 100
                            ? '🏆 Flawless'
                            : (percentage >= 70 ? '⚡ Passed' : '🎯 Needs Review'),
                        style: AppTypography.badge.copyWith(
                          color: isSuccess ? AppColors.success : AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Retake',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _restartQuiz();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Back to Deck',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
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

  @override
  Widget build(BuildContext context) {
    if (_quizCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deck.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('No quiz questions available.', style: AppTypography.titleMedium),
              const SizedBox(height: 16),
              AppButton(
                label: 'Back to Deck',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final currentCard = _quizCards[_currentIndex];
    final progress = (_currentIndex + 1) / _quizCards.length;
    const optionLetters = ['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiz Mode', style: AppTypography.titleMedium),
            Text(
              '${widget.deck.title} • Score: $_score/${_quizCards.length}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.borderSubtle.withValues(alpha: 0.5),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QUESTION HERO BENTO CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'QUESTION ${_currentIndex + 1} OF ${_quizCards.length}',
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (currentCard.tags.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurface2,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${currentCard.tags.first}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            currentCard.question,
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select the correct definition or match from the choices below:',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // MULTIPLE CHOICE OPTIONS
                    Text(
                      'OPTIONS',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...List.generate(_currentOptions.length, (idx) {
                      final option = _currentOptions[idx];
                      final letter = idx < optionLetters.length ? optionLetters[idx] : '${idx + 1}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildOptionTile(idx, letter, option),
                      );
                    }),

                    // EXPLANATION CARD (WHEN ANSWERED)
                    if (_answered && currentCard.explanation.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Key Takeaway / Explanation',
                                    style: AppTypography.titleMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentCard.explanation,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ANCHORED BOTTOM CTA (APPEARS WHEN ANSWERED)
            if (_answered)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface1,
                  border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: AppButton(
                  label: _currentIndex < _quizCards.length - 1
                      ? 'Next Question'
                      : 'View Final Score',
                  isExpanded: true,
                  icon: _currentIndex < _quizCards.length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.emoji_events_rounded,
                  onPressed: _nextQuestion,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(int index, String letter, String optionText) {
    Color bg = AppColors.bgSurface1;
    Color border = AppColors.borderSubtle;
    Color textColor = AppColors.textPrimary;
    Color badgeBg = AppColors.bgSurface2;
    Color badgeText = AppColors.textSecondary;
    IconData? trailingIcon;
    Color iconColor = Colors.transparent;

    if (_answered) {
      if (index == _correctOptionIndex) {
        bg = AppColors.successSurface;
        border = AppColors.success;
        textColor = AppColors.isDarkMode ? Colors.white : const Color(0xFF065F46);
        badgeBg = AppColors.success;
        badgeText = Colors.white;
        trailingIcon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
      } else if (index == _selectedOptionIndex) {
        bg = AppColors.dangerSurface;
        border = AppColors.danger;
        textColor = AppColors.isDarkMode ? Colors.white : const Color(0xFF991B1B);
        badgeBg = AppColors.danger;
        badgeText = Colors.white;
        trailingIcon = Icons.cancel_rounded;
        iconColor = AppColors.danger;
      }
    }

    return InkWell(
      onTap: () => _selectOption(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: AppTypography.titleMedium.copyWith(
                  color: badgeText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                optionText,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: iconColor, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
