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
    _loadQuestion();
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
      if (!options.contains(other.answer)) {
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

    // Shuffle options
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

  void _showQuizResults() {
    final total = _quizCards.length;
    final percentage = ((_score / total) * 100).round();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfettiBurst(
        child: AlertDialog(
          backgroundColor: AppColors.bgSurface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.borderSubtle),
          ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: percentage >= 70
                    ? AppColors.successSurface
                    : AppColors.warningSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                percentage >= 70
                    ? Icons.military_tech_rounded
                    : Icons.refresh_rounded,
                color: percentage >= 70 ? AppColors.success : AppColors.warning,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Quiz Results', style: AppTypography.titleLarge),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You scored $_score out of $total ($percentage%) on ${widget.deck.title}.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _score / total,
                minHeight: 10,
                backgroundColor: AppColors.bgSurface2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 70 ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'Back to Deck',
            isExpanded: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deck.title)),
        body: const Center(child: Text('No quiz questions available.')),
      );
    }

    final currentCard = _quizCards[_currentIndex];
    final progress = (_currentIndex + 1) / _quizCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiz Mode', style: AppTypography.titleMedium),
            Text(
              'Question ${_currentIndex + 1} of ${_quizCards.length} • Score: $_score',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  currentCard.question,
                  style: AppTypography.titleLarge.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _currentOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final option = _currentOptions[idx];
                    return _buildOptionTile(idx, option);
                  },
                ),
              ),
              if (_answered) ...[
                if (currentCard.explanation.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Explanation: ${currentCard.explanation}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                AppButton(
                  label: _currentIndex < _quizCards.length - 1
                      ? 'Next Question'
                      : 'View Final Score',
                  isExpanded: true,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _nextQuestion,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(int index, String optionText) {
    Color bg = AppColors.bgSurface1;
    Color border = AppColors.borderSubtle;
    Color textColor = AppColors.textPrimary;
    IconData? trailingIcon;
    Color iconColor = Colors.transparent;

    if (_answered) {
      if (index == _correctOptionIndex) {
        bg = AppColors.successSurface;
        border = AppColors.success;
        textColor = AppColors.isDarkMode ? Colors.white : const Color(0xFF065F46);
        trailingIcon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
      } else if (index == _selectedOptionIndex) {
        bg = AppColors.dangerSurface;
        border = AppColors.danger;
        textColor = AppColors.isDarkMode ? Colors.white : const Color(0xFF991B1B);
        trailingIcon = Icons.cancel_rounded;
        iconColor = AppColors.danger;
      }
    }

    return InkWell(
      onTap: () => _selectOption(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                optionText,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: iconColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
