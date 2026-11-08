import 'package:flutter/foundation.dart';
import '../algorithms/sm2_engine.dart';
import '../models/flashcard_model.dart';

/// Central state and data repository for Recall.
/// Implements SM-2 execution, weak-card detection, and learning metrics.
class StudyRepository extends ChangeNotifier {
  static final StudyRepository instance = StudyRepository._internal();
  StudyRepository._internal() {
    _initializeSeedData();
  }

  final List<Subject> _subjects = [];
  final List<Deck> _decks = [];
  final List<ReviewLog> _reviewLogs = [];
  int _studyStreakDays = 5;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Deck> get decks => List.unmodifiable(_decks);
  List<ReviewLog> get reviewLogs => List.unmodifiable(_reviewLogs);
  int get studyStreakDays => _studyStreakDays;

  // -------------------------------------------------------------
  // Queries & Analytics
  // -------------------------------------------------------------

  int get totalCardsCount => _decks.fold(0, (sum, deck) => sum + deck.totalCards);

  int get totalDueCardsCount => _decks.fold(0, (sum, deck) => sum + deck.dueCardsCount);

  int get totalMasteredCardsCount =>
      _decks.fold(0, (sum, deck) => sum + deck.masteredCount);

  double get overallRetentionRate {
    if (_reviewLogs.isEmpty) return 88.5; // baseline
    final successfulReviews = _reviewLogs.where((log) =>
        log.rating == RecallRating.good || log.rating == RecallRating.easy).length;
    return (successfulReviews / _reviewLogs.length) * 100.0;
  }

  List<Flashcard> get allCards {
    final list = <Flashcard>[];
    for (final deck in _decks) {
      list.addAll(deck.cards);
    }
    return list;
  }

  List<Flashcard> get weakCards {
    return allCards.where((card) => card.isWeakCard).toList();
  }

  List<Flashcard> get dueCards {
    return allCards.where((card) => card.isDue).toList();
  }

  Deck? getDeckById(String id) {
    try {
      return _decks.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // SM-2 Review Recording
  // -------------------------------------------------------------

  void recordCardReview({
    required String deckId,
    required String cardId,
    required RecallRating rating,
  }) {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final deck = _decks[deckIndex];
    final cardIndex = deck.cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = deck.cards[cardIndex];

    // Execute SM-2 algorithm
    final result = SM2Engine.calculateNextReview(
      rating: rating,
      currentRepetitions: card.repetitions,
      currentIntervalDays: card.intervalDays,
      currentEaseFactor: card.easeFactor,
    );

    final isForgot = rating == RecallRating.again;

    final updatedCard = card.copyWith(
      repetitions: result.repetitions,
      intervalDays: result.intervalDays,
      easeFactor: result.easeFactor,
      nextReviewDate: result.nextReviewDate,
      lastReviewedDate: DateTime.now(),
      timesReviewed: card.timesReviewed + 1,
      timesForgot: isForgot ? card.timesForgot + 1 : card.timesForgot,
      masteryStatus: result.status,
    );

    final updatedCards = List<Flashcard>.from(deck.cards);
    updatedCards[cardIndex] = updatedCard;

    _decks[deckIndex] = deck.copyWith(cards: updatedCards);

    // Append to review history
    _reviewLogs.add(ReviewLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      cardId: cardId,
      deckId: deckId,
      rating: rating,
      timestamp: DateTime.now(),
    ));

    notifyListeners();
  }

  // -------------------------------------------------------------
  // Deck & Card CRUD
  // -------------------------------------------------------------

  void addDeck({
    required String title,
    required String description,
    required String subjectId,
    required int colorValue,
  }) {
    final newDeck = Deck(
      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: subjectId,
      title: title,
      description: description,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      cards: const [],
    );
    _decks.add(newDeck);
    notifyListeners();
  }

  void toggleFavoriteDeck(String deckId) {
    final index = _decks.indexWhere((d) => d.id == deckId);
    if (index != -1) {
      _decks[index] = _decks[index].copyWith(isFavorite: !_decks[index].isFavorite);
      notifyListeners();
    }
  }

  void deleteDeck(String deckId) {
    _decks.removeWhere((d) => d.id == deckId);
    notifyListeners();
  }

  void addCardToDeck({
    required String deckId,
    required String question,
    required String answer,
    required String explanation,
    required List<String> tags,
    required FlashcardType cardType,
  }) {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final newCard = Flashcard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      deckId: deckId,
      question: question,
      answer: answer,
      explanation: explanation,
      tags: tags,
      cardType: cardType,
      nextReviewDate: DateTime.now(), // Due immediately
    );

    final deck = _decks[deckIndex];
    _decks[deckIndex] = deck.copyWith(cards: [...deck.cards, newCard]);
    notifyListeners();
  }

