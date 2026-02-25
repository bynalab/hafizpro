import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/quran/widgets/error.dart';
import 'package:hafiz_test/quran/quran_list.dart';
import 'package:hafiz_test/quran/quran_viewmodel.dart';
import 'package:hafiz_test/quran/surah_loader.dart';
import 'package:hafiz_test/quran/widgets/quran_settings_button.dart';
import 'package:hafiz_test/quran/widgets/bottom_audio_controls.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/services/surah.services.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/quran/reading_progress_controller.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

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

  void _onPlayingIndexChanged() {
    final idx = viewModel.playingIndexNotifier.value;
    if (idx == null) return;

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

        setState(() {});
        if (widget.initialAyahNumber != null) {
          final targetIdx = widget.initialAyahNumber! - 1;
          viewModel.playingIndexNotifier.value = targetIdx;
          _scrollWithRetry(targetIdx, animated: false);
        } else {
          _onPlayingIndexChanged();
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
                      'Success',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF78B7C6),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Progress updated to Ayah $ayahNumber',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
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
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 70,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Directionality(
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
                        child: QuranSettingsButton(
                          storage: _storage,
                          isDark: isDark,
                          onChanged: () {
                            if (mounted) {
                              final nextMode =
                                  _storage.getProgressTrackingMode();
                              if (nextMode != _trackingMode) {
                                // Reload surah to refresh the controller with new mode
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) {
                                    return QuranView(surah: widget.surah);
                                  }),
                                );
                                return;
                              }
                              setState(() {});
                            }
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
                      if (_resumeAyah != null) _buildResumeBanner(),
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
                                isPlayingNotifier: viewModel.isPlayingNotifier,
                                scrollController:
                                    viewModel.itemScrollController,
                                itemPositionsListener:
                                    viewModel.itemPositionsListener,
                                onControlPressed:
                                    viewModel.onAyahControlPressed,
                                onBookmarkUpdated: () => setState(() {}),
                                readingProgressController: _progressController,
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
              'You skipped some verses. Continue from Ayah $_resumeAyah?',
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
              _scrollWithRetry(targetIdx, animated: true);
              _storage.setSurahGap(widget.surah.number, null);
              setState(() => _resumeAyah = null);
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFF78B7C6),
            ),
            child: const Text('Continue'),
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
