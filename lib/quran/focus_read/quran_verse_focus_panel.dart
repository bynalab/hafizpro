import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/bookmark.model.dart';
import 'package:hafiz_test/quran/focus_read/verse_focus_item.dart';
import 'package:hafiz_test/quran/reading_progress_controller.dart';
import 'package:hafiz_test/quran/share/verse_share_controller.dart';
import 'package:hafiz_test/quran/widgets/ayah_card.dart';
import 'package:hafiz_test/quran/widgets/quran_adjacent_reader_nav_bar.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/util/reading_preferences.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Verse-by-verse focus UI (one ayah per page). Uses [AyahCard] like [QuranAyahList].
/// Swipe between ayat is horizontal only ([PageView]).
///
/// [PageView] uses [TextDirection.rtl] so forward reading matches mushaf-style paging.
class QuranVerseFocusPanel extends StatelessWidget {
  const QuranVerseFocusPanel({
    super.key,
    required this.items,
    required this.pageController,
    required this.prefs,
    required this.onPageChanged,
    required this.onControlPressed,
    required this.playingIndexNotifier,
    required this.isPlayingNotifier,
    required this.audioCenter,
    required this.dark,
    required this.bottomPadding,
    this.readingProgressController,
    this.onBookmarkUpdated,
    this.loadingMatchSurahNumber,
    this.loadingMatchJuzNumber,
    this.bookmarkViewContext = BookmarkViewContext.surah,
    this.juzNumber,
    this.onPreviousNav,
    this.onNextNav,
    this.previousNavLabel,
    this.nextNavLabel,
  });

  final List<VerseFocusItem> items;
  final PageController pageController;
  final ReadingPreferences prefs;
  final ValueChanged<int> onPageChanged;
  final void Function(int playingIndex) onControlPressed;
  final ValueNotifier<int?> playingIndexNotifier;
  final ValueNotifier<bool> isPlayingNotifier;
  final AudioCenter audioCenter;
  final bool dark;
  final double bottomPadding;
  final ReadingProgressController? readingProgressController;
  final VoidCallback? onBookmarkUpdated;
  final int? loadingMatchSurahNumber;
  final int? loadingMatchJuzNumber;
  final BookmarkViewContext bookmarkViewContext;
  final int? juzNumber;

  final VoidCallback? onPreviousNav;
  final VoidCallback? onNextNav;
  final String? previousNavLabel;
  final String? nextNavLabel;

  void _onPageChanged(int i) {
    HapticFeedback.selectionClick();
    onPageChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  itemCount: items.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return Directionality(
                      textDirection: TextDirection.ltr,
                      child: _AyahFocusPage(
                        item: items[index],
                        prefs: prefs,
                        dark: dark,
                        playingIndexNotifier: playingIndexNotifier,
                        isPlayingNotifier: isPlayingNotifier,
                        audioCenter: audioCenter,
                        onControlPressed: onControlPressed,
                        readingProgressController: readingProgressController,
                        onBookmarkUpdated: onBookmarkUpdated,
                        loadingMatchSurahNumber: loadingMatchSurahNumber,
                        loadingMatchJuzNumber: loadingMatchJuzNumber,
                        bookmarkViewContext: bookmarkViewContext,
                        juzNumber: juzNumber,
                      ),
                    );
                  },
                ),
              ),
            ),
            QuranAdjacentReaderNavBar(
              onPrevious: onPreviousNav,
              previousLabel: previousNavLabel,
              onNext: onNextNav,
              nextLabel: nextNavLabel,
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

class _AyahFocusPage extends StatelessWidget {
  const _AyahFocusPage({
    required this.item,
    required this.prefs,
    required this.dark,
    required this.playingIndexNotifier,
    required this.isPlayingNotifier,
    required this.audioCenter,
    required this.onControlPressed,
    required this.readingProgressController,
    required this.onBookmarkUpdated,
    required this.loadingMatchSurahNumber,
    required this.loadingMatchJuzNumber,
    required this.bookmarkViewContext,
    required this.juzNumber,
  });

  final VerseFocusItem item;
  final ReadingPreferences prefs;
  final bool dark;
  final ValueNotifier<int?> playingIndexNotifier;
  final ValueNotifier<bool> isPlayingNotifier;
  final AudioCenter audioCenter;
  final void Function(int playingIndex) onControlPressed;
  final ReadingProgressController? readingProgressController;
  final VoidCallback? onBookmarkUpdated;
  final int? loadingMatchSurahNumber;
  final int? loadingMatchJuzNumber;
  final BookmarkViewContext bookmarkViewContext;
  final int? juzNumber;

  @override
  Widget build(BuildContext context) {
    final storage = getIt<IStorageService>();
    final surah = item.surah;
    final ayah = item.ayah;
    final pi = item.playingIndex;
    final displayAyah = ayah.copyWith(text: item.displayArabic);

    final isCompleted =
        storage.isAyahCompleted(surah.number, ayah.numberInSurah);
    final isBookmarked = storage.isBookmarked(surah.number, ayah.numberInSurah);
    final isEven = pi % 2 == 0;
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
        final viewportHeight =
            (constraints.maxHeight - 2 * vPad).clamp(0.0, double.infinity);

        final card = VisibilityDetector(
          key: ValueKey('focus_vis_${surah.number}_${ayah.numberInSurah}_$pi'),
          onVisibilityChanged: (info) {
            readingProgressController?.onVerseVisibilityChanged(
              pi,
              info.visibleFraction,
            );
          },
          child: AyahCard(
            key: ValueKey(
              'focus_ayah_${surah.number}_${ayah.numberInSurah}_${prefs.arabicFontSize}_${prefs.arabicFontFamily}',
            ),
            index: pi,
            ayah: displayAyah,
            playingIndexNotifier: playingIndexNotifier,
            isPlayingNotifier: isPlayingNotifier,
            audioCenter: audioCenter,
            loadingMatchSurahNumber: loadingMatchSurahNumber,
            loadingMatchJuzNumber: loadingMatchJuzNumber,
            prefs: prefs,
            isCompleted: isCompleted,
            backgroundColor: backgroundColor,
            showPlayButton: showPlayButton,
            onPlayPressed: (_) => onControlPressed(pi),
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
                await storage.addBookmark(
                  Bookmark(
                    surah: surah,
                    ayah: ayah,
                    juzNumber: juzNumber,
                    viewContext: bookmarkViewContext,
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
              displayArabic: item.displayArabic,
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
