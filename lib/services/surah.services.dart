import 'package:flutter/foundation.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/surah_picker.dart';

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
      final reciter = storageServices.getReciter();
      final response = await networkServices.get('surah/$surahNumber/$reciter');
      final body = response.data;

      if (body != null) {
        return Surah.fromJson(body['data']);
      }
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }

    return Surah();
  }
}
