class Bismillah {
  static const Set<int> _noBismillahPreSurahs = {1, 9};

  static const String glyph = '﷽';

  static const String plain = 'بسم الله الرحمن الرحيم';
  static const String withTashkeel = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  static bool shouldShow(int? surahNumber) {
    if (surahNumber == null) return false;
    return !_noBismillahPreSurahs.contains(surahNumber);
  }

  static String trimLeadingForDisplay(String text) {
    final trimmedLeft = text.trimLeft();

    if (trimmedLeft.startsWith(plain)) {
      return trimmedLeft.substring(plain.length).trimLeft();
    }

    if (trimmedLeft.startsWith(withTashkeel)) {
      return trimmedLeft.substring(withTashkeel.length).trimLeft();
    }

    return text;
  }
}
