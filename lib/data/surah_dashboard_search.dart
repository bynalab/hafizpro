import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/quran_surah_ayah_reference.dart';

import 'surah_list.dart';

/// Result of resolving the Quran dashboard surah search field.
class SurahDashboardSearchResult {
  const SurahDashboardSearchResult({
    required this.surahs,
    this.initialAyahNumber,
  });

  final List<Surah> surahs;

  /// When set, open the reader at this 1-based ayah (verse reference search).
  final int? initialAyahNumber;

  /// Empty query: full catalog, no deep link.
  static SurahDashboardSearchResult allSurahs() {
    return SurahDashboardSearchResult(surahs: surahList);
  }
}

/// Surah tab search: name filter, digits-only surah number, or `surah:ayah` deep link.
///
/// Invalid `surah:ayah` (unknown surah or ayah out of range) yields an empty list.
SurahDashboardSearchResult resolveSurahDashboardSearch(String query) {
  final q = query.trim();
  if (q.isEmpty) {
    return SurahDashboardSearchResult.allSurahs();
  }

  final ref = tryParseSurahAyahReference(q);
  if (ref != null) {
    if (!ref.isValid) {
      return const SurahDashboardSearchResult(surahs: []);
    }

    final surah = ref.surahMetadata;
    return SurahDashboardSearchResult(
      surahs: [surah],
      initialAyahNumber: ref.ayahNumber,
    );
  }

  final surahByNumber = tryResolveSurahFromNumberOnlyDigits(q);
  if (surahByNumber != null) {
    return SurahDashboardSearchResult(surahs: [surahByNumber]);
  }

  return SurahDashboardSearchResult(surahs: searchSurah(q));
}
