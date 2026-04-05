import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/util/bismillah.dart';

/// One line of Arabic in mushaf order (single surah or juz sequence).
class MushafVerseLine {
  const MushafVerseLine({
    required this.surah,
    required this.ayah,
    required this.displayArabic,
    required this.playingIndex,
  });

  final Surah surah;
  final Ayah ayah;
  final String displayArabic;

  /// Matched with [ValueNotifier] for highlight / audio (surah-local or juz-global).
  final int playingIndex;
}

/// One Madani mushaf page (or a single fallback slice) within a verse sequence.
class MushafPageSlice {
  const MushafPageSlice({
    required this.mushafPageNumber,
    required this.ayahIndices,
  });

  /// Standard mushaf page 1–604; `0` when metadata is missing (whole surah on one “page”).
  final int mushafPageNumber;

  /// Indices into [MushafVerseLine] list or [Surah.ayahs] (same order).
  final List<int> ayahIndices;
}

/// Groups the surah’s ayat by [Ayah.page] (Madani page) while preserving order.
///
/// Ayat with `page <= 0` are folded into the previous known page, or page `0` if none.
List<MushafPageSlice> buildMushafSlicesForSurah(List<Ayah> ayahs) {
  if (ayahs.isEmpty) return const [];

  final orderedKeys = <int>[];
  final byPage = <int, List<int>>{};
  var carryPage = 0;

  for (var i = 0; i < ayahs.length; i++) {
    var p = ayahs[i].page;
    if (p > 0) {
      carryPage = p;
    } else {
      p = carryPage;
    }

    if (!byPage.containsKey(p)) {
      orderedKeys.add(p);
      byPage[p] = [];
    }
    byPage[p]!.add(i);
  }

  return orderedKeys
      .map((k) => MushafPageSlice(
            mushafPageNumber: k,
            ayahIndices: byPage[k]!,
          ))
      .toList(growable: false);
}

int mushafSliceIndexForAyahIndex(List<MushafPageSlice> slices, int ayahIndex) {
  for (var s = 0; s < slices.length; s++) {
    if (slices[s].ayahIndices.contains(ayahIndex)) return s;
  }
  return 0;
}

/// Builds [MushafVerseLine]s for a whole surah (same order as [Surah.ayahs]).
List<MushafVerseLine> mushafLinesForSurah(
  Surah surah, {
  required bool showBismillah,
}) {
  return List.generate(
    surah.ayahs.length,
    (i) => MushafVerseLine(
      surah: surah,
      ayah: surah.ayahs[i],
      displayArabic: (showBismillah && i == 0)
          ? Bismillah.trimLeadingForDisplay(surah.ayahs[i].text)
          : surah.ayahs[i].text,
      playingIndex: i,
    ),
  );
}
