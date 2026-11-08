import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../algorithms/sm2_engine.dart';
import '../models/flashcard_model.dart';
import '../network/api_client.dart';

/// Central state and cloud-synced data repository for Recall.
/// Implements SM-2 execution, weak-card detection, local JSON caching, and cloud API synchronization.
class StudyRepository extends ChangeNotifier {
  static final StudyRepository instance = StudyRepository._internal();
  StudyRepository._internal() {
    _initializeSeedData();
  }

  static const String _cacheSubjectsKey = 'recall_cached_subjects_v1';
  static const String _cacheDecksKey = 'recall_cached_decks_v1';
  static const String _cacheRetentionKey = 'recall_cached_retention_v1';

  final List<Subject> _subjects = [];
  final List<Deck> _decks = [];
  final List<ReviewLog> _reviewLogs = [];
  final int _studyStreakDays = 5;
  double? _cloudRetentionRate;
  bool _isSyncing = false;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Deck> get decks => List.unmodifiable(_decks);
  List<ReviewLog> get reviewLogs => List.unmodifiable(_reviewLogs);
  int get studyStreakDays => _studyStreakDays;
  bool get isSyncing => _isSyncing;

  // -------------------------------------------------------------
  // Local Disk Cache (SharedPreferences) & Cloud Synchronization
  // -------------------------------------------------------------

  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectsJson = prefs.getString(_cacheSubjectsKey);
      final decksJson = prefs.getString(_cacheDecksKey);
      final cachedRetention = prefs.getDouble(_cacheRetentionKey);

      if (cachedRetention != null) {
        _cloudRetentionRate = cachedRetention;
      }

