import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/quran/quran_list.dart';
import 'package:hafiz_test/quran/quran_viewmodel.dart';
import 'package:hafiz_test/quran/surah_loader.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuranView extends StatefulWidget {
  final Surah surah;

  const QuranView({super.key, required this.surah});

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  final viewModel = QuranViewModel(
    audioCenter: getIt<AudioCenter>(),
    surahService: getIt<SurahServices>(),
  );

  double _speed = 1.5;

  void _onPlayingIndexChanged() {
    final idx = viewModel.playingIndexNotifier.value;
    if (idx == null) return;

    // The scroll controller may not be attached yet (initial build / rebuild).
    if (!viewModel.itemScrollController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        viewModel.scrollToVerse(idx);
      });

      return;
    }

    viewModel.scrollToVerse(idx);
  }

  @override
  void initState() {
    super.initState();

    viewModel.initiateListeners();
    viewModel.playingIndexNotifier.addListener(_onPlayingIndexChanged);
    viewModel.initialize(widget.surah.number).then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    viewModel.playingIndexNotifier.removeListener(_onPlayingIndexChanged);
    viewModel.dispose();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return Scaffold(body: SurahLoader());
    }

    if (viewModel.hasError) {
      return Scaffold(
        body: CustomErrorWidget(
          title: 'Failed to Load Surah',
          message:
              'Please check your internet connection or try again shortly. ${viewModel.error}',
          icon: Icons.menu_book_rounded,
          color: Colors.green.shade700,
          onRetry: () async {
            setState(() {});
            await viewModel.initialize(widget.surah.number);
            setState(() {});
          },
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Track back press
          AnalyticsService.trackBackPress(fromScreen: 'Quran View');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Column(
          children: [
            Container(
              color: const Color(0xFF78B7C6),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 70,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          viewModel.surah?.englishName ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: viewModel.surah == null
                            ? const SizedBox.shrink()
                            : QuranAyahList(
                                surah: viewModel.surah!,
                                showBismillah: viewModel.shouldShowBismillah(
                                  viewModel.surah?.number,
                                ),
                                playingIndexNotifier:
                                    viewModel.playingIndexNotifier,
                                scrollController:
                                    viewModel.itemScrollController,
                                onControlPressed:
                                    viewModel.onAyahControlPressed,
                              ),
                      ),
                      const SizedBox(height: 150),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      color: const Color(0xFF78B7C6),
                      child: SafeArea(
                        top: false,
                        child: ValueListenableBuilder<int?>(
                          valueListenable: viewModel.playingIndexNotifier,
                          builder: (context, index, _) {
                            final surah = viewModel.surah;
                            if (surah == null) {
                              return const SizedBox.shrink();
                            }

                            final ayahs = surah.ayahs;
                            final i = index;
                            final valid =
                                i != null && i >= 0 && i < ayahs.length;
                            final current = valid ? ayahs[i] : null;
                            final title = current == null
                                ? surah.englishName
                                : '${surah.englishName}: ${current.numberInSurah}';

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.black500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                StreamBuilder<Duration>(
                                  stream: viewModel.audioCenter
                                          .isCurrentSurah(surah.number)
                                      ? viewModel.audioPlayer.positionStream
                                      : const Stream<Duration>.empty(),
                                  builder: (context, snap) {
                                    final matches = viewModel.audioCenter
                                        .isCurrentSurah(surah.number);
                                    final pos = matches
                                        ? (snap.data ?? Duration.zero)
                                        : Duration.zero;
                                    final total = matches
                                        ? (viewModel.audioPlayer.duration ??
                                            Duration.zero)
                                        : Duration.zero;
                                    final totalMs = total.inMilliseconds;
                                    final value = totalMs == 0
                                        ? 0.0
                                        : (pos.inMilliseconds / totalMs)
                                            .clamp(0.0, 1.0);

                                    String fmt(Duration d) {
                                      final m = d.inMinutes
                                          .remainder(60)
                                          .toString()
                                          .padLeft(2, '0');
                                      final s = d.inSeconds
                                          .remainder(60)
                                          .toString()
                                          .padLeft(2, '0');
                                      return '$m:$s';
                                    }

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          fmt(pos),
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.black500,
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                              trackHeight: 4,
                                              thumbShape:
                                                  const RoundSliderThumbShape(
                                                      enabledThumbRadius: 0),
                                              overlayShape: SliderComponentShape
                                                  .noOverlay,
                                              activeTrackColor:
                                                  AppColors.green500,
                                              inactiveTrackColor: AppColors
                                                  .black500
                                                  .withValues(alpha: 0.30),
                                            ),
                                            child: Slider(
                                              value: value,
                                              onChanged: matches
                                                  ? (v) async {
                                                      final ms =
                                                          (totalMs * v).round();
                                                      await viewModel
                                                          .audioPlayer
                                                          .pause();
                                                      await viewModel
                                                          .audioPlayer
                                                          .seek(Duration(
                                                              milliseconds:
                                                                  ms));
                                                    }
                                                  : null,
                                              onChangeEnd: matches
                                                  ? (v) async {
                                                      final ms =
                                                          (totalMs * v).round();
                                                      await viewModel
                                                          .audioPlayer
                                                          .seek(Duration(
                                                              milliseconds:
                                                                  ms));
                                                      await viewModel
                                                          .audioPlayer
                                                          .play();
                                                    }
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Text(
                                          fmt(total),
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.black500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                ValueListenableBuilder<bool>(
                                  valueListenable: viewModel.isPlayingNotifier,
                                  builder: (context, playing, _) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            _speed = _speed == 2.0
                                                ? 1.0
                                                : _speed + 0.5;
                                            await viewModel.audioPlayer
                                                .setSpeed(_speed);
                                            setState(() {});
                                          },
                                          child: Text(
                                            '${_speed.toStringAsFixed(1)}x',
                                            style: GoogleFonts.cairo(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.black500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed:
                                              viewModel.audioPlayer.hasPrevious
                                                  ? viewModel.audioPlayer
                                                      .seekToPrevious
                                                  : null,
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints.tightFor(
                                            width: 40,
                                            height: 40,
                                          ),
                                          icon: SvgPicture.asset(
                                            'assets/icons/previous.svg',
                                            width: 30,
                                            height: 30,
                                            colorFilter: const ColorFilter.mode(
                                              Color(0xFF111827),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF111827),
                                          ),
                                          child: IconButton(
                                            onPressed:
                                                viewModel.togglePlayPause,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints.expand(),
                                            icon: Icon(
                                              playing
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size: 28,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: viewModel
                                                  .audioPlayer.hasNext
                                              ? viewModel.audioPlayer.seekToNext
                                              : null,
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints.tightFor(
                                            width: 40,
                                            height: 40,
                                          ),
                                          icon: SvgPicture.asset(
                                            'assets/icons/next.svg',
                                            width: 30,
                                            height: 30,
                                            colorFilter: const ColorFilter.mode(
                                              Color(0xFF111827),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            final next = viewModel
                                                        .audioPlayer.loopMode ==
                                                    LoopMode.one
                                                ? LoopMode.off
                                                : LoopMode.one;
                                            await viewModel.audioPlayer
                                                .setLoopMode(next);
                                            setState(() {});
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints.tightFor(
                                            width: 40,
                                            height: 40,
                                          ),
                                          icon: Icon(
                                            Icons.repeat_rounded,
                                            size: 24,
                                            color: viewModel
                                                        .audioPlayer.loopMode ==
                                                    LoopMode.one
                                                ? AppColors.black
                                                : AppColors.black600,
                                          ),
                                        )
                                      ],
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
