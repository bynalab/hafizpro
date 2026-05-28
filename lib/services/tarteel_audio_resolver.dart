import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/util/reciter_audio_profile.dart';
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
  static Future<int?> _firstReachableAyahSourceIndex({
    required NetworkServices networkServices,
    required String reciterId,
    required int surahNumber,
  }) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.every((r) => r == ConnectivityResult.none)) return null;

    final profile = ReciterAudioProfiles.forReciter(reciterId);
    final sources = profile?.sources ?? const <ReciterAudioSource>[];
    for (var i = 0; i < sources.length; i++) {
      final url = TarteelAudio.ayahUrlForSource(
        sources[i],
        surahNumber,
        1,
        ayahGlobal: 1,
      );

      if (url.trim().isEmpty) continue;

      final ok = await networkServices.urlExists(url);
      if (ok) return i;
    }

    return null;
  }

  static Future<int?> _firstReachableSurahSourceIndex({
    required NetworkServices networkServices,
    required String reciterId,
    required int surahNumber,
  }) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.every((r) => r == ConnectivityResult.none)) return null;

    final profile = ReciterAudioProfiles.forReciter(reciterId);
    final sources = profile?.sources ?? const <ReciterAudioSource>[];

    for (var i = 0; i < sources.length; i++) {
      final url = TarteelAudio.surahUrlForSource(sources[i], surahNumber);
      if (url.trim().isEmpty) continue;

      final ok = await networkServices.urlExists(url);
      if (ok) return i;
    }

    return null;
  }

  static Future<TarteelSelection> resolve({
    required NetworkServices networkServices,
    required String reciterId,
    required int surahNumber,
    bool checkNetwork = true,
  }) async {
    final reciterType = TarteelAudio.reciterType(reciterId);

    final surahBase = TarteelAudio.surahBaseForReciter(reciterId);
    if (reciterType == RecitationType.surahbysurah && surahBase != null) {
      if (checkNetwork) {
        int? sourceIndex = ReciterAudioProfiles.preferredSourceIndexForReciter(reciterId);
        
        if (sourceIndex == null) {
          sourceIndex = await _firstReachableSurahSourceIndex(
            networkServices: networkServices,
            reciterId: reciterId,
            surahNumber: surahNumber,
          );

          if (sourceIndex != null) {
            ReciterAudioProfiles.setPreferredSourceIndexForReciter(
              reciterId,
              sourceIndex,
            );
          }
        }
      }

      return TarteelSelection._(
        mode: TarteelMode.surah,
        ayahBase: null,
        surahBase: surahBase,
      );
    }

    final ayahBase = TarteelAudio.ayahBaseForReciter(reciterId);
    if (reciterType == RecitationType.versebyverse && ayahBase != null) {
      if (checkNetwork) {
        int? sourceIndex = ReciterAudioProfiles.preferredSourceIndexForReciter(reciterId);
        
        if (sourceIndex == null) {
          sourceIndex = await _firstReachableAyahSourceIndex(
            networkServices: networkServices,
            reciterId: reciterId,
            surahNumber: surahNumber,
          );

          if (sourceIndex != null) {
            ReciterAudioProfiles.setPreferredSourceIndexForReciter(
              reciterId,
              sourceIndex,
            );
          }
        }
      }

      return TarteelSelection._(
        mode: TarteelMode.verse,
        ayahBase: ayahBase,
        surahBase: null,
      );
    }

    return const TarteelSelection._(
      mode: TarteelMode.none,
      ayahBase: null,
      surahBase: null,
    );
  }
}
