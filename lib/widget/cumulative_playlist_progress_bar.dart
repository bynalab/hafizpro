// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';
// import 'package:rxdart/rxdart.dart';

// class CumulativePlaylistProgressBar extends StatefulWidget {
//   const CumulativePlaylistProgressBar({
//     super.key,
//     required this.audioPlayer,
//     this.minHeight = 4,
//     this.backgroundColor,
//     this.valueColor,
//   });

//   final AudioPlayer audioPlayer;
//   final double minHeight;
//   final Color? backgroundColor;
//   final Color? valueColor;

//   @override
//   State<CumulativePlaylistProgressBar> createState() =>
//       _CumulativePlaylistProgressBarState();
// }

// class _CumulativePlaylistProgressBarState
//     extends State<CumulativePlaylistProgressBar> {
//   StreamSubscription<int?>? _indexSub;
//   StreamSubscription<Duration?>? _durationSub;

//   final Map<int, Duration> _durationByIndex = {};

//   int _maxSeenIndex = 0;
//   int _trackCountHint = 0;

//   AudioPlayer get _audioPlayer => widget.audioPlayer;

//   @override
//   void initState() {
//     super.initState();

//     _indexSub = _audioPlayer.currentIndexStream.listen((index) {
//       if (index != null && index > _maxSeenIndex) {
//         setState(() {
//           _maxSeenIndex = index;
//         });
//       }
//       _maybeCacheCurrentDuration(index);
//     });
//     _durationSub = _audioPlayer.durationStream.listen((_) {
//       _maybeCacheCurrentDuration(_audioPlayer.currentIndex);
//     });

//     _maybeCacheCurrentDuration(_audioPlayer.currentIndex);
//   }

//   void _maybeCacheCurrentDuration(int? index) {
//     if (!mounted) return;
//     if (index == null) return;

//     final duration = _audioPlayer.duration;
//     if (duration == null) return;

//     final existing = _durationByIndex[index];
//     if (existing == duration) return;

//     setState(() {
//       _durationByIndex[index] = duration;
//     });
//   }

//   @override
//   void dispose() {
//     _indexSub?.cancel();
//     _durationSub?.cancel();
//     super.dispose();
//   }

//   Stream<Duration> overallPositionStream(AudioPlayer player) {
//     return Rx.combineLatest3<SequenceState?, Duration, Duration?, Duration>(
//       player.sequenceStateStream,
//       player.positionStream,
//       player.durationStream,
//       (state, position, _) {
//         if (state == null) return Duration.zero;

//         final index = state.currentIndex;
//         if (index == null) return Duration.zero;

//         final previousTracksDuration = state.sequence
//             .take(index)
//             .map((s) => s.tag as MediaItem?)
//             .whereType<MediaItem>()
//             .map((m) => m.duration ?? Duration.zero)
//             .fold(Duration.zero, (a, b) => a + b);

//         return previousTracksDuration + position;
//       },
//     );
//   }

//   Stream<Duration> overallDurationStream(AudioPlayer player) {
//     return player.sequenceStateStream.map((state) {
//       // if (state == null) return Duration.zero;

//       return state.sequence
//           .map((s) => s.tag as MediaItem?)
//           .whereType<MediaItem>()
//           .map((m) => m.duration ?? Duration.zero)
//           .fold(Duration.zero, (a, b) => a + b);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<Duration>(
//       stream: overallPositionStream(_audioPlayer),
//       builder: (context, posSnap) {
//         return StreamBuilder<Duration>(
//           stream: overallDurationStream(_audioPlayer),
//           builder: (context, durSnap) {
//             final pos = posSnap.data ?? Duration.zero;
//             final dur = durSnap.data ?? Duration.zero;

//             return LinearProgressIndicator(
//               value: pos.inMilliseconds.toDouble(),
//               minHeight: widget.minHeight,
//               backgroundColor: widget.backgroundColor,
//               valueColor: widget.valueColor == null
//                   ? null
//                   : AlwaysStoppedAnimation<Color>(widget.valueColor!),
//             );
//           },
//         );
//       },
//     );

