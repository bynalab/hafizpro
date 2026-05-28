import 'package:flutter/foundation.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_download_service.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/surah_source.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/tarteel_audio_resolver.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';

import 'package:hafiz_test/util/internet_checker.dart';

class SurahServices {
  final NetworkServices networkServices;
  final IStorageService storageServices;
  final SurahPicker surahPicker;
  final SurahSource surahSource;
  final AudioDownloadService audioDownloadService;

  SurahServices({
    required this.networkServices,
    required this.storageServices,
    required this.surahPicker,
    required this.surahSource,
    required this.audioDownloadService,
  });

  static const int totalSurahs = 114;

  int getRandomSurahNumber() {
    return surahPicker.getNextSurah();
  }

  /// Retrieves the processed Surah database structure, resolving local audio sources
  /// and, optionally, remote streaming mirrors.
  /// 
  /// The [forPlayback] flag specifies if the call is intended to initialize audio playback:
  /// - If `true`, the resolver will actively ping networks to locate the best online mirror
  ///   for streaming and throw an internet exception if the user is offline and the audio
  ///   is not downloaded.
  /// - If `false` (default), the Surah text and local audio references are resolved silently
  ///   and instantly, allowing fully offline viewing/reading without throwing network errors.
  Future<Surah> getSurah(int surahNumber, {bool forPlayback = false}) async {
    try {
      final reciterId = storageServices.getReciterId();
      
      // Get the format mode instantly without checking network
      TarteelSelection tarteel = await TarteelAudioResolver.resolve(
        networkServices: networkServices,
        reciterId: reciterId,
        surahNumber: surahNumber,
        checkNetwork: false,
      );

      final surah = await surahSource.getSurah(surahNumber);
      
      final isDownloaded = await audioDownloadService.isSurahDownloaded(
          surahNumber, reciterId, tarteel, surah);
          
      // If we don't have all local files, we MUST ping the network to find the best mirror for streaming.
      if (!isDownloaded) {
        if (forPlayback) {
          final hasNet = await hasInternetConnection();
          if (!hasNet) {
            throw Exception('Internet connection is required to stream this Surah.');
          }
        }

        tarteel = await TarteelAudioResolver.resolve(
          networkServices: networkServices,
          reciterId: reciterId,
          surahNumber: surahNumber,
          checkNetwork: forPlayback,
        );
      }

      Surah processedSurah = surah;

      if (tarteel.mode == TarteelMode.surah) {
        processedSurah = TarteelAudio.withSurahAudioForSurahByReciter(
          surah,
          reciterId: reciterId,
        );
      } else if (tarteel.mode == TarteelMode.verse) {
        processedSurah = TarteelAudio.withAudioForSurahByReciter(
          surah,
          reciterId: reciterId,
        );
      }

      if (tarteel.mode != TarteelMode.none) {
        final ayahsWithLocalAudio = <Ayah>[];
        for (final ayah in processedSurah.ayahs) {
          final localUrl = await audioDownloadService.getLocalAudioUrlIfExists(
            reciterId,
            surahNumber,
            ayahNumber:
                tarteel.mode == TarteelMode.verse ? ayah.numberInSurah : null,
          );

          if (localUrl != null) {
            ayahsWithLocalAudio.add(ayah.copyWith(audio: localUrl));
          } else {
            ayahsWithLocalAudio.add(ayah);
          }
        }
        processedSurah = processedSurah.copyWith(ayahs: ayahsWithLocalAudio);
      }

      return processedSurah;
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }
}
