import 'package:hafiz_test/model/ayah.model.dart';

/// One Madani mushaf page (or a single fallback slice) within the current surah.
class MushafPageSlice {
  const MushafPageSlice({
    required this.mushafPageNumber,
    required this.ayahIndices,
  });

  /// Standard mushaf page 1–604; `0` when metadata is missing (whole surah on one “page”).
  final int mushafPageNumber;

  /// Indices into [Surah.ayahs], in surah order.
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
