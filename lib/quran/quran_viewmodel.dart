import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/rating_service.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class QuranViewModel {
  final AudioServices audioService;
  final SurahServices surahService;

  final itemScrollController = ItemScrollController();

  QuranViewModel({required this.audioService, required this.surahService});

  late Surah surah;
  bool isLoading = true;
  bool hasError = false;
  bool isPlaylist = false;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _currentIndexSub;

  final playingIndexNotifier = ValueNotifier<int?>(null);
  final isPlayingNotifier = ValueNotifier<bool>(false);

  AudioPlayer get audioPlayer => audioService.audioPlayer;

  Future<void> initialize(int surahNumber) async {
    try {
      isLoading = true;
      surah = await surahService.getSurah(surahNumber);
      if (surah.ayahs.isEmpty) return;

      await audioService.setPlaylistAudio(surah.audioSources);
      hasError = false;
    } catch (e) {
      debugPrint('Error loading surah: $e');
      hasError = true;
    } finally {
      isLoading = false;
    }
  }

  void initiateListeners() {
    _playerStateSub = audioPlayer.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;

      if (state.playing && state.processingState == ProcessingState.ready) {
        AnalyticsService.trackAudioStart(
          surah.englishName,
          surahName: surah.englishName,
          isPlaylist: isPlaylist,
        );
      }

      if (state.processingState == ProcessingState.completed) {
        isPlayingNotifier.value = false;
        isPlaylist = false;

        AnalyticsService.trackAudioComplete(
          surah.englishName,
          surahName: surah.englishName,
          wasPlaylist: true,
        );

        // Track surah listening completion for rating system
        RatingService.trackSurahListened();
      }
    });

    _currentIndexSub = audioPlayer.currentIndexStream.listen((index) {
      if (index != null && isPlaylist) {
        playingIndexNotifier.value = index;
        scrollToVerse(index);
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (isPlayingNotifier.value) {
      await audioService.pause(audioName: surah.englishName);
    } else {
      await audioService.play(audioName: surah.englishName);
    }
  }

  Future<void> togglePlayPause() async {
    if (!isPlaylist) {
      await _initializePlaylist();

      return;
    }

    _togglePlayback();
  }

  Future<void> _initializePlaylist() async {
    AnalyticsService.trackAudioStart(
      surah.englishName,
      surahName: surah.englishName,
      isPlaylist: isPlaylist,
    );

    isPlaylist = true;
    playingIndexNotifier.value = 0;

    await audioService.setPlaylistAudio(surah.audioSources);
    await audioPlayer.seek(Duration.zero, index: 0);

    await audioService.play();
  }

  void scrollToVerse(int? index) {
    if (index == null) return;

    itemScrollController.scrollTo(
      index: index,
      alignment: 0.5,
      duration: const Duration(),
    );
  }

  void playSingleAyah(int index) {
    isPlaylist = false;
    playingIndexNotifier.value = index;
    audioService.setAudioSource(surah.ayahs[index].audioSource);

    _togglePlayback();
  }

  void onAyahControlPressed(int index) async {
    if (isPlaylist) {
      await audioPlayer.seek(Duration.zero, index: index);
      await audioService.play();
    } else {
      playSingleAyah(index);
    }
  }

  void dispose() {
    audioService.resetAudioPlayer();

    _playerStateSub?.cancel();
    _currentIndexSub?.cancel();
  }

  bool get isPlayingPlaylist => isPlaylist && isPlayingNotifier.value;
}
