import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/util/test_random_ayah.dart';

void main() {
  group('TestRandomAyah', () {
    test('pick excludes surah first and last when surahNumber provided', () {
      final s = Surah(number: 112, numberOfAyahs: 4);
      final ayahs = [
        Ayah(numberInSurah: 1, surah: s),
        Ayah(numberInSurah: 2, surah: s),
        Ayah(numberInSurah: 3, surah: s),
        Ayah(numberInSurah: 4, surah: s),
      ];
      final r = TestRandomAyah.pick(ayahs, surahNumber: 112, random: Random(0));
      expect([2, 3], contains(r.numberInSurah));
    });

    test('pick uses per-ayah surah metadata for mixed lists', () {
      final s112 = Surah(number: 112, numberOfAyahs: 4);
      final ayahs = [
        Ayah(numberInSurah: 1, surah: s112),
        Ayah(numberInSurah: 2, surah: s112),
      ];
      final r = TestRandomAyah.pick(ayahs, random: Random(0));
      expect(r.numberInSurah, equals(2));
    });

    test('pick returns full list when only two ayahs (unavoidable edges)', () {
      final s = Surah(number: 91, numberOfAyahs: 15);
      final ayahs = [
        Ayah(numberInSurah: 1, surah: s),
        Ayah(numberInSurah: 15, surah: s),
      ];
      final r = TestRandomAyah.pick(ayahs, surahNumber: 91, random: Random(1));
      expect([1, 15], contains(r.numberInSurah));
    });
  });
}
