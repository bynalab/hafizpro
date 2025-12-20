import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hafiz_test/data/juz_list.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/model/juz.model.dart';
import 'package:hafiz_test/model/playback_snapshot.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:just_audio/just_audio.dart';

enum PlaybackOwner { reading, test, juz }

class AudioCenter extends ChangeNotifier {
  final AudioServices _audioServices;
  final SurahServices _surahServices;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _indexSub;
  bool _isAutoAdvancing = false;
  bool _readingWasPlaylist = false;
  int _readingPlaylistIndexOffset = 0;
  AudioSource? _bismillahAudioSource;
  PlaybackOwner _playbackOwner = PlaybackOwner.reading;
  PlaybackSnapshot? _readingSnapshot;

  final ValueNotifier<int?> juzPlayingIndexNotifier = ValueNotifier<int?>(null);

  PlaybackOwner get playbackOwner => _playbackOwner;

  bool _tryAutoAdvanceToNextSurah() {
    if (_playbackOwner != PlaybackOwner.reading) return false;
    if (!_readingWasPlaylist) return false;

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
    _readingWasPlaylist = false;
    _readingPlaylistIndexOffset = 0;
    isPlaying = false;
    isLoading = false;
    currentSurahNumber = null;
    currentSurahName = null;
    currentJuzNumber = null;
    juzPlayingIndexNotifier.value = null;
    notifyListeners();
  }

  void _handlePlaybackCompleted() {
    if (_tryAutoAdvanceToNextSurah()) return;
    _resetPlaybackSession();
  }

  void _snapshotReadingSession() {
    final audioPlayer = _audioServices.audioPlayer;
    final current = currentSurahNumber;
    final name = currentSurahName;
    final idx = audioPlayer.currentIndex;

    if (current != null && name != null && idx != null) {
      _readingSnapshot = PlaybackSnapshot(
        surahNumber: current,
        surahName: name,
        index: idx,
        position: audioPlayer.position,
      );
    } else {
      _readingSnapshot = null;
    }
  }

  void beginTestSession() {
    if (_playbackOwner == PlaybackOwner.test) return;

    _snapshotReadingSession();

    _playbackOwner = PlaybackOwner.test;
    _indexSub?.cancel();
    _indexSub = null;
    juzPlayingIndexNotifier.value = null;

    if (_audioServices.audioPlayer.playing) {
      unawaited(_audioServices.pause(audioName: currentSurahName));
    }

    _resetPlaybackSession();
  }

  void endTestSession() {
    if (_playbackOwner != PlaybackOwner.test) return;
    unawaited(_endTestSessionAsync());
  }

  Future<void> _endTestSessionAsync() async {
    if (_playbackOwner != PlaybackOwner.test) return;

    _playbackOwner = PlaybackOwner.reading;

    _indexSub?.cancel();
    _indexSub = null;
    juzPlayingIndexNotifier.value = null;

    await _audioServices.stop(trackEvent: false);
    _resetPlaybackSession();

    final snapshot = _readingSnapshot;
    _readingSnapshot = null;
    if (snapshot != null) {
      await _restoreReadingSession(snapshot);
    }
  }

