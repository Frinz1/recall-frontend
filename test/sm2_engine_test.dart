import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/algorithms/sm2_engine.dart';

void main() {
  group('SM-2 Spaced Repetition Engine Tests', () {
    test('Initial review with Good rating (q=4) sets interval to 1 day', () {
      final result = SM2Engine.calculateNextReview(
        rating: RecallRating.good,
        currentRepetitions: 0,
        currentIntervalDays: 0,
        currentEaseFactor: 2.5,
      );

      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.status, CardMasteryStatus.reviewing);
      expect(result.easeFactor, 2.5); // (5-4) calculation
    });

    test('Second review with Good rating sets interval to 6 days', () {
      final result = SM2Engine.calculateNextReview(
        rating: RecallRating.good,
        currentRepetitions: 1,
        currentIntervalDays: 1,
        currentEaseFactor: 2.5,
      );

      expect(result.repetitions, 2);
      expect(result.intervalDays, 6);
      expect(result.status, CardMasteryStatus.reviewing);
    });

    test('Third review multiplies interval by ease factor', () {
      final result = SM2Engine.calculateNextReview(
        rating: RecallRating.easy, // q=5 increases ease factor
        currentRepetitions: 2,
        currentIntervalDays: 6,
        currentEaseFactor: 2.5,
      );

      expect(result.repetitions, 3);
      expect(result.easeFactor, greaterThan(2.5));
      expect(result.intervalDays, (6 * result.easeFactor).round());
    });

    test('Failed recall (Again, q=1) resets repetitions to 0 and interval to 1 day', () {
      final result = SM2Engine.calculateNextReview(
        rating: RecallRating.again,
        currentRepetitions: 4,
        currentIntervalDays: 20,
        currentEaseFactor: 2.5,
      );

      expect(result.repetitions, 0);
      expect(result.intervalDays, 1);
      expect(result.status, CardMasteryStatus.learning);
      expect(result.easeFactor, lessThan(2.5));
    });

    test('Ease factor never drops below minimum bound 1.3', () {
      double ef = 1.4;
      for (int i = 0; i < 5; i++) {
        final result = SM2Engine.calculateNextReview(
          rating: RecallRating.again,
          currentRepetitions: 0,
          currentIntervalDays: 1,
          currentEaseFactor: ef,
        );
        ef = result.easeFactor;
      }

      expect(ef, greaterThanOrEqualTo(1.3));
    });
  });
}
