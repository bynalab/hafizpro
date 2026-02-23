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
  Bookmark? getBookmark();

  /// Marks all ayahs in a Surah from 1 up to [upToAyahNumber] as completed.
  /// This is used for the "Mark up to here" feature and auto-saving progress.
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

  /// Resets the progress (marks all ayahs as unread) for a specific Surah.
  Future<void> clearSurahProgress(int surahNumber);

  /// Clears the entire reading history for the whole Quran.
  Future<void> clearAllProgress();

  bool hasViewedShowcase();
  Future<void> saveUserGuide();

  /// Theme mode persistence
  Future<bool> setThemeMode(String mode);
  String getThemeMode();

  /// User identification persistence (simplified)
  Future<bool> setString(String key, String value);
  String? getString(String key);
}
