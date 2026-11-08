import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../algorithms/sm2_engine.dart';
import '../models/flashcard_model.dart';
import '../network/api_client.dart';

/// Central state and cloud-synced data repository for Recall.
/// Implements SM-2 execution, weak-card detection, per-user local caching, and cloud API synchronization.
/// Starts with 0 subjects, 0 decks, 0 cards for fresh accounts.
class StudyRepository extends ChangeNotifier {
  static final StudyRepository instance = StudyRepository._internal();
  StudyRepository._internal();

  String? _activeUserId;
  final List<Subject> _subjects = [];
  final List<Deck> _decks = [];
  final List<ReviewLog> _reviewLogs = [];
  int _studyStreakDays = 0;
  double _cloudRetentionRate = 0.0;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;

  // User Study Preferences
  int _dailyGoalCards = 20;
  bool _shuffleStudyCards = false;
  bool _includeNewInDue = true;

  List<Subject> get subjects => List.unmodifiable(_subjects);

  /// Starred (isFavorite) decks are automatically pinned to the top
  List<Deck> get decks {
    final sorted = List<Deck>.from(_decks);
    sorted.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return List.unmodifiable(sorted);
  }

  List<ReviewLog> get reviewLogs => List.unmodifiable(_reviewLogs);
  int get studyStreakDays => _studyStreakDays;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  int get dailyGoalCards => _dailyGoalCards;
  bool get shuffleStudyCards => _shuffleStudyCards;
  bool get includeNewInDue => _includeNewInDue;

  String get _subjectsCacheKey => 'recall_subjects_v2_${_activeUserId ?? "guest"}';
  String get _decksCacheKey => 'recall_decks_v2_${_activeUserId ?? "guest"}';
  String get _retentionCacheKey => 'recall_retention_v2_${_activeUserId ?? "guest"}';
  String get _streakCacheKey => 'recall_streak_v2_${_activeUserId ?? "guest"}';
  String get _goalCacheKey => 'recall_goal_v2_${_activeUserId ?? "guest"}';
  String get _shuffleCacheKey => 'recall_shuffle_v2_${_activeUserId ?? "guest"}';
  String get _includeNewCacheKey => 'recall_inc_new_v2_${_activeUserId ?? "guest"}';

