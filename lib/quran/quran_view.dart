import 'package:flutter/material.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/quran/quran_list.dart';
import 'package:hafiz_test/quran/quran_viewmodel.dart';
import 'package:hafiz_test/quran/surah_loader.dart';
import 'package:hafiz_test/quran/widgets/reading_preferences_button.dart';
import 'package:hafiz_test/quran/widgets/bottom_audio_controls.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';

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

  final _storage = getIt<IStorageService>();

  double _speed = 1.5;
  bool _isAutoSwitching = false;

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
    viewModel.audioCenter.addListener(_onAudioCenterChanged);
    viewModel.initialize(widget.surah.number).then((_) {
      setState(() {});
      _onPlayingIndexChanged();
    });
  }

  void _onAudioCenterChanged() {
    if (!mounted) return;

    // Only auto-switch screens when AudioCenter is in reading mode and has
    // moved playback to a different surah (auto-advance at end of playlist).
    if (viewModel.audioCenter.playbackOwner != PlaybackOwner.reading) return;

    final currentSurahNumer = viewModel.audioCenter.currentSurahNumber;
    if (currentSurahNumer == null || currentSurahNumer == widget.surah.number) {
      return;
    }

    if (_isAutoSwitching) return;

    _isAutoSwitching = true;

    final nextSurah = findSurahByNumber(currentSurahNumer);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) {
          return QuranView(surah: nextSurah);
        }),
      ).whenComplete(() => _isAutoSwitching = false);
    });
  }

  @override
  void dispose() {
    viewModel.playingIndexNotifier.removeListener(_onPlayingIndexChanged);
    viewModel.audioCenter.removeListener(_onAudioCenterChanged);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFF9FAFB),
        body: Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF1D353B) : const Color(0xFF78B7C6),
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
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          viewModel.surah?.englishName ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ReadingPreferencesButton(
                          storage: _storage,
                          isDark: isDark,
                          onChanged: () {
                            if (mounted) setState(() {});
                          },
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
                    child: ListenableBuilder(
                      listenable: viewModel.audioCenter,
                      builder: (context, _) {
                        return BottomAudioControls(
                          playingIndexListenable:
                              viewModel.playingIndexNotifier,
                          titleBuilder: (index) {
                            final surah = viewModel.surah;
                            if (surah == null) return '';

                            final ayahs = surah.ayahs;
                            final i = index;
                            final valid =
                                i != null && i >= 0 && i < ayahs.length;
                            final current = valid ? ayahs[i] : null;

                            return current == null
                                ? surah.englishName
                                : '${surah.englishName}: ${current.numberInSurah}';
                          },
                          audioCenter: viewModel.audioCenter,
                          audioPlayer: viewModel.audioPlayer,
                          isContextActive: viewModel.surah == null
                              ? false
                              : viewModel.audioCenter
                                  .isCurrentSurah(viewModel.surah!.number),
                          speed: _speed,
                          onSpeedChanged: (nextSpeed) async {
                            _speed = nextSpeed;
                            await viewModel.audioPlayer.setSpeed(_speed);
                            setState(() {});
                          },
                          onTogglePlayPause: viewModel.togglePlayPause,
                        );
                      },
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
