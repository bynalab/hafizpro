import 'dart:async';
import 'package:hafiz_test/widget/verse_picker_bottom_sheet.dart';
import 'package:hafiz_test/widget/button.dart';
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
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/services/rating_service.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/widget/quran_loader.dart';
import 'package:just_audio/just_audio.dart';

import 'package:hafiz_test/services/recitation_verification_service.dart';

class TestScreen extends StatefulWidget {
  final Surah surah;
  final Ayah currentAyah;

  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final Future<void> Function({int? ayahNumber})? onReadFull;
  final String readFullLabel;
  final VoidCallback? onNextBoundary;
  final VoidCallback? onPreviousBoundary;

  const TestScreen({
    super.key,
    required this.surah,
    required this.currentAyah,
    this.onRefresh,
    this.onReadFull,
    this.readFullLabel = '',
    this.isLoading = false,
    this.onNextBoundary,
    this.onPreviousBoundary,
  });

  @override
  State<StatefulWidget> createState() => _TestPage();
}

class _TestPage extends State<TestScreen> {
  final audioServices = getIt<AudioServices>();
  final storageServices = getIt<IStorageService>();
  final audioCenter = getIt<AudioCenter>();
  final recitationService = getIt<RecitationVerificationService>();

  bool _isRefreshing = false;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  String _recognizedText = '';
  RecitationResult? _recitationResult;
  bool _isNextDirection = true;

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
    if (oldWidget.currentAyah.number == widget.currentAyah.number &&
        oldWidget.surah.number == widget.surah.number) {
      return;
    }

