import 'package:hafiz_test/services/quran_sources.dart';
import 'package:hafiz_test/services/surah_source.dart';
import 'package:hafiz_test/services/quran_search_service.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/quran_db.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/surah.model.dart';

class DbSurahSource implements SurahSource {
  final QuranDb db;
  final String Function() translationId;
  final String Function() transliterationId;

  DbSurahSource({
    required this.db,
    required this.translationId,
    required this.transliterationId,
  });

  QuranDb get quranDb => db;

  @override
  Future<Surah> getSurah(int surahNumber) async {
    final rows = await db.getAyahsForSurah(
      surahNumber,
      translationId: translationId(),
      transliterationId: transliterationId(),
    );

    if (rows.isEmpty) throw StateError('No cached surah $surahNumber in DB');

    final surah = findSurahByNumber(surahNumber);
    final ayahs = rows.map((row) => row.toAyah(surah)).toList(growable: false);

    return surah.copyWith(ayahs: ayahs);
  }
}

Future<QuranSources> createQuranSources({
  required NetworkServices networkServices,
  required IStorageService storageServices,
}) async {
  final db = QuranDb();
  await db.init();
  
  if (!getIt.isRegistered<QuranDb>()) {
    getIt.registerSingleton<QuranDb>(db);
  }

  final searchService = QuranSearchService.db(db: db);
  // We don't await init here to avoid blocking startup,
  // but it will be ready soon.
  searchService.init();

  return QuranSources(
    surahSource: DbSurahSource(
      db: db,
      translationId: () =>
          storageServices.getString('translation_id') ?? 'en_khattab',
      transliterationId: () =>
          storageServices.getString('transliteration_id') ?? 'tr_default',
    ),
    searchService: searchService,
  );
}
