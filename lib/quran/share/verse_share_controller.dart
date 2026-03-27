import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hafiz_test/l10n/app_localizations.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/share/verse_share_image.dart';
import 'package:hafiz_test/util/app_messenger.dart';
import 'package:hafiz_test/util/quran_arabic_display.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class VerseShareController {
  VerseShareController._();

  static const double _logicalW = 360;
  static const double _pixelRatio = 3;

  static Future<void> shareVerse({
    required BuildContext context,
    required Surah surah,
    required Ayah ayah,
    required String displayArabic,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    if (kIsWeb) {
      AppMessenger.showSnackBar(l10n.verseShareWebUnsupported);
      return;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final arabic = QuranArabicDisplay.forCard(displayArabic);
    if (arabic.isEmpty) return;

    final key = GlobalKey();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -8000,
        top: 0,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: key,
            child: VerseShareImage(
              width: _logicalW,
              arabicText: arabic,
              surahEnglishName: surah.englishName,
              surahNumber: surah.number,
              ayahNumber: ayah.numberInSurah,
              translation: ayah.translation,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));

    try {
      final ro = key.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) return;
      final image = await ro.toImage(pixelRatio: _pixelRatio);
      final bd = await image.toByteData(format: ImageByteFormat.png);
      if (bd == null) return;

      final bytes = bd.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/hafiz_pro_verse_${surah.number}_${ayah.numberInSurah}.png',
      );
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;

      final text =
          '${surah.englishName} · ${surah.number}:${ayah.numberInSurah}\n${l10n.appTitle}\nhttps://hafizpro.com';

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'image/png',
            name: 'hafiz_pro_verse.png',
          ),
        ],
        text: text,
      );
    } finally {
      entry.remove();
    }
  }
}
