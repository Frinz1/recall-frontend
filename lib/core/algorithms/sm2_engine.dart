/// Scientific SuperMemo-2 (SM-2) Spaced Repetition Algorithm Implementation.
/// Used to calculate optimal memory retention intervals based on user recall quality.

enum RecallRating {
  again(1, 'Again', 'Forgot / Blank'),
  hard(3, 'Hard', 'Struggled'),
  good(4, 'Good', 'Correct'),
  easy(5, 'Easy', 'Instant Recall');

  final int quality;
  final String label;
  final String subtitle;

  const RecallRating(this.quality, this.label, this.subtitle);
}

enum CardMasteryStatus {
  learning('Learning'),
  reviewing('Reviewing'),
  mastered('Mastered');

  final String label;
  const CardMasteryStatus(this.label);
}

class SM2CalculationResult {
  final DateTime nextReviewDate;
  final int intervalDays;
  final int repetitions;
  final double easeFactor;
  final CardMasteryStatus status;

  const SM2CalculationResult({
    required this.nextReviewDate,
    required this.intervalDays,
    required this.repetitions,
    required this.easeFactor,
    required this.status,
  });
}

class SM2Engine {
  SM2Engine._();

  static const double minEaseFactor = 1.3;
  static const double defaultEaseFactor = 2.5;

  /// Calculates the next review interval and new ease factor using the SM-2 algorithm.
  ///
  /// - [rating]: The user's self-assessed recall quality.
  /// - [currentRepetitions]: How many consecutive successful reviews have occurred.
  /// - [currentIntervalDays]: The previous review interval in days.
  /// - [currentEaseFactor]: The difficulty multiplier (defaults to 2.5).
  static SM2CalculationResult calculateNextReview({
    required RecallRating rating,
    required int currentRepetitions,
    required int currentIntervalDays,
    required double currentEaseFactor,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final q = rating.quality;

    // 1. Calculate new Ease Factor (EF)
    // Formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    double newEaseFactor = currentEaseFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (newEaseFactor < minEaseFactor) {
      newEaseFactor = minEaseFactor;
    }

    int nextRepetitions;
    int nextIntervalDays;
    CardMasteryStatus nextStatus;

    // 2. Interval & Repetition calculation
    if (q < 3) {
      // Failed recall: reset repetitions to 0, card must be reviewed tomorrow
      nextRepetitions = 0;
      nextIntervalDays = 1;
      nextStatus = CardMasteryStatus.learning;
    } else {
      // Successful recall
      if (currentRepetitions == 0) {
        nextIntervalDays = 1;
      } else if (currentRepetitions == 1) {
        nextIntervalDays = 6;
      } else {
        nextIntervalDays = (currentIntervalDays * newEaseFactor).round();
      }

      nextRepetitions = currentRepetitions + 1;

      if (nextRepetitions >= 4 && newEaseFactor >= 2.3) {
        nextStatus = CardMasteryStatus.mastered;
      } else {
        nextStatus = CardMasteryStatus.reviewing;
      }
    }

    final nextReviewDate = now.add(Duration(days: nextIntervalDays));

    return SM2CalculationResult(
      nextReviewDate: nextReviewDate,
      intervalDays: nextIntervalDays,
      repetitions: nextRepetitions,
      easeFactor: double.parse(newEaseFactor.toStringAsFixed(2)),
      status: nextStatus,
    );
  }
}
