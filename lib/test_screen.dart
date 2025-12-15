import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/util.dart';
import 'package:hafiz_test/services/rating_service.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/widget/quran_loader.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

class TestScreen extends StatefulWidget {
  final Surah surah;
  final Ayah currentAyah;

  final bool isLoading;
  final Function()? onRefresh;
  final VoidCallback? onReadFull;
  final String readFullLabel;

  const TestScreen({
    super.key,
    required this.surah,
    required this.currentAyah,
    this.onRefresh,
    this.onReadFull,
    this.readFullLabel = 'Read Entire Surah',
    this.isLoading = false,
  });

  @override
  State<StatefulWidget> createState() => _TestPage();
}

class _TestPage extends State<TestScreen> {
  final audioServices = getIt<AudioServices>();
  final storageServices = getIt<IStorageService>();
  final audioCenter = getIt<AudioCenter>();

  bool _isRefreshing = false;

  AudioPlayer get audioPlayer => audioServices.audioPlayer;

  Surah get surah => widget.surah;
  Ayah currentAyah = Ayah();

  List<Ayah> get ayahs => surah.ayahs;

  String get currentAudioName =>
      '${surah.englishName} - Ayah ${currentAyah.numberInSurah}';

  bool loop = false;
  bool autoplay = true;
  bool isPlaying = false;

  LoopMode loopMode = LoopMode.off;
  StreamSubscription<PlayerState>? _playerStateSub;

  Future<void> init() async {
    currentAyah = widget.currentAyah;

    autoplay = storageServices.checkAutoPlay();

    audioServices.setLoopMode(loopMode);

    if (autoplay) {
      await audioServices.play(audioName: currentAudioName);
    }
  }

