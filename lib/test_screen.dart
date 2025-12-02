import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/extension/quran_extension.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_services.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/surah/view_full_surah.dart';
import 'package:hafiz_test/util/util.dart';
import 'package:hafiz_test/widget/button.dart';
import 'package:hafiz_test/services/rating_service.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

class TestScreen extends StatefulWidget {
  final Surah surah;
  final Ayah currentAyah;

  final bool isLoading;
  final Function()? onRefresh;

  const TestScreen({
    super.key,
    required this.surah,
    required this.currentAyah,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  State<StatefulWidget> createState() => _TestPage();
}

class _TestPage extends State<TestScreen> {
  final audioServices = getIt<AudioServices>();
  final storageServices = getIt<IStorageService>();

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
    audioServices.stop();
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
    final content = Column(
      children: [
        if (currentAyah.numberInSurah < ayahs.length)
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Marquee(
              text: 'Guess the next Ayah!!!',
              blankSpace: 20,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        const SizedBox(height: 13),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width,
                height: 293,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Image.asset('assets/img/faded_vector_quran.png'),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Text(
                              'v${currentAyah.numberInSurah}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 150,
                              child: Scrollbar(
                                thumbVisibility: true,
                                thickness: 2,
                                child: SingleChildScrollView(
                                  child: Text(
                                    currentAyah.text,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Kitab',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Text(
                            surah.englishName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            surah.englishNameTranslation,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            width: 140,
                            child: Divider(color: Colors.white),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                surah.revelationType.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const CircleAvatar(
                                backgroundColor: Color(0xFFFF8E6F),
                                radius: 2,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${surah.numberOfAyahs} verses'.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 31),
              StreamBuilder<Duration>(
                stream: audioPlayer.positionStream,
                builder: (_, durationState) {
                  final progress = durationState.data ?? Duration.zero;

                  return ProgressBar(
                    barHeight: 8,
                    thumbRadius: 0,
                    thumbGlowColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    progressBarColor: Theme.of(context).colorScheme.primary,
                    baseBarColor: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.4),
                    progress: progress,
                    total: audioPlayer.duration ?? Duration.zero,
                    onDragUpdate: (details) async {
                      await audioServices.pause();
                      await audioServices.seek(details.timeStamp);
                    },
                    onSeek: (duration) async {
                      await audioServices.seek(duration);
                      await audioServices.play();
                    },
                    timeLabelLocation: TimeLabelLocation.sides,
                    timeLabelTextStyle: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 31),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Column(
                      children: [
                        Icon(
                          Icons.skip_previous_rounded,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          'Previous',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () => playPreviousAyah(),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 85,
                    height: 85,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFFFFE456),
                          Color(0xFF95CB92),
                        ],
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 50,
                          color: const Color(0xFF004B40),
                        ),
                        onPressed: () async {
                          if (isPlaying) {
                            await audioServices.pause(
                                audioName: currentAudioName);
                          } else {
                            await audioServices.play(
                                audioName: currentAudioName);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Column(
                      children: [
                        Icon(
                          Icons.skip_next_rounded,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          'Next',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () => playNextAyah(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repeat Ayah',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: loop,
                    onChanged: (_) {
                      loop = !loop;

                      loopMode = loop ? LoopMode.one : LoopMode.off;
                      audioServices.setLoopMode(loopMode);

                      // Track repeat switch
                      AnalyticsService.trackRepeatSwitch(loop,
                          audioName: currentAudioName);

                      setState(() {});
                    },
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    activeColor: Colors.white,
                  )
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GradientBorderButton(
                      text: 'Speed ${speed}x',
                      icon: SvgPicture.asset(
                        'assets/img/solar_playback-speed-outline.svg',
                      ),
                      onTap: updatePlaybackRate,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GradientBorderButton(
                      text: 'Refresh',
                      icon: SvgPicture.asset(
                        'assets/img/pepicons-pencil_repeat.svg',
                      ),
                      onTap: () async {
                        // Track test refresh
                        AnalyticsService.trackTestRefresh('surah', context: {
                          'surah_name': widget.surah.englishName,
                          'ayah_number': widget.currentAyah.numberInSurah,
                        });

                        await widget.onRefresh?.call();
                        init();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        return SurahScreen(surah: surah);
                      },
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHigh
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/img/iconoir_list.svg'),
                      const SizedBox(width: 8),
                      Text(
                        'See Full List',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: content,
        ),
      );
    }

    return content;
  }
}
