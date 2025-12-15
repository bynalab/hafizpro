class JuzModel {
  final int number;
  final String name;

  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  final int surahCount;
  final int ayahCount;

  const JuzModel({
    required this.number,
    required this.name,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.surahCount,
    required this.ayahCount,
  });

  List<JuzSurahRange> surahRanges() {
    final ranges = <JuzSurahRange>[];

    for (int surahNumber = startSurah; surahNumber <= endSurah; surahNumber++) {
      final rangeStartAyah = surahNumber == startSurah ? startAyah : 1;
      final rangeEndAyah = surahNumber == endSurah ? endAyah : null;

      ranges.add(
        JuzSurahRange(
          surahNumber: surahNumber,
          startAyah: rangeStartAyah,
          endAyah: rangeEndAyah,
        ),
      );
    }

    return ranges;
  }
}

class JuzSurahRange {
  final int surahNumber;
  final int startAyah;
  final int? endAyah;

  const JuzSurahRange({
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
  });
}
