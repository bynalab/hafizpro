import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/model/bookmark.model.dart';
import 'package:hafiz_test/quran/reading_progress_controller.dart';
import 'package:hafiz_test/quran/widgets/ayah_card.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/bismillah.dart';
import 'package:hafiz_test/util/reading_preferences.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class QuranAyahList extends StatelessWidget {
  final Surah surah;
  final bool showBismillah;
  final ValueNotifier<int?> playingIndexNotifier;
  final ValueNotifier<bool> isPlayingNotifier;
  final ItemScrollController scrollController;
  final ItemPositionsListener itemPositionsListener;
  final void Function(int index) onControlPressed;
  final VoidCallback? onProgressUpdated;
  final VoidCallback? onBookmarkUpdated;
  final int? juzNumber;
  final ReadingProgressController? readingProgressController;
  final double bottomPadding;

  const QuranAyahList({
    super.key,
    required this.surah,
    required this.showBismillah,
    required this.playingIndexNotifier,
    required this.isPlayingNotifier,
    required this.scrollController,
    required this.itemPositionsListener,
    required this.onControlPressed,
    this.onProgressUpdated,
    this.onBookmarkUpdated,
    this.juzNumber,
    this.readingProgressController,
    this.bottomPadding = 30,
  });

  int get _offset => showBismillah ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storage = getIt<IStorageService>();
    final prefs = ReadingPreferences.fromStorage(storage);

    return ScrollablePositionedList.separated(
      padding: EdgeInsets.only(top: 30, bottom: bottomPadding),
      itemCount: surah.ayahs.length + _offset,
      itemScrollController: scrollController,
      itemPositionsListener: itemPositionsListener,
      itemBuilder: (_, index) {
        if (showBismillah && index == 0) {
          return Padding(
            key: const ValueKey('bismillah'),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Text(
              Bismillah.glyph,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 24,
                height: 2,
                color: isDark ? Colors.white : AppColors.black500,
              ),
            ),
          );
        }

        final ayahIndex = index - _offset;
        final isEven = ayahIndex % 2 == 0;

        final ayah = surah.ayahs[ayahIndex];
        final displayText = (showBismillah && ayahIndex == 0)
            ? Bismillah.trimLeadingForDisplay(ayah.text)
            : ayah.text;

        final isCompleted =
            storage.isAyahCompleted(surah.number, ayah.numberInSurah);

        final isBookmarked =
            storage.isBookmarked(surah.number, ayah.numberInSurah);

        return VisibilityDetector(
          key: ValueKey('ayah_vis_${ayah.numberInSurah}'),
          onVisibilityChanged: (info) {
            readingProgressController?.onVerseVisibilityChanged(
              ayahIndex,
              info.visibleFraction,
            );
          },
          child: AyahCard(
            key: ValueKey(
                'ayah_${ayah.numberInSurah}_${prefs.arabicFontSize}_${prefs.arabicFontFamily}'),
            index: index - _offset,
            ayah: ayah.copyWith(text: displayText),
            playingIndexNotifier: playingIndexNotifier,
            isPlayingNotifier: isPlayingNotifier,
            prefs: prefs,
            isCompleted: isCompleted,
            backgroundColor: isDark
                ? (isEven ? const Color(0xFF101010) : const Color(0xFF0E0E0E))
                : (isEven ? AppColors.gray500 : AppColors.gray50),
            onPlayPressed: (_) => onControlPressed(ayahIndex),
            onMarkAsRead: (idx) {
              readingProgressController?.markAsReadUpTo(idx);
            },
            isBookmarked: isBookmarked,
            onBookmark: (idx) async {
              if (isBookmarked) {
                await storage.removeBookmark(surah.number, ayah.numberInSurah);
              } else {
                final selectedAyah = surah.ayahs[idx];
                await storage.addBookmark(Bookmark(
                  surah: surah,
                  ayah: selectedAyah,
                  viewContext: BookmarkViewContext.surah,
                  timestamp: DateTime.now(),
                ));
              }
              onBookmarkUpdated?.call();
            },
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 2),
    );
  }
}
