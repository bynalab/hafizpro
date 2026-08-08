import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/quran/focus_read/quran_mushaf_panel.dart';
import 'package:hafiz_test/quran/focus_read/quran_verse_focus_panel.dart';
import 'package:hafiz_test/quran/focus_read/mushaf_surah_layout.dart';
import 'package:hafiz_test/quran/focus_read/verse_focus_item.dart';
import 'package:hafiz_test/quran/widgets/bottom_audio_controls.dart';
import 'package:hafiz_test/quran/quran_list.dart';
import 'package:hafiz_test/quran/quran_viewmodel.dart';
import 'package:hafiz_test/quran/surah_loader.dart';
import 'package:hafiz_test/quran/widgets/quran_settings_button.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/reading_preferences.dart';
import 'package:hafiz_test/util/tarteel_audio.dart';
import 'package:hafiz_test/quran/reading_progress_controller.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/widget/verse_picker_bottom_sheet.dart';

class QuranView extends StatefulWidget {
  final Surah surah;
  final int? initialAyahNumber;

  const QuranView({super.key, required this.surah, this.initialAyahNumber});

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
  ReadingProgressController? _progressController;
  int? _resumeAyah;
  String _trackingMode = 'smart';

  PageController? _focusPageController;
  int _focusPageIndex = 0;

  PageController? _mushafPageController;
  int _mushafPageIndex = 0;

  void _disposeFocusController() {
    _focusPageController?.dispose();
    _focusPageController = null;
  }

  void _disposeMushafController() {
    _mushafPageController?.dispose();
    _mushafPageController = null;
  }

  void _ensureFocusController(int initialPage) {
    final surahVm = viewModel.surah;
    if (surahVm == null) return;
    final max = surahVm.ayahs.length - 1;
    final p = initialPage.clamp(0, max);
    _focusPageController?.dispose();
    _focusPageController = PageController(initialPage: p);
    _focusPageIndex = p;
  }

  void _ensureMushafController(int initialSliceIndex) {
    final surahVm = viewModel.surah;
    if (surahVm == null) return;
    final slices = buildMushafSlicesForSurah(surahVm.ayahs);
    if (slices.isEmpty) return;
    final max = slices.length - 1;
    final p = initialSliceIndex.clamp(0, max);
    _mushafPageController?.dispose();
    _mushafPageController = PageController(initialPage: p);
    _mushafPageIndex = p;
  }

  void _syncReaderModeWithView() {
    final prefs = ReadingPreferences.fromStorage(_storage);
    if (viewModel.surah == null) return;
    final mode = prefs.readerViewMode;

    if (mode == QuranReaderViewMode.verseFocus) {
      _disposeMushafController();
      final idx = viewModel.playingIndexNotifier.value ?? _focusPageIndex;
      _ensureFocusController(idx);
      return;
    }

    if (mode == QuranReaderViewMode.mushaf) {
      _disposeFocusController();
      final surahVm = viewModel.surah!;
      final slices = buildMushafSlicesForSurah(surahVm.ayahs);
      if (slices.isEmpty) return;
      final int ayahIdx;
      if (viewModel.playingIndexNotifier.value != null) {
        ayahIdx = viewModel.playingIndexNotifier.value!
            .clamp(0, surahVm.ayahs.length - 1);
      } else if (_mushafPageIndex >= 0 && _mushafPageIndex < slices.length) {
        ayahIdx = slices[_mushafPageIndex].ayahIndices.first;
      } else {
        ayahIdx = 0;
      }
      final sliceIdx = mushafSliceIndexForAyahIndex(slices, ayahIdx);
      _ensureMushafController(sliceIdx);
      return;
    }

    _disposeFocusController();
    _disposeMushafController();
  }

  void _onPlayingIndexChanged() {
    final idx = viewModel.playingIndexNotifier.value;
    if (idx == null) return;

    final mode = ReadingPreferences.fromStorage(_storage).readerViewMode;
    if (mode == QuranReaderViewMode.verseFocus) {
      final surahVm = viewModel.surah;
      if (surahVm == null) return;
      final max = surahVm.ayahs.length - 1;
      final p = idx.clamp(0, max);
      void animate() {
        final c = _focusPageController;
        if (c != null && c.hasClients) {
          c.animateToPage(
            p,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      }

      animate();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        animate();
      });
      setState(() => _focusPageIndex = p);
      return;
    }

    if (mode == QuranReaderViewMode.mushaf) {
      final surahVm = viewModel.surah;
      if (surahVm == null) return;
      final slices = buildMushafSlicesForSurah(surahVm.ayahs);
      if (slices.isEmpty) return;
      final p = mushafSliceIndexForAyahIndex(
        slices,
        idx.clamp(0, surahVm.ayahs.length - 1),
      );
      void animate() {
        final c = _mushafPageController;
        if (c != null && c.hasClients) {
          c.animateToPage(
            p,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      }

      animate();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        animate();
      });
      setState(() => _mushafPageIndex = p);
      return;
    }

    _scrollWithRetry(idx, animated: true);
  }