//     return StreamBuilder<SequenceState?>(
//       stream: _audioPlayer.sequenceStateStream,
//       builder: (context, seqSnap) {
//         return StreamBuilder<Duration>(
//           stream: _audioPlayer.positionStream,
//           builder: (context, posSnap) {
//             final trackPosition = posSnap.data ?? _audioPlayer.position;
//             final effectiveSequence = seqSnap.data?.effectiveSequence;
//             final playlist = effectiveSequence ?? _audioPlayer.sequence;
//             // final playlistIndex =
//             //     seqSnap.data?.currentIndex ?? _audioPlayer.currentIndex ?? 0;

//             final effectiveCount = effectiveSequence?.length ?? 0;
//             if (effectiveCount > 0 && _trackCountHint != effectiveCount) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (!mounted) return;
//                 setState(() {
//                   _trackCountHint = effectiveCount;
//                 });
//               });
//             }

//             // final trackCount = (playlist.isNotEmpty)
//             //     ? playlist.length
//             //     : (_trackCountHint > 0 ? _trackCountHint : (_maxSeenIndex + 1));
//             // final currentTrackDuration = _audioPlayer.duration;

//             Duration playlistDuration = Duration.zero;
//             for (var i = 0; i < playlist.length; i++) {
//               playlistDuration += _durationByIndex[i] ??
//                   (playlist[i].duration ?? Duration.zero);
//             }

//             // Duration durationBeforeCurrentTrack = Duration.zero;
//             // for (var i = 0; i < playlistIndex && i < playlist.length; i++) {
//             //   durationBeforeCurrentTrack += _durationByIndex[i] ??
//             //       (playlist[i].duration ?? Duration.zero);
//             // }

//             // final playedDuration = durationBeforeCurrentTrack + trackPosition;
//             final totalMs = playlistDuration.inMilliseconds;

//             // double progress;

//             // if (totalMs == 0) {
//             //   // On first play, most track durations can be unknown. We still
//             //   // want a smoothly moving progress indicator, so approximate
//             //   // playlist progress by index + fractional progress through the
//             //   // current track.
//             //   if (trackCount <= 0) {
//             //     return LinearProgressIndicator(
//             //       value: 0.0,
//             //       minHeight: widget.minHeight,
//             //       backgroundColor: widget.backgroundColor,
//             //       valueColor: widget.valueColor == null
//             //           ? null
//             //           : AlwaysStoppedAnimation<Color>(widget.valueColor!),
//             //     );
//             //   }

//             //   // If we don't know the current track duration yet, approximate a
//             //   // fractional progress using an assumed window so the bar still
//             //   // moves during first playback.
//             //   const assumedTrackDurationMs = 10000;

//             //   final curDurMs = (currentTrackDuration == null ||
//             //           currentTrackDuration.inMilliseconds == 0)
//             //       ? assumedTrackDurationMs
//             //       : currentTrackDuration.inMilliseconds;

//             //   final frac =
//             //       (trackPosition.inMilliseconds / curDurMs).clamp(0.0, 1.0);

//             //   progress = ((playlistIndex.clamp(0, trackCount - 1)) + frac) /
//             //       trackCount;
//             // } else {
//             //   progress =
//             //       (playedDuration.inMilliseconds / totalMs).clamp(0.0, 1.0);
//             // }

//             final value = totalMs == 0
//                 ? 0.0
//                 : (trackPosition.inMilliseconds / totalMs).clamp(0.0, 1.0);

//             print('totalMs: $totalMs');
//             print('trackPosition: ${trackPosition.inMilliseconds}');

//             return LinearProgressIndicator(
//               value: value,
//               minHeight: widget.minHeight,
//               backgroundColor: widget.backgroundColor,
//               valueColor: widget.valueColor == null
//                   ? null
//                   : AlwaysStoppedAnimation<Color>(widget.valueColor!),
//             );
//           },
//         );
//       },
//     );
//   }
// }
