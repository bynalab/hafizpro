import 'package:flutter/foundation.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';

enum TarteelMode { none, surah, verse }

class RecitationType {
  static const String surahbysurah = 'surahbysurah';
  static const String versebyverse = 'versebyverse';
}

class TarteelSelection {
  final TarteelMode mode;
  final String? ayahBase;
  final String? surahBase;

  const TarteelSelection._({
    required this.mode,
    required this.ayahBase,
    required this.surahBase,
  });

  bool get enabled => mode != TarteelMode.none;
}

class TarteelAudioResolver {
  static Future<TarteelSelection> resolve({
    required NetworkServices networkServices,
    required String reciterId,
    required int surahNumber,
  }) async {
    if (kIsWeb) {
      return const TarteelSelection._(
        mode: TarteelMode.none,
        ayahBase: null,
        surahBase: null,
      );
    }

    final reciterType = TarteelAudio.reciterType(reciterId);

    final surahBase = TarteelAudio.surahBaseForReciter(reciterId);
    if (reciterType == RecitationType.surahbysurah && surahBase != null) {
      final ok = await networkServices.urlExists(
        TarteelAudio.surahUrlForReciter(reciterId, surahNumber),
      );

      if (ok) {
        return TarteelSelection._(
          mode: TarteelMode.surah,
          ayahBase: null,
          surahBase: surahBase,
        );
      }
    }

    final ayahBase = TarteelAudio.ayahBaseForReciter(reciterId);
    if (reciterType == RecitationType.versebyverse && ayahBase != null) {
      final ok = await networkServices.urlExists(
        TarteelAudio.ayahUrlForReciter(reciterId, surahNumber, 1),
      );

      if (ok) {
        return TarteelSelection._(
          mode: TarteelMode.verse,
          ayahBase: ayahBase,
          surahBase: null,
        );
      }
    }

    return const TarteelSelection._(
      mode: TarteelMode.none,
      ayahBase: null,
      surahBase: null,
    );
  }
}
