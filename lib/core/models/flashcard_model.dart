import '../algorithms/sm2_engine.dart';

enum FlashcardType {
  standard('Standard Concept'),
  definition('Definition / Term'),
  codeSnippet('Code / Syntax');

  final String label;
  const FlashcardType(this.label);

  static FlashcardType fromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'definition':
        return FlashcardType.definition;
      case 'codesnippet':
      case 'code_snippet':
      case 'code':
        return FlashcardType.codeSnippet;
      case 'standard':
      default:
        return FlashcardType.standard;
    }
  }
}

int parseHexColor(String? hex, {int fallback = 0xFF6366F1}) {
  if (hex == null || hex.trim().isEmpty) return fallback;
  final cleaned = hex.replaceAll('#', '').replaceAll('0x', '').trim();
  if (cleaned.length == 6) {
    return int.tryParse('FF$cleaned', radix: 16) ?? fallback;
  }
  if (cleaned.length == 8) {
    return int.tryParse(cleaned, radix: 16) ?? fallback;
  }
  return fallback;
}

String toHexColorString(int colorValue) {
  final rgb = colorValue & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

CardMasteryStatus parseMasteryStatus(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'mastered':
      return CardMasteryStatus.mastered;
    case 'reviewing':
      return CardMasteryStatus.reviewing;
    case 'learning':
    default:
      return CardMasteryStatus.learning;
  }
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

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final parsedTags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];

    return Flashcard(
      id: json['id']?.toString() ?? '',
      deckId: json['deckId']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      tags: parsedTags,
      cardType: FlashcardType.fromString(json['cardType']?.toString()),
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate: json['nextReviewDate'] != null
          ? DateTime.tryParse(json['nextReviewDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastReviewedDate: json['lastReviewedDate'] != null
          ? DateTime.tryParse(json['lastReviewedDate'].toString())
          : null,
      timesReviewed: (json['timesReviewed'] as num?)?.toInt() ?? 0,
      timesForgot: (json['timesForgot'] as num?)?.toInt() ?? 0,
      masteryStatus: parseMasteryStatus(json['masteryStatus']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'explanation': explanation,
      'tags': tags,
      'cardType': cardType.name,
      'repetitions': repetitions,
      'intervalDays': intervalDays,
      'easeFactor': easeFactor,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'lastReviewedDate': lastReviewedDate?.toIso8601String(),
      'timesReviewed': timesReviewed,
      'timesForgot': timesForgot,
      'masteryStatus': masteryStatus.name,
    };
  }

  /// True when the card is newly created and has never been studied yet
  bool get isNewCard => timesReviewed == 0;

  /// Check if card is due for review today or overdue (includes new cards ready for initial learning)
  bool get isDue {
    final now = DateTime.now();
    return nextReviewDate.isBefore(now) ||
        (nextReviewDate.year == now.year &&
            nextReviewDate.month == now.month &&
            nextReviewDate.day == now.day);
  }

  /// True only for previously studied cards whose SM-2 review interval is due today
  bool get isScheduledDue => timesReviewed > 0 && isDue;

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

  factory Deck.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    final parsedCards = rawCards is List
        ? rawCards
            .whereType<Map>()
            .map((c) => Flashcard.fromJson(Map<String, dynamic>.from(c)))
            .toList()
        : <Flashcard>[];

    final subjectMap = json['subject'];
    final resolvedSubjectId = json['subjectId']?.toString() ??
        (subjectMap is Map ? subjectMap['id']?.toString() : null) ??
        '';

    final colorVal = json['colorValue'] is int
        ? json['colorValue'] as int
        : parseHexColor(json['colorHex']?.toString());

    return Deck(
      id: json['id']?.toString() ?? '',
      subjectId: resolvedSubjectId,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      colorValue: colorVal,
      cards: parsedCards,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFavorite: json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'colorHex': toHexColorString(colorValue),
      'colorValue': colorValue,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }

  int get totalCards => cards.length;
  int get newCardsCount => cards.where((c) => c.isNewCard).length;
  int get scheduledDueCount => cards.where((c) => c.isScheduledDue).length;
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

  factory Subject.fromJson(Map<String, dynamic> json) {
    final colorVal = json['colorValue'] is int
        ? json['colorValue'] as int
        : parseHexColor(json['colorHex']?.toString());
    return Subject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      colorValue: colorVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': toHexColorString(colorValue),
      'colorValue': colorValue,
    };
  }
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
