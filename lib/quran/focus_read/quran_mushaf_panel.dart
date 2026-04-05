import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/focus_read/mushaf_surah_layout.dart';
import 'package:hafiz_test/quran/reading_progress_controller.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/bismillah.dart';
import 'package:hafiz_test/util/quran_arabic_display.dart';
import 'package:hafiz_test/util/reading_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Madani-style page turns: Arabic only, continuous mushaf-like flow; ayat are
/// separated only by verse-number ornaments (no translation/transliteration).
class QuranMushafPanel extends StatelessWidget {
  const QuranMushafPanel({
    super.key,
    required this.lines,
    required this.slices,
    required this.pageController,
    required this.prefs,
    required this.onPageChanged,
    required this.playingIndexNotifier,
    required this.dark,
    required this.contentBottomInset,
    this.readingProgressController,
    this.showSurahBoundaries = false,
  });

  final List<MushafVerseLine> lines;
  final List<MushafPageSlice> slices;
  final PageController pageController;
  final ReadingPreferences prefs;
  final ValueChanged<int> onPageChanged;
  final ValueNotifier<int?> playingIndexNotifier;
  final bool dark;

  /// Clears [BottomAudioControls] when visible; 0 when hidden (see
  /// [BottomAudioControls.readerBottomClearance]).
  final double contentBottomInset;
  final ReadingProgressController? readingProgressController;

  /// When true (e.g. Juz reader), inserts surah titles and basmallah at each
  /// surah boundary within the flat verse sequence.
  final bool showSurahBoundaries;

