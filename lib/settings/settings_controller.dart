import 'package:flutter/material.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/theme_controller.dart';

class SettingsController extends ChangeNotifier {
  final IStorageService _storage;
  final ThemeController _theme;

  SettingsController({
    IStorageService? storage,
    ThemeController? theme,
  })  : _storage = storage ?? getIt<IStorageService>(),
        _theme = theme ?? getIt<ThemeController>();

  bool isLoading = true;

  bool autoPlay = true;
  String? reciter;
  late ThemeMode themeMode;

  bool notificationsEnabled = false;
  TimeOfDay notificationTime = const TimeOfDay(hour: 20, minute: 0);

  void load() {
    try {
      autoPlay = _storage.checkAutoPlay();
      reciter = _storage.getReciterId();
      themeMode = ThemeMode.values.byName(_theme.mode);

      final rawEnabled = _storage.getString('notifications_enabled');
      notificationsEnabled = rawEnabled == 'true';

      final rawTime = _storage.getString('notification_time');
      if (rawTime != null && rawTime.contains(':')) {
        final parts = rawTime.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) {
            notificationTime = TimeOfDay(hour: h, minute: m);
          }
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAutoPlay(bool value) async {
    final oldValue = autoPlay;
    autoPlay = value;
    notifyListeners();

    AnalyticsService.trackSettingsChanged('autoplay', oldValue, value);
    await _storage.setAutoPlay(value);
  }

  Future<void> setReciter(String identifier) async {
    final oldValue = reciter;
    reciter = identifier;
    notifyListeners();

    AnalyticsService.trackSettingsChanged('reciter', oldValue, identifier);
    await _storage.setReciterId(identifier);
  }

  Future<void> setNotifications({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    notificationsEnabled = enabled;
    notificationTime = time;
    notifyListeners();

    await _storage.setString('notifications_enabled', enabled.toString());
    await _storage.setString(
      'notification_time',
      '${time.hour}:${time.minute}',
    );
  }
}
