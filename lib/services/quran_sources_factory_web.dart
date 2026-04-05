import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/ayah_text_source.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/quran_api_providers.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/quran_sources.dart';
import 'package:hafiz_test/services/quran_search_service.dart';
import 'package:hafiz_test/services/quran_db.dart';
import 'package:hafiz_test/services/surah_source.dart';

class NetworkSurahSource implements SurahSource {
  final NetworkServices networkServices;
  final IStorageService storageServices;

  NetworkSurahSource({
    required this.networkServices,
    required this.storageServices,
  });

  QuranDb? get quranDb => null;

  @override
  Future<Surah> getSurah(int surahNumber) async {
    final path = 'surah/$surahNumber/quran-uthmani';
    final candidates =
        kIsWeb ? const <String?>[null] : QuranApiProviders.baseUrls;

    Surah? surah;
    for (final base in candidates) {
      final url = (base == null) ? path : '$base$path';

      try {
        final response = await networkServices.get(url);
        final body = response.data;
        if (body != null) {
          surah = Surah.fromJson(body['data']);
          break;
        }
      } on FormatException {
        continue;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 400 || code == 404) continue;

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          continue;
        }
        rethrow;
      } catch (_) {
        continue;
      }
    }

    if (surah == null) {
      throw Exception('Failed to load surah $surahNumber');
    }

    return _withTextOverlay(surah);
  }

  Future<Surah> _withTextOverlay(Surah surah) async {
    try {
      final translationId =
          storageServices.getString('translation_id') ?? 'en_default';
      final transliterationId =
          storageServices.getString('transliteration_id') ?? 'tr_default';

      final textSource = SurahMetaAssetAyahTextSource();
      final byAyah = await textSource.getTextForSurah(
        surah.number,
        translationId: translationId,
        transliterationId: transliterationId,
      );

      if (byAyah.isEmpty) return surah;

      final updatedAyahs = surah.ayahs.map((ayah) {
        final text = byAyah[ayah.numberInSurah];
        if (text == null) return ayah;
        return ayah.copyWith(
          translation: text.translation,
          transliteration: text.transliteration,
        );
      }).toList(growable: false);

      return surah.copyWith(ayahs: updatedAyahs);
    } catch (_) {
      return surah;
    }
  }
}

Future<QuranSources> createQuranSources({
  required NetworkServices networkServices,
  required IStorageService storageServices,
}) async {
  final source = NetworkSurahSource(
    networkServices: networkServices,
    storageServices: storageServices,
  );

  final searchService =
      QuranSearchService(db: QuranDb()); // Will fail but keeps types happy

  return QuranSources(
    surahSource: source,
    searchService: searchService,
  );
}
