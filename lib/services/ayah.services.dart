import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/quran_api_providers.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/tarteel_audio_resolver.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';

class AyahServices {
  final NetworkServices networkServices;
  final IStorageService storageServices;

  AyahServices({
    required this.networkServices,
    required this.storageServices,
  });

  Future<List<Ayah>> getSurahAyahs(int surahNumber) async {
    try {
      final reciterId = storageServices.getReciterId();
      final tarteel = await TarteelAudioResolver.resolve(
        networkServices: networkServices,
        reciterId: reciterId,
        surahNumber: surahNumber,
      );

      final path =
          'surah/$surahNumber/${tarteel.enabled ? 'quran-uthmani' : reciterId}';

      final candidates =
          kIsWeb ? const <String?>[null] : QuranApiProviders.baseUrls;

      for (final base in candidates) {
        final url = (base == null) ? path : '$base$path';
        try {
          final response = await networkServices.get(url);
          if (response.data != null) {
            final ayahs = Ayah.fromJsonList(response.data['data']['ayahs']);

            if (tarteel.mode == TarteelMode.surah) {
              return TarteelAudio.withSurahAudioForAyahsByReciter(
                ayahs,
                surahNumber: surahNumber,
                reciterId: reciterId,
              );
            }

            if (tarteel.mode == TarteelMode.verse) {
              return TarteelAudio.withAudioForAyahsByReciter(
                ayahs,
                surahNumber: surahNumber,
                reciterId: reciterId,
              );
            }

            return ayahs;
          }
        } on DioException catch (e) {
          final code = e.response?.statusCode;
          if (code == 400 || code == 404) {
            continue;
          }
          rethrow;
        }
      }
    } catch (error) {
      if (kDebugMode) print('getSurahAyahs error: $error');
    }

    return [];
  }

  Future<Ayah> getRandomAyahFromJuz(int juzNumber) async {
    try {
      final response =
          await networkServices.get('juz/$juzNumber/quran-uthmani');

      if (response.data != null) {
        final ayahs = Ayah.fromJsonList(response.data['data']['ayahs']);
        return getRandomAyahForSurah(ayahs);
      }
    } catch (error) {
      if (kDebugMode) print('getRandomAyahFromJuz error: $error');
    }

    return Ayah();
  }

  Ayah getRandomAyahForSurah(List<Ayah> ayahs) {
    try {
      if (ayahs.isEmpty) return Ayah();

      final random = Random();
      final ayah = ayahs[random.nextInt(ayahs.length)];
      return ayah;
    } catch (error) {
      if (kDebugMode) print('getRandomAyahForSurah error: $error');
    }

    return Ayah();
  }
}
