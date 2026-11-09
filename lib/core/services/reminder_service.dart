import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/flashcard_model.dart';
import 'study_repository.dart';

/// On-device study reminders (no server required).
///
/// Two reminders, both computed from data already on the phone and rescheduled
/// whenever study data changes, the app resumes, or the day rolls over:
///  1. Daily review reminder — at the user's chosen time, only when cards are due.
///  2. Streak protection — at 9:00 PM, only when an active streak would break tonight.
///
/// Content is fixed at schedule time, so it is refreshed for today plus the next
/// two days on every reschedule. Studying in the app cancels/updates them.
class ReminderService extends ChangeNotifier {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _kDailyEnabled = 'reminder_daily_enabled';
  static const _kStreakEnabled = 'reminder_streak_enabled';
  static const _kHour = 'reminder_hour';
  static const _kMinute = 'reminder_minute';
  static const _kPermissionAsked = 'reminder_permission_asked';

  static const _dailyBaseId = 100;
  static const _streakBaseId = 200;
  static const _daysAhead = 3; // today + next 2 days
  static const _streakWarningHour = 21;

  static const _channel = AndroidNotificationDetails(
    'recall_study_reminders',
    'Study reminders',
    channelDescription: 'Daily review reminders and streak warnings',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _dailyEnabled = true;
  bool _streakEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _permissionGranted = false;
  Timer? _debounce;

  bool get isAvailable => _initialized;
  bool get dailyEnabled => _dailyEnabled;
  bool get streakEnabled => _streakEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get permissionGranted => _permissionGranted;

  /// Called once from main(). Safe to skip in tests (all calls no-op until initialized).
  Future<void> initialize() async {
    if (_initialized || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Manila'));
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      _dailyEnabled = prefs.getBool(_kDailyEnabled) ?? true;
      _streakEnabled = prefs.getBool(_kStreakEnabled) ?? true;
      _reminderTime = TimeOfDay(
        hour: prefs.getInt(_kHour) ?? 19,
        minute: prefs.getInt(_kMinute) ?? 0,
      );

      _permissionGranted = await _android?.areNotificationsEnabled() ?? false;
      _initialized = true;

      StudyRepository.instance.addListener(_scheduleSoon);
      notifyListeners();
      await reschedule();
    } catch (e) {
      debugPrint('ReminderService init failed: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Ask for notification permission once, right after the user's first completed study
  /// session (when the value of reminders is obvious), instead of on first launch.
  Future<void> maybeAskAfterFirstSession() async {
    if (!_initialized || _permissionGranted) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kPermissionAsked) ?? false) return;
    await prefs.setBool(_kPermissionAsked, true);
    await requestPermission();
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    _permissionGranted = await _android?.requestNotificationsPermission() ?? false;
    notifyListeners();
    await reschedule();
    return _permissionGranted;
  }

  Future<void> setDailyEnabled(bool value) async {
    _dailyEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyEnabled, value);
    if (value && !_permissionGranted) await requestPermission();
    notifyListeners();
    await reschedule();
  }

  Future<void> setStreakEnabled(bool value) async {
    _streakEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStreakEnabled, value);
    if (value && !_permissionGranted) await requestPermission();
    notifyListeners();
    await reschedule();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHour, time.hour);
    await prefs.setInt(_kMinute, time.minute);
    notifyListeners();
    await reschedule();
  }

  void _scheduleSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), reschedule);
  }

  /// Rebuilds all pending reminders from current study data.
  Future<void> reschedule() async {
    if (!_initialized) return;
    try {
      for (var i = 0; i < _daysAhead; i++) {
        await _plugin.cancel(id: _dailyBaseId + i);
        await _plugin.cancel(id: _streakBaseId + i);
      }
      if (!_permissionGranted) return;

      final repo = StudyRepository.instance;
      final now = tz.TZDateTime.now(tz.local);
      final studiedToday = repo.reviewedTodayCount > 0;

      for (var offset = 0; offset < _daysAhead; offset++) {
        final day = tz.TZDateTime(tz.local, now.year, now.month, now.day + offset);

        if (_dailyEnabled) {
          final at = tz.TZDateTime(
              tz.local, day.year, day.month, day.day, _reminderTime.hour, _reminderTime.minute);
          final goalMetToday = offset == 0 && repo.reviewedTodayCount >= repo.dailyGoalCards;
          final message = _dailyMessage(repo, day);
          if (at.isAfter(now) && !goalMetToday && message != null) {
            await _schedule(_dailyBaseId + offset, at, message.$1, message.$2);
          }
        }

        if (_streakEnabled) {
          final at = tz.TZDateTime(tz.local, day.year, day.month, day.day, _streakWarningHour);
          // Streak length that would be lost if the user skips that day.
          final int streakAtRisk;
          if (offset == 0) {
            streakAtRisk = studiedToday ? 0 : repo.studyStreakDays;
          } else if (offset == 1) {
            // Tomorrow: only alive if the user studied today. Days beyond that depend on
            // whether they study tomorrow, which triggers a fresh reschedule anyway.
            streakAtRisk = studiedToday ? repo.studyStreakDays : 0;
          } else {
            streakAtRisk = 0;
          }
          if (at.isAfter(now) && streakAtRisk > 0) {
            await _schedule(
              _streakBaseId + offset,
              at,
              'Keep your $streakAtRisk-day streak',
              'Your streak ends at midnight. One quick review keeps it alive.',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('ReminderService reschedule failed: $e');
    }
  }

  /// Builds the daily reminder text for [day], or null when nothing is due.
  (String, String)? _dailyMessage(StudyRepository repo, tz.TZDateTime day) {
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    Deck? topDeck;
    var topCount = 0;
    var total = 0;
    for (final deck in repo.decks) {
      final count = deck.cards.where((c) {
        if (c.isNewCard) return repo.includeNewInDue;
        return !c.nextReviewDate.isAfter(endOfDay);
      }).length;
      total += count;
      if (count > topCount) {
        topCount = count;
        topDeck = deck;
      }
    }
    if (total == 0) return null;

    final cardsWord = total == 1 ? 'card' : 'cards';
    final title = '$total $cardsWord ready to review';
    final body = (topDeck != null && topCount < total)
        ? '$topCount in ${topDeck.title} and more. A few minutes now keeps them fresh.'
        : 'From ${topDeck?.title ?? 'your decks'}. A few minutes now keeps them fresh.';
    return (title, body);
  }

  Future<void> _schedule(int id, tz.TZDateTime at, String title, String body) {
    return _plugin.zonedSchedule(
      id: id,
      scheduledDate: at,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _channel),
      // Inexact scheduling avoids the restricted exact-alarm permission; a few minutes of drift is fine.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
