import 'dart:convert';

/// A utility class to manage reading progress using a standard Dart Set.
/// Each integer in the set represents a completed global ayah index (1-6236).
class VerseProgress {
  final Set<int> _readVerses;
  final int totalVerses;

  VerseProgress(this.totalVerses) : _readVerses = {};

  VerseProgress.fromSet(this.totalVerses, Set<int> readVerses)
      : _readVerses = readVerses;

  /// Loads progress from a JSON string (List of integers).
  factory VerseProgress.fromJson(int totalVerses, String? json) {
    if (json == null || json.isEmpty) {
      return VerseProgress(totalVerses);
    }
    try {
      final List<dynamic> decoded = jsonDecode(json);
      final Set<int> set = decoded.cast<int>().toSet();
      return VerseProgress.fromSet(totalVerses, set);
    } catch (_) {
      return VerseProgress(totalVerses);
    }
  }

  /// Serializes the progress to a JSON string (List of integers).
  String toJson() => jsonEncode(_readVerses.toList());

  /// Marks a specific global verse number as read.
  void markRead(int globalVerseNumber) {
    if (globalVerseNumber >= 1 && globalVerseNumber <= totalVerses) {
      _readVerses.add(globalVerseNumber);
    }
  }

  /// Unmarks a specific global verse number as read.
  void unmarkRead(int globalVerseNumber) {
    _readVerses.remove(globalVerseNumber);
  }

  /// Checks if a specific global verse number is read.
  bool isRead(int globalVerseNumber) {
    return _readVerses.contains(globalVerseNumber);
  }

  /// Returns the total number of read ayahs.
  int get totalRead => _readVerses.length;

  /// Returns the completion percentage (0.0 to 1.0).
  double get completionPercentage =>
      totalVerses > 0 ? _readVerses.length / totalVerses : 0.0;

  /// Clears progress for a specific range of global verse numbers (inclusive).
  void clearRange(int start, int end) {
    _readVerses.removeWhere((v) => v >= start && v <= end);
  }

  /// Clears all progress.
  void clearAll() {
    _readVerses.clear();
  }

  /// Counts read ayahs within a specific global range (inclusive).
  int countReadInRange(int start, int end) {
    return _readVerses.where((v) => v >= start && v <= end).length;
  }
}
