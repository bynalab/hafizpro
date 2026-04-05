import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/util/bismillah.dart';

/// One ayah in a [QuranVerseFocusPanel] sequence (single surah or juz).
class VerseFocusItem {
  const VerseFocusItem({
    required this.surah,
    required this.ayah,
    required this.displayArabic,
    required this.playingIndex,
  });

  final Surah surah;
  final Ayah ayah;

  /// Arabic shown in the card (e.g. bismillah trimmed for first ayah).
  final String displayArabic;

  /// Index matched against [playingIndexNotifier] (surah-local or juz-global).
  final int playingIndex;
}

List<VerseFocusItem> verseFocusItemsForSurah(
  Surah surah, {
  required bool showBismillah,
}) {
  return List.generate(
    surah.ayahs.length,
    (i) => VerseFocusItem(
      surah: surah,
      ayah: surah.ayahs[i],
      displayArabic: (showBismillah && i == 0)
          ? Bismillah.trimLeadingForDisplay(surah.ayahs[i].text)
          : surah.ayahs[i].text,
      playingIndex: i,
    ),
  );
}
