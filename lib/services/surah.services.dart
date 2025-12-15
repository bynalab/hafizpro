import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/quran_api_providers.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/tarteel_audio_resolver.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';

class SurahServices {
  final NetworkServices networkServices;
  final IStorageService storageServices;
  final SurahPicker surahPicker;

  SurahServices({
    required this.networkServices,
    required this.storageServices,
    required this.surahPicker,
  });

  static const int totalSurahs = 114;

  int getRandomSurahNumber() {
    return surahPicker.getNextSurah();
  }

  Future<Surah> getSurah(int surahNumber) async {
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

            if (tarteel.mode == TarteelMode.surah) {
              return TarteelAudio.withSurahAudioForSurahByReciter(
                surah,
                reciterId: reciterId,
              );
            }

            if (tarteel.mode == TarteelMode.verse) {
              return TarteelAudio.withAudioForSurahByReciter(
                surah,
                reciterId: reciterId,
              );
            }

            return surah;
          }
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
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }

    throw Exception('Failed to load surah $surahNumber');
  }
}
