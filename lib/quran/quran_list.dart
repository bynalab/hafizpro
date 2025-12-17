import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/ayah_card.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/bismillah.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class QuranAyahList extends StatelessWidget {
  final Surah surah;
  final bool showBismillah;
  final ValueNotifier<int?> playingIndexNotifier;
  final ItemScrollController scrollController;
  final void Function(int index) onControlPressed;

  const QuranAyahList({
    super.key,
    required this.surah,
    required this.showBismillah,
    required this.playingIndexNotifier,
    required this.scrollController,
    required this.onControlPressed,
  });

  int get _offset => showBismillah ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.separated(
      padding: const EdgeInsets.symmetric(vertical: 30),
      itemCount: surah.ayahs.length + _offset,
      itemScrollController: scrollController,
      itemBuilder: (_, index) {
        if (showBismillah && index == 0) {
          return Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Text(
              Bismillah.glyph,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 24,
                height: 2,
                color: AppColors.black500,
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

        return AyahCard(
          index: ayahIndex,
          ayah: ayah.copyWith(text: displayText),
          playingIndexNotifier: playingIndexNotifier,
          backgroundColor: isEven ? AppColors.gray500 : AppColors.gray50,
          onPlayPressed: (_) => onControlPressed(ayahIndex),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 2),
    );
  }
}
