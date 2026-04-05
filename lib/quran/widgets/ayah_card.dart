import 'package:flutter/material.dart';
import 'package:hafiz_test/util/reading_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/quran_arabic_display.dart';

class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final int index;
  final ValueNotifier<int?> playingIndexNotifier;
  final ValueNotifier<bool> isPlayingNotifier;
  final void Function(int)? onPlayPressed;
  final Color backgroundColor;
  final ReadingPreferences prefs;
  final bool isCompleted;
  final void Function(int)? onMarkAsRead;
  final bool showPlayButton;

  final VoidCallback? onShare;
  final String? verseShareTooltip;

  final bool isBookmarked;
  final void Function(int)? onBookmark;

  /// Scales translation / transliteration body text (e.g. focus mode long ayat).
  final double secondaryTextScale;

  final AudioCenter audioCenter;

  /// Set one of these so the play button shows a spinner while [audioCenter] loads.
  final int? loadingMatchSurahNumber;
  final int? loadingMatchJuzNumber;

  /// Verse-focus layout: no outer padding, no outer card border or fill.
  final bool focusMode;

  // We derive contrast from the actual card background color (not Theme.brightness)
  // because some screens may intentionally render light cards in dark mode (or vice
  // versa). Using luminance keeps text/icon/border colors readable regardless.
  bool _isDarkColor(Color c) {
    final luminance = c.computeLuminance();
    return luminance < 0.45;
  }

  const AyahCard({
    super.key,
    required this.ayah,
    required this.index,
    required this.playingIndexNotifier,
    required this.isPlayingNotifier,
    required this.audioCenter,
    this.backgroundColor = Colors.white,
    this.onPlayPressed,
    required this.prefs,
    this.isCompleted = false,
    this.onMarkAsRead,
    this.showPlayButton = true,
    this.isBookmarked = false,
    this.onBookmark,
    this.onShare,
    this.verseShareTooltip,
    this.secondaryTextScale = 1.0,
    this.loadingMatchSurahNumber,
    this.loadingMatchJuzNumber,
    this.focusMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final juz = loadingMatchJuzNumber;
    final surahN = loadingMatchSurahNumber;
    final watchAudioCenter = juz != null || surahN != null;

    return AnimatedBuilder(
      animation: Listenable.merge([
        playingIndexNotifier,
        isPlayingNotifier,
        if (watchAudioCenter) audioCenter,
      ]),
      builder: (context, _) {
        final playingIdx = playingIndexNotifier.value;
        final isPlaying = isPlayingNotifier.value;
        final isActive = playingIdx == index && isPlaying;
        final isPlayLoading = watchAudioCenter &&
            audioCenter.isLoading &&
            playingIdx == index &&
            (juz != null
                ? audioCenter.isCurrentJuz(juz)
                : surahN != null && audioCenter.isCurrentSurah(surahN));

        final isDarkCard = _isDarkColor(backgroundColor);
        final textColor = isDarkCard ? Colors.white : AppColors.black500;
        final borderColor = isActive
            ? const Color(0xFF78B7C6)
            : (isDarkCard
                ? Colors.white.withValues(alpha: 0.16)
                : const Color(0xFFE5E7EB));
        final chipBorderColor = isDarkCard
            ? Colors.white.withValues(alpha: 0.75)
            : const Color(0xFF111827);

        final bodyFont = (14 * secondaryTextScale).clamp(10.0, 14.0).toDouble();

        final inner = Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          decoration: BoxDecoration(
            color: focusMode ? Colors.transparent : backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: focusMode
                ? null
                : Border.all(
                    color: borderColor,
                  ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: chipBorderColor),
                    ),
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (prefs.trackingMode != 'off') ...[
                    GestureDetector(
                      onTap: () => onMarkAsRead?.call(index),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF78B7C6).withValues(alpha: 0.2)
                              : null,
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFF78B7C6)
                                : chipBorderColor,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.check : Icons.done_all,
                            size: 18,
                            color: isCompleted
                                ? const Color(0xFF78B7C6)
                                : textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () => onBookmark?.call(index),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isBookmarked
                            ? const Color(0xFF78B7C6).withValues(alpha: 0.2)
                            : null,
                        border: Border.all(
                          color: isBookmarked
                              ? const Color(0xFF78B7C6)
                              : chipBorderColor,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          size: 18,
                          color: isBookmarked
                              ? const Color(0xFF78B7C6)
                              : textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  if (onShare != null) ...[
                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        Widget btn = GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onShare,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: chipBorderColor),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.share_rounded,
                                size: 18,
                                color: textColor.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        );
                        final tip = verseShareTooltip;
                        if (tip != null && tip.isNotEmpty) {
                          btn = Tooltip(message: tip, child: btn);
                        }
                        return btn;
                      },
                    ),
                  ],
                  const Spacer(),
                  if (showPlayButton)
                    GestureDetector(
                      onTap: isPlayLoading
                          ? null
                          : () => onPlayPressed?.call(index),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: chipBorderColor),
                        ),
                        child: Center(
                          child: isPlayLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: textColor.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isActive
                                      ? Icons.pause
                                      : Icons.play_arrow_rounded,
                                  size: 20,
                                  color: textColor,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: SelectableText(
                  '${QuranArabicDisplay.forCard(ayah.text)} ${QuranArabicDisplay.ayahNumberOrnament(ayah.numberInSurah)}',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: _getArabicStyle(),
                ),
              ),
              if (prefs.showTransliteration &&
                  (ayah.transliteration ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    ayah.transliteration!.trim(),
                    textAlign: TextAlign.left,
                    style: GoogleFonts.inter(
                      fontSize: bodyFont,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (prefs.showTranslation &&
                  (ayah.translation ?? '').trim().isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    ayah.translation!.trim(),
                    textAlign: TextAlign.left,
                    style: GoogleFonts.inter(
                      fontSize: bodyFont,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

        if (focusMode) return inner;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          child: inner,
        );
      },
    );
  }

  TextStyle _getArabicStyle() {
    final baseStyle = TextStyle(
      fontSize: prefs.arabicFontSize,
      height: 2,
      color: _isDarkColor(backgroundColor) ? Colors.white : AppColors.black500,
    );

    final family = prefs.arabicFontFamily.toString().toLowerCase();
    switch (family) {
      // Amiri is a specific font in google_fonts
      case 'amiri':
        return GoogleFonts.amiri(textStyle: baseStyle);
      // Lateef is a specific font in google_fonts
      case 'lateef':
        return GoogleFonts.lateef(textStyle: baseStyle);
      // Scheherazade New is a specific font in google_fonts
      case 'scheherazade new':
        return GoogleFonts.scheherazadeNew(textStyle: baseStyle);
      default:
        return GoogleFonts.amiri(textStyle: baseStyle);
    }
  }
}