  void setActiveUser(String? userId) {
    if (_activeUserId != userId) {
      _activeUserId = userId;
      _subjects.clear();
      _decks.clear();
      _reviewLogs.clear();
      _studyStreakDays = 0;
      _cloudRetentionRate = 0.0;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // Per-User Local Disk Cache (SharedPreferences) & Cloud Sync
  // -------------------------------------------------------------

  Future<void> loadFromCache({String? userId}) async {
    if (userId != null) {
      setActiveUser(userId);
    }
    if (_activeUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectsJson = prefs.getString(_subjectsCacheKey);
      final decksJson = prefs.getString(_decksCacheKey);
      final cachedRetention = prefs.getDouble(_retentionCacheKey);
      final cachedStreak = prefs.getInt(_streakCacheKey);

      _cloudRetentionRate = cachedRetention ?? 0.0;
      _studyStreakDays = cachedStreak ?? 0;
      _dailyGoalCards = prefs.getInt(_goalCacheKey) ?? 20;
      _shuffleStudyCards = prefs.getBool(_shuffleCacheKey) ?? false;
      _includeNewInDue = prefs.getBool(_includeNewCacheKey) ?? true;

      _subjects.clear();
      if (subjectsJson != null && subjectsJson.isNotEmpty) {
        final decoded = jsonDecode(subjectsJson);
        if (decoded is List) {
          _subjects.addAll(
            decoded
                .whereType<Map>()
                .map((s) => Subject.fromJson(Map<String, dynamic>.from(s))),
          );
        }
      }

      _decks.clear();
      if (decksJson != null && decksJson.isNotEmpty) {
        final decoded = jsonDecode(decksJson);
        if (decoded is List) {
          _decks.addAll(
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
    if (_activeUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectsJson = jsonEncode(_subjects.map((s) => s.toJson()).toList());
      final decksJson = jsonEncode(_decks.map((d) => d.toJson()).toList());
      await prefs.setString(_subjectsCacheKey, subjectsJson);
      await prefs.setString(_decksCacheKey, decksJson);
      await prefs.setDouble(_retentionCacheKey, _cloudRetentionRate);
      await prefs.setInt(_streakCacheKey, _studyStreakDays);
      await prefs.setInt(_goalCacheKey, _dailyGoalCards);
      await prefs.setBool(_shuffleCacheKey, _shuffleStudyCards);
      await prefs.setBool(_includeNewCacheKey, _includeNewInDue);
    } catch (_) {}
  }

  Future<void> setDailyGoalCards(int goal) async {
    _dailyGoalCards = goal.clamp(5, 200);
    notifyListeners();
    await _saveToCache();
  }

  Future<void> setShuffleStudyCards(bool value) async {
    _shuffleStudyCards = value;
    notifyListeners();
    await _saveToCache();
  }

  Future<void> setIncludeNewInDue(bool value) async {
    _includeNewInDue = value;
    notifyListeners();
    await _saveToCache();
  }

  Future<void> clearLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeUserId != null) {
        await prefs.remove(_subjectsCacheKey);
        await prefs.remove(_decksCacheKey);
        await prefs.remove(_retentionCacheKey);
        await prefs.remove(_streakCacheKey);
      }
      // Also remove legacy global cache keys so old data never resurfaces
      await prefs.remove('recall_cached_subjects_v1');
      await prefs.remove('recall_cached_decks_v1');
      await prefs.remove('recall_cached_retention_v1');
    } catch (_) {}

    _activeUserId = null;
    _subjects.clear();
    _decks.clear();
    _reviewLogs.clear();
    _studyStreakDays = 0;
    _cloudRetentionRate = 0.0;
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
        _subjects
          ..clear()
          ..addAll(remoteSubjects);
      }

      if (decksRes.success && decksRes.data is List) {
        final rawList = (decksRes.data as List).whereType<Map>().toList();
        final loadedDecks = <Deck>[];

        for (final rawDeck in rawList) {
          final deckMap = Map<String, dynamic>.from(rawDeck);
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

        _decks
          ..clear()
          ..addAll(loadedDecks);
      }

      if (analyticsRes.success && analyticsRes.data is Map) {
        final metrics = (analyticsRes.data as Map)['metrics'];
        if (metrics is Map) {
          if (metrics['retentionRate'] is num) {
            _cloudRetentionRate = (metrics['retentionRate'] as num).toDouble();
          }
          if (metrics['streakDays'] is num) {
            _studyStreakDays = (metrics['streakDays'] as num).toInt();
          }
        }
      } else if (_decks.isEmpty) {
        _cloudRetentionRate = 0.0;
        _studyStreakDays = 0;
      }

      _lastSyncedAt = DateTime.now();
      await _saveToCache();
    } catch (_) {
      // Keep current user's cached state on transient network glitch
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // Queries & Analytics
  // -------------------------------------------------------------

  int get totalCardsCount => _decks.fold(0, (sum, deck) => sum + deck.totalCards);

  int get totalNewCardsCount => _decks.fold(0, (sum, deck) => sum + deck.newCardsCount);

  int get totalScheduledDueCount =>
      _decks.fold(0, (sum, deck) => sum + deck.scheduledDueCount);

  int get totalDueCardsCount => _includeNewInDue
      ? _decks.fold(0, (sum, deck) => sum + deck.dueCardsCount)
      : totalScheduledDueCount;

  int get reviewedTodayCount {
    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    final fromLogs = _reviewLogs.where((r) => isToday(r.timestamp)).map((r) => r.cardId).toSet();
    final fromCards = allCards
        .where((c) => c.lastReviewedDate != null && isToday(c.lastReviewedDate!))
        .map((c) => c.id)
        .toSet();
    return {...fromLogs, ...fromCards}.length;
  }

  int get totalMasteredCardsCount =>
      _decks.fold(0, (sum, deck) => sum + deck.masteredCount);

  double get overallRetentionRate {
    if (_reviewLogs.isNotEmpty) {
      final successfulReviews = _reviewLogs
          .where((log) => log.rating == RecallRating.good || log.rating == RecallRating.easy)
          .length;
      return (successfulReviews / _reviewLogs.length) * 100.0;
    }
    if (totalCardsCount == 0) {
      return 0.0;
    }
    return _cloudRetentionRate;
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
  // Subject CRUD (Cloud + Per-User Local Cache)
  // -------------------------------------------------------------

  Future<Subject?> addSubject({
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
        } else {
          _subjects.insert(0, created);
        }
        await _saveToCache();
        notifyListeners();
        return created;
      }
    }

    await _saveToCache();
    return optimistic;
  }

  Future<void> deleteSubject(String subjectId) async {
    _subjects.removeWhere((s) => s.id == subjectId);
    _decks.removeWhere((d) => d.subjectId == subjectId);
    notifyListeners();

    if (ApiClient.instance.isAuthenticated && !subjectId.startsWith('sub_')) {
      await ApiClient.instance.delete('/subjects/$subjectId');
    }
    await _saveToCache();
  }

  Future<void> updateSubject({
    required String subjectId,
    required String name,
    required int colorValue,
  }) async {
    final idx = _subjects.indexWhere((s) => s.id == subjectId);
    if (idx != -1) {
      _subjects[idx] = Subject(id: subjectId, name: name, colorValue: colorValue);
      notifyListeners();
      await _saveToCache();
    }

    if (ApiClient.instance.isAuthenticated && !subjectId.startsWith('sub_')) {
      await ApiClient.instance.patch('/subjects/$subjectId', {
        'name': name,
        'colorHex': toHexColorString(colorValue),
      });
    }
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

    if (_studyStreakDays == 0) {
      _studyStreakDays = 1;
    }

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
  // Deck & Card CRUD (Cloud + Per-User Local Cache)
  // -------------------------------------------------------------

  Future<Deck?> addDeck({
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
      if (subjectId.isNotEmpty && !subjectId.startsWith('sub_')) {
        payload['subjectId'] = subjectId;
      }

      final res = await ApiClient.instance.post('/decks', payload);
      if (res.success && res.data is Map) {
        final created = Deck.fromJson(Map<String, dynamic>.from(res.data as Map));
        final idx = _decks.indexWhere((d) => d.id == tempId);
        if (idx != -1) {
          _decks[idx] = created;
        }
        // If backend also auto-created a default subject when none existed, sync subjects
        if (_subjects.isEmpty) {
          await fetchAllFromCloud();
        } else {
          await _saveToCache();
          notifyListeners();
        }
        return created;
      }
    }

    await _saveToCache();
    notifyListeners();
    return newDeck;
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

  Future<void> updateDeck({
    required String deckId,
    required String title,
    required String description,
    required String subjectId,
    required int colorValue,
  }) async {
    final idx = _decks.indexWhere((d) => d.id == deckId);
    if (idx != -1) {
      _decks[idx] = _decks[idx].copyWith(
        title: title,
        description: description,
        subjectId: subjectId,
        colorValue: colorValue,
      );
      notifyListeners();
      await _saveToCache();
    }

    if (ApiClient.instance.isAuthenticated && !deckId.startsWith('deck_')) {
      await ApiClient.instance.patch('/decks/$deckId', {
        'title': title,
        'description': description,
        'subjectId': subjectId,
        'colorHex': toHexColorString(colorValue),
      });
    }
  }

  Future<void> resetDeckProgress(String deckId) async {
    final idx = _decks.indexWhere((d) => d.id == deckId);
    if (idx == -1) return;

    final resetCards = _decks[idx].cards.map((c) {
      return c.copyWith(
        repetitions: 0,
        intervalDays: 0,
        easeFactor: 2.5,
        nextReviewDate: DateTime.now(),
        timesReviewed: 0,
        timesForgot: 0,
        masteryStatus: CardMasteryStatus.learning,
      );
    }).toList();

    _decks[idx] = _decks[idx].copyWith(cards: resetCards);
    notifyListeners();
    await _saveToCache();

    if (ApiClient.instance.isAuthenticated && !deckId.startsWith('deck_')) {
      await ApiClient.instance.post('/decks/$deckId/reset', {});
    }
  }

  Future<void> resetAllProgress() async {
    for (final deck in List<Deck>.from(_decks)) {
      await resetDeckProgress(deck.id);
    }
    _reviewLogs.clear();
    _cloudRetentionRate = 0.0;
    notifyListeners();
    await _saveToCache();
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

  Future<void> updateCard({
    required String deckId,
    required String cardId,
    required String question,
    required String answer,
    required String explanation,
    required List<String> tags,
    required FlashcardType cardType,
  }) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final deck = _decks[deckIndex];
    final cardIndex = deck.cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final updatedCard = deck.cards[cardIndex].copyWith(
      question: question,
      answer: answer,
      explanation: explanation,
      tags: tags,
      cardType: cardType,
    );

    final updatedList = List<Flashcard>.from(deck.cards);
    updatedList[cardIndex] = updatedCard;
    _decks[deckIndex] = deck.copyWith(cards: updatedList);
    notifyListeners();
    await _saveToCache();

    if (ApiClient.instance.isAuthenticated && !cardId.startsWith('card_')) {
      await ApiClient.instance.patch('/cards/$cardId', {
        'question': question,
        'answer': answer,
        'explanation': explanation,
        'tags': tags,
        'cardType': cardType.name,
      });
    }
  }
}
