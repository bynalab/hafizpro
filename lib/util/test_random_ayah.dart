import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/ayah.model.dart';

/// Chooses ayahs for guess/recitation tests while avoiding surah edges when possible.
///
/// First and last verses of a surah are usually too recognizable; this module
/// centralizes that rule so callers only forward ayah lists (and optional surah context).
class TestRandomAyah {
  TestRandomAyah._();

  static void _logStrategy(
    String strategy, {
    int? surahNumber,
    required int poolSize,
    required int candidateCount,
  }) {
    if (!kDebugMode) return;
    final sn = surahNumber != null ? ' surahNumber=$surahNumber' : '';
    debugPrint(
      'TestRandomAyah: strategy=$strategy$sn poolSize=$poolSize/$candidateCount',
    );
  }

  static int? _lastAyahInSurah(int surahNumber) {
    if (surahNumber < 1 || surahNumber > surahList.length) return null;
    final n = surahList[surahNumber - 1].numberOfAyahs;
    return n > 0 ? n : null;
  }

  static bool _isEdgeInSurah(Ayah a, int surahNumber) {
    final n = a.numberInSurah;
    if (n <= 0) return false;
    final last = _lastAyahInSurah(surahNumber);
    if (last == null) return false;
    return n == 1 || n == last;
  }

  /// Ayahs that are allowed for random test selection.
  ///
  /// [surahNumber] — when all verses belong to one surah (e.g. test-by-surah), pass it
  /// so edge detection works even if [Ayah.surah] is missing on some rows.
  ///
  /// Falls back to the full list when every verse would be excluded (e.g. 1–2 ayah surahs).
  static List<Ayah> eligiblePool(List<Ayah> ayahs, {int? surahNumber}) {
    if (ayahs.isEmpty) {
      if (kDebugMode) {
        debugPrint('TestRandomAyah: strategy=emptyInput poolSize=0/0');
      }
      return ayahs;
    }

    /// Returns all eligible Ayahs in a specific surah, excluding the first and last verse.
    ///
    /// If [surahNumber] is null, invalid, or out of range, returns null. Excludes edge ayahs
    /// by filtering out ayahs whose [numberInSurah] is 1 (first) or the last verse in the surah.
    /// Returns null if the filtered pool is empty.
    List<Ayah>? explicitSurah() {
      // Check if surahNumber is specified and valid.
      if (surahNumber == null ||
          surahNumber < 1 ||
          surahNumber > surahList.length) {
        return null;
      }

      final last = _lastAyahInSurah(surahNumber);
      if (last == null) return null;
      // Filter: Exclude first (1) and last ayah of surah from the pool.
      final pool = ayahs.where((ayah) {
        final numberInSurah = ayah.numberInSurah;
        if (numberInSurah <= 0) return false;
        return numberInSurah != 1 && numberInSurah != last;
      }).toList();

      // If no eligible ayahs found, return null.
      return pool.isEmpty ? null : pool;
    }

    /// Returns all eligible Ayahs based on surah metadata (numberInSurah).
    ///
    /// If no ayahs have valid surah metadata (number), returns null. Excludes edge ayahs
    /// by filtering out ayahs whose [numberInSurah] is 1 (first) or the last verse in the surah.
    /// Returns null if the filtered pool is empty.
    List<Ayah>? byAyahSurahMetadata() {
      // Check if any ayah has valid surah metadata (number).
      if (!ayahs.any((ayah) => (ayah.surah?.number ?? 0) >= 1)) {
        return null;
      }
      // Filter: Exclude first (1) and last ayah of surah from the pool.
      final pool = ayahs.where((ayah) {
        final surahNumber = ayah.surah?.number ?? 0;
        if (surahNumber < 1 || surahNumber > surahList.length) return true;
        return !_isEdgeInSurah(ayah, surahNumber);
      }).toList();
      // If no eligible ayahs found, return null.
      return pool.isEmpty ? null : pool;
    }

    /// Returns all eligible Ayahs based on the maximum number in the list.
    ///
    /// If the maximum number is 1 or less, returns null. Excludes edge ayahs
    /// by filtering out ayahs whose [numberInSurah] is 1 (first) or the last verse in the surah.
    /// Returns null if the filtered pool is empty.
    List<Ayah>? byMaxNumberInList() {
      var maxN = 0;
      for (final a in ayahs) {
        if (a.numberInSurah > maxN) maxN = a.numberInSurah;
      }
      if (maxN <= 1) return null;
      final p = ayahs
          .where(
            (a) =>
                a.numberInSurah > 0 &&
                a.numberInSurah != 1 &&
                a.numberInSurah != maxN,
          )
          .toList();
      return p.isEmpty ? null : p;
    }

    /// Returns all eligible Ayahs based on the list position.
    ///
    /// If the list has 2 or fewer ayahs, returns null. Excludes edge ayahs
    /// by filtering out ayahs whose [numberInSurah] is 1 (first) or the last verse in the surah.
    /// Returns null if the filtered pool is empty.
    List<Ayah>? byListPosition() {
      if (ayahs.length <= 2) return null;
      final pool = ayahs.sublist(1, ayahs.length - 1);
      // If no eligible ayahs found, return null.
      return pool.isEmpty ? null : pool;
    }

    final explicit = explicitSurah();
    if (explicit != null) {
      _logStrategy(
        'explicitSurah',
        surahNumber: surahNumber,
        poolSize: explicit.length,
        candidateCount: ayahs.length,
      );
      return explicit;
    }

    final byMeta = byAyahSurahMetadata();
    if (byMeta != null) {
      _logStrategy(
        'perAyahSurahMetadata',
        poolSize: byMeta.length,
        candidateCount: ayahs.length,
      );
      return byMeta;
    }

    final byMax = byMaxNumberInList();
    if (byMax != null) {
      _logStrategy(
        'maxNumberInList',
        poolSize: byMax.length,
        candidateCount: ayahs.length,
      );
      return byMax;
    }

    final byPos = byListPosition();
    if (byPos != null) {
      _logStrategy(
        'listPosition',
        poolSize: byPos.length,
        candidateCount: ayahs.length,
      );
      return byPos;
    }

    _logStrategy(
      'fullListFallback',
      poolSize: ayahs.length,
      candidateCount: ayahs.length,
    );
    return ayahs;
  }

  static Ayah pick(List<Ayah> ayahs, {Random? random, int? surahNumber}) {
    if (ayahs.isEmpty) return Ayah();
    final pool = eligiblePool(ayahs, surahNumber: surahNumber);
    final range = random ?? Random();
    return pool[range.nextInt(pool.length)];
  }
}