  @override
  void didUpdateWidget(covariant TestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAyah.number == widget.currentAyah.number) return;
    currentAyah = widget.currentAyah;
    unawaited(handleAudioPlay());
  }

  void playNextAyah() {
    if (currentAyah.numberInSurah >= ayahs.length) {
      showSnackBar(context, 'End of Surah');

      return;
    }

    // Store previous ayah for tracking
    final previousAyah = currentAyah.numberInSurah;
    currentAyah = ayahs[currentAyah.numberInSurah];

    // Track navigation from previous to next verse
    AnalyticsService.trackEvent('Audio Navigation', properties: {
      'action': 'next',
      'from_ayah': previousAyah,
      'to_ayah': currentAyah.numberInSurah,
      'surah_name': surah.englishName,
    });

    handleAudioPlay();
  }

  void playPreviousAyah() {
    if (currentAyah.numberInSurah == 1) {
      showSnackBar(context, 'Beginning of Surah');

      return;
    }

    // Store previous ayah for tracking
    final previousAyah = currentAyah.numberInSurah;
    currentAyah = ayahs[currentAyah.numberInSurah - 2];

    // Track navigation from next to previous verse
    AnalyticsService.trackEvent('Audio Navigation', properties: {
      'action': 'previous',
      'from_ayah': previousAyah,
      'to_ayah': currentAyah.numberInSurah,
      'surah_name': surah.englishName,
    });

    handleAudioPlay();
  }

  Future<void> handleAudioPlay() async {
    try {
      await audioServices.setAudioSource(currentAyah.audioSource);

      if (autoplay) {
        await audioServices.play(audioName: currentAudioName);
      } else {
        await audioServices.pause(audioName: currentAudioName);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();

    init();

    _playerStateSub = audioPlayer.playerStateStream.listen((state) async {
      setState(() {
        isPlaying = state.playing;
      });

      // Track audio start
      if (state.playing && state.processingState == ProcessingState.ready) {
        AnalyticsService.trackAudioStart(
          currentAudioName,
          surahName: surah.englishName,
          ayahNumber: currentAyah.numberInSurah,
        );
      }

      if (state.processingState == ProcessingState.completed) {
        setState(() => isPlaying = false);

        // Track audio completion
        AnalyticsService.trackAudioComplete(
          currentAudioName,
          surahName: surah.englishName,
          ayahNumber: currentAyah.numberInSurah,
        );

        storageServices.saveLastRead(surah, currentAyah);

        // Track test session completion for rating system
        await RatingService.trackTestSessionCompleted();
      }
    });
  }

  @override
  dispose() {
    unawaited(audioServices.stop(trackEvent: false));
    _playerStateSub?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  double speed = 1;
  void updatePlaybackRate() {
    speed = (speed == 2.5) ? 0.5 : speed + 0.5;

    audioServices.setSpeed(speed, audioName: currentAudioName);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const bgGrey = Color(0xFFF3F4F6);
    const cardTeal = Color(0xFF78B7C6);
    const brandGreen = Color(0xFF004B40);
    const textDark = Color(0xFF0F172A);

    String fmt(Duration d) {
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    final content = Column(
      children: [
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: bgGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: ClipRect(
              child: Marquee(
                text: 'Guess the next Ayah      Guess the next Ayah',
                blankSpace: 32,
                velocity: 30,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: cardTeal,
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.35,
                    child: Image.asset(
                      'assets/img/faded_vector_quran.png',
                      width: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${surah.englishName} (${surah.number.toString().padLeft(2, '0')})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${surah.numberOfAyahs} Verses',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Verse ${currentAyah.numberInSurah}',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Text(
                              currentAyah.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Kitab',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
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
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgGrey,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                StreamBuilder<Duration>(
                  stream: audioPlayer.positionStream,
                  builder: (_, durationState) {
                    final progress = durationState.data ?? Duration.zero;

                    final total = audioPlayer.duration ?? Duration.zero;
                    final totalMs = total.inMilliseconds;
                    final clampedProgress = totalMs <= 0
                        ? Duration.zero
                        : Duration(
                            milliseconds: progress.inMilliseconds
                                .clamp(0, totalMs)
                                .toInt(),
                          );

                    return Column(
                      children: [
                        _WaveformSeekBar(
                          progress: clampedProgress,
                          total: total,
                          activeColor: cardTeal,
                          inactiveColor: Colors.black.withValues(alpha: 0.14),
                          onSeekStart: () async {
                            await audioServices.pause();
                          },
                          onSeekUpdate: (d) async {
                            await audioServices.seek(d);
                          },
                          onSeekEnd: (d) async {
                            await audioServices.seek(d);
                            await audioServices.play();
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fmt(clampedProgress),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                            ),
                            Text(
                              fmt(total),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: updatePlaybackRate,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          '${speed}x',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: playPreviousAyah,
                      icon: SvgPicture.asset(
                        'assets/icons/previous.svg',
                        width: 30,
                        height: 30,
                      ),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardTeal,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          if (isPlaying) {
                            await audioServices.pause(
                              audioName: currentAudioName,
                            );
                          } else {
                            await audioServices.play(
                              audioName: currentAudioName,
                            );
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: playNextAyah,
                      icon: SvgPicture.asset(
                        'assets/icons/next.svg',
                        width: 30,
                        height: 30,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        loop = !loop;

                        loopMode = loop ? LoopMode.one : LoopMode.off;
                        audioServices.setLoopMode(loopMode);

                        AnalyticsService.trackRepeatSwitch(loop,
                            audioName: currentAudioName);

                        setState(() {});
                      },
                      icon: Icon(
                        Icons.repeat_rounded,
                        size: 30,
                        color: loop
                            ? brandGreen
                            : textDark.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: brandGreen,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.onReadFull,
                    child: Text(
                      widget.readFullLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: brandGreen,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      AnalyticsService.trackTestRefresh('surah', context: {
                        'surah_name': widget.surah.englishName,
                        'ayah_number': widget.currentAyah.numberInSurah,
                      });

                      setState(() {
                        _isRefreshing = true;
                      });

                      try {
                        await widget.onRefresh?.call();
                      } finally {
                        await init();
                        if (mounted) {
                          setState(() {
                            _isRefreshing = false;
                          });
                        }
                      }
                    },
                    child: Text(
                      'Refresh Ayah',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );

    final body = QuranLoaderOverlay(
      visible: widget.isLoading || _isRefreshing,
      title: 'Loading Ayah',
      subtitle: 'جارٍ التحميل',
      child: content,
    );

    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: body,
        ),
      );
    }

    return body;
  }
}

class _WaveformSeekBar extends StatefulWidget {
  final Duration progress;
  final Duration total;
  final Color activeColor;
  final Color inactiveColor;
  final Future<void> Function()? onSeekStart;
  final Future<void> Function(Duration)? onSeekUpdate;
  final Future<void> Function(Duration)? onSeekEnd;

  const _WaveformSeekBar({
    required this.progress,
    required this.total,
    required this.activeColor,
    required this.inactiveColor,
    this.onSeekStart,
    this.onSeekUpdate,
    this.onSeekEnd,
  });

  @override
  State<_WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends State<_WaveformSeekBar> {
  double? _lastDx;

  double get _progress01 {
    final totalMs = widget.total.inMilliseconds;
    if (totalMs <= 0) return 0;
    return (widget.progress.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }

  Duration _durationForDx(double dx, double width) {
    final totalMs = widget.total.inMilliseconds;
    if (totalMs <= 0 || width <= 0) return Duration.zero;
    final t = (dx / width).clamp(0.0, 1.0);
    return Duration(milliseconds: (totalMs * t).round());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) async {
            final d = _durationForDx(details.localPosition.dx, width);
            await widget.onSeekStart?.call();
            await widget.onSeekUpdate?.call(d);
            await widget.onSeekEnd?.call(d);
          },
          onHorizontalDragStart: (_) async {
            _lastDx = null;
            await widget.onSeekStart?.call();
          },
          onHorizontalDragUpdate: (details) async {
            final box = context.findRenderObject() as RenderBox?;
            final local = box?.globalToLocal(details.globalPosition);
            if (local == null) return;
            _lastDx = local.dx;
            final d = _durationForDx(local.dx, width);
            await widget.onSeekUpdate?.call(d);
          },
          onHorizontalDragEnd: (_) async {
            final dx = _lastDx;
            final d = dx == null ? widget.progress : _durationForDx(dx, width);
            await widget.onSeekEnd?.call(d);
          },
          child: SizedBox(
            height: 34,
            width: double.infinity,
            child: CustomPaint(
              painter: _WaveformPainter(
                progress01: _progress01,
                activeColor: widget.activeColor,
                inactiveColor: widget.inactiveColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress01;
  final Color activeColor;
  final Color inactiveColor;

  const _WaveformPainter({
    required this.progress01,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Bar-style waveform like typical audio UIs.
    final barWidth = 2.6;
    final gap = 2.2;
    final step = barWidth + gap;
    final barCount = (size.width / step).floor().clamp(24, 160);

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = barWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = barWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double pseudoRand(int i) {
      // Deterministic pseudo-random in [0, 1)
      final x = math.sin(i * 12.9898) * 43758.5453;
      return x - x.floorToDouble();
    }

    for (var i = 0; i < barCount; i++) {
      final t = i / (barCount - 1);
      final x = (i * step) + (barWidth / 2);

      // Shape: combine a few smooth waves + pseudo-random jitter
      final a = (math.sin(t * math.pi * 2.0 * 2.4).abs() * 0.55) +
          (math.sin(t * math.pi * 2.0 * 6.5).abs() * 0.25) +
          (pseudoRand(i) * 0.25);
      final height01 = (0.15 + a).clamp(0.15, 1.0);
      final halfH = (size.height * 0.45) * height01;

      final paint = t <= progress01 ? activePaint : inactivePaint;
      canvas.drawLine(
        Offset(x, centerY - halfH),
        Offset(x, centerY + halfH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress01 != progress01 ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
