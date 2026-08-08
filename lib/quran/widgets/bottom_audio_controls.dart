import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/l10n/app_localizations.dart';
import 'package:hafiz_test/services/audio_center.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:just_audio/just_audio.dart';

class BottomAudioControls extends StatelessWidget {
  final ValueListenable<int?> playingIndexListenable;
  final String Function(int? index) titleBuilder;
  final AudioCenter audioCenter;
  final AudioPlayer audioPlayer;

  /// Whether this bottom control bar should currently reflect/drive the shared
  /// global player state.
  final bool isContextActive;

  final double speed;
  final Future<void> Function(double nextSpeed) onSpeedChanged;
  final Future<void> Function() onTogglePlayPause;

  const BottomAudioControls({
    super.key,
    required this.playingIndexListenable,
    required this.titleBuilder,
    required this.audioCenter,
    required this.audioPlayer,
    required this.isContextActive,
    required this.speed,
    required this.onSpeedChanged,
    required this.onTogglePlayPause,
  });

  /// Fixed bottom inset for reader UIs when the bar is expanded.
  /// Tune here if [_buildExpanded] height changes.
  static const double kReaderBottomInsetExpanded = 200;

  /// Fixed bottom inset for reader UIs when the bar is minimized (collapsed).
  /// Tune here if [_buildCollapsed] height changes.
  static const double kReaderBottomInsetMinimized =
      kReaderBottomInsetExpanded - 120;

