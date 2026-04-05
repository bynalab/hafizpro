import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/bookmark.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/reading_progress_controller.dart';
import 'package:hafiz_test/quran/share/verse_share_controller.dart';
import 'package:hafiz_test/quran/widgets/ayah_card.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/bismillah.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/util/reading_preferences.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Verse-by-verse focus UI (one ayah per page). Uses [AyahCard] like [QuranAyahList].
/// Swipe between ayat is horizontal only ([PageView]).
///
/// [PageView] follows ambient [Directionality]. Quranic reading is RTL, so the pager
/// is wrapped in [TextDirection.rtl] so “forward” in the surah matches RTL screen
/// progression regardless of app locale. Each page resets to [TextDirection.ltr] so
/// [AyahCard] controls (bookmark, play, etc.) stay in a stable LTR layout.
class QuranVerseFocusPanel extends StatelessWidget {
  const QuranVerseFocusPanel({
    super.key,
    required this.surah,
    required this.pageController,
    required this.prefs,
    required this.onPageChanged,
    required this.onControlPressed,
    required this.playingIndexNotifier,
    required this.isPlayingNotifier,
    required this.audioCenter,
    required this.dark,
    required this.bottomPadding,
    required this.showBismillah,
    this.readingProgressController,
    this.onBookmarkUpdated,
  });

  final Surah surah;
  final PageController pageController;
  final ReadingPreferences prefs;
  final ValueChanged<int> onPageChanged;
  final void Function(int ayahIndex) onControlPressed;
  final ValueNotifier<int?> playingIndexNotifier;
  final ValueNotifier<bool> isPlayingNotifier;
  final AudioCenter audioCenter;
  final bool dark;
  final double bottomPadding;
  final bool showBismillah;
  final ReadingProgressController? readingProgressController;
  final VoidCallback? onBookmarkUpdated;

  void _onPageChanged(int i) {
    HapticFeedback.selectionClick();
    onPageChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    final s = surah;

    return Stack(
      children: [
        _BackgroundVeil(dark: dark),
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
                  itemCount: s.ayahs.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return Directionality(
                      textDirection: TextDirection.ltr,
                      child: _AyahFocusPage(
                        surah: s,
                        ayahIndex: index,
                        ayah: s.ayahs[index],
                        showBismillah: showBismillah,
                        prefs: prefs,
                        dark: dark,
                        playingIndexNotifier: playingIndexNotifier,
                        isPlayingNotifier: isPlayingNotifier,
                        audioCenter: audioCenter,
                        onControlPressed: onControlPressed,
                        readingProgressController: readingProgressController,
                        onBookmarkUpdated: onBookmarkUpdated,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (bottomPadding > 0) SizedBox(height: bottomPadding),
          ],
        ),
      ],
    );
  }
}

class _BackgroundVeil extends StatelessWidget {
  const _BackgroundVeil({required this.dark});

  final bool dark;

  /// Matches [QuranView] body in light mode ([Theme] scaffold is white there).
  static const Color _quranLightScaffold = Color(0xFFF9FAFB);

  /// [QuranView] header strip — only a hint is mixed in so the focus area
  /// continues the header without a separate “card” look.
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

class _AyahFocusPage extends StatelessWidget {
  const _AyahFocusPage({
    required this.surah,
    required this.ayahIndex,
    required this.ayah,
    required this.showBismillah,
    required this.prefs,
    required this.dark,
    required this.playingIndexNotifier,
    required this.isPlayingNotifier,
    required this.audioCenter,
    required this.onControlPressed,
    required this.readingProgressController,
    required this.onBookmarkUpdated,
  });

  final Surah surah;
  final int ayahIndex;
  final Ayah ayah;
  final bool showBismillah;
  final ReadingPreferences prefs;
  final bool dark;
  final ValueNotifier<int?> playingIndexNotifier;
  final ValueNotifier<bool> isPlayingNotifier;
  final AudioCenter audioCenter;
  final void Function(int ayahIndex) onControlPressed;
  final ReadingProgressController? readingProgressController;
  final VoidCallback? onBookmarkUpdated;

  @override
  Widget build(BuildContext context) {
    final storage = getIt<IStorageService>();
    final displayText = (showBismillah && ayahIndex == 0)
        ? Bismillah.trimLeadingForDisplay(ayah.text)
        : ayah.text;
    final displayAyah = ayah.copyWith(text: displayText);

    final isCompleted =
        storage.isAyahCompleted(surah.number, ayah.numberInSurah);
    final isBookmarked = storage.isBookmarked(surah.number, ayah.numberInSurah);
    final isEven = ayahIndex % 2 == 0;
    final backgroundColor = dark
        ? (isEven ? const Color(0xFF101010) : const Color(0xFF0E0E0E))
        : (isEven ? AppColors.gray500 : AppColors.gray50);

    final reciterId = storage.getReciterId();
    final reciter = TarteelAudio.reciterForId(reciterId);
    final showPlayButton = reciter?.isVerseByVerse ?? true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final vPad = constraints.maxHeight > 520 ? 20.0 : 8.0;
        final maxW = (constraints.maxWidth - 16).clamp(0.0, 520.0);
        final viewportHeight = (constraints.maxHeight - 2 * vPad).clamp(0.0, double.infinity);

        final card = VisibilityDetector(
          key: ValueKey('focus_vis_${surah.number}_$ayahIndex'),
          onVisibilityChanged: (info) {
            readingProgressController?.onVerseVisibilityChanged(
              ayahIndex,
              info.visibleFraction,
            );
          },
          child: AyahCard(
            key: ValueKey(
              'focus_ayah_${surah.number}_${ayah.numberInSurah}_${prefs.arabicFontSize}_${prefs.arabicFontFamily}',
            ),
            index: ayahIndex,
            ayah: displayAyah,
            playingIndexNotifier: playingIndexNotifier,
            isPlayingNotifier: isPlayingNotifier,
            audioCenter: audioCenter,
            loadingMatchSurahNumber: surah.number,
            prefs: prefs,
            isCompleted: isCompleted,
            backgroundColor: backgroundColor,
            showPlayButton: showPlayButton,
            onPlayPressed: (_) => onControlPressed(ayahIndex),
            onMarkAsRead: (idx) {
              readingProgressController?.markAsReadUpTo(idx);
            },
            isBookmarked: isBookmarked,
            onBookmark: (idx) async {
              if (isBookmarked) {
                await storage.removeBookmark(
                  surah.number,
                  ayah.numberInSurah,
                );
              } else {
                final selectedAyah = surah.ayahs[idx];
                await storage.addBookmark(
                  Bookmark(
                    surah: surah,
                    ayah: selectedAyah,
                    viewContext: BookmarkViewContext.surah,
                    timestamp: DateTime.now(),
                  ),
                );
              }
              onBookmarkUpdated?.call();
            },
            onShare: () => VerseShareController.shareVerse(
              context: context,
              surah: surah,
              ayah: ayah,
              displayArabic: displayText,
            ),
            verseShareTooltip: context.l10n.verseShareTooltip,
            focusMode: true,
          ),
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(8, vPad, 8, vPad),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportHeight),
                  child: Center(
                    child: card,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
