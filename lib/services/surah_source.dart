import 'package:hafiz_test/model/surah.model.dart';

abstract interface class SurahSource {
  Future<Surah> getSurah(int surahNumber);
}
