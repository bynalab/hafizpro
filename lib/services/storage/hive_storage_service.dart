import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/bookmark.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/model/verse_progress.model.dart';
import 'package:hafiz_test/util/reciter_audio_profile.dart';
import 'abstract_storage_service.dart';

class HiveStorageService implements IStorageService {
  static const String _boxSettings = 'settings';
  static const String _boxBookmarks = 'bookmarks';
  static const String _boxProgress = 'progress';
  static const String _boxLastRead = 'last_read';

  static const int _totalVerses = 6236;

  // Boxes
  late Box _settingsBox;
  late Box<String> _bookmarksBox;
  late Box _progressBox;
  late Box _lastReadBox;

  Future<void> init(SharedPreferences prefs) async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(_boxSettings);
    _bookmarksBox = await Hive.openBox<String>(_boxBookmarks);
    _progressBox = await Hive.openBox(_boxProgress);
    _lastReadBox = await Hive.openBox(_boxLastRead);

    await _migrateIfNeeded(prefs);
  }

  Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    if (_settingsBox.get('migration_completed', defaultValue: false)) {
      return;
    }

    // Migrate generic settings from the SharedPrefsStorageService
    final settingsKeys = [
      'autoplay',
      'reciter',
      'reciter_id',
      'theme_mode',
      'has_view_showcase',
      'language',
      'notifications_enabled',
      'notification_time',
    ];

    for (var key in settingsKeys) {
      final value = prefs.get(key);
      if (value != null) {
        await _settingsBox.put(key, value);
      }
    }

    // Migrate Last Read
    final lastReadRaw = prefs.getString('last_read');
    if (lastReadRaw != null) {
      await _lastReadBox.put('current', lastReadRaw);
    }

    await _settingsBox.put('migration_completed', true);
  }

  @override
  bool checkAutoPlay() {
    return _settingsBox.get('autoplay', defaultValue: true);
  }

  @override
  Future<bool> setAutoPlay(bool autoPlay) async {
    await _settingsBox.put('autoplay', autoPlay);
    return true;
  }

  @override
  Future<bool> setReciter(String identifier) async {
    await _settingsBox.put('reciter', identifier);
    return true;
  }

  @override
  String getReciter() {
    return _settingsBox.get('reciter', defaultValue: 'ar.alafasy');
  }

  @override
  Future<bool> setReciterId(String reciterId) async {
    await _settingsBox.put('reciter_id', reciterId);
    return true;
  }

  @override
  String getReciterId() {
    final existing = _settingsBox.get('reciter_id');
    if (existing != null && existing.isNotEmpty) {
      final profile = ReciterAudioProfiles.forReciter(existing);
      if (profile != null) return existing;
      setReciterId('ar.alafasy');
      return 'ar.alafasy';
    }

    final legacy = getReciter();
    final legacyProfile = ReciterAudioProfiles.forReciter(legacy);
    if (legacyProfile != null) {
      setReciterId(legacy);
      return legacy;
    }

    setReciterId('ar.alafasy');
    return 'ar.alafasy';
  }

  @override
  Future<bool> saveLastRead(Surah surah, Ayah ayah) async {
    await _lastReadBox.put(
      'current',
      jsonEncode({'surah': surah.toJson(), 'ayah': ayah.toJson()}),
    );
    return true;
  }

  @override
  (Surah, Ayah)? getLastRead() {
    final raw = _lastReadBox.get('current');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return (
        Surah.fromJson(decoded['surah']),
        Ayah.fromJson(decoded['ayah']),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    final key = '${bookmark.surah.number}_${bookmark.ayah.numberInSurah}';
    await _bookmarksBox.put(key, jsonEncode(bookmark.toJson()));
  }

  @override
  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final key = '${surahNumber}_$ayahNumber';
    await _bookmarksBox.delete(key);
  }

  @override
  List<Bookmark> getBookmarks() {
    return _bookmarksBox.values
        .map((raw) => Bookmark.fromJson(jsonDecode(raw)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  bool isBookmarked(int surahNumber, int ayahNumber) {
    final key = '${surahNumber}_$ayahNumber';
    return _bookmarksBox.containsKey(key);
  }

  @override
  Future<void> markSpecificAyahsAsRead(
      int surahNumber, Set<int> ayahNumbers) async {
    final progress = _loadProgress();
    for (int ayahNumber in ayahNumbers) {
      final globalIndex = _getGlobalIndex(surahNumber, ayahNumber);
      progress.markRead(globalIndex + 1);
    }
    await _saveProgress(progress);
    await _updateSurahTimestamp(surahNumber);
  }

  @override
  Future<void> unmarkSpecificAyahsAsRead(
      int surahNumber, Set<int> ayahNumbers) async {
    final progress = _loadProgress();
    for (int ayahNumber in ayahNumbers) {
      final globalIndex = _getGlobalIndex(surahNumber, ayahNumber);
      progress.unmarkRead(globalIndex + 1);
    }
    await _saveProgress(progress);
    await _updateSurahTimestamp(surahNumber);
  }

  @override
  Future<void> markAyahsAsRead(int surahNumber, int upToAyahNumber) async {
    final progress = _loadProgress();
    for (int i = 1; i <= upToAyahNumber; i++) {
      final globalIndex = _getGlobalIndex(surahNumber, i);
      progress.markRead(globalIndex + 1);
    }
    await _saveProgress(progress);
    await _updateSurahTimestamp(surahNumber);
  }

  @override
  bool isAyahCompleted(int surahNumber, int ayahNumber) {
    final globalIndex = _getGlobalIndex(surahNumber, ayahNumber);
    return _loadProgress().isRead(globalIndex + 1);
  }

  @override
  int getTotalReadCount() {
    return _loadProgress().totalRead;
  }

  @override
  double getCompletionPercentage() {
    return _loadProgress().completionPercentage;
  }

  @override
  int getSurahReadCount(int surahNumber) {
    final progress = _loadProgress();
    final range = _getSurahRange(surahNumber);
    return progress.countReadInRange(range.$1, range.$2);
  }

  @override
  int getCompletedSurahsCount() {
    int completedCount = 0;
    final progress = _loadProgress();
    for (final surah in surahList) {
      final range = _getSurahRange(surah.number);
      if (progress.countReadInRange(range.$1, range.$2) ==
          surah.numberOfAyahs) {
        completedCount++;
      }
    }
    return completedCount;
  }

  @override
  DateTime? getSurahLastUpdated(int surahNumber) {
    final String? ts = _settingsBox.get('surah_update_$surahNumber');
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  @override
  Future<void> clearSurahProgress(int surahNumber) async {
    final progress = _loadProgress();
    final range = _getSurahRange(surahNumber);
    progress.clearRange(range.$1, range.$2);
    await _saveProgress(progress);
    await _settingsBox.delete('surah_update_$surahNumber');
  }

  @override
  Future<void> clearAllProgress() async {
    await _saveProgress(VerseProgress(_totalVerses));
    final keysToDelete = _settingsBox.keys
        .where((k) => k.toString().startsWith('surah_update_'))
        .toList();
    for (final key in keysToDelete) {
      await _settingsBox.delete(key);
    }
  }

  @override
  Future<void> saveUserGuide() async {
    await _settingsBox.put('has_view_showcase', true);
  }

  @override
  String getProgressTrackingMode() {
    return _settingsBox.get('reading_mode', defaultValue: 'smart');
  }

  @override
  Future<void> setProgressTrackingMode(String mode) async {
    await _settingsBox.put('reading_mode', mode);
  }

  @override
  Future<void> setSurahGap(int surahNumber, int? firstUnreadAyah) async {
    if (firstUnreadAyah == null) {
      await _settingsBox.delete('surah_gap_$surahNumber');
    } else {
      await _settingsBox.put('surah_gap_$surahNumber', firstUnreadAyah);
    }
  }

  @override
  int? getSurahGap(int surahNumber) {
    return _settingsBox.get('surah_gap_$surahNumber');
  }

  @override
  Future<bool> setThemeMode(String mode) async {
    await _settingsBox.put('theme_mode', mode);
    return true;
  }

  @override
  String getThemeMode() {
    return _settingsBox.get('theme_mode', defaultValue: 'system');
  }

  @override
  Future<bool> setString(String key, String value) async {
    await _settingsBox.put(key, value);
    return true;
  }

  @override
  String? getString(String key) {
    return _settingsBox.get(key);
  }

  // --- Helpers ---

  int _getGlobalIndex(int surahNumber, int ayahNumber) {
    int index = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      index += surahList[i].numberOfAyahs;
    }
    return index + ayahNumber - 1;
  }

  (int, int) _getSurahRange(int surahNumber) {
    int start = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      start += surahList[i].numberOfAyahs;
    }
    final count = surahList[surahNumber - 1].numberOfAyahs;
    return (start + 1, start + count);
  }

  VerseProgress _loadProgress() {
    return VerseProgress.fromJson(_totalVerses, _progressBox.get('data'));
  }

  Future<void> _saveProgress(VerseProgress progress) async {
    await _progressBox.put('data', progress.toJson());
  }

  Future<void> _updateSurahTimestamp(int surahNumber) async {
    await _settingsBox.put(
        'surah_update_$surahNumber', DateTime.now().toIso8601String());
  }
}
