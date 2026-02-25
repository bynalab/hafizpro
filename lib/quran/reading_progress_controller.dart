import 'package:flutter/foundation.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';

class ReadingProgressController {
  final int surahNumber;
  final int totalVerses;
  final IStorageService storageService;
  final Function(int) onProgressSaved;
  final String trackingMode;

  final Set<int> _confirmedReadVerses = {};

  // High-accuracy tracking
  final Map<int, Duration> _accumulatedDurations = {};
  final Map<int, DateTime> _lastCheckTimes = {};

  final DateTime _sessionStart = DateTime.now();
  int _lastSavedVerseIndex = -1;
  int _maxObservedIndex = -1;
  bool _isSaved = false;

  // Track if any manual marking happened in this session
  bool _manualMarked = false;

  // Rules
  static const double _visibilityThreshold = 0.6;
  static const double _confirmationSeconds = 1.5;
  static const int _sessionMinSeconds = 5;
  static const int _sessionMinVerses = 2;

  ReadingProgressController({
    required this.surahNumber,
    required this.totalVerses,
    required this.storageService,
    required this.onProgressSaved,
    required this.trackingMode,
  }) {
    _lastSavedVerseIndex = storageService.getSurahReadCount(surahNumber) - 1;
    if (_lastSavedVerseIndex < 0) _lastSavedVerseIndex = -1;
  }

  void onVerseVisibilityChanged(int index, double visibilityFraction) {
    if (trackingMode != 'smart') return;

    final now = DateTime.now();
    final wasVisible = _lastCheckTimes.containsKey(index);
    final isVisible = visibilityFraction >= _visibilityThreshold;

    if (wasVisible) {
      // Accumulate time spent since last check
      final startTime = _lastCheckTimes[index]!;
      final delta = now.difference(startTime);
      _accumulatedDurations[index] =
          (_accumulatedDurations[index] ?? Duration.zero) + delta;

      // If no longer visible, stop tracking this "pulse"
      if (!isVisible) {
        _lastCheckTimes.remove(index);
        _evaluateVerse(index);
      } else {
        // Still visible, update marker for next delta
        _lastCheckTimes[index] = now;
        _evaluateVerse(index);
      }
    } else if (isVisible) {
      // Just became visible
      if (!_confirmedReadVerses.contains(index)) {
        _lastCheckTimes[index] = now;
        if (index > _maxObservedIndex) {
          _maxObservedIndex = index;
        }
      }
    }
  }

  void _evaluateVerse(int index) {
    if (_confirmedReadVerses.contains(index)) return;

    final accumulated = _accumulatedDurations[index] ?? Duration.zero;

    // Rule: Total visible time >= 1.5 seconds
    if (accumulated.inMilliseconds >= (_confirmationSeconds * 1000)) {
      if (index > _lastSavedVerseIndex) {
        // Also check if it's already in storage, avoid redundant work
        if (!storageService.isAyahCompleted(surahNumber, index + 1)) {
          _confirmedReadVerses.add(index);
          debugPrint(
              'Smart Auto-Save: Verse ${index + 1} confirmed as read (Cumulative: ${accumulated.inSeconds}s).');
        }
      }
    }
  }

  /// Final evaluation and storage update.
  /// Can be called explicitly (e.g. on back press) or as a fallback in dispose.
  void saveProgress() {
    if (trackingMode == 'off') return;
    if (_isSaved) return;

    // In manual mode, we only save if something was manually marked
    if (trackingMode == 'manual' && !_manualMarked) return;

    _isSaved = true;

    // Evaluate all tracked verses one last time to capture currently visible time
    final now = DateTime.now();
    for (final index in _lastCheckTimes.keys.toList()) {
      final startTime = _lastCheckTimes[index]!;
      final delta = now.difference(startTime);
      _accumulatedDurations[index] =
          (_accumulatedDurations[index] ?? Duration.zero) + delta;
      _evaluateVerse(index);
    }

    // SESSION QUALIFICATION:
    // Discard session if not deep enough to be considered a "reading session"
    // Note: Manual mode bypasses qualification since the user explicitly tapped.
    final sessionDuration = now.difference(_sessionStart);
    final isQualified = trackingMode == 'manual' ||
        _confirmedReadVerses.length >= _sessionMinVerses ||
        sessionDuration.inSeconds >= _sessionMinSeconds;

    if (!isQualified) {
      debugPrint(
          'Smart Auto-Save: Session for Surah $surahNumber discarded (too short/few verses).');
      return;
    }

    if (_confirmedReadVerses.isEmpty) return;

    // 1. Find the FIRST gap for the Resume Banner
    int highestContiguousIndex = _lastSavedVerseIndex;
    List<int> sortedConfirmed = _confirmedReadVerses.toList()..sort();

    for (final index in sortedConfirmed) {
      if (index == highestContiguousIndex + 1) {
        highestContiguousIndex = index;
      } else if (index > highestContiguousIndex + 1) {
        break;
      }
    }

    // 2. Identify the highest overall confirmed index
    final highestOverallConfirmed = sortedConfirmed.last;

    // 3. Gap Detection (Significant skip)
    // Only in smart mode
    if (trackingMode == 'smart') {
      final gapSize = highestOverallConfirmed - highestContiguousIndex;
      if (gapSize > 3) {
        final firstUnreadAyah = highestContiguousIndex + 2;
        storageService.setSurahGap(surahNumber, firstUnreadAyah);
        debugPrint(
            'Smart Auto-Save: Significant gap detected. Resume banner will point to $firstUnreadAyah');
      }
    } else if (trackingMode == 'manual') {
      // Clear gaps in manual mode as requested
      storageService.setSurahGap(surahNumber, null);
    }

    // 4. Persistence: DISCRETE MARKING
    final ayahNumbers = _confirmedReadVerses.map((idx) => idx + 1).toSet();

    // Adaptive Save Logic (60% or 3 verses)
    // Manual mode bypasses adaptive logic as it is "authoritative"
    final newlyReadCount = ayahNumbers.length;
    final currentlyReadCount = storageService.getSurahReadCount(surahNumber);
    final readingPercentage =
        (currentlyReadCount + newlyReadCount) / totalVerses;

    if (trackingMode == 'manual' ||
        readingPercentage >= 0.6 ||
        newlyReadCount >= 3) {
      storageService.markSpecificAyahsAsRead(surahNumber, ayahNumbers);
      onProgressSaved(highestContiguousIndex + 1);
      debugPrint(
          'Reading Progress: Saved progress for ${ayahNumbers.length} verses (Mode: $trackingMode).');
    }
  }

  /// Manual Mode: Force mark progress up to [index] (0-based)
  void markAsReadUpTo(int index) {
    if (trackingMode == 'off') return;

    // Don't move backwards
    if (index <= _lastSavedVerseIndex) return;

    // Add all ayahs from last saved + 1 to index
    for (int i = _lastSavedVerseIndex + 1; i <= index; i++) {
      _confirmedReadVerses.add(i);
    }

    _manualMarked = true;

    // Force immediate save for manual mode to satisfy "Update completion analytics accordingly"
    _isSaved = false; // Allow saveProgress to run
    saveProgress();

    debugPrint('Manual Progress: Marked up to verse ${index + 1}');
  }

  void dispose() {
    saveProgress();
  }
}
