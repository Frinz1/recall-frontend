import '../algorithms/sm2_engine.dart';

enum FlashcardType {
  standard('Standard Concept'),
  definition('Definition / Term'),
  codeSnippet('Code / Syntax');

  final String label;
  const FlashcardType(this.label);
}

class Flashcard {
  final String id;
  final String deckId;
  final String question;
  final String answer;
  final String explanation;
  final List<String> tags;
  final FlashcardType cardType;
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
  final DateTime nextReviewDate;
  final DateTime? lastReviewedDate;
  final int timesReviewed;
  final int timesForgot;
  final CardMasteryStatus masteryStatus;

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    this.explanation = '',
    this.tags = const [],
    this.cardType = FlashcardType.standard,
    this.repetitions = 0,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    required this.nextReviewDate,
    this.lastReviewedDate,
    this.timesReviewed = 0,
    this.timesForgot = 0,
    this.masteryStatus = CardMasteryStatus.learning,
  });

  /// Check if card is due for review today or overdue
  bool get isDue {
    final now = DateTime.now();
    return nextReviewDate.isBefore(now) ||
        (nextReviewDate.year == now.year &&
            nextReviewDate.month == now.month &&
            nextReviewDate.day == now.day);
  }

  /// Calculates failure rate for weakness detection
  double get failureRate {
    if (timesReviewed == 0) return 0.0;
    return timesForgot / timesReviewed;
  }

  bool get isWeakCard => timesReviewed >= 2 && (failureRate >= 0.40 || easeFactor < 1.9);

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? question,
    String? answer,
    String? explanation,
    List<String>? tags,
    FlashcardType? cardType,
    int? repetitions,
    int? intervalDays,
    double? easeFactor,
    DateTime? nextReviewDate,
    DateTime? lastReviewedDate,
    int? timesReviewed,
    int? timesForgot,
    CardMasteryStatus? masteryStatus,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      tags: tags ?? this.tags,
      cardType: cardType ?? this.cardType,
      repetitions: repetitions ?? this.repetitions,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedDate: lastReviewedDate ?? this.lastReviewedDate,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      timesForgot: timesForgot ?? this.timesForgot,
      masteryStatus: masteryStatus ?? this.masteryStatus,
    );
  }
}

class Deck {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final int colorValue;
  final List<Flashcard> cards;
  final DateTime createdAt;
  final bool isFavorite;

  const Deck({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.colorValue,
    this.cards = const [],
    required this.createdAt,
    this.isFavorite = false,
  });

  int get totalCards => cards.length;
  int get dueCardsCount => cards.where((c) => c.isDue).length;
  int get masteredCount => cards.where((c) => c.masteryStatus == CardMasteryStatus.mastered).length;
  int get learningCount => cards.where((c) => c.masteryStatus == CardMasteryStatus.learning).length;

  double get masteryPercentage {
    if (cards.isEmpty) return 0.0;
    return (masteredCount / cards.length) * 100.0;
  }

  Deck copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    int? colorValue,
    List<Flashcard>? cards,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return Deck(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class Subject {
  final String id;
  final String name;
  final int colorValue;

  const Subject({
    required this.id,
    required this.name,
    required this.colorValue,
  });
}

class ReviewLog {
  final String id;
  final String cardId;
  final String deckId;
  final RecallRating rating;
  final DateTime timestamp;

  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.deckId,
    required this.rating,
    required this.timestamp,
  });
}
