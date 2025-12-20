import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/quran_api_providers.dart';
import 'package:hafiz_test/services/quran_db.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/tarteel_audio_resolver.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';

class SurahServices {
  final NetworkServices networkServices;
  final IStorageService storageServices;
  final SurahPicker surahPicker;
  final QuranDb? quranDb;

  SurahServices({
    required this.networkServices,
    required this.storageServices,
    required this.surahPicker,
    this.quranDb,
  });

  static const int totalSurahs = 114;

  static const String translationIdKey = 'translation_id';
  static const String transliterationIdKey = 'transliteration_id';

  String _selectedTranslationId() {
    return storageServices.getString(translationIdKey) ??
        QuranDb.defaultTranslationId;
  }

  String _selectedTransliterationId() {
    return storageServices.getString(transliterationIdKey) ??
        QuranDb.defaultTransliterationId;
  }

  Future<Surah> _withTextData(Surah surah) async {
    final db = quranDb;
    if (db == null) return surah;

    try {
      final rows = await db.getAyahsForSurah(
        surah.number,
        translationId: _selectedTranslationId(),
        transliterationId: _selectedTransliterationId(),
      );

      if (rows.isEmpty) return surah;

      final byAyah = <int, QuranDbAyahRow>{
        for (final r in rows) r.ayah: r,
      };

      final updatedAyahs = surah.ayahs.map((ayah) {
        final row = byAyah[ayah.numberInSurah];
        if (row == null) return ayah;
        return ayah.copyWith(
          translation: row.translation,
          transliteration: row.transliteration,
        );
      }).toList(growable: false);

      return surah.copyWith(ayahs: updatedAyahs);
    } catch (e) {
      // Translation/transliteration are non-critical; never block loading.
      debugPrint('Failed to load DB text data for surah ${surah.number}: $e');
      return surah;
    }
  }

  int getRandomSurahNumber() {
    return surahPicker.getNextSurah();
  }

  Future<Surah?> _getSurahFromDb(int surahNumber) async {
    final db = quranDb;
    if (db == null) return null;

    try {
      final rows = await db.getAyahsForSurah(
        surahNumber,
        translationId: _selectedTranslationId(),
        transliterationId: _selectedTransliterationId(),
      );

      if (rows.isEmpty) return null;

      final surah = findSurahByNumber(surahNumber);

      final ayahs = rows.map(
        (r) {
          return Ayah(
            number: 0,
            text: r.textAr,
            translation: r.translation,
            transliteration: r.transliteration,
            numberInSurah: r.ayah,
            juz: r.juz ?? 0,
            manzil: r.manzil ?? 0,
            page: r.page ?? 0,
            ruku: r.ruku ?? 0,
            hizbQuarter: r.hizbQuarter ?? 0,
            surah: surah,
          );
        },
      ).toList(growable: false);

      final surahWithMeta = Surah(
        number: surah.number,
        name: surah.name,
        englishName: surah.englishName,
        englishNameTranslation: surah.englishNameTranslation,
        revelationType: surah.revelationType,
        numberOfAyahs: surah.numberOfAyahs,
        ayahs: ayahs,
      );

      final reciterId = storageServices.getReciterId();

      // When we load from DB, we can still attach audio URLs (online) without
      // any network check by using our known reciter templates.
      final reciterType = TarteelAudio.reciterType(reciterId);
      if (reciterType == RecitationType.surahbysurah) {
        return TarteelAudio.withSurahAudioForSurahByReciter(
          surahWithMeta,
          reciterId: reciterId,
        );
      }

      if (reciterType == RecitationType.versebyverse) {
        return TarteelAudio.withAudioForSurahByReciter(
          surahWithMeta,
          reciterId: reciterId,
        );
      }

      return surahWithMeta;
    } catch (e) {
      debugPrint('Failed to load surah $surahNumber from DB: $e');
      return null;
    }
  }

  Future<Surah> getSurah(int surahNumber) async {
    final cached = await _getSurahFromDb(surahNumber);
    if (cached != null && cached.ayahs.isNotEmpty) {
      return cached;
    }

    try {
      final reciterId = storageServices.getReciterId();
      final tarteel = await TarteelAudioResolver.resolve(
        networkServices: networkServices,
        reciterId: reciterId,
        surahNumber: surahNumber,
      );

      final path =
          'surah/$surahNumber/${tarteel.enabled ? 'quran-uthmani' : reciterId}';

      // On web we rely on NetworkServices' proxy baseUrl (CORS). Avoid absolute
      // provider URLs there.
      final candidates =
          kIsWeb ? const <String?>[null] : QuranApiProviders.baseUrls;

      for (final base in candidates) {
        final url = (base == null) ? path : '$base$path';

        try {
          final response = await networkServices.get(url);
          final body = response.data;
          if (body != null) {
            final surah = Surah.fromJson(body['data']);

            final surahWithMeta = await _withTextData(surah);

            if (tarteel.mode == TarteelMode.surah) {
              return TarteelAudio.withSurahAudioForSurahByReciter(
                surahWithMeta,
                reciterId: reciterId,
              );
            }

            if (tarteel.mode == TarteelMode.verse) {
              return TarteelAudio.withAudioForSurahByReciter(
                surahWithMeta,
                reciterId: reciterId,
              );
            }

            return surahWithMeta;
          }
        } on FormatException catch (e) {
          // Some providers/proxies may occasionally return a non-JSON payload
          // (e.g. HTML error page). Treat this as a provider failure and try
          // the next provider.
          debugPrint('Invalid response format from $url: $e');
          continue;
        } on DioException catch (e) {
          final code = e.response?.statusCode;
          // If this provider doesn't support the reciter, try next.
          if (code == 400 || code == 404) {
            continue;
          }

          // On slow/unstable networks, try the next provider.
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError) {
            continue;
          }
          rethrow;
        } catch (e) {
          // Any other unexpected parsing/runtime error from this provider:
          // try next provider.
          debugPrint('Error loading surah from $url: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }

    throw Exception('Failed to load surah $surahNumber');
  }
}
