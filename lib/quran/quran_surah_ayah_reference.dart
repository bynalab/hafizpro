import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/surah.model.dart';

/// A surah + verse coordinate in user-facing form (e.g. from search `2:255`).
class QuranSurahAyahReference {
  const QuranSurahAyahReference({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  /// Metadata from [surahList], or `null` if [surahNumber] is not 1–114.
  Surah get surahMetadata {
    return findSurahByNumber(surahNumber);
  }

  /// True when the surah exists and [ayahNumber] is within that surah’s length.
  bool get isValid {
    final surah = surahMetadata;
    return ayahNumber >= 1 && ayahNumber <= surah.numberOfAyahs;
  }
}

/// Parses a strict `surah:ayah` token (ASCII or fullwidth colon).
///
/// Examples: `2:255`, `02 : 17`, `114：6` (fullwidth colon).
/// Returns `null` if [raw] does not match the pattern (so name search can run).
QuranSurahAyahReference? tryParseSurahAyahReference(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(
    r'^(\d{1,3})\s*[:：﹕]\s*(\d{1,3})$',
  ).firstMatch(trimmed);

  if (match == null) return null;

  final surahNumber = int.tryParse(match.group(1)!);
  final ayahNumber = int.tryParse(match.group(2)!);
  if (surahNumber == null || ayahNumber == null) return null;

  return QuranSurahAyahReference(
    surahNumber: surahNumber,
    ayahNumber: ayahNumber,
  );
}

/// When [raw] is **only** digits (e.g. `2`, `012`, `114`), resolves to that surah.
///
/// Returns `null` if the string contains anything else or the number is not 1–114,
/// so normal name search can run.
Surah? tryResolveSurahFromNumberOnlyDigits(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  if (!RegExp(r'^\d{1,3}$').hasMatch(trimmed)) return null;

  final surahNumber = int.tryParse(trimmed);
  if (surahNumber == null || surahNumber < 1 || surahNumber > 114) {
    return null;
  }

  return findSurahByNumber(surahNumber);
}
