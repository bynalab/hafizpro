import 'package:hafiz_test/util/util.dart';

/// Normalizes ayah Arabic for on-screen display (strip decorative markers, etc.).
class QuranArabicDisplay {
  QuranArabicDisplay._();

  static final RegExp _arabicIndicDigits =
      RegExp(r'[\u0660-\u0669\u06F0-\u06F9]');
  static final RegExp _quranMarkers = RegExp(
    r'[\u06DD\u06DE\u06E9\u06D7\u06D8\u06D9\u06DA\u06DB\u06DC\u06DF\u06E0\u06E1\u06E2\u06E3\u06E4\u06E5\u06E6\u06E7\u06E8\u06EA\u06EB\u06EC\u06ED\u0640]'
    r'|[﴿﴾]'
    r'|\(\d+\)'
    r'|\[\d+\]',
  );

  static String forCard(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .replaceAll(_quranMarkers, '')
        .replaceAll(_arabicIndicDigits, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String ayahNumberOrnament(int numberInSurah) {
    return '﴿${toArabicIndicDigits(numberInSurah.toString())}﴾';
  }
}
