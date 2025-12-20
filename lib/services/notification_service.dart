import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int dailyNotificationId = 1001;

  static const String _channelId = 'daily_motivation';
  static const String _channelName = 'Daily Motivation';
  static const String _channelDescription =
      'Daily motivational reminders for Quran memorization.';

  static const List<String> _motivationalMessages = [
    '🌟 Every moment spent with the Quran is a moment of blessing. Continue your journey!',
    '⭐ The Prophet (PBUH) said: "Whoever recites a letter from the Book of Allah will have a reward."',
    '🕌 The Quran is a source of peace and guidance. Your memorization journey is blessed!',
    "🕊️ The Quran is healing for the heart and soul. Let today's session bring you peace!",
    '📚 Consistency is key in memorization. Your daily practice is building a strong foundation!',
    '📖 The Quran is the word of Allah. What a privilege to memorize His divine words!',
    '📚 The Quran is a companion for life. Each verse you memorize is a friend for eternity!',
    "⭐ Every verse you memorize is a step towards becoming a Hafiz. You're on a blessed path!",
    '🌙 The Prophet (PBUH) said: "The one who is proficient in the Quran will be with the noble angels."',
    "🌅 Begin your day with Allah's words. Your memorization journey is a blessed one!",
    '🕊️ Your dedication to memorizing the Quran is inspiring. Keep up the excellent work!',
    '💎 Your effort to memorize the Quran is a form of worship that brings you closer to Allah!',
    "✨ The Quran is a treasure, and you're collecting its gems. Today is another opportunity!",
    '🕌 Your effort to memorize the Quran is a form of Ibadah. May Allah reward you abundantly!',
    '🎯 Consistency in memorization leads to mastery. Your daily practice is building excellence!',
    '🌙 The Prophet (PBUH) said: "The best of you are those who learn the Quran and teach it."',
    '📖 Each day of practice is an investment in your spiritual growth. Keep going!',
    "⭐ Every verse you learn is a step closer to becoming a Hafiz. You're on the right path!",
    '🎯 Small consistent steps lead to great achievements. Keep memorizing, keep growing!',
    '📚 The Quran is a companion for life. Each verse you memorize is a friend for eternity!',
  ];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[NotificationService] $message');
  }

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // If timezone resolution fails, tz.local still works but may default.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final androidSpecific = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidSpecific?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await init();

    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return ok;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // Android 12+ may require explicit user approval for exact alarms
      // (especially on Pixel devices). This is a best-effort request.
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {
        // Ignore; some Android versions/devices don't expose this API.
      }
      final ok = await android?.requestNotificationsPermission() ?? true;
      return ok;
    }

    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    await init();
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled ?? true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final enabled = await ios?.checkPermissions();
      final ok = enabled?.isEnabled ?? false;
      return ok;
    }

    return true;
  }

  String _pickRandomMessage() {
    final r = Random();
    return _motivationalMessages[r.nextInt(_motivationalMessages.length)];
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the chosen time is "now" or already passed, schedule it for tomorrow.
    // However, if the user is trying to test by selecting the current minute
    // (common UX), schedule it slightly in the future so it can still fire.
    if (!scheduled.isAfter(now)) {
      if (scheduled.isSameMinuteAs(now)) {
        scheduled = now.add(const Duration(minutes: 1));
      } else {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    return scheduled;
  }

  Future<void> scheduleDailyMotivation(TimeOfDay time) async {
    await init();

    if (kIsWeb) return;

    // Ensure we're not stacking schedules.
    await cancelDailyMotivation();

    final granted = await requestPermissions();
    if (!granted) {
      throw StateError('Notification permission not granted');
    }

    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      throw StateError('Notifications are disabled in system settings');
    }

    final scheduled = _nextInstanceOfTime(time);
    final message = _pickRandomMessage();

    _log(
        'Scheduling daily notification at: $scheduled (local tz: ${tz.local.name})');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    AndroidScheduleMode scheduleMode =
        AndroidScheduleMode.inexactAllowWhileIdle;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        final canExact =
            await android?.canScheduleExactNotifications() ?? false;
        scheduleMode = canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
        _log('Android exact alarms allowed: $canExact (using $scheduleMode)');
      } catch (e) {
        _log(
            'Failed to query exact alarm capability: $e (using $scheduleMode)');
      }
    }

    await _plugin.zonedSchedule(
      dailyNotificationId,
      'Hafiz Pro',
      message,
      scheduled,
      details,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final pending = await _plugin.pendingNotificationRequests();
    _log(
      'Pending notifications after schedule: ${pending.map((p) => p.id).toList()}',
    );
  }

  Future<void> cancelDailyMotivation() async {
    await init();
    if (kIsWeb) return;
    await _plugin.cancel(dailyNotificationId);
  }
}

extension _TZDateTimeMinuteComparison on tz.TZDateTime {
  bool isSameMinuteAs(tz.TZDateTime other) {
    return year == other.year &&
        month == other.month &&
        day == other.day &&
        hour == other.hour &&
        minute == other.minute;
  }
}
