import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/data/juz_list.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/juz.model.dart';
import 'package:hafiz_test/model/surah.model.dart';

int deriveAyahCount(
  JuzModel juz,
  List<Surah> surahs,
) {
  int total = 0;

  for (int s = juz.startSurah; s <= juz.endSurah; s++) {
    final surah = surahs.firstWhere((x) => x.number == s);

    if (s == juz.startSurah && s == juz.endSurah) {
      total += juz.endAyah - juz.startAyah + 1;
    } else if (s == juz.startSurah) {
      total += surah.numberOfAyahs - juz.startAyah + 1;
    } else if (s == juz.endSurah) {
      total += juz.endAyah;
    } else {
      total += surah.numberOfAyahs;
    }
  }

  return total;
}

int deriveSurahCount(JuzModel juz) {
  return juz.endSurah - juz.startSurah + 1;
}

void main() {
  test('Juz data integrity', () {
    for (final juz in juzList) {
      expect(
        deriveSurahCount(juz),
        juz.surahCount,
        reason: 'Surah count mismatch in Juz ${juz.number}',
      );

      expect(
        deriveAyahCount(juz, surahList),
        juz.ayahCount,
        reason: 'Ayah count mismatch in Juz ${juz.number}',
      );
    }
  });
}
