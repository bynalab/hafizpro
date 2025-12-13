import 'package:flutter/material.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/ayah_card.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class QuranAyahList extends StatelessWidget {
  final Surah surah;
  final ValueNotifier<int?> playingIndexNotifier;
  final ItemScrollController scrollController;
  final void Function(int index) onControlPressed;

  const QuranAyahList({
    super.key,
    required this.surah,
    required this.playingIndexNotifier,
    required this.scrollController,
    required this.onControlPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.separated(
      padding: const EdgeInsets.symmetric(vertical: 30),
      itemCount: surah.ayahs.length,
      itemScrollController: scrollController,
      itemBuilder: (_, index) {
        final isEven = index % 2 == 0;

        return AyahCard(
          index: index,
          ayah: surah.ayahs[index],
          playingIndexNotifier: playingIndexNotifier,
          backgroundColor: isEven ? AppColors.gray500 : AppColors.gray50,
          onPlayPressed: (_) => onControlPressed(index),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 2),
    );
  }
}