    currentAyah = widget.currentAyah;
    unawaited(handleAudioPlay());
  }

  void playNextAyah() {
    if (currentAyah.numberInSurah >= ayahs.length) {
      if (widget.onNextBoundary != null) {
        widget.onNextBoundary!();
      } else {
        showSnackBar(context, context.l10n.testEndOfSurah);
      }

      return;
    }

    // Store previous ayah for tracking
    final previousAyah = currentAyah.numberInSurah;
    setState(() {
      _isNextDirection = true;
      currentAyah = ayahs[currentAyah.numberInSurah];
      _recitationResult = null;
      _recognizedText = '';
    });

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
      if (widget.onPreviousBoundary != null) {
        widget.onPreviousBoundary!();
      } else {
        showSnackBar(context, context.l10n.testBeginningOfSurah);
      }

      return;
    }

    // Store previous ayah for tracking
    final previousAyah = currentAyah.numberInSurah;
    setState(() {
      _isNextDirection = false;
      currentAyah = ayahs[currentAyah.numberInSurah - 2];
      _recitationResult = null;
      _recognizedText = '';
    });

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
    // PREVENT playback during/after recording
    if (_isRecording || _isAnalyzing) {
      debugPrint('[TestScreen] handleAudioPlay blocked by active state');
      return;
    }
    try {
      if (currentAyah.audio.isEmpty) {
        debugPrint(
            '[TestScreen] Ayah ${currentAyah.numberInSurah} has no audio URL. Skipping playback.');
        await audioServices.stop(trackEvent: false);
        return;
      }

      await audioServices.setAudioSource(currentAyah.audioSource);

      if (autoplay) {
        await audioServices.play(audioName: currentAudioName);
      } else {
        await audioServices.pause(audioName: currentAudioName);
      }
    } catch (e) {
      debugPrint('[TestScreen] handleAudioPlay error: $e');
    }
  }

  void _jumpToAyah(int ayahIndex) {
    if (ayahIndex < 0 || ayahIndex >= ayahs.length) return;

    final previousAyah = currentAyah.numberInSurah;
    setState(() {
      _isNextDirection = ayahIndex > (previousAyah - 1);
      currentAyah = ayahs[ayahIndex];
      _recitationResult = null;
      _recognizedText = '';
    });

    AnalyticsService.trackEvent('Audio Navigation', properties: {
      'action': 'jump',
      'from_ayah': previousAyah,
      'to_ayah': currentAyah.numberInSurah,
      'surah_name': surah.englishName,
    });

    handleAudioPlay();
  }

  void _showVersePicker(BuildContext context) {
    VersePickerBottomSheet.show(
      context,
      ayahs: ayahs,
      currentAyahNumber: currentAyah.numberInSurah,
      onVerseSelected: (index) => _jumpToAyah(index),
    );
  }

  @override
  void initState() {
    super.initState();

    init();

    _playerStateSub = audioPlayer.playerStateStream.listen((state) async {
      // FORCED PAUSE: If audio starts playing while we are recording/analyzing
      if (state.playing && (_isRecording || _isAnalyzing)) {
        debugPrint(
            '[TestScreen] FORCING PAUSE: Audio resumed during protected state');
        audioServices.pause(audioName: currentAudioName);
        return;
      }

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
    audioServices.isPlaybackBlocked = false;
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
    unawaited(
      audioServices.setSpeed(speed, audioName: currentAudioName),
    );

    setState(() {});
  }

  Future<void> _startRecording() async {
    audioServices.isPlaybackBlocked = true;
    if (isPlaying || audioPlayer.playing) {
      await audioServices.stop(trackEvent: false);
    }

    setState(() {
      _isRecording = true;
      _recognizedText = '';
      _recitationResult = null;
    });

    try {
      await recitationService.startListening((text) {
        setState(() {
          _recognizedText = text;
        });
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    audioServices.isPlaybackBlocked = false;
    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    try {
      await recitationService.stopListening();

      // If we have some recognized text, verify it
      if (_recognizedText.isNotEmpty) {
        // Verify against the NEXT verse
        final nextIndex = currentAyah.numberInSurah;
        if (nextIndex < ayahs.length) {
          final targetAyah = ayahs[nextIndex];
          final result = recitationService.verify(
            targetAyah.text,
            _recognizedText,
          );
          setState(() {
            _recitationResult = result;
            _isAnalyzing = false;
          });
        } else {
          // No next verse in this surah
          debugPrint('End of surah reached, no next verse to verify');
          setState(() {
            _isAnalyzing = false;
            _recitationResult = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.testNoNextVerseInSurah)),
            );
          }
        }
      } else {
        setState(() => _isAnalyzing = false);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final readFullLabel = widget.readFullLabel.isEmpty
        ? context.l10n.testReadEntireSurah
        : widget.readFullLabel;

    const bgGrey = Color(0xFFF3F4F6);
    const cardTeal = Color(0xFF78B7C6);
    const brandGreen = Color(0xFF004B40);
    const textDark = Color(0xFF0F172A);

    final sectionBg = isDark ? const Color(0xFF1A1A1A) : bgGrey;
    final cardBg = isDark ? const Color(0xFF243F46) : cardTeal;
    final primary = isDark ? const Color(0xFF2A6B6F) : brandGreen;
    final onPrimary = Colors.white;
    final onSurface = isDark ? const Color(0xFFF3F4F6) : textDark;
    final onSurfaceMuted = isDark ? const Color(0xFF9CA3AF) : textDark;
    final waveformInactive = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.14);

    String fmt(Duration d) {
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    final content = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Combined Instruction & Verse Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < -300) {
                        // Swipe Left -> Next
                        playNextAyah();
                      } else if (details.primaryVelocity! > 300) {
                        // Swipe Right -> Previous
                        playPreviousAyah();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      width: MediaQuery.sizeOf(context).width,
                      height: (_recitationResult == null &&
                              !_isRecording &&
                              !_isAnalyzing)
                          ? 340
                          : 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: cardBg,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Opacity(
                              opacity: 0.25,
                              child: Image.asset(
                                'assets/img/faded_vector_quran.png',
                                width: 160,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              // Instruction Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _showVersePicker(context),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              context.l10n.verseNumberLabel(
                                                  currentAyah.numberInSurah),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      context.l10n
                                          .testVersesCount(surah.numberOfAyahs),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    widget.onReadFull?.call(
                                      ayahNumber: currentAyah.numberInSurah,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      switchInCurve: Curves.easeInOutCubic,
                                      switchOutCurve: Curves.easeInOutCubic,
                                      transitionBuilder: (Widget child,
                                          Animation<double> animation) {
                                        final offsetValue =
                                            _isNextDirection ? 1.2 : -1.2;
                                        final inAnimation = Tween<Offset>(
                                          begin: Offset(offsetValue, 0),
                                          end: Offset.zero,
                                        ).animate(animation);

                                        final outAnimation = Tween<Offset>(
                                          begin: Offset(-offsetValue, 0),
                                          end: Offset.zero,
                                        ).animate(animation);

                                        if (child.key ==
                                            ValueKey(currentAyah.number)) {
                                          return SlideTransition(
                                              position: inAnimation,
                                              child: FadeTransition(
                                                  opacity: animation,
                                                  child: child));
                                        } else {
                                          return SlideTransition(
                                              position: outAnimation,
                                              child: FadeTransition(
                                                  opacity: animation,
                                                  child: child));
                                        }
                                      },
                                      child: Center(
                                        key: ValueKey(currentAyah.number),
                                        child: SingleChildScrollView(
                                          child: Builder(
                                            builder: (context) {
                                              final text = currentAyah.text;
                                              final fontSize =
                                                  _getVerseFontSize(text);

                                              return Text(
                                                text,
                                                textAlign: TextAlign.center,
                                                textDirection:
                                                    TextDirection.rtl,
                                                style: GoogleFonts.amiri(
                                                  textStyle: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    height: 2.0,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Placeholder or Results Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: (_isRecording ||
                            _isAnalyzing ||
                            _recitationResult != null)
                        ? _RecitationStatusCard(
                            isRecording: _isRecording,
                            isAnalyzing: _isAnalyzing,
                            recognizedText: _recognizedText,
                            result: _recitationResult,
                            targetVerseNumber: currentAyah.numberInSurah + 1,
                            onStop: _stopRecording,
                            onRetry: _startRecording,
                            onClose: () {
                              setState(() {
                                _recitationResult = null;
                                _recognizedText = '';
                              });
                            },
                          )
                        : // Subtle Placeholder
                        InkWell(
                            onTap:
                                _isRecording ? _stopRecording : _startRecording,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24, horizontal: 16),
                              width: MediaQuery.sizeOf(context).width,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isRecording
                                      ? Colors.red.withValues(alpha: 0.5)
                                      : primary.withValues(alpha: 0.1),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : Colors.grey.withValues(alpha: 0.05),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _isRecording
                                        ? Icons.stop_rounded
                                        : Icons.keyboard_voice_rounded,
                                    color: _isRecording ? Colors.red : primary,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isRecording
                                        ? context.l10n.recitationReciteVerse(
                                            currentAyah.numberInSurah + 1)
                                        : context.l10n.testGuessNextAyah,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isRecording
                                          ? Colors.red
                                          : (isDark ? Colors.white : primary),
                                    ),
                                  ),
                                  if (!_isRecording) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      context.l10n.recitationExperimentalLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: onSurfaceMuted.withValues(
                                            alpha: 0.6),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    _isRecording
                                        ? context.l10n.ayahFinderListeningStatus
                                        : context.l10n.ayahFinderTapToIdentify,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sectionBg,
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
                              activeColor: primary,
                              inactiveColor: waveformInactive,
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
                                    color: onSurface,
                                  ),
                                ),
                                Text(
                                  fmt(total),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
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
                                    color: onSurface,
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
                                colorFilter: ColorFilter.mode(
                                  isDark ? onPrimary : textDark,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 30,
                                  color: onPrimary,
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
                                colorFilter: ColorFilter.mode(
                                  isDark ? onPrimary : textDark,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    loop = !loop;

                                    loopMode =
                                        loop ? LoopMode.one : LoopMode.off;
                                    audioServices.setLoopMode(loopMode);

                                    AnalyticsService.trackRepeatSwitch(loop,
                                        audioName: currentAudioName);

                                    setState(() {});
                                  },
                                  icon: Icon(
                                    Icons.repeat_rounded,
                                    size: 30,
                                    color: loop
                                        ? primary
                                        : onSurfaceMuted.withValues(
                                            alpha: 0.65),
                                  ),
                                ),
                                if (loop)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: primary,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '1',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: onPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                isDark ? const Color(0xFF3A3A3A) : brandGreen,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => widget.onReadFull?.call(),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            readFullLabel,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? onSurface : brandGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
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
                            await audioServices.stop(trackEvent: false);
                            await widget.onRefresh?.call();
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isRefreshing = false;
                              });
                            }
                          }
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.l10n.testRefreshAyah,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final body = QuranLoaderOverlay(
      visible: widget.isLoading || _isRefreshing,
      title: context.l10n.testLoadingAyahTitle,
      subtitle: context.l10n.commonLoadingSubtitle,
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

  double _getVerseFontSize(String text) {
    if (text.length < 50) {
      return 46;
    } else if (text.length < 100) {
      return 32;
    } else if (text.length < 200) {
      return 24;
    } else {
      return 20;
    }
  }
}

class _RecitationStatusCard extends StatelessWidget {
  final bool isRecording;
  final bool isAnalyzing;
  final String recognizedText;
  final RecitationResult? result;
  final int targetVerseNumber;
  final VoidCallback onClose;
  final VoidCallback? onStop;
  final VoidCallback? onRetry;

  const _RecitationStatusCard({
    required this.isRecording,
    required this.isAnalyzing,
    required this.recognizedText,
    required this.result,
    required this.targetVerseNumber,
    required this.onClose,
    this.onStop,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFF2A6B6F) : const Color(0xFF004B40);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E292B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: result != null
              ? _getResultColor(result!.type).withValues(alpha: 0.3)
              : isRecording
                  ? Colors.red.withValues(alpha: 0.3)
                  : primary.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isRecording
                    ? Icons.mic_rounded
                    : isAnalyzing
                        ? Icons.sync_rounded
                        : Icons.analytics_rounded,
                color: isRecording ? Colors.red : primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRecording
                          ? context.l10n
                              .recitationReciteVerse(targetVerseNumber)
                          : isAnalyzing
                              ? context.l10n
                                  .recitationAnalyzingVerse(targetVerseNumber)
                              : context.l10n
                                  .recitationVerseResult(targetVerseNumber),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isRecording)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_rounded,
                        color: Colors.red, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                )
              else if (!isAnalyzing)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isRecording || isAnalyzing) ...[
            Text(
              recognizedText.isEmpty
                  ? context.l10n.recitationStartNow
                  : recognizedText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Kitab',
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
            if (isAnalyzing)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ] else if (result != null) ...[
            _ResultItem(
              label: context.l10n.recitationSimilarityScore,
              value: '${(result!.similarity * 100).toStringAsFixed(1)}%',
              color: _getResultColor(result!.type),
              isBold: true,
            ),
            const Divider(height: 24),
            Text(
              context.l10n.recitationYourRecitation,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              result!.recognizedText,
              style: const TextStyle(
                fontFamily: 'Kitab',
                fontSize: 18,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getResultColor(result!.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getResultLabel(context, result!.type),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getResultColor(result!.type),
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Button(
                  onPressed: onRetry,
                  height: 34,
                  width: 140,
                  color: _getResultColor(result!.type).withValues(alpha: 0.1),
                  radius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 16, color: _getResultColor(result!.type)),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.errorRetryButton,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _getResultColor(result!.type),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _getResultColor(RecitationResultType type) {
    switch (type) {
      case RecitationResultType.correct:
        return Colors.green.shade600;
      case RecitationResultType.almostCorrect:
        return Colors.orange.shade700;
      case RecitationResultType.incorrect:
        return Colors.red.shade600;
    }
  }

  String _getResultLabel(BuildContext context, RecitationResultType type) {
    final l = context.l10n;
    switch (type) {
      case RecitationResultType.correct:
        return l.recitationResultPerfect;
      case RecitationResultType.almostCorrect:
        return l.recitationResultAlmost;
      case RecitationResultType.incorrect:
        return l.recitationResultIncorrect;
    }
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _ResultItem({
    required this.label,
    required this.value,
    this.color = Colors.black87,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
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
