import 'package:flutter/material.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/quran/quran_list.dart';
import 'package:hafiz_test/quran/quran_viewmodel.dart';
import 'package:hafiz_test/quran/surah_loader.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
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
              'Please check your internet connection or try again shortly.',
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
                          viewModel.surah.englishName,
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
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            viewModel.surah.englishName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: QuranAyahList(
                          surah: viewModel.surah,
                          playingIndexNotifier: viewModel.playingIndexNotifier,
                          scrollController: viewModel.itemScrollController,
                          onControlPressed: viewModel.onAyahControlPressed,
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
                            final ayahs = viewModel.surah.ayahs;
                            final i = index;
                            final valid =
                                i != null && i >= 0 && i < ayahs.length;
                            final current = valid ? ayahs[i] : null;
                            final title = current == null
                                ? viewModel.surah.englishName
                                : '${viewModel.surah.englishName}: ${current.numberInSurah}';

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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        await viewModel.audioCenter.stop();
                                        viewModel.playingIndexNotifier.value =
                                            null;
                                        viewModel.isPlayingNotifier.value =
                                            false;
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                StreamBuilder<Duration>(
                                  stream: viewModel.audioCenter.isCurrentSurah(
                                          viewModel.surah.number)
                                      ? viewModel.audioPlayer.positionStream
                                      : const Stream<Duration>.empty(),
                                  builder: (context, snap) {
                                    final matches = viewModel.audioCenter
                                        .isCurrentSurah(viewModel.surah.number);
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

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SliderTheme(
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                    enabledThumbRadius: 0),
                                            overlayShape:
                                                SliderComponentShape.noOverlay,
                                            activeTrackColor:
                                                const Color(0xFF111827),
                                            inactiveTrackColor: Colors.black
                                                .withValues(alpha: 0.25),
                                          ),
                                          child: Slider(
                                            value: value,
                                            onChanged: matches
                                                ? (v) async {
                                                    final ms =
                                                        (totalMs * v).round();
                                                    await viewModel.audioPlayer
                                                        .pause();
                                                    await viewModel.audioPlayer
                                                        .seek(Duration(
                                                            milliseconds: ms));
                                                  }
                                                : null,
                                            onChangeEnd: matches
                                                ? (v) async {
                                                    final ms =
                                                        (totalMs * v).round();
                                                    await viewModel.audioPlayer
                                                        .seek(Duration(
                                                            milliseconds: ms));
                                                    await viewModel.audioPlayer
                                                        .play();
                                                  }
                                                : null,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                fmt(pos),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                              Text(
                                                fmt(total),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 2),
                                ValueListenableBuilder<bool>(
                                  valueListenable: viewModel.isPlayingNotifier,
                                  builder: (context, playing, _) {
                                    IconButton smallIconButton({
                                      required VoidCallback? onPressed,
                                      required IconData icon,
                                    }) {
                                      return IconButton(
                                        onPressed: onPressed,
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                          width: 40,
                                          height: 40,
                                        ),
                                        icon: Icon(
                                          icon,
                                          size: 24,
                                          color: const Color(0xFF111827),
                                        ),
                                      );
                                    }

                                    return Row(
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
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        smallIconButton(
                                          onPressed:
                                              viewModel.audioPlayer.hasPrevious
                                                  ? viewModel.audioPlayer
                                                      .seekToPrevious
                                                  : null,
                                          icon: Icons.skip_previous_rounded,
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
                                            width: 22,
                                            height: 22,
                                            colorFilter: const ColorFilter.mode(
                                              Color(0xFF111827),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                        smallIconButton(
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
                                          icon: Icons.repeat_rounded,
                                        ),
                                        const Spacer(),
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
