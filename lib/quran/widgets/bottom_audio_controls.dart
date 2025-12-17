import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
  ///
  /// Example:
  /// - Surah view: audioCenter.isCurrentSurah(surahNumber)
  /// - Juz view: audioCenter.isCurrentJuz(juzNumber)
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

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        color: const Color(0xFF78B7C6),
        child: SafeArea(
          top: false,
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
                            color: AppColors.black500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 0,
                                ),
                                overlayShape: SliderComponentShape.noOverlay,
                                activeTrackColor: AppColors.green500,
                                inactiveTrackColor:
                                    AppColors.black500.withValues(alpha: 0.30),
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
                              color: AppColors.black500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<SequenceState?>(
                    stream: audioPlayer.sequenceStateStream,
                    builder: (context, _) {
                      final hasPrevious =
                          isContextActive && audioPlayer.hasPrevious;
                      final hasNext = isContextActive && audioPlayer.hasNext;

                      return StreamBuilder<PlayerState>(
                        stream: audioPlayer.playerStateStream,
                        builder: (context, snap) {
                          final isActuallyPlaying = snap.data?.playing ?? false;
                          final playing = isContextActive && isActuallyPlaying;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final nextSpeed =
                                      speed == 2.0 ? 1.0 : speed + 0.5;
                                  await onSpeedChanged(nextSpeed);
                                },
                                child: Text(
                                  '${speed.toStringAsFixed(1)}x',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black500,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: hasPrevious
                                    ? audioPlayer.seekToPrevious
                                    : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
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
                                child: AnimatedBuilder(
                                  animation: audioCenter,
                                  builder: (context, _) {
                                    final isLoading = isContextActive &&
                                        audioCenter.isLoading;

                                    return IconButton(
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              await onTogglePlayPause();
                                            },
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.expand(),
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
                                              playing
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size: 28,
                                              color: Colors.white,
                                            ),
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    hasNext ? audioPlayer.seekToNext : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
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
                              StreamBuilder<LoopMode>(
                                stream: audioPlayer.loopModeStream,
                                builder: (context, snap) {
                                  final loopMode = snap.data ?? LoopMode.off;

                                  return IconButton(
                                    onPressed: () async {
                                      final next = loopMode == LoopMode.one
                                          ? LoopMode.off
                                          : LoopMode.one;
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
                                      color: loopMode == LoopMode.one
                                          ? AppColors.black
                                          : AppColors.black600,
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
