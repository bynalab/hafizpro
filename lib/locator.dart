import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/ayah.services.dart';
import 'package:hafiz_test/services/notification_service.dart';
import 'package:hafiz_test/services/quran_db.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/storage/shared_prefs_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/util/theme_controller.dart';

final getIt = GetIt.instance;

Future<void> _restoreNotificationScheduleIfEnabled() async {
  final storage = getIt<IStorageService>();
  final rawEnabled = storage.getString('notifications_enabled');
  final enabled = rawEnabled == 'true';
  if (!enabled) return;

  final rawTime = storage.getString('notification_time');
  int hour = 20;
  int minute = 0;
  if (rawTime != null && rawTime.contains(':')) {
    final parts = rawTime.split(':');
    if (parts.length == 2) {
      hour = int.tryParse(parts[0]) ?? hour;
      minute = int.tryParse(parts[1]) ?? minute;
    }
  }

  try {
    final notifications = getIt<NotificationService>();
    final osEnabled = await notifications.areNotificationsEnabled();
    if (!osEnabled) return;

    await notifications
        .scheduleDailyMotivation(TimeOfDay(hour: hour, minute: minute));
  } catch (e) {
    debugPrint(
        '[NotificationService] Failed to restore schedule on startup: $e');
  }
}

Future<void> setupLocator() async {
  final prefs = await SharedPreferences.getInstance();

  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerSingleton<IStorageService>(SharedPrefsStorageService(prefs));
  getIt.registerSingleton<NetworkServices>(NetworkServices());
  getIt.registerSingleton<SurahPicker>(SurahPicker());
  getIt.registerSingleton<AudioServices>(AudioServices());
  getIt.registerSingleton<ThemeController>(ThemeController());
  getIt.registerSingleton<NotificationService>(NotificationService());

  final quranDb = QuranDb();
  await quranDb.init();
  getIt.registerSingleton<QuranDb>(quranDb);

  getIt.registerSingleton<SurahServices>(
    SurahServices(
      networkServices: getIt<NetworkServices>(),
      storageServices: getIt<IStorageService>(),
      surahPicker: getIt<SurahPicker>(),
      quranDb: getIt<QuranDb>(),
    ),
  );

  getIt.registerSingleton<AudioCenter>(
    AudioCenter(
      audioServices: getIt<AudioServices>(),
      surahServices: getIt<SurahServices>(),
    ),
  );

  getIt.registerSingleton<AyahServices>(
    AyahServices(
      networkServices: getIt<NetworkServices>(),
      storageServices: getIt<IStorageService>(),
    ),
  );

  // Initialize notifications and restore schedule if user previously enabled it.
  await _restoreNotificationScheduleIfEnabled();
}
