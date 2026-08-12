import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSystemTtsSettings() async {
  if (Platform.isAndroid) {
    const intent = AndroidIntent(
      action: 'com.android.settings.TTS_SETTINGS',
    );
    await intent.launch();
  } else if (Platform.isIOS) {
    try {
      final url = Uri.parse('app-settings:');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      // safe fallback
    }
  }
}
