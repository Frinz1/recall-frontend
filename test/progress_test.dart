import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/algorithms/sm2_engine.dart';
import 'package:recall/core/models/flashcard_model.dart';

Flashcard _card(String id, {int timesReviewed = 0, CardMasteryStatus status = CardMasteryStatus.learning}) {
  return Flashcard(
    id: id,
    deckId: 'deck_net',
    question: 'What does the TCP three-way handshake establish?',
    answer: 'A synchronized, reliable connection (SYN, SYN-ACK, ACK).',
    explanation: '',
    tags: const ['Networking'],
    nextReviewDate: DateTime.now(),
    timesReviewed: timesReviewed,
    masteryStatus: status,
  );
}

Deck _deck(List<Flashcard> cards) => Deck(
      id: 'deck_net',
      subjectId: 'sub_net',
      title: 'Computer Networks',
      description: 'Transport layer fundamentals',
      colorValue: 0xFF6366F1,
      cards: cards,
      createdAt: DateTime.now(),
    );

void main() {
  test('A brand-new or freshly reset deck shows 0% progress', () {
    final deck = _deck([_card('a'), _card('b'), _card('c'), _card('d')]);
    expect(deck.learningCount, 0);
    expect(deck.graduatedProgressPercentage, 0);
  });

  test('Only studied cards sent back by "Again" count as Learning (25%)', () {
    final deck = _deck([
      _card('a', timesReviewed: 3, status: CardMasteryStatus.learning),
      _card('b'),
      _card('c'),
      _card('d'),
    ]);
    expect(deck.learningCount, 1);
    expect(deck.graduatedProgressPercentage.round(), 6); // 0.25 / 4
  });

  test('Legacy intervals beyond 180 days are capped on load, including the due date', () {
    final lastReviewed = DateTime.utc(2026, 11, 9);
    final card = Flashcard.fromJson({
      'id': 'c1',
      'deckId': 'deck_net',
      'question': 'B+Tree fan-out',
      'answer': 'Number of child pointers per internal node',
      'intervalDays': 3014,
      'lastReviewedDate': lastReviewed.toIso8601String(),
      'nextReviewDate': DateTime.utc(2034, 12, 1).toIso8601String(),
      'timesReviewed': 14,
      'masteryStatus': 'mastered',
    });
    expect(card.intervalDays, 180);
    expect(card.nextReviewDate.difference(lastReviewed.toLocal()).inDays, 180);
  });
}
