import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hafiz_test/services/analytics_service.dart';

class AudioServices {
  AudioServices._internal();

  static final AudioServices _instance = AudioServices._internal();

  factory AudioServices() => _instance;

  final audioPlayer = AudioPlayer();

  Future<void> setAudioSource(AudioSource audioSource,
      {bool preload = true}) async {
    try {
      if (kIsWeb) {
        await setWebAudioSource(audioSource);

        return;
      }

      await audioPlayer.setAudioSource(audioSource, preload: preload);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Sets the [audioSource] for audio playback specifically optimized for the web platform.
  ///
  /// On the web, this method ensures that playback:
  /// 1. Stops any existing audio without tracking the event.
  /// 2. Sets the new audio source for the player.
  ///
  /// Any errors encountered are caught and printed for debugging.
  Future<void> setWebAudioSource(AudioSource audioSource) async {
    try {
      await stop(trackEvent: false);
      await audioPlayer.setAudioSource(audioSource);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> setPlaylistAudio(List<AudioSource> audioSources) async {
    try {
      await stop(trackEvent: false);
      await audioPlayer.setAudioSources(audioSources);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> play({String? audioName}) async {
    try {
      // If playback has completed, restart from beginning
      if (audioPlayer.processingState == ProcessingState.completed) {
        await stop(trackEvent: false);
        await seek(Duration.zero, index: 0);
      }

      await audioPlayer.play();

      // Track audio play with context
      AnalyticsService.trackAudioControl('play', audioName ?? 'Audio Playback',
          audioType: 'recitation');
    } catch (e) {
      debugPrint('Error playing audio: ${e.toString()}');
    }
  }

  Future<void> pause({String? audioName}) async {
    try {
      await audioPlayer.pause();

      // Track audio pause with context
      AnalyticsService.trackAudioControl('pause', audioName ?? 'Audio Playback',
          audioType: 'recitation');
    } catch (e) {
      debugPrint('Error pausing audio: ${e.toString()}');
    }
  }

  Future<void> seek(Duration duration, {int? index}) async {
    try {
      await audioPlayer.seek(duration, index: index);
    } catch (e) {
      debugPrint('Error pausing audio: ${e.toString()}');
    }
  }

  Future<void> stop({String? audioName, bool trackEvent = true}) async {
    try {
      await audioPlayer.stop();

      // Track audio stop with context
      if (trackEvent) {
        AnalyticsService.trackAudioControl(
            'stop', audioName ?? 'Audio Playback',
            audioType: 'recitation');
      }
    } catch (e) {
      debugPrint('Error stopping audio: ${e.toString()}');
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    try {
      await audioPlayer.setLoopMode(mode);
    } catch (e) {
      debugPrint('Error setting loop mode: ${e.toString()}');
    }
  }

  Future<void> setSpeed(double speed, {String? audioName}) async {
    try {
      await audioPlayer.setSpeed(speed);

      // Track speed change
      AnalyticsService.trackSpeedChanged(speed, audioName ?? 'Audio Playback');
    } catch (e) {
      debugPrint('Error setting speed: ${e.toString()}');
    }
  }

  void dispose() => resetAudioPlayer();

  Future<void> resetAudioPlayer({
    AudioSource? audioSource,
    Duration? position,
    int? index,
  }) async {
    await stop();
    await seek(position ?? Duration.zero, index: index);
    await setAudioSource(
      preload: false,
      audioSource ?? AudioSource.uri(Uri(), tag: MediaItem(id: '', title: '')),
    );
  }
}
