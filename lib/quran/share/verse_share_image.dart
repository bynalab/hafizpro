import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Verse share graphic; height is intrinsic to Arabic + translation + chrome.
class VerseShareImage extends StatelessWidget {
  const VerseShareImage({
    super.key,
    required this.width,
    required this.arabicText,
    required this.surahEnglishName,
    required this.surahNumber,
    required this.ayahNumber,
    this.translation,
  });

  final double width;
  final String arabicText;
  final String surahEnglishName;
  final int surahNumber;
  final int ayahNumber;
  final String? translation;

  /// Widespread citation: surah name + surah:ayah (e.g. Al-Baqara · 2:255).
  String get _verseReferenceLine =>
      '$surahEnglishName · $surahNumber:$ayahNumber';

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldDim = Color(0xFFC9A961);
  static const Color _teal0 = Color(0xFF042823);
  static const Color _teal1 = Color(0xFF0D3D36);
  static const Color _teal2 = Color(0xFF145A50);

  /// Max vertical gap (logical px) between Arabic block and verse reference line.
  static const double _arabicToRefSpacing = 20;

  /// Quran body font size by approximate character count (multi-line; do not use [FittedBox]).
  static double arabicFontSizeForLength(int len) {
    if (len <= 80) return 28;
    if (len <= 120) return 24;
    if (len <= 170) return 21;
    if (len <= 230) return 18;
    if (len <= 310) return 16;
    if (len <= 400) return 14;
    return 12.5;
  }

  static double _translationFontSize(int len) {
    if (len > 480) return 8.8;
    if (len > 320) return 9.5;
    if (len > 180) return 10;
    return 11;
  }

  static int _translationMaxLines(int len) {
    if (len <= 0) return 0;
    final est = (len / 36).ceil() + 1;
    return math.min(16, math.max(3, est));
  }

  @override
  Widget build(BuildContext context) {
    final trans = translation?.trim();
    final translationBody = trans != null && trans.isNotEmpty ? trans : null;

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_teal0, _teal1, _teal2],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.13,
                  child: Image.asset(
                    'assets/img/islamic_pattern_gold.png',
                    // 'assets/img/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.32),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              color: _gold.withValues(alpha: 0.38),
                              thickness: 1,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Image.asset(
                              'assets/img/logo.png',
                              height: 44,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 17,
                                width: 17,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: _gold.withValues(alpha: 0.38),
                              thickness: 1,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        arabicText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        softWrap: true,
                        style: GoogleFonts.scheherazadeNew(
                          fontSize: arabicFontSizeForLength(
                            arabicText.length,
                          ),
                          height: 1.78,
                          color: Colors.white.withValues(alpha: 0.96),
                        ),
                      ),
                      if (translationBody != null) ...[
                        SizedBox(height: _arabicToRefSpacing),
                        Text(
                          translationBody,
                          textAlign: TextAlign.center,
                          maxLines: _translationMaxLines(
                            translationBody.length,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: _translationFontSize(
                              translationBody.length,
                            ),
                            height: 1.38,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                      SizedBox(height: _arabicToRefSpacing),
                      Text(
                        _verseReferenceLine,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _goldDim,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
