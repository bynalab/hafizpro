import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/rating_service.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class QuranViewModel {
  final AudioCenter audioCenter;
  final SurahServices surahService;

  final itemScrollController = ItemScrollController();

  QuranViewModel({required this.audioCenter, required this.surahService});

  late Surah surah;
  bool isLoading = true;
  bool hasError = false;
  bool isPlaylist = false;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _currentIndexSub;

  final playingIndexNotifier = ValueNotifier<int?>(null);
  final isPlayingNotifier = ValueNotifier<bool>(false);

  AudioPlayer get audioPlayer => audioCenter.audioPlayer;

  Future<void> initialize(int surahNumber) async {
    try {
      isLoading = true;
      surah = await surahService.getSurah(surahNumber);
      if (surah.ayahs.isEmpty) return;

      // Only reflect existing playback state if the currently playing surah
      // matches the surah being viewed.
      if (audioCenter.isCurrentSurah(surahNumber)) {
        final seqLen = audioPlayer.sequence.length;
        isPlaylist = seqLen > 1;

        isPlayingNotifier.value = audioPlayer.playing;

        if (isPlaylist) {
          final idx = audioPlayer.currentIndex;
          if (idx != null) playingIndexNotifier.value = idx;
        }
      } else {
        isPlaylist = false;
        playingIndexNotifier.value = null;
        isPlayingNotifier.value = false;
      }

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
      final matches = audioCenter.isCurrentSurah(surah.number);
      if (!matches) {
        if (isPlayingNotifier.value != false) {
          isPlayingNotifier.value = false;
        }
        return;
      }

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
      final matches = audioCenter.isCurrentSurah(surah.number);
      if (!matches) {
        if (playingIndexNotifier.value != null) {
          playingIndexNotifier.value = null;
        }
        return;
      }

      if (index != null && isPlaylist) {
        playingIndexNotifier.value = index;
        scrollToVerse(index);
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (isPlayingNotifier.value) {
      await audioPlayer.pause();
    } else {
      // Use AudioCenter so global state (dashboard) stays in sync.
      await audioCenter.toggleSurah(surah);
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

    await audioCenter.toggleSurah(surah, startIndex: 0);
  }

  void scrollToVerse(int? index) {
    if (index == null) return;

    if (!itemScrollController.isAttached) return;

    itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 250),
    );
  }

  void playSingleAyah(int index) {
    isPlaylist = false;
    playingIndexNotifier.value = index;
    audioCenter.playSingleAyah(surah, surah.ayahs[index].audioSource);
  }

  void onAyahControlPressed(int index) async {
    if (isPlaylist) {
      await audioCenter.playFromAyahIndex(surah, index);
    } else {
      playSingleAyah(index);
    }
  }

  void dispose() {
    _playerStateSub?.cancel();
    _currentIndexSub?.cancel();
  }

  bool get isPlayingPlaylist => isPlaylist && isPlayingNotifier.value;
}