  /// Space reader bodies should leave above this bar so content is not covered.
  ///
  /// **hidden:** `0` when the bar is absent; only [MediaQuery.viewInsets.bottom]
  /// (IME) is added.
  ///
  /// **collapsed / expanded:** [kReaderBottomInsetMinimized] /
  /// [kReaderBottomInsetExpanded] — no layout math, adjust constants if needed.
  static double readerBottomClearance(
    BuildContext context,
    AudioPlayerUiState uiState,
  ) {
    final ime = MediaQuery.viewInsetsOf(context).bottom;
    switch (uiState) {
      case AudioPlayerUiState.hidden:
        return ime;
      case AudioPlayerUiState.collapsed:
        return kReaderBottomInsetMinimized;
      case AudioPlayerUiState.expanded:
        return kReaderBottomInsetExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: audioCenter,
      builder: (context, _) {
        if (audioCenter.uiState == AudioPlayerUiState.hidden) {
          return const SizedBox.shrink();
        }

        if (audioCenter.uiState == AudioPlayerUiState.collapsed) {
          return _buildCollapsed(context);
        }

        return _buildExpanded(context);
      },
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF1D353B) : const Color(0xFF78B7C6);
    final onBar = isDark ? Colors.white : AppColors.black500;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Tooltip(
        message: AppLocalizations.of(context)!.audioPlayerTapToExpandSemantics,
        child: GestureDetector(
          onTap: () {
            audioCenter.setUiState(AudioPlayerUiState.expanded);
          },
          child: Container(
            width: double.infinity,
            color: barBg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onBar.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                StreamBuilder<Duration>(
                  stream: isContextActive
                      ? audioPlayer.positionStream
                      : const Stream<Duration>.empty(),
                  builder: (context, snap) {
                    final pos = isContextActive
                        ? (snap.data ?? Duration.zero)
                        : Duration.zero;
                    final total = isContextActive
                        ? (audioPlayer.duration ?? Duration.zero)
                        : Duration.zero;
                    final totalMs = total.inMilliseconds;
                    final value = totalMs == 0
                        ? 0.0
                        : (pos.inMilliseconds / totalMs).clamp(0.0, 1.0);

                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 3,
                      backgroundColor: onBar.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(onBar),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
                  child: SafeArea(
                    top: false,
                    child: ValueListenableBuilder<int?>(
                      valueListenable: playingIndexListenable,
                      builder: (context, index, _) {
                        final title = titleBuilder(index);

                        return Row(
                          children: [
                            Icon(
                              Icons.arrow_circle_up_sharp,
                              color: onBar.withValues(alpha: 0.5),
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: onBar,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildPlayPauseButton(context, onBar,
                                isCollapsed: true),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF1D353B) : const Color(0xFF78B7C6);
    final onBar = isDark ? Colors.white : AppColors.black500;
    final mutedOnBar =
        isDark ? Colors.white.withValues(alpha: 0.70) : AppColors.black600;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
        color: barBg,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    audioCenter.setUiState(AudioPlayerUiState.collapsed);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: onBar.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.arrow_circle_down_sharp,
                      color: onBar,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ValueListenableBuilder<int?>(
                  valueListenable: playingIndexListenable,
                  builder: (context, index, _) {
                    final title = titleBuilder(index);

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
                                  color: onBar,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProgressSlider(context, onBar, isDark),
                        const SizedBox(height: 16),
                        _buildMainControls(context, onBar, mutedOnBar, isDark),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSlider(BuildContext context, Color onBar, bool isDark) {
    return StreamBuilder<Duration>(
      stream: isContextActive
          ? audioPlayer.positionStream
          : const Stream<Duration>.empty(),
      builder: (context, snap) {
        final pos =
            isContextActive ? (snap.data ?? Duration.zero) : Duration.zero;
        final total = isContextActive
            ? (audioPlayer.duration ?? Duration.zero)
            : Duration.zero;
        final totalMs = total.inMilliseconds;
        final value =
            totalMs == 0 ? 0.0 : (pos.inMilliseconds / totalMs).clamp(0.0, 1.0);

        String fmt(Duration d) {
          final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
          final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
          return '$m:$s';
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              fmt(pos),
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: onBar,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 0,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: isDark ? Colors.white : AppColors.green500,
                  inactiveTrackColor: isDark
                      ? Colors.white.withValues(alpha: 0.30)
                      : AppColors.black500.withValues(alpha: 0.30),
                ),
                child: Slider(
                  value: value,
                  onChanged: isContextActive
                      ? (v) async {
                          final ms = (totalMs * v).round();
                          await audioPlayer.pause();
                          await audioPlayer.seek(
                            Duration(milliseconds: ms),
                          );
                        }
                      : null,
                  onChangeEnd: isContextActive
                      ? (v) async {
                          final ms = (totalMs * v).round();
                          await audioPlayer.seek(
                            Duration(milliseconds: ms),
                          );
                          await audioPlayer.play();
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
                color: onBar,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainControls(
      BuildContext context, Color onBar, Color mutedOnBar, bool isDark) {
    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, _) {
        final hasPrevious = isContextActive && audioPlayer.hasPrevious;
        final hasNext = isContextActive && audioPlayer.hasNext;

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  final nextSpeed = speed == 2.0 ? 1.0 : speed + 0.5;
                  await onSpeedChanged(nextSpeed);
                },
                child: Text(
                  '${speed.toStringAsFixed(1)}x',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onBar,
                  ),
                ),
              ),
              IconButton(
                onPressed: hasPrevious ? audioPlayer.seekToPrevious : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                icon: SvgPicture.asset(
                  'assets/icons/previous.svg',
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : const Color(0xFF111827),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              _buildPlayPauseButton(context, onBar, isCollapsed: false),
              IconButton(
                onPressed: hasNext ? audioPlayer.seekToNext : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                icon: SvgPicture.asset(
                  'assets/icons/next.svg',
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : const Color(0xFF111827),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              _buildLoopButton(context, onBar, mutedOnBar, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, Color onBar,
      {required bool isCollapsed}) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snap) {
        final isActuallyPlaying = snap.data?.playing ?? false;
        final playing = isContextActive && isActuallyPlaying;

        return AnimatedBuilder(
          animation: audioCenter,
          builder: (context, _) {
            final isLoading = isContextActive && audioCenter.isLoading;

            if (isCollapsed) {
              return GestureDetector(
                onTap: isLoading ? null : () => onTogglePlayPause(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: onBar, width: 1.5),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: onBar,
                          ),
                        )
                      : Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                          color: onBar,
                        ),
                ),
              );
            }

            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0E0E0E)
                    : const Color(0xFF111827),
              ),
              child: IconButton(
                onPressed: isLoading ? null : () => onTogglePlayPause(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.expand(),
                icon: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        size: 28,
                        color: Colors.white,
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoopButton(
      BuildContext context, Color onBar, Color mutedOnBar, bool isDark) {
    return StreamBuilder<LoopMode>(
      stream: audioPlayer.loopModeStream,
      builder: (context, snap) {
        final loopMode = snap.data ?? LoopMode.off;
        final isLooping = loopMode != LoopMode.off;
        final isLoopingOne = loopMode == LoopMode.one;

        return Tooltip(
          message: loopMode == LoopMode.all
              ? 'Repeat Surah'
              : (loopMode == LoopMode.one ? 'Repeat Verse' : 'Repeat Off'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () async {
                  final LoopMode next;
                  if (loopMode == LoopMode.off) {
                    next = LoopMode.all;
                  } else if (loopMode == LoopMode.all) {
                    next = LoopMode.one;
                  } else {
                    next = LoopMode.off;
                  }
                  await audioPlayer.setLoopMode(next);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                icon: Icon(
                  Icons.repeat_rounded,
                  size: 24,
                  color: isLooping ? onBar : mutedOnBar,
                ),
              ),
              if (isLoopingOne)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: onBar,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF1D353B)
                              : const Color(0xFF78B7C6),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
