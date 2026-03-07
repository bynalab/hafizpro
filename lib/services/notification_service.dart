import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hafiz_test/services/daily_item_provider.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/asset_util.dart';
import 'package:hafiz_test/services/analytics_service.dart';

class NotificationService {
  final IStorageService _storage;

  NotificationService({required IStorageService storage}) : _storage = storage;

  static const int dailyNotificationId = 1001;

  static const String _channelId = 'daily_motivation';
  static const String _channelName = 'Daily Motivation';
  static const String _channelDescription =
      'Daily motivational reminders for Quran memorization.';

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
      tz.setLocalLocation(tz.getLocation(localTz.identifier));
    } catch (_) {}

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
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {}
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

  Future<String> _pickMessage(DateTime date) async {
    try {
      final List<dynamic> messages =
          await AssetUtil.loadJson('assets/json/motivation.json');

      if (messages.isEmpty) return '🌟 Keep up the great work!';

      final provider = DailyItemProvider<String>(
        items: messages.cast<String>(),
        storage: _storage,
        key: 'motivation',
      );

      return await provider.getItem(date: date);
    } catch (e) {
      _log('Error loading motivational messages from assets: $e');
      return '🌟 Keep up the great work!';
    }
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
    final message = await _pickMessage(scheduled);

    _log(
        'Scheduling daily notification at: $scheduled (local tz: ${tz.local.name})');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/notification_logo',
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

    // Log to Mixpanel
    AnalyticsService.trackMotivationNotification(message);

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
