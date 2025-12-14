import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:just_audio/just_audio.dart';

enum PlaybackOwner { reading, test }

class AudioCenter extends ChangeNotifier {
  final AudioServices _audioServices;
  final SurahServices _surahServices;
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _isAutoAdvancing = false;
  PlaybackOwner _playbackOwner = PlaybackOwner.reading;

  PlaybackOwner get playbackOwner => _playbackOwner;

  bool _tryAutoAdvanceToNextSurah() {
    if (_playbackOwner != PlaybackOwner.reading) return false;

    final current = currentSurahNumber;
    if (_isAutoAdvancing ||
        current == null ||
        current >= SurahServices.totalSurahs) {
      return false;
    }

    _isAutoAdvancing = true;

    final nextNumber = current + 1;
    final nextName = surahList
        .firstWhere(
          (s) => s.number == nextNumber,
          orElse: () => Surah(number: nextNumber, englishName: 'Surah'),
        )
        .englishName;

    unawaited(
      toggleSurah(
        Surah(number: nextNumber, englishName: nextName),
        startIndex: 0,
      ).whenComplete(() {
        _isAutoAdvancing = false;
      }),
    );

    return true;
  }

  void _resetPlaybackSession() {
    _isAutoAdvancing = false;
    isPlaying = false;
    isLoading = false;
    currentSurahNumber = null;
    currentSurahName = null;
    notifyListeners();
  }

  void _handlePlaybackCompleted() {
    if (_tryAutoAdvanceToNextSurah()) return;
    _resetPlaybackSession();
  }

  void beginTestSession() {
    if (_playbackOwner == PlaybackOwner.test) return;

    _playbackOwner = PlaybackOwner.test;

    if (_audioServices.audioPlayer.playing) {
      unawaited(_audioServices.pause(audioName: currentSurahName));
    }

    _resetPlaybackSession();
  }

  void endTestSession() {
    if (_playbackOwner != PlaybackOwner.test) return;

    _playbackOwner = PlaybackOwner.reading;
    unawaited(_audioServices.stop(trackEvent: false));
    _resetPlaybackSession();
  }

  AudioCenter({
    required AudioServices audioServices,
    required SurahServices surahServices,
  })  : _audioServices = audioServices,
        _surahServices = surahServices {
    _playerStateSub =
        _audioServices.audioPlayer.playerStateStream.listen((state) {
      if (_playbackOwner == PlaybackOwner.test) return;

      // When playback finishes, just_audio reports `processingState == completed`
      // (and playing is typically false). We need to reset our shared UI state
      // so dashboard/QuranView stop showing an active "Now Playing" session.
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
        return;
      }

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

  void setCurrentSurah(Surah surah) {
    currentSurahNumber = surah.number;
    currentSurahName = surah.englishName;
    notifyListeners();
  }

  Future<void> playSingleAyah(Surah surah, AudioSource source) async {
    if (isLoading) return;

    isLoading = true;
    setCurrentSurah(surah);

    try {
      await _audioServices.setAudioSource(source);
      isPlaying = true;
      unawaited(_audioServices.play(audioName: currentSurahName));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSurah(Surah surah, {int startIndex = 0}) async {
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
      await audioPlayer.seek(Duration.zero, index: startIndex);
      unawaited(_audioServices.play(audioName: fullSurah.englishName));

      isPlaying = true;
    } catch (_) {
      isPlaying = audioPlayer.playing;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playFromAyahIndex(Surah surah, int index) async {
    await toggleSurah(surah, startIndex: index);
  }

  Future<void> stop() async {
    if (isLoading) return;
    isPlaying = false;
    notifyListeners();
    await _audioServices.stop(audioName: currentSurahName);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();

    super.dispose();
  }
}
