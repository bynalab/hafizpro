import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // iOS audio session category
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

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

  Future<void> openSystemTtsSettings() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'com.android.settings.TTS_SETTINGS',
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      // iOS doesn't have a direct link to TTS settings, so we open the main settings
      await launchUrl(Uri.parse('App-Prefs:root=General&path=Accessibility'));
    }
  }
}
