import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/model/bookmark.model.dart';
import 'package:hafiz_test/util/reciter_audio_profile.dart';
import 'package:hafiz_test/model/verse_progress.model.dart';
import 'abstract_storage_service.dart';

class SharedPrefsStorageService implements IStorageService {
  static const String _keyProgress = 'quran_progress_v2';
  static const _keyReadingMode = 'reading_mode';
  static const String _keyBookmark = 'quran_bookmark';
  static const String _keySurahUpdates = 'quran_surah_updates';
  static const int _totalVerses = 6236;

  final SharedPreferences prefs;

  SharedPrefsStorageService(this.prefs);

  @override
  bool checkAutoPlay() {
    return prefs.getBool('autoplay') ?? true;
  }

  @override
  Future<bool> setAutoPlay(bool autoPlay) async {
    return prefs.setBool('autoplay', autoPlay);
  }

  @override
  Future<bool> setReciter(String identifier) async {
    return prefs.setString('reciter', identifier);
  }

  @override
  String getReciter() {
    return prefs.getString('reciter') ?? 'ar.alafasy';
  }

  @override
  Future<bool> setReciterId(String reciterId) async {
    return prefs.setString('reciter_id', reciterId);
  }

  @override
  String getReciterId() {
    final existing = prefs.getString('reciter_id');
    if (existing != null && existing.isNotEmpty) {
      // Check if the reciter exists in the reciters list
      final profile = ReciterAudioProfiles.forReciter(existing);
      if (profile != null) return existing;

      unawaited(setReciterId('ar.alafasy'));
      return 'ar.alafasy';
    }

    // Backward compatibility: migrate from legacy `reciter` (provider-specific)
    // to stable `reciter_id`. For now we use the legacy identifier as the id;
    // the resolver layer can map it to provider-specific identifiers.
    final legacy = getReciter();
    final legacyProfile = ReciterAudioProfiles.forReciter(legacy);
    if (legacyProfile != null) {
      unawaited(setReciterId(legacy));
      return legacy;
    }

    unawaited(setReciterId('ar.alafasy'));
    return 'ar.alafasy';
  }

  @override
  Future<bool> saveLastRead(Surah surah, Ayah ayah) async {
    try {
      return prefs.setString(
        'last_read',
        jsonEncode({'surah': surah.toJson(), 'ayah': ayah.toJson()}),
      );
    } catch (e) {
      return false;
    }
  }

  @override
  (Surah, Ayah)? getLastRead() {
    final raw = prefs.getString('last_read');
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      return (
        Surah.fromJson(decoded['surah']),
        Ayah.fromJson(decoded['ayah']),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    final bookmarks = getBookmarks();
    bookmarks.add(bookmark);
    await prefs.setStringList(
      _keyBookmark,
      bookmarks.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  @override
  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final bookmarks = getBookmarks();
    bookmarks.removeWhere((b) =>
        b.surah.number == surahNumber && b.ayah.numberInSurah == ayahNumber);
    await prefs.setStringList(
      _keyBookmark,
      bookmarks.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  @override
  List<Bookmark> getBookmarks() {
    final list = prefs.getStringList(_keyBookmark) ?? [];
    return list.map((s) => Bookmark.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  bool isBookmarked(int surahNumber, int ayahNumber) {
    return getBookmarks().any((b) =>
        b.surah.number == surahNumber && b.ayah.numberInSurah == ayahNumber);
  }

  bool hasViewedShowcase() {
    return prefs.getBool('has_view_showcase') ?? false;
  }

  @override
  Future<void> saveUserGuide() async {
    await prefs.setBool('has_view_showcase', true);
  }

  @override
  Future<bool> setThemeMode(String mode) async {
    final serialized =
        ['light', 'dark', 'system'].contains(mode) ? mode : 'system';

    return prefs.setString('theme_mode', serialized);
  }

  @override
  String getThemeMode() {
    final raw = prefs.getString('theme_mode');
    return ['light', 'dark', 'system'].contains(raw)
        ? raw ?? 'system'
        : 'system';
  }

  @override
  Future<bool> setString(String key, String value) async {
    return prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return prefs.getString(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return prefs.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    return prefs.getBool(key);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    return prefs.setInt(key, value);
  }

  @override
  int? getInt(String key) {
    return prefs.getInt(key);
  }

  // --- Progress Tracking Implementation ---

  /// Converts a Surah and Ayah number into a single continuous index (0-6235).
  /// This mapping allows us to use a flat bitset for the entire Quran.
  int _getGlobalIndex(int surahNumber, int ayahNumber) {
    int index = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      index += surahList[i].numberOfAyahs;
    }
    return index + ayahNumber - 1;
  }

  /// Helper to get the global index range [start, end] for a specific Surah.
  (int, int) _getSurahRange(int surahNumber) {
    int start = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      start += surahList[i].numberOfAyahs;
    }
    final count = surahList[surahNumber - 1].numberOfAyahs;
    return (start + 1, start + count);
  }

  VerseProgress _loadProgress() {
    return VerseProgress.fromJson(_totalVerses, prefs.getString(_keyProgress));
  }

  Future<void> _saveProgress(VerseProgress progress) async {
    await prefs.setString(_keyProgress, progress.toJson());
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

  Future<void> _updateSurahTimestamp(int surahNumber) async {
    final raw = prefs.getString(_keySurahUpdates);
    Map<String, dynamic> updates = {};
    if (raw != null) {
      try {
        updates = jsonDecode(raw);
      } catch (_) {}
    }
    updates[surahNumber.toString()] = DateTime.now().toIso8601String();
    await prefs.setString(_keySurahUpdates, jsonEncode(updates));
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
  Future<void> clearSurahProgress(int surahNumber) async {
    final progress = _loadProgress();
    final range = _getSurahRange(surahNumber);
    progress.clearRange(range.$1, range.$2);
    await _saveProgress(progress);

    // Clear timestamp
    final raw = prefs.getString(_keySurahUpdates);
    if (raw != null) {
      try {
        final updates = Map<String, dynamic>.from(jsonDecode(raw));
        updates.remove(surahNumber.toString());
        await prefs.setString(_keySurahUpdates, jsonEncode(updates));
      } catch (_) {}
    }
  }

  @override
  DateTime? getSurahLastUpdated(int surahNumber) {
    final raw = prefs.getString(_keySurahUpdates);
    if (raw == null) return null;
    try {
      final updates = jsonDecode(raw);
      final ts = updates[surahNumber.toString()];
      if (ts == null) return null;
      return DateTime.tryParse(ts);
    } catch (_) {
      return null;
    }
  }

  @override
  String getProgressTrackingMode() {
    return prefs.getString(_keyReadingMode) ?? 'smart';
  }

  @override
  Future<void> setProgressTrackingMode(String mode) async {
    await prefs.setString(_keyReadingMode, mode);
  }

  @override
  Future<void> setSurahGap(int surahNumber, int? firstUnreadAyah) async {
    final key = 'surah_gap_$surahNumber';
    if (firstUnreadAyah == null) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, firstUnreadAyah);
    }
  }

  @override
  int? getSurahGap(int surahNumber) {
    return prefs.getInt('surah_gap_$surahNumber');
  }

  @override
  Future<void> clearAllProgress() async {
    await _saveProgress(VerseProgress(_totalVerses));
    await prefs.remove(_keySurahUpdates);
  }
}