  void _scrollWithRetry(int idx, {required bool animated}) {
    // The scroll controller may not be attached yet (initial build / rebuild).
    if (!viewModel.itemScrollController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollWithRetry(idx, animated: animated);
      });

      return;
    }

    viewModel.scrollToVerse(idx, isAnimated: animated);
  }

  @override
  void initState() {
    super.initState();

    viewModel.initiateListeners();
    viewModel.playingIndexNotifier.addListener(_onPlayingIndexChanged);
    viewModel.audioCenter.addListener(_onAudioCenterChanged);
    viewModel.initialize(widget.surah.number).then((_) {
      if (mounted) {
        _trackingMode = _storage.getProgressTrackingMode();

        _progressController = ReadingProgressController(
          surahNumber: widget.surah.number,
          totalVerses: widget.surah.ayahs.length,
          storageService: _storage,
          onProgressSaved: _onProgressSaved,
          trackingMode: _trackingMode,
        );

        if (_trackingMode != 'off') {
          _resumeAyah = _storage.getSurahGap(widget.surah.number);
        }

        if (widget.initialAyahNumber != null) {
          final targetIdx = widget.initialAyahNumber! - 1;
          viewModel.playingIndexNotifier.value = targetIdx;
        }

        _syncReaderModeWithView();
        setState(() {});

        final layoutMode =
            ReadingPreferences.fromStorage(_storage).readerViewMode;
        if (layoutMode == QuranReaderViewMode.normal) {
          if (widget.initialAyahNumber != null) {
            final targetIdx = widget.initialAyahNumber! - 1;
            _scrollWithRetry(targetIdx, animated: true);
          } else {
            _onPlayingIndexChanged();
          }
        }

        final reciterId = _storage.getReciterId();
        final reciter = TarteelAudio.reciterForId(reciterId);
        if (reciter?.isSurahBySurah == true &&
            viewModel.audioCenter.uiState == AudioPlayerUiState.hidden) {
          viewModel.audioCenter.setUiState(AudioPlayerUiState.expanded);
        }
      }
    });
  }

  void _onProgressSaved(int upToAyahNumber) {
    if (!mounted) return;

    // Use a short delay via microtask to ensure we aren't in the middle of a build
    // but the context is still very much valid.
    Future.microtask(() {
      if (!mounted) return;
      setState(() {});
      _showPremiumToast(upToAyahNumber);
    });
  }

  void _showPremiumToast(int ayahNumber) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1D353B),
                const Color(0xFF1D353B).withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF78B7C6).withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF78B7C6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.markReadSuccessTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF78B7C6),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      context.l10n.markReadProgressUpdated(ayahNumber),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  _progressController?.undoMarkAsRead();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  if (mounted) setState(() {});
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF78B7C6),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text(
                  context.l10n.undo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 40),
      ),
    );
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
    _disposeFocusController();
    _disposeMushafController();
    _progressController?.dispose();
    viewModel.playingIndexNotifier.removeListener(_onPlayingIndexChanged);
    viewModel.audioCenter.removeListener(_onAudioCenterChanged);
    viewModel.dispose();

    super.dispose();
  }

  Future<bool> _handlePop() async {
    _progressController?.saveProgress();
    return true; // Simple pop now, controller handles save
  }

  void _openAdjacentSurah(int surahNumber) {
    _progressController?.saveProgress();
    final target = findSurahByNumber(surahNumber);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuranView(surah: target),
      ),
    );
  }

  void _showVersePicker() {
    final surahVm = viewModel.surah;
    if (surahVm == null) return;

    final idx = viewModel.playingIndexNotifier.value;
    final currentAyahNumber = (idx ?? 0) + 1;

    VersePickerBottomSheet.show(
      context,
      ayahs: surahVm.ayahs,
      currentAyahNumber: currentAyahNumber,
      subtitle: context.l10n.versePickerSubtitleRead,
      onVerseSelected: _jumpToVerse,
    );
  }

  void _jumpToVerse(int ayahIndex) {
    final surahVm = viewModel.surah;
    if (surahVm == null) return;
    if (ayahIndex < 0 || ayahIndex >= surahVm.ayahs.length) return;

    final fromAyah = (viewModel.playingIndexNotifier.value ?? 0) + 1;
    final toAyah = ayahIndex + 1;

    viewModel.playingIndexNotifier.value = ayahIndex;

    final mode = ReadingPreferences.fromStorage(_storage).readerViewMode;
    if (mode == QuranReaderViewMode.verseFocus) {
      final max = surahVm.ayahs.length - 1;
      final p = ayahIndex.clamp(0, max);
      final c = _focusPageController;
      if (c != null && c.hasClients) {
        c.animateToPage(
          p,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      setState(() => _focusPageIndex = p);
    } else if (mode == QuranReaderViewMode.mushaf) {
      final slices = buildMushafSlicesForSurah(surahVm.ayahs);
      if (slices.isEmpty) return;
      final p = mushafSliceIndexForAyahIndex(slices, ayahIndex);
      final c = _mushafPageController;
      if (c != null && c.hasClients) {
        c.animateToPage(
          p,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      setState(() => _mushafPageIndex = p);
    } else {
      _scrollWithRetry(ayahIndex, animated: true);
    }

    AnalyticsService.trackEvent('Reading Navigation', properties: {
      'action': 'jump',
      'from_ayah': fromAyah,
      'to_ayah': toAyah,
      'surah_name': surahVm.englishName,
    });
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
    final readerPrefs = ReadingPreferences.fromStorage(_storage);
    final readerViewMode = readerPrefs.readerViewMode;

    if (viewModel.isLoading) {
      return Scaffold(
        body: SurahLoader(
          title: context.l10n.surahLoadingTitle,
          subtitle: context.l10n.surahLoadingSubtitle,
        ),
      );
    }

    if (viewModel.hasError) {
      return Scaffold(
        body: CustomErrorWidget(
          title: context.l10n.quranViewErrorTitle,
          message: '${context.l10n.quranViewErrorMessage} ${viewModel.error}',
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _handlePop();
        if (shouldPop && mounted) {
          AnalyticsService.trackBackPress(fromScreen: 'Quran View');

          if (context.mounted) {
            Navigator.of(context).pop();
          }
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
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 54,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
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
                      Expanded(
                        child: viewModel.surah == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: InkWell(
                                  onTap: _showVersePicker,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                viewModel.surah!.englishName,
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  height: 1.15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF111827),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 18,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF111827),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          context.l10n.testVersesCount(
                                            viewModel.surah!.numberOfAyahs,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            height: 1.15,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.75,
                                                  )
                                                : const Color(0xFF111827)
                                                    .withValues(alpha: 0.65),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      QuranSettingsButton(
                        storage: _storage,
                        isDark: isDark,
                        onChanged: () {
                          if (mounted) {
                            final nextMode = _storage.getProgressTrackingMode();
                            if (nextMode != _trackingMode) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) {
                                  return QuranView(surah: widget.surah);
                                }),
                              );
                              return;
                            }
                            viewModel
                                .initialize(widget.surah.number,
                                    showLoading: false)
                                .then((_) {
                              if (!mounted) return;
                              _syncReaderModeWithView();
                              setState(() {});
                              final layout = ReadingPreferences.fromStorage(
                                _storage,
                              ).readerViewMode;
                              if (layout == QuranReaderViewMode.normal) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  final i =
                                      viewModel.playingIndexNotifier.value;
                                  if (i != null) {
                                    _scrollWithRetry(i, animated: false);
                                  }
                                });
                              }
                            });
                          }
                        },
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
                      if (_resumeAyah != null) _buildResumeBanner(),
                      Expanded(
                        child: viewModel.surah == null
                            ? const SizedBox.shrink()
                            : ListenableBuilder(
                                listenable: viewModel.audioCenter,
                                builder: (context, _) {
                                  final state = viewModel.audioCenter.uiState;
                                  double bottomPadding = 20;
                                  if (state == AudioPlayerUiState.collapsed) {
                                    bottomPadding = 72;
                                  } else if (state ==
                                      AudioPlayerUiState.expanded) {
                                    bottomPadding = 200;
                                  }

                                  final onPrevSurah = widget.surah.number > 1
                                      ? () => _openAdjacentSurah(
                                            widget.surah.number - 1,
                                          )
                                      : null;
                                  final onNextSurah = widget.surah.number < 114
                                      ? () => _openAdjacentSurah(
                                            widget.surah.number + 1,
                                          )
                                      : null;
                                  final l10n = context.l10n;

                                  if (readerViewMode ==
                                      QuranReaderViewMode.mushaf) {
                                    if (_mushafPageController == null) {
                                      return const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    final s = viewModel.surah!;
                                    final showBi =
                                        viewModel.shouldShowBismillah(
                                      s.number,
                                    );
                                    final mushafLines = mushafLinesForSurah(
                                      s,
                                      showBismillah: showBi,
                                    );
                                    final slices =
                                        buildMushafSlicesForSurah(s.ayahs);
                                    if (slices.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return QuranMushafPanel(
                                      lines: mushafLines,
                                      slices: slices,
                                      pageController: _mushafPageController!,
                                      prefs: readerPrefs,
                                      onPageChanged: (i) => setState(
                                        () => _mushafPageIndex = i,
                                      ),
                                      playingIndexNotifier:
                                          viewModel.playingIndexNotifier,
                                      dark: isDark,
                                      contentBottomInset: BottomAudioControls
                                          .readerBottomClearance(
                                        context,
                                        state,
                                      ),
                                      readingProgressController:
                                          _progressController,
                                      onPreviousNav: onPrevSurah,
                                      previousNavLabel: onPrevSurah != null
                                          ? l10n.quranReadPreviousSurah
                                          : null,
                                      onNextNav: onNextSurah,
                                      nextNavLabel: onNextSurah != null
                                          ? l10n.quranReadNextSurah
                                          : null,
                                    );
                                  }

                                  if (readerViewMode ==
                                      QuranReaderViewMode.verseFocus) {
                                    if (_focusPageController == null) {
                                      return const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    final s = viewModel.surah!;
                                    final focusItems = verseFocusItemsForSurah(
                                      s,
                                      showBismillah:
                                          viewModel.shouldShowBismillah(
                                        s.number,
                                      ),
                                    );
                                    return QuranVerseFocusPanel(
                                      items: focusItems,
                                      pageController: _focusPageController!,
                                      prefs: readerPrefs,
                                      onPageChanged: (i) => setState(
                                        () => _focusPageIndex = i,
                                      ),
                                      onControlPressed:
                                          viewModel.onAyahControlPressed,
                                      playingIndexNotifier:
                                          viewModel.playingIndexNotifier,
                                      isPlayingNotifier:
                                          viewModel.isPlayingNotifier,
                                      audioCenter: viewModel.audioCenter,
                                      dark: isDark,
                                      bottomPadding: bottomPadding,
                                      readingProgressController:
                                          _progressController,
                                      onBookmarkUpdated: () => setState(() {}),
                                      loadingMatchSurahNumber: s.number,
                                      onPreviousNav: onPrevSurah,
                                      previousNavLabel: onPrevSurah != null
                                          ? l10n.quranReadPreviousSurah
                                          : null,
                                      onNextNav: onNextSurah,
                                      nextNavLabel: onNextSurah != null
                                          ? l10n.quranReadNextSurah
                                          : null,
                                    );
                                  }

                                  return QuranAyahList(
                                    surah: viewModel.surah!,
                                    showBismillah:
                                        viewModel.shouldShowBismillah(
                                      viewModel.surah?.number,
                                    ),
                                    playingIndexNotifier:
                                        viewModel.playingIndexNotifier,
                                    isPlayingNotifier:
                                        viewModel.isPlayingNotifier,
                                    audioCenter: viewModel.audioCenter,
                                    scrollController:
                                        viewModel.itemScrollController,
                                    itemPositionsListener:
                                        viewModel.itemPositionsListener,
                                    onControlPressed:
                                        viewModel.onAyahControlPressed,
                                    onBookmarkUpdated: () => setState(() {}),
                                    readingProgressController:
                                        _progressController,
                                    bottomPadding: bottomPadding,
                                    onPreviousSurah: onPrevSurah,
                                    onNextSurah: onNextSurah,
                                  );
                                },
                              ),
                      ),
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

  Widget _buildResumeBanner() {
    final cardBg = DashboardPalette.cardTeal(context);
    final primaryText = DashboardPalette.primaryText(context);

    return Container(
      width: double.infinity,
      color: cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.history_edu_rounded,
              size: 20, color: primaryText.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.quranResumeReadingPrompt(_resumeAyah!),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final targetIdx = _resumeAyah! - 1;
              viewModel.playingIndexNotifier.value = targetIdx;
              final mode =
                  ReadingPreferences.fromStorage(_storage).readerViewMode;
              if (mode == QuranReaderViewMode.verseFocus) {
                final max = widget.surah.ayahs.length - 1;
                final p = targetIdx.clamp(0, max);
                _focusPageController?.jumpToPage(p);
                setState(() => _focusPageIndex = p);
              } else if (mode == QuranReaderViewMode.mushaf) {
                final slices = buildMushafSlicesForSurah(widget.surah.ayahs);
                if (slices.isNotEmpty) {
                  final p = mushafSliceIndexForAyahIndex(slices, targetIdx);
                  _mushafPageController?.jumpToPage(p);
                  setState(() => _mushafPageIndex = p);
                }
              } else if (mode == QuranReaderViewMode.normal) {
                _scrollWithRetry(targetIdx, animated: true);
              }
              _storage.setSurahGap(widget.surah.number, null);
              setState(() => _resumeAyah = null);
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFF78B7C6),
            ),
            child: Text(context.l10n.lastReadContinueButton),
          ),
          IconButton(
            onPressed: () {
              _storage.setSurahGap(widget.surah.number, null);
              setState(() => _resumeAyah = null);
            },
            icon: Icon(Icons.close_rounded,
                size: 18, color: primaryText.withValues(alpha: 0.4)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
