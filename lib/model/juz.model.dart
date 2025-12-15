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
}