  Future<void> _restoreReadingSession(PlaybackSnapshot snapshot) async {
    if (isLoading) return;
    if (_playbackOwner != PlaybackOwner.reading) return;

    isLoading = true;
    currentSurahNumber = snapshot.surahNumber;
    currentSurahName = snapshot.surahName;
    isPlaying = false;
    notifyListeners();

    try {
      final fullSurah = await _surahServices.getSurah(snapshot.surahNumber);
      if (fullSurah.ayahs.isEmpty) return;

      currentSurahName = fullSurah.englishName;

      if (fullSurah.isSurahLevelAudio) {
        _readingPlaylistIndexOffset = 0;
        await _audioServices
            .setPlaylistAudio([fullSurah.ayahs.first.audioSource]);
      } else {
        // Keep playlist shape consistent with normal surah playback: if this
        // surah would normally have a prepended Bismillah track (Surah 1:1),
        // include it here too so snapshot indices remain valid.
        _readingPlaylistIndexOffset = 0;
        final canPrepend = fullSurah.number != 1 && fullSurah.number != 9;

        final playlist = <AudioSource>[];
        if (canPrepend) {
          final bismillah = await _getBismillahSource();
          if (bismillah != null) {
            playlist.add(bismillah);
            _readingPlaylistIndexOffset = 1;
          }
        }

        playlist.addAll(fullSurah.audioSources);
        await _audioServices.setPlaylistAudio(playlist);
      }

      await _audioServices.seek(snapshot.position, index: snapshot.index);
      await _audioServices.pause(audioName: currentSurahName);
      isPlaying = false;
    } catch (_) {
      // Keep UI state cleared if restore fails.
      currentSurahNumber = null;
      currentSurahName = null;
      isPlaying = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
        if (_isAutoAdvancing) return;
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
  int? currentJuzNumber;
  bool isPlaying = false;
  bool isLoading = false;

  AudioPlayer get audioPlayer => _audioServices.audioPlayer;

  int get readingPlaylistIndexOffset => _readingPlaylistIndexOffset;

  Future<void> onReciterChanged() async {
    // Reciter change affects all verse URLs (including our cached Bismillah).
    _bismillahAudioSource = null;

    final audioPlayer = _audioServices.audioPlayer;
    final wasPlaying = audioPlayer.playing;

    if (isLoading) return;

    if (_playbackOwner == PlaybackOwner.reading && currentSurahNumber != null) {
      final n = currentSurahNumber!;
      final idx = audioPlayer.currentIndex ?? 0;
      final mapped = (idx - _readingPlaylistIndexOffset);
      final startIndex = mapped < 0 ? 0 : mapped;

      final fallbackName = surahList
          .firstWhere(
            (s) => s.number == n,
            orElse: () => Surah(number: n, englishName: 'Surah'),
          )
          .englishName;

      await toggleSurah(
        Surah(number: n, englishName: currentSurahName ?? fallbackName),
        startIndex: startIndex,
        forceReload: true,
      );

      if (!wasPlaying) {
        await audioPlayer.pause();
        isPlaying = false;
        notifyListeners();
      }

      return;
    }

    if (_playbackOwner == PlaybackOwner.juz && currentJuzNumber != null) {
      final j = currentJuzNumber!;
      final startIndex = (audioPlayer.currentIndex ?? 0);
      await toggleJuz(
        findJuzByNumber(j),
        startIndex: startIndex,
        forceReload: true,
      );

      if (!wasPlaying) {
        await audioPlayer.pause();
        isPlaying = false;
        notifyListeners();
      }
    }
  }

  bool isCurrentSurah(int surahNumber) => currentSurahNumber == surahNumber;

  bool isCurrentJuz(int juzNumber) => currentJuzNumber == juzNumber;

  void setCurrentSurah(Surah surah) {
    currentSurahNumber = surah.number;
    currentSurahName = surah.englishName;
    notifyListeners();
  }

  bool _shouldPrependBismillah({
    required int surahNumber,
    required int startIndex,
    required Surah fullSurah,
  }) {
    if (startIndex != 0) return false;
    if (surahNumber == 1 || surahNumber == 9) return false;
    if (fullSurah.ayahs.isEmpty) return false;
    if (fullSurah.isSurahLevelAudio) return false;

    return true;
  }

  Future<AudioSource?> _getBismillahSource() async {
    final cached = _bismillahAudioSource;
    if (cached != null) return cached;

    try {
      final surah1 = await _surahServices.getSurah(1);
      if (surah1.ayahs.isEmpty) return null;
      if (surah1.isSurahLevelAudio) return null;

      final src = surah1.ayahs.first.audioSource;
      _bismillahAudioSource = src;
      return src;
    } catch (_) {
      return null;
    }
  }

  Future<void> playSingleAyah(Surah surah, AudioSource source) async {
    if (isLoading) return;

    isLoading = true;
    _readingWasPlaylist = false;
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

  Future<void> toggleSurah(
    Surah surah, {
    int startIndex = 0,
    bool forceReload = false,
  }) async {
    if (isLoading) return;

    if (_playbackOwner != PlaybackOwner.reading) {
      _playbackOwner = PlaybackOwner.reading;
      currentJuzNumber = null;
      _indexSub?.cancel();
      _indexSub = null;
      juzPlayingIndexNotifier.value = null;
    }

    final audioPlayer = _audioServices.audioPlayer;

    if (!forceReload && currentSurahNumber == surah.number) {
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
    _readingWasPlaylist = true;
    _readingPlaylistIndexOffset = 0;
    currentSurahNumber = surah.number;
    currentSurahName = surah.englishName;
    currentJuzNumber = null;
    notifyListeners();

    try {
      final fullSurah = await _surahServices.getSurah(surah.number);
      if (fullSurah.ayahs.isEmpty) return;

      currentSurahName = fullSurah.englishName;

      if (fullSurah.isSurahLevelAudio) {
        _readingPlaylistIndexOffset = 0;
        await _audioServices
            .setPlaylistAudio([fullSurah.ayahs.first.audioSource]);
        await audioPlayer.seek(Duration.zero, index: 0);
      } else {
        final bismillah = _shouldPrependBismillah(
          surahNumber: fullSurah.number,
          startIndex: startIndex,
          fullSurah: fullSurah,
        )
            ? await _getBismillahSource()
            : null;

        _readingPlaylistIndexOffset = bismillah == null ? 0 : 1;

        final playlist = fullSurah.audioSources.prependBismillah(bismillah);

        await _audioServices.setPlaylistAudio(playlist);
        // If we prepended a Bismillah track, it must play first.
        // Since we only prepend when startIndex == 0, we always seek to 0.
        final initialIndex =
            (_readingPlaylistIndexOffset == 1) ? 0 : startIndex;
        await audioPlayer.seek(Duration.zero, index: initialIndex);
      }
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
    if (isLoading) return;

    // Force reading mode for surah playback.
    if (_playbackOwner != PlaybackOwner.reading) {
      _playbackOwner = PlaybackOwner.reading;
      currentJuzNumber = null;
      _indexSub?.cancel();
      _indexSub = null;
      juzPlayingIndexNotifier.value = null;
    }

    final audioPlayer = _audioServices.audioPlayer;

    // If the surah is already loaded, just seek to the requested ayah index and
    // continue the playlist instead of re-toggling (which would pause/resume).
    if (currentSurahNumber == surah.number && audioPlayer.sequence.isNotEmpty) {
      final target = index + _readingPlaylistIndexOffset;
      final clamped = target.clamp(0, audioPlayer.sequence.length - 1);
      await audioPlayer.seek(Duration.zero, index: clamped);
      isPlaying = true;
      notifyListeners();
      unawaited(_audioServices.play(audioName: currentSurahName));
      return;
    }

    await toggleSurah(surah, startIndex: index);
  }

  Future<void> toggleJuz(
    JuzModel juz, {
    int startIndex = 0,
    bool forceReload = false,
  }) async {
    if (isLoading) return;

    final audioPlayer = _audioServices.audioPlayer;

    if (!forceReload &&
        _playbackOwner == PlaybackOwner.juz &&
        currentJuzNumber == juz.number) {
      if (audioPlayer.sequence.isEmpty) {
        // Fall through to rebuild playlist.
      } else {
        if (audioPlayer.playing) {
          isPlaying = false;
          notifyListeners();
          await _audioServices.pause(audioName: currentSurahName);
          return;
        }

        // Resume playback without rewinding. Only seek when a non-zero index
        // is explicitly requested (e.g. user taps a specific verse).
        if (startIndex != 0) {
          final clamped = startIndex.clamp(0, audioPlayer.sequence.length - 1);
          await audioPlayer.seek(Duration.zero, index: clamped);
        }
        isPlaying = true;
        notifyListeners();
        unawaited(_audioServices.play(audioName: currentSurahName));
        return;
      }
    }

    isLoading = true;
    _playbackOwner = PlaybackOwner.juz;
    currentJuzNumber = juz.number;
    currentSurahNumber = null;
    currentSurahName = 'Juz ${juz.number}';
    juzPlayingIndexNotifier.value = null;
    notifyListeners();

    try {
      final playlist = <AudioSource>[];

      for (final range in juz.surahRanges()) {
        final full = await _surahServices.getSurah(range.surahNumber);
        if (full.ayahs.isEmpty) continue;

        final endAyah = range.endAyah ?? full.numberOfAyahs;
        final startIndex = range.startAyah - 1;
        final endIndexInclusive = endAyah - 1;

        if (startIndex < 0 || endIndexInclusive < 0) continue;
        final clampedStart = startIndex.clamp(0, full.ayahs.length - 1);
        final clampedEnd = endIndexInclusive.clamp(0, full.ayahs.length - 1);
        if (clampedEnd < clampedStart) continue;

        final slice = full.ayahs.sublist(clampedStart, clampedEnd + 1);
        playlist.addAll(slice.map((a) => a.audioSource));
      }

      if (playlist.isEmpty) {
        throw Exception('No verses available for Juz ${juz.number}');
      }

      await _audioServices.setPlaylistAudio(playlist);
      final clamped = startIndex.clamp(0, playlist.length - 1);
      await audioPlayer.seek(Duration.zero, index: clamped);

      await _indexSub?.cancel();
      _indexSub = audioPlayer.currentIndexStream.listen((idx) {
        if (_playbackOwner != PlaybackOwner.juz) return;
        if (currentJuzNumber != juz.number) return;
        juzPlayingIndexNotifier.value = idx;
      });

      unawaited(_audioServices.play(audioName: currentSurahName));

      isPlaying = true;
    } catch (_) {
      isPlaying = audioPlayer.playing;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (isLoading) return;
    isPlaying = false;
    _indexSub?.cancel();
    _indexSub = null;
    juzPlayingIndexNotifier.value = null;
    notifyListeners();
    await _audioServices.stop(audioName: currentSurahName);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _indexSub?.cancel();
    juzPlayingIndexNotifier.dispose();

    super.dispose();
  }
}
