import 'package:flutter/foundation.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/surah_source.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/tarteel_audio_resolver.dart';
import 'package:hafiz_test/util/surah_picker.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';

class SurahServices {
  final NetworkServices networkServices;
  final IStorageService storageServices;
  final SurahPicker surahPicker;
  final SurahSource surahSource;

  SurahServices({
    required this.networkServices,
    required this.storageServices,
    required this.surahPicker,
    required this.surahSource,
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

      final surah = await surahSource.getSurah(surahNumber);

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
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }
}
