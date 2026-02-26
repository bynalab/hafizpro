import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/model/bookmark.model.dart';

abstract class IStorageService {
  bool checkAutoPlay();
  Future<bool> setAutoPlay(bool autoPlay);

  Future<bool> setReciter(String identifier);

  /// Get the reciter identifier from shared preferences.
  ///
  /// Returns the reciter identifier as a string. If no identifier is found,
  /// returns 'ar.alafasy' as the default.
  String getReciter();

  Future<bool> setReciterId(String reciterId);

  /// Returns a stable reciter id (provider-agnostic). If not present, this may
  /// migrate from the legacy `reciter` value.
  String getReciterId();

  Future<bool> saveLastRead(Surah surah, Ayah ayah);
  (Surah, Ayah)? getLastRead();

  Future<void> saveBookmark(Bookmark bookmark);
  Future<void> deleteBookmark();
  Bookmark? getBookmark();

  /// Marks specific ayahs in a Surah as completed.
  Future<void> markSpecificAyahsAsRead(int surahNumber, Set<int> ayahNumbers);
  Future<void> unmarkSpecificAyahsAsRead(int surahNumber, Set<int> ayahNumbers);

  /// Marks all ayahs in a Surah from 1 up to [upToAyahNumber] as completed.
  Future<void> markAyahsAsRead(int surahNumber, int upToAyahNumber);

  /// Checks if a specific ayah has been marked as completed.
  bool isAyahCompleted(int surahNumber, int ayahNumber);

  /// Returns the total count of unique ayahs read across the entire Quran (out of 6236).
  int getTotalReadCount();

  /// Returns the overall completion percentage (0.0 to 1.0).
  double getCompletionPercentage();

  /// Reading Insights helpers

  /// Returns how many ayahs have been completed in a specific Surah.
  int getSurahReadCount(int surahNumber);

  /// Returns the count of Surahs where all ayahs have been completed.
  int getCompletedSurahsCount();

  /// Returns the DateTime when progress for a specific Surah was last updated.
  DateTime? getSurahLastUpdated(int surahNumber);

  /// Resets the progress (marks all ayahs as unread) for a specific Surah.
  Future<void> clearSurahProgress(int surahNumber);

  /// Clears the entire reading history for the whole Quran.
  Future<void> clearAllProgress();

  Future<void> saveUserGuide();

  /// Progress Tracking persistence: 'smart', 'manual', 'off'
  String getProgressTrackingMode();
  Future<void> setProgressTrackingMode(String mode);

  /// Gap Persistence for Smart Auto-Save
  Future<void> setSurahGap(int surahNumber, int? firstUnreadAyah);
  int? getSurahGap(int surahNumber);

  /// Theme mode persistence
  Future<bool> setThemeMode(String mode);
  String getThemeMode();

  /// User identification persistence (simplified)
  Future<bool> setString(String key, String value);
  String? getString(String key);
}
