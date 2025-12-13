import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:just_audio/just_audio.dart';

class AudioCenter extends ChangeNotifier {
  final AudioServices _audioServices;
  final SurahServices _surahServices;
  StreamSubscription<PlayerState>? _playerStateSub;

  AudioCenter({
    required AudioServices audioServices,
    required SurahServices surahServices,
  })  : _audioServices = audioServices,
        _surahServices = surahServices {
    _playerStateSub =
        _audioServices.audioPlayer.playerStateStream.listen((state) {
      final newPlaying = state.playing;
      if (newPlaying == isPlaying) return;

      isPlaying = newPlaying;
      notifyListeners();
    });
  }

  int? currentSurahNumber;
  String? currentSurahName;
  bool isPlaying = false;
  bool isLoading = false;

  AudioPlayer get audioPlayer => _audioServices.audioPlayer;

  bool isCurrentSurah(int surahNumber) => currentSurahNumber == surahNumber;

  Future<void> toggleSurah(Surah surah) async {
    if (isLoading) return;

    final audioPlayer = _audioServices.audioPlayer;

    if (currentSurahNumber == surah.number) {
      if (audioPlayer.playing) {
        isPlaying = false;
        notifyListeners();
        await _audioServices.pause(audioName: currentSurahName);
      } else {
        isPlaying = true;
        notifyListeners();
        unawaited(_audioServices.play(audioName: currentSurahName));
      }
      return;
    }

    isLoading = true;
    currentSurahNumber = surah.number;
    currentSurahName = surah.englishName;
    notifyListeners();

    try {
      final fullSurah = await _surahServices.getSurah(surah.number);
      if (fullSurah.ayahs.isEmpty) return;

      currentSurahName = fullSurah.englishName;
      await _audioServices.setPlaylistAudio(fullSurah.audioSources);
      await audioPlayer.seek(Duration.zero, index: 0);
      unawaited(_audioServices.play(audioName: fullSurah.englishName));

      isPlaying = true;
    } catch (_) {
      isPlaying = audioPlayer.playing;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();

    super.dispose();
  }
}