  void deleteCard({required String deckId, required String cardId}) {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final deck = _decks[deckIndex];
    final updatedCards = deck.cards.where((c) => c.id != cardId).toList();
    _decks[deckIndex] = deck.copyWith(cards: updatedCards);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Authentic Domain Seed Data (Computer Systems & Engineering)
  // -------------------------------------------------------------

  void _initializeSeedData() {
    _subjects.addAll([
      const Subject(id: 'sub_net', name: 'Networking', colorValue: 0xFF3B82F6),
      const Subject(id: 'sub_os', name: 'Operating Systems', colorValue: 0xFFA855F7),
      const Subject(id: 'sub_db', name: 'Databases', colorValue: 0xFF10B981),
      const Subject(id: 'sub_algo', name: 'Algorithms', colorValue: 0xFFF59E0B),
    ]);

    final now = DateTime.now();

    // 1. Networking Deck
    final netCards = [
      Flashcard(
        id: 'card_net_1',
        deckId: 'deck_net',
        question: 'Explain the difference between TCP 3-Way Handshake and 4-Way Teardown.',
        answer: 'Handshake establishes reliable connection (SYN -> SYN-ACK -> ACK). Teardown gracefully closes both simplex channels (FIN -> ACK -> FIN -> ACK).',
        explanation: 'Because TCP is full-duplex, each direction must be terminated independently by sending a FIN packet.',
        tags: ['Transport Layer', 'TCP/IP', 'Protocols'],
        cardType: FlashcardType.standard,
        repetitions: 3,
        intervalDays: 6,
        easeFactor: 2.4,
        nextReviewDate: now.subtract(const Duration(hours: 4)), // Due today!
        timesReviewed: 4,
        timesForgot: 1,
        masteryStatus: CardMasteryStatus.reviewing,
      ),
      Flashcard(
        id: 'card_net_2',
        deckId: 'deck_net',
        question: 'What is CIDR Subnetting and why was it introduced to replace classful addressing?',
        answer: 'Classless Inter-Domain Routing (CIDR) uses variable-length subnet masking (/24, /27) to allocate IP addresses efficiently and reduce global BGP routing table bloat.',
        explanation: 'Classful addressing (Class A, B, C) caused massive waste because organizations were assigned entire /16 or /8 blocks regardless of real need.',
        tags: ['IP Addressing', 'Subnets', 'Routing'],
        cardType: FlashcardType.definition,
        repetitions: 1,
        intervalDays: 1,
        easeFactor: 1.7, // Weakness candidate
        nextReviewDate: now.subtract(const Duration(hours: 1)), // Due today!
        timesReviewed: 3,
        timesForgot: 2, // 66% failure rate
        masteryStatus: CardMasteryStatus.learning,
      ),
      Flashcard(
        id: 'card_net_3',
        deckId: 'deck_net',
        question: 'How does TLS 1.3 handshake improve latency over TLS 1.2?',
        answer: 'TLS 1.3 reduces the handshake to a single round-trip (1-RTT) by combining key exchange with the cipher suite negotiation in ClientHello.',
        explanation: 'It also introduces 0-RTT resumption for returning clients.',
        tags: ['Security', 'TLS/SSL', 'Encryption'],
        cardType: FlashcardType.standard,
        repetitions: 4,
        intervalDays: 14,
        easeFactor: 2.6,
        nextReviewDate: now.add(const Duration(days: 8)),
        timesReviewed: 5,
        timesForgot: 0,
        masteryStatus: CardMasteryStatus.mastered,
      ),
      Flashcard(
        id: 'card_net_4',
        deckId: 'deck_net',
        question: 'What is the purpose of the ARP (Address Resolution Protocol)?',
        answer: 'ARP resolves a known Layer 3 IPv4 address into its corresponding Layer 2 physical MAC address on a local broadcast network.',
        explanation: 'Without ARP, a host cannot build Ethernet frames to forward packets to local destinations or the default gateway.',
        tags: ['Link Layer', 'ARP', 'Ethernet'],
        cardType: FlashcardType.definition,
        repetitions: 2,
        intervalDays: 3,
        easeFactor: 2.3,
        nextReviewDate: now.add(const Duration(days: 2)),
        timesReviewed: 3,
        timesForgot: 1,
        masteryStatus: CardMasteryStatus.reviewing,
      ),
    ];

    final osCards = [
      Flashcard(
        id: 'card_os_1',
        deckId: 'deck_os',
        question: 'What are the 4 Coffman conditions required for a Deadlock to occur?',
        answer: '1. Mutual Exclusion\n2. Hold and Wait\n3. No Preemption\n4. Circular Wait',
        explanation: 'Breaking any single one of these four conditions mathematically guarantees that deadlock cannot occur.',
        tags: ['Concurrency', 'Deadlocks', 'Kernel'],
        cardType: FlashcardType.standard,
        repetitions: 1,
        intervalDays: 1,
        easeFactor: 1.6, // Weakness candidate
        nextReviewDate: now.subtract(const Duration(hours: 2)), // Due today!
        timesReviewed: 4,
        timesForgot: 3,
        masteryStatus: CardMasteryStatus.learning,
      ),
      Flashcard(
        id: 'card_os_2',
        deckId: 'deck_os',
        question: 'Compare Mutex vs. Counting Semaphore in thread synchronization.',
        answer: 'A Mutex is a locking mechanism with ownership (only the thread that locked it can unlock it). A Semaphore is a signaling mechanism without ownership.',
        explanation: 'Counting semaphores allow up to N concurrent threads access to a finite pool of shared resources.',
        tags: ['Threads', 'Synchronization', 'Primitives'],
        cardType: FlashcardType.standard,
        repetitions: 3,
        intervalDays: 7,
        easeFactor: 2.5,
        nextReviewDate: now.add(const Duration(days: 4)),
        timesReviewed: 4,
        timesForgot: 0,
        masteryStatus: CardMasteryStatus.mastered,
      ),
      Flashcard(
        id: 'card_os_3',
        deckId: 'deck_os',
        question: 'What causes Thrashing in Virtual Memory systems?',
        answer: 'Thrashing occurs when the system spends more time paging pages in/out of swap storage than executing CPU instructions due to working set overflow.',
        explanation: 'Solved by adding physical RAM or using Working Set page replacement algorithms to throttle low-priority processes.',
        tags: ['Memory Management', 'Paging', 'Virtual Memory'],
        cardType: FlashcardType.definition,
        repetitions: 2,
        intervalDays: 3,
        easeFactor: 2.2,
        nextReviewDate: now.subtract(const Duration(minutes: 30)), // Due today!
        timesReviewed: 3,
        timesForgot: 1,
        masteryStatus: CardMasteryStatus.reviewing,
      ),
    ];

    final dbCards = [
      Flashcard(
        id: 'card_db_1',
        deckId: 'deck_db',
        question: 'Define the 4 ACID properties in Database Transaction Processing.',
        answer: 'Atomicity (all-or-nothing), Consistency (preserves schema invariants), Isolation (concurrent tx execution behaves as serial), Durability (committed changes survive crashes).',
        explanation: 'Durability is typically guaranteed using Write-Ahead Logging (WAL) flushed to non-volatile disk.',
        tags: ['ACID', 'Transactions', 'RDBMS'],
        cardType: FlashcardType.definition,
        repetitions: 4,
        intervalDays: 16,
        easeFactor: 2.7,
        nextReviewDate: now.add(const Duration(days: 10)),
        timesReviewed: 5,
        timesForgot: 0,
        masteryStatus: CardMasteryStatus.mastered,
      ),
      Flashcard(
        id: 'card_db_2',
        deckId: 'deck_db',
        question: 'Why are B+ Trees preferred over Binary Search Trees for Disk-Based database indexes?',
        answer: 'B+ Trees have high fan-out (hundreds of child pointers per node), which minimizes high-latency disk I/O seeks compared to deep binary trees.',
        explanation: 'All leaf nodes are linked in a sequential doubly-linked list, making range queries (BETWEEN x AND y) extremely fast.',
        tags: ['Indexing', 'B+ Tree', 'Storage Engines'],
        cardType: FlashcardType.standard,
        repetitions: 2,
        intervalDays: 4,
        easeFactor: 2.4,
        nextReviewDate: now.subtract(const Duration(hours: 3)), // Due today!
        timesReviewed: 3,
        timesForgot: 0,
        masteryStatus: CardMasteryStatus.reviewing,
      ),
    ];

    _decks.addAll([
      Deck(
        id: 'deck_net',
        subjectId: 'sub_net',
        title: 'Computer Networking & Protocols',
        description: 'Transport layer, TCP/IP, CIDR subnetting, and TLS 1.3 protocol handshakes.',
        colorValue: 0xFF3B82F6,
        cards: netCards,
        createdAt: now.subtract(const Duration(days: 14)),
        isFavorite: true,
      ),
      Deck(
        id: 'deck_os',
        subjectId: 'sub_os',
        title: 'Operating Systems & Concurrency',
        description: 'Thread synchronization, deadlock prevention, virtual memory paging, and kernel scheduling.',
        colorValue: 0xFFA855F7,
        cards: osCards,
        createdAt: now.subtract(const Duration(days: 10)),
        isFavorite: true,
      ),
      Deck(
        id: 'deck_db',
        subjectId: 'sub_db',
        title: 'Relational Database Architecture',
        description: 'ACID transactional guarantees, WAL logging, and B+Tree indexing mechanisms.',
        colorValue: 0xFF10B981,
        cards: dbCards,
        createdAt: now.subtract(const Duration(days: 7)),
        isFavorite: false,
      ),
    ]);

    // Initial review logs for realistic historical metrics
    _reviewLogs.addAll([
      ReviewLog(id: 'l1', cardId: 'card_net_1', deckId: 'deck_net', rating: RecallRating.good, timestamp: now.subtract(const Duration(days: 3))),
      ReviewLog(id: 'l2', cardId: 'card_net_2', deckId: 'deck_net', rating: RecallRating.again, timestamp: now.subtract(const Duration(days: 2))),
      ReviewLog(id: 'l3', cardId: 'card_os_1', deckId: 'deck_os', rating: RecallRating.hard, timestamp: now.subtract(const Duration(days: 2))),
      ReviewLog(id: 'l4', cardId: 'card_os_2', deckId: 'deck_os', rating: RecallRating.easy, timestamp: now.subtract(const Duration(days: 1))),
      ReviewLog(id: 'l5', cardId: 'card_db_1', deckId: 'deck_db', rating: RecallRating.easy, timestamp: now.subtract(const Duration(hours: 12))),
    ]);
  }
}
