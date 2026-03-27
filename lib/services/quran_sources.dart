import 'package:hafiz_test/services/surah_source.dart';
import 'package:hafiz_test/services/quran_search_service.dart';

class QuranSources {
  final SurahSource surahSource;
  final QuranSearchService searchService;

  QuranSources({
    required this.surahSource,
    required this.searchService,
  });
}