  void _onSliceChanged(int i) {
    HapticFeedback.selectionClick();
    onPageChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        _MushafBackgroundVeil(dark: dark),
        Column(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: pageController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: slices.length,
                  onPageChanged: _onSliceChanged,
                  itemBuilder: (context, sliceIndex) {
                    return Directionality(
                      textDirection: TextDirection.ltr,
                      child: _MushafSlicePage(
                        lines: lines,
                        slice: slices[sliceIndex],
                        prefs: prefs,
                        dark: dark,
                        playingIndexNotifier: playingIndexNotifier,
                        readingProgressController: readingProgressController,
                        contentBottomInset: contentBottomInset,
                        showSurahBoundaries: showSurahBoundaries,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MushafBackgroundVeil extends StatelessWidget {
  const _MushafBackgroundVeil({required this.dark});

  final bool dark;

  static const Color _quranLightScaffold = Color(0xFFF9FAFB);
  static const Color _headerTintLight = Color(0xFF78B7C6);
  static const Color _headerTintDark = Color(0xFF1D353B);

  @override
  Widget build(BuildContext context) {
    final base =
        dark ? Theme.of(context).scaffoldBackgroundColor : _quranLightScaffold;
    final headerTint = dark ? _headerTintDark : _headerTintLight;
    final topWash = Color.lerp(base, headerTint, dark ? 0.09 : 0.055)!;
    final midBlend = Color.lerp(base, headerTint, dark ? 0.035 : 0.02)!;

    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                topWash,
                midBlend,
                base,
                base,
              ],
              stops: const [0.0, 0.1, 0.28, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mushaf uses looser line height than list cards for easier reading.
const double _mushafArabicLineHeight = 2.85;

TextStyle _mushafArabicTextStyle(ReadingPreferences prefs, Color color) {
  final baseStyle = TextStyle(
    fontSize: prefs.arabicFontSize,
    height: _mushafArabicLineHeight,
    color: color,
  );
  final family = prefs.arabicFontFamily.toString().toLowerCase();
  switch (family) {
    case 'amiri':
      return GoogleFonts.amiri(textStyle: baseStyle);
    case 'lateef':
      return GoogleFonts.lateef(textStyle: baseStyle);
    case 'scheherazade new':
      return GoogleFonts.scheherazadeNew(textStyle: baseStyle);
    default:
      return GoogleFonts.amiri(textStyle: baseStyle);
  }
}

List<InlineSpan> _mushafAyahSpansForIndices({
  required List<MushafVerseLine> lines,
  required List<int> lineIndicesInOrder,
  required int? playingIdx,
  required ReadingPreferences prefs,
  required Color textColor,
  required bool dark,
}) {
  final spans = <InlineSpan>[];
  final baseStyle = _mushafArabicTextStyle(prefs, textColor);
  final highlightLight =
      const Color(0xFF78B7C6).withValues(alpha: 0.12);
  final highlightDark =
      const Color(0xFF78B7C6).withValues(alpha: 0.18);

  for (var k = 0; k < lineIndicesInOrder.length; k++) {
    final lineIndex = lineIndicesInOrder[k];
    final line = lines[lineIndex];
    final ayah = line.ayah;
    final displayText = line.displayArabic;
    final isCurrent = playingIdx == line.playingIndex;
    final bg = isCurrent
        ? (dark ? highlightDark : highlightLight)
        : null;

    spans.add(
      TextSpan(
        text: '${QuranArabicDisplay.forCard(displayText)} ',
        style: baseStyle.copyWith(backgroundColor: bg),
      ),
    );
    spans.add(
      TextSpan(
        text: QuranArabicDisplay.ayahNumberOrnament(ayah.numberInSurah),
        style: baseStyle.copyWith(
          backgroundColor: bg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (k < lineIndicesInOrder.length - 1) {
      spans.add(TextSpan(text: '  ', style: baseStyle));
    }
  }

  return spans;
}

class _MushafSurahBoundaryHeader extends StatelessWidget {
  const _MushafSurahBoundaryHeader({
    required this.surah,
    required this.dark,
  });

  final Surah surah;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final ruleColor =
        (dark ? Colors.white : AppColors.black500).withValues(alpha: 0.22);
    final titleColor =
        dark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);
    final subColor =
        dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Divider(height: 1, thickness: 1, color: ruleColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  surah.englishName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.2,
                  ),
                ),
              ),
              Expanded(child: Divider(height: 1, thickness: 1, color: ruleColor)),
            ],
          ),
          if (surah.name.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              surah.name,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 22,
                height: 1.35,
                color: subColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MushafSlicePage extends StatelessWidget {
  const _MushafSlicePage({
    required this.lines,
    required this.slice,
    required this.prefs,
    required this.dark,
    required this.playingIndexNotifier,
    required this.readingProgressController,
    required this.contentBottomInset,
    required this.showSurahBoundaries,
  });

  final List<MushafVerseLine> lines;
  final MushafPageSlice slice;
  final ReadingPreferences prefs;
  final bool dark;
  final ValueNotifier<int?> playingIndexNotifier;
  final ReadingProgressController? readingProgressController;
  final double contentBottomInset;
  final bool showSurahBoundaries;

  bool _lineStartsSurahBlock(int lineIndex) {
    if (lineIndex <= 0) return true;
    return lines[lineIndex - 1].surah.number != lines[lineIndex].surah.number;
  }

  Widget _richBlockForIndices(
    List<int> lineIndicesInOrder,
    Color textColor,
  ) {
    if (lineIndicesInOrder.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: playingIndexNotifier,
      builder: (context, _) {
        final playingIdx = playingIndexNotifier.value;
        final spans = _mushafAyahSpansForIndices(
          lines: lines,
          lineIndicesInOrder: lineIndicesInOrder,
          playingIdx: playingIdx,
          prefs: prefs,
          textColor: textColor,
          dark: dark,
        );
        final baseStyle = _mushafArabicTextStyle(prefs, textColor);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SelectableText.rich(
            TextSpan(children: spans),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            strutStyle: StrutStyle(
              fontSize: prefs.arabicFontSize,
              height: _mushafArabicLineHeight,
              fontFamily: baseStyle.fontFamily,
              leadingDistribution: TextLeadingDistribution.even,
              forceStrutHeight: true,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildJuzBoundaryChildren(Color textColor) {
    final children = <Widget>[];
    var group = <int>[];

    void flushGroup() {
      if (group.isEmpty) return;
      children.add(_richBlockForIndices(group, textColor));
      group = <int>[];
    }

    for (var k = 0; k < slice.ayahIndices.length; k++) {
      final lineIndex = slice.ayahIndices[k];
      if (_lineStartsSurahBlock(lineIndex)) {
        flushGroup();
        final line = lines[lineIndex];
        final surah = line.surah;
        children.add(_MushafSurahBoundaryHeader(surah: surah, dark: dark));
        if (line.ayah.numberInSurah == 1 &&
            Bismillah.shouldShow(surah.number)) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                Bismillah.glyph,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: _mushafArabicTextStyle(prefs, textColor).copyWith(
                  fontSize: 31,
                  height: 2.3,
                ),
              ),
            ),
          );
        }
      }
      group.add(lineIndex);
    }
    flushGroup();
    return children;
  }

  @override
  Widget build(BuildContext context) {
    const hPad = 10.0;
    const vPad = 14.0;
    final textColor = dark ? Colors.white : AppColors.black500;
    var showBismillahLine = false;
    if (!showSurahBoundaries && slice.ayahIndices.isNotEmpty) {
      final first = lines[slice.ayahIndices.first];
      showBismillahLine = first.ayah.numberInSurah == 1 &&
          Bismillah.shouldShow(first.surah.number);
    }

    final scrollBody = showSurahBoundaries
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildJuzBoundaryChildren(textColor),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBismillahLine) ...[
                Text(
                  Bismillah.glyph,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: _mushafArabicTextStyle(prefs, textColor).copyWith(
                    fontSize: 31,
                    height: 2.3,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _richBlockForIndices(slice.ayahIndices, textColor),
            ],
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(hPad, vPad, hPad, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewportH = (constraints.maxHeight - 48)
                        .clamp(0.0, double.infinity);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(4, 18, 4, 22),
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: viewportH),
                        child: VisibilityDetector(
                          key: ValueKey(
                            'mushaf_vis_${slice.mushafPageNumber}_${slice.ayahIndices.join('-')}',
                          ),
                          onVisibilityChanged: (info) {
                            final f = info.visibleFraction;
                            for (final i in slice.ayahIndices) {
                              final pi = lines[i].playingIndex;
                              readingProgressController
                                  ?.onVerseVisibilityChanged(pi, f);
                            }
                          },
                          child: scrollBody,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: contentBottomInset),
            ],
          ),
        ),
      ),
    );
  }
}
