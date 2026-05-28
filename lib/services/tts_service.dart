import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:hafiz_test/services/tts_settings_launcher_io.dart'
    if (dart.library.html) 'package:hafiz_test/services/tts_settings_launcher_stub.dart'
    as tts_settings;

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _flutterTts = FlutterTts();

    // Default settings
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    if (!kIsWeb) {
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

    _isInitialized = true;
  }

  Future<void> speak(String text,
      {String language = "en-US", double rate = 0.5}) async {
    if (!_isInitialized) await init();
    if (text.isNotEmpty) {
      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(rate);

      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _flutterTts.stop();
  }

  void setHandler(
      {required Function() onStart,
      required Function() onCompletion,
      required Function() onPause}) {
    if (!_isInitialized) return;
    _flutterTts.setStartHandler(onStart);
    _flutterTts.setCompletionHandler(onCompletion);
    _flutterTts.setPauseHandler(onPause);
    _flutterTts.setCancelHandler(onPause);
  }

  Future<void> openSystemTtsSettings() => tts_settings.openSystemTtsSettings();
}