      if (subjectsJson != null && subjectsJson.isNotEmpty) {
        final decoded = jsonDecode(subjectsJson);
        if (decoded is List && decoded.isNotEmpty) {
          _subjects
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((s) => Subject.fromJson(Map<String, dynamic>.from(s))),
            );
        }
      }

      if (decksJson != null && decksJson.isNotEmpty) {
        final decoded = jsonDecode(decksJson);
        if (decoded is List && decoded.isNotEmpty) {
          _decks
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((d) => Deck.fromJson(Map<String, dynamic>.from(d))),
            );
        }
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectsJson = jsonEncode(_subjects.map((s) => s.toJson()).toList());
      final decksJson = jsonEncode(_decks.map((d) => d.toJson()).toList());
      await prefs.setString(_cacheSubjectsKey, subjectsJson);
      await prefs.setString(_cacheDecksKey, decksJson);
      if (_cloudRetentionRate != null) {
        await prefs.setDouble(_cacheRetentionKey, _cloudRetentionRate!);
      }
    } catch (_) {}
  }

  Future<void> clearLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheSubjectsKey);
      await prefs.remove(_cacheDecksKey);
      await prefs.remove(_cacheRetentionKey);
    } catch (_) {}
    _subjects.clear();
    _decks.clear();
    _reviewLogs.clear();
    _cloudRetentionRate = null;
    _initializeSeedData();
    notifyListeners();
  }

  Future<void> fetchAllFromCloud() async {
    if (!ApiClient.instance.isAuthenticated) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiClient.instance.get('/subjects'),
        ApiClient.instance.get('/decks'),
        ApiClient.instance.get('/analytics/overview'),
      ]);

      final subjectsRes = results[0];
      final decksRes = results[1];
      final analyticsRes = results[2];

      if (subjectsRes.success && subjectsRes.data is List) {
        final remoteSubjects = (subjectsRes.data as List)
            .whereType<Map>()
            .map((s) => Subject.fromJson(Map<String, dynamic>.from(s)))
            .toList();
        if (remoteSubjects.isNotEmpty) {
          _subjects
            ..clear()
            ..addAll(remoteSubjects);
        }
      }

      if (decksRes.success && decksRes.data is List) {
        final rawList = (decksRes.data as List).whereType<Map>().toList();
        final loadedDecks = <Deck>[];

        for (final rawDeck in rawList) {
          final deckMap = Map<String, dynamic>.from(rawDeck);
          // If the deck list response already contains full card objects, parse directly;
          // otherwise fetch full deck detail via GET /decks/:id
          final cardsField = deckMap['cards'];
          final hasFullCards = cardsField is List &&
              (cardsField.isEmpty ||
                  (cardsField.first is Map && (cardsField.first as Map).containsKey('question')));

          if (hasFullCards) {
            loadedDecks.add(Deck.fromJson(deckMap));
          } else {
            final deckId = deckMap['id']?.toString() ?? '';
            if (deckId.isNotEmpty) {
              final detailRes = await ApiClient.instance.get('/decks/$deckId');
              if (detailRes.success && detailRes.data is Map) {
                loadedDecks.add(Deck.fromJson(Map<String, dynamic>.from(detailRes.data as Map)));
              } else {
                loadedDecks.add(Deck.fromJson(deckMap));
              }
            }
          }
        }

        if (loadedDecks.isNotEmpty) {
          _decks
            ..clear()
            ..addAll(loadedDecks);
        }
      }

      if (analyticsRes.success && analyticsRes.data is Map) {
        final metrics = (analyticsRes.data as Map)['metrics'];
        if (metrics is Map && metrics['retentionRate'] is num) {
          _cloudRetentionRate = (metrics['retentionRate'] as num).toDouble();
        }
      }

      await _saveToCache();
    } catch (_) {
      // Retain cached/existing state on transient network glitch
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // Queries & Analytics
  // -------------------------------------------------------------

  int get totalCardsCount => _decks.fold(0, (sum, deck) => sum + deck.totalCards);

  int get totalDueCardsCount => _decks.fold(0, (sum, deck) => sum + deck.dueCardsCount);

  int get totalMasteredCardsCount =>
      _decks.fold(0, (sum, deck) => sum + deck.masteredCount);

  double get overallRetentionRate {
    if (_reviewLogs.isNotEmpty) {
      final successfulReviews = _reviewLogs
          .where((log) => log.rating == RecallRating.good || log.rating == RecallRating.easy)
          .length;
      return (successfulReviews / _reviewLogs.length) * 100.0;
    }
    return _cloudRetentionRate ?? 88.5;
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
  // Subject CRUD (Cloud + Local Cache)
  // -------------------------------------------------------------

  Future<bool> addSubject({
    required String name,
    required int colorValue,
  }) async {
    final tempId = 'sub_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Subject(id: tempId, name: name, colorValue: colorValue);
    _subjects.insert(0, optimistic);
    notifyListeners();

    if (ApiClient.instance.isAuthenticated) {
      final res = await ApiClient.instance.post('/subjects', {
        'name': name,
        'colorHex': toHexColorString(colorValue),
      });
      if (res.success && res.data is Map) {
        final created = Subject.fromJson(Map<String, dynamic>.from(res.data as Map));
        final idx = _subjects.indexWhere((s) => s.id == tempId);
        if (idx != -1) {
          _subjects[idx] = created;
        }
        await _saveToCache();
        notifyListeners();
        return true;
      }
    }

    await _saveToCache();
    return true;
  }

  Future<void> deleteSubject(String subjectId) async {
    _subjects.removeWhere((s) => s.id == subjectId);
    _decks.removeWhere((d) => d.subjectId == subjectId);
    notifyListeners();

    if (ApiClient.instance.isAuthenticated) {
      await ApiClient.instance.delete('/subjects/$subjectId');
    }
    await _saveToCache();
  }

  // -------------------------------------------------------------
  // SM-2 Review Recording & Study Sessions (Cloud + Local Cache)
  // -------------------------------------------------------------

  Future<void> recordCardReview({
    required String deckId,
    required String cardId,
    required RecallRating rating,
  }) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final deck = _decks[deckIndex];
    final cardIndex = deck.cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = deck.cards[cardIndex];

    // Execute local SM-2 algorithm immediately for zero-latency UI
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

    _reviewLogs.add(ReviewLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      cardId: cardId,
      deckId: deckId,
      rating: rating,
      timestamp: DateTime.now(),
    ));

    notifyListeners();
    await _saveToCache();

    // Sync review to cloud backend (/api/v1/reviews)
    if (ApiClient.instance.isAuthenticated && !cardId.startsWith('card_')) {
      final res = await ApiClient.instance.post('/reviews', {
        'cardId': cardId,
        'rating': rating.name,
      });
      if (res.success && res.data is Map) {
        final remoteCardMap = (res.data as Map)['card'];
        if (remoteCardMap is Map) {
          final syncedCard = Flashcard.fromJson(Map<String, dynamic>.from(remoteCardMap));
          final dIdx = _decks.indexWhere((d) => d.id == deckId);
          if (dIdx != -1) {
            final cIdx = _decks[dIdx].cards.indexWhere((c) => c.id == cardId);
            if (cIdx != -1) {
              final list = List<Flashcard>.from(_decks[dIdx].cards);
              list[cIdx] = syncedCard;
              _decks[dIdx] = _decks[dIdx].copyWith(cards: list);
              await _saveToCache();
              notifyListeners();
            }
          }
        }
      }
    }
  }

  Future<String?> startStudySession(String deckId) async {
    if (!ApiClient.instance.isAuthenticated || deckId.startsWith('deck_')) {
      return null;
    }
    final res = await ApiClient.instance.post('/study-sessions', {
      'deckId': deckId,
    });
    if (res.success && res.data is Map) {
      return (res.data as Map)['id']?.toString();
    }
    return null;
  }

  Future<void> completeStudySession({
    required String? sessionId,
    required int cardsReviewed,
    required int correctCount,
    required int durationSeconds,
  }) async {
    if (sessionId == null || !ApiClient.instance.isAuthenticated) return;
    await ApiClient.instance.patch('/study-sessions/$sessionId/complete', {
      'cardsReviewed': cardsReviewed,
      'correctCount': correctCount,
      'durationSeconds': durationSeconds,
    });
  }

  // -------------------------------------------------------------
  // Deck & Card CRUD (Cloud + Local Cache)
  // -------------------------------------------------------------

  Future<void> addDeck({
    required String title,
    required String description,
    required String subjectId,
    required int colorValue,
  }) async {
    final tempId = 'deck_${DateTime.now().millisecondsSinceEpoch}';
    final newDeck = Deck(
      id: tempId,
      subjectId: subjectId,
      title: title,
      description: description,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      cards: const [],
    );
    _decks.insert(0, newDeck);
    notifyListeners();

    if (ApiClient.instance.isAuthenticated) {
      final payload = <String, dynamic>{
        'title': title,
        'description': description,
        'colorHex': toHexColorString(colorValue),
      };
      if (!subjectId.startsWith('sub_')) {
        payload['subjectId'] = subjectId;
      }

      final res = await ApiClient.instance.post('/decks', payload);
      if (res.success && res.data is Map) {
        final created = Deck.fromJson(Map<String, dynamic>.from(res.data as Map));
        final idx = _decks.indexWhere((d) => d.id == tempId);
        if (idx != -1) {
          _decks[idx] = created;
        }
      }
    }

    await _saveToCache();
    notifyListeners();
  }

  Future<void> toggleFavoriteDeck(String deckId) async {
    final index = _decks.indexWhere((d) => d.id == deckId);
    if (index != -1) {
      _decks[index] = _decks[index].copyWith(isFavorite: !_decks[index].isFavorite);
      notifyListeners();
      await _saveToCache();

      if (ApiClient.instance.isAuthenticated && !deckId.startsWith('deck_')) {
        await ApiClient.instance.patch('/decks/$deckId/favorite', {});
      }
    }
  }

  Future<void> deleteDeck(String deckId) async {
    _decks.removeWhere((d) => d.id == deckId);
    notifyListeners();
    await _saveToCache();

    if (ApiClient.instance.isAuthenticated && !deckId.startsWith('deck_')) {
      await ApiClient.instance.delete('/decks/$deckId');
    }
  }

  Future<void> addCardToDeck({
    required String deckId,
    required String question,
    required String answer,
    required String explanation,
    required List<String> tags,
    required FlashcardType cardType,
  }) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final tempId = 'card_${DateTime.now().millisecondsSinceEpoch}';
    final newCard = Flashcard(
      id: tempId,
      deckId: deckId,
      question: question,
      answer: answer,
      explanation: explanation,
      tags: tags,
      cardType: cardType,
      nextReviewDate: DateTime.now(),
    );

    final deck = _decks[deckIndex];
    _decks[deckIndex] = deck.copyWith(cards: [...deck.cards, newCard]);
    notifyListeners();

    if (ApiClient.instance.isAuthenticated && !deckId.startsWith('deck_')) {
      final res = await ApiClient.instance.post('/cards', {
        'deckId': deckId,
        'question': question,
        'answer': answer,
        'explanation': explanation,
        'tags': tags,
        'cardType': cardType.name,
      });

      if (res.success && res.data is Map) {
        final createdCard = Flashcard.fromJson(Map<String, dynamic>.from(res.data as Map));
        final dIdx = _decks.indexWhere((d) => d.id == deckId);
        if (dIdx != -1) {
          final updatedList = _decks[dIdx]
              .cards
              .map((c) => c.id == tempId ? createdCard : c)
              .toList();
          _decks[dIdx] = _decks[dIdx].copyWith(cards: updatedList);
        }
      }
    }

    await _saveToCache();
    notifyListeners();
  }

  Future<void> deleteCard({required String deckId, required String cardId}) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final deck = _decks[deckIndex];
    final updatedCards = deck.cards.where((c) => c.id != cardId).toList();
    _decks[deckIndex] = deck.copyWith(cards: updatedCards);
    notifyListeners();
    await _saveToCache();

    if (ApiClient.instance.isAuthenticated && !cardId.startsWith('card_')) {
      await ApiClient.instance.delete('/cards/$cardId');
    }
  }

  // -------------------------------------------------------------
  // Authentic Domain Seed Data (Fallback before first cloud sync)
  // -------------------------------------------------------------

  void _initializeSeedData() {
    _subjects.addAll([
      const Subject(id: 'sub_net', name: 'Networking', colorValue: 0xFF3B82F6),
      const Subject(id: 'sub_os', name: 'Operating Systems', colorValue: 0xFFA855F7),
      const Subject(id: 'sub_db', name: 'Databases', colorValue: 0xFF10B981),
      const Subject(id: 'sub_algo', name: 'Algorithms', colorValue: 0xFFF59E0B),
    ]);

    final now = DateTime.now();

    final netCards = [
      Flashcard(
        id: 'card_net_1',
        deckId: 'deck_net',
        question: 'Explain the difference between TCP 3-Way Handshake and 4-Way Teardown.',
        answer:
            'Handshake establishes reliable connection (SYN -> SYN-ACK -> ACK). Teardown gracefully closes both simplex channels (FIN -> ACK -> FIN -> ACK).',
        explanation:
            'Because TCP is full-duplex, each direction must be terminated independently by sending a FIN packet.',
        tags: ['Transport Layer', 'TCP/IP', 'Protocols'],
        cardType: FlashcardType.standard,
        repetitions: 3,
        intervalDays: 6,
        easeFactor: 2.4,
        nextReviewDate: now.subtract(const Duration(hours: 4)),
        timesReviewed: 4,
        timesForgot: 1,
        masteryStatus: CardMasteryStatus.reviewing,
      ),
      Flashcard(
        id: 'card_net_2',
        deckId: 'deck_net',
        question: 'What is CIDR Subnetting and why was it introduced to replace classful addressing?',
        answer:
            'Classless Inter-Domain Routing (CIDR) uses variable-length subnet masking (/24, /27) to allocate IP addresses efficiently and reduce global BGP routing table bloat.',
        explanation:
            'Classful addressing (Class A, B, C) caused massive waste because organizations were assigned entire /16 or /8 blocks regardless of real need.',
        tags: ['IP Addressing', 'Subnets', 'Routing'],
        cardType: FlashcardType.definition,
        repetitions: 1,
        intervalDays: 1,
        easeFactor: 1.7,
        nextReviewDate: now.subtract(const Duration(hours: 1)),
        timesReviewed: 3,
        timesForgot: 2,
        masteryStatus: CardMasteryStatus.learning,
      ),
      Flashcard(
        id: 'card_net_3',
        deckId: 'deck_net',
        question: 'How does TLS 1.3 handshake improve latency over TLS 1.2?',
        answer:
            'TLS 1.3 reduces the handshake to a single round-trip (1-RTT) by combining key exchange with the cipher suite negotiation in ClientHello.',
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
        answer:
            'ARP resolves a known Layer 3 IPv4 address into its corresponding Layer 2 physical MAC address on a local broadcast network.',
        explanation:
            'Without ARP, a host cannot build Ethernet frames to forward packets to local destinations or the default gateway.',
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
        explanation:
            'Breaking any single one of these four conditions mathematically guarantees that deadlock cannot occur.',
        tags: ['Concurrency', 'Deadlocks', 'Kernel'],
        cardType: FlashcardType.standard,
        repetitions: 1,
        intervalDays: 1,
        easeFactor: 1.6,
        nextReviewDate: now.subtract(const Duration(hours: 2)),
        timesReviewed: 4,
        timesForgot: 3,
        masteryStatus: CardMasteryStatus.learning,
      ),
      Flashcard(
        id: 'card_os_2',
        deckId: 'deck_os',
        question: 'Compare Mutex vs. Counting Semaphore in thread synchronization.',
        answer:
            'A Mutex is a locking mechanism with ownership (only the thread that locked it can unlock it). A Semaphore is a signaling mechanism without ownership.',
        explanation:
            'Counting semaphores allow up to N concurrent threads access to a finite pool of shared resources.',
        tags: ['Threads', 'Synchronization', 'Primitives'],
        cardType: FlashcardType.standard,
        repetitions: 3,
        intervalDays: 7,
        easeFactor: 2.5,
        nextReviewDate: now.add(const Duration(days: 5)),
        timesReviewed: 3,
        timesForgot: 0,
        masteryStatus: CardMasteryStatus.mastered,
      ),
      Flashcard(
        id: 'card_os_3',
        deckId: 'deck_os',
        question: 'What is a Translation Lookaside Buffer (TLB) and why is TLB Hit Ratio critical?',
        answer:
            'The TLB is a hardware associative cache inside the MMU storing recent virtual-to-physical page table translations.',
        explanation:
            'A TLB miss requires walking multi-level page tables in main RAM, doubling or quadrupling memory access latency.',
        tags: ['Virtual Memory', 'MMU', 'Hardware'],
        cardType: FlashcardType.definition,
        repetitions: 0,
        intervalDays: 0,
        easeFactor: 2.5,
        nextReviewDate: now.subtract(const Duration(minutes: 30)),
        timesReviewed: 2,
        timesForgot: 1,
        masteryStatus: CardMasteryStatus.learning,
      ),
    ];

    final dbCards = [
      Flashcard(
        id: 'card_db_1',
        deckId: 'deck_db',
        question: 'Define the 4 ACID properties of database transactions.',
        answer:
            'Atomicity (all-or-nothing), Consistency (valid state invariants), Isolation (concurrent serializability), Durability (WAL persistence after commit).',
        explanation: 'Write-Ahead Logging (WAL) ensures Atomicity and Durability across power failures.',
        tags: ['Transactions', 'ACID', 'SQL'],
        cardType: FlashcardType.standard,
        repetitions: 5,
        intervalDays: 21,
        easeFactor: 2.7,
        nextReviewDate: now.add(const Duration(days: 15)),
        timesReviewed: 5,
        timesForgot: 0,
        masteryStatus: CardMasteryStatus.mastered,
      ),
      Flashcard(
        id: 'card_db_2',
        deckId: 'deck_db',
        question: 'Why do relational databases prefer B+Trees over Binary Search Trees for disk indexes?',
        answer:
            'B+Trees have a high fan-out (hundreds of keys per 4KB/16KB page), minimizing tree height and disk I/O seeks, and link leaf nodes sequentially for fast range scans.',
        explanation: 'All data pointers reside strictly in the leaf nodes of a B+Tree.',
        tags: ['Indexing', 'B+Tree', 'Storage Engine'],
        cardType: FlashcardType.standard,
        repetitions: 1,
        intervalDays: 1,
        easeFactor: 1.75,
        nextReviewDate: now.subtract(const Duration(hours: 3)),
        timesReviewed: 3,
        timesForgot: 2,
        masteryStatus: CardMasteryStatus.learning,
      ),
    ];

    _decks.addAll([
      Deck(
        id: 'deck_net',
        subjectId: 'sub_net',
        title: 'TCP/IP & Routing Architecture',
        description: 'Transport layer handshakes, CIDR subnetting, ARP, and TLS 1.3.',
        colorValue: 0xFF3B82F6,
        cards: netCards,
        createdAt: now.subtract(const Duration(days: 12)),
        isFavorite: true,
      ),
      Deck(
        id: 'deck_os',
        subjectId: 'sub_os',
        title: 'Kernel & Concurrency Primitives',
        description: 'Deadlocks, synchronization locks, virtual memory paging, and TLB caching.',
        colorValue: 0xFFA855F7,
        cards: osCards,
        createdAt: now.subtract(const Duration(days: 9)),
        isFavorite: true,
      ),
      Deck(
        id: 'deck_db',
        subjectId: 'sub_db',
        title: 'Database Internals & Indexing',
        description: 'ACID isolation levels, B+Tree storage engines, and WAL recovery.',
        colorValue: 0xFF10B981,
        cards: dbCards,
        createdAt: now.subtract(const Duration(days: 6)),
        isFavorite: false,
      ),
    ]);
  }
}
