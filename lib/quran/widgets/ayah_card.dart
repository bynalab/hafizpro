import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/model/ayah.model.dart';
import 'package:hafiz_test/util/app_colors.dart';

class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final int index;
  final ValueNotifier<int?> playingIndexNotifier;
  final void Function(int)? onPlayPressed;
  final Color backgroundColor;
  final bool showTranslation;
  final bool showTransliteration;

  // We derive contrast from the actual card background color (not Theme.brightness)
  // because some screens may intentionally render light cards in dark mode (or vice
  // versa). Using luminance keeps text/icon/border colors readable regardless.
  bool _isDarkColor(Color c) {
    final luminance = c.computeLuminance();
    return luminance < 0.45;
  }

  static final RegExp _arabicIndicDigits =
      RegExp(r'[\u0660-\u0669\u06F0-\u06F9]');
  static final RegExp _quranMarkers = RegExp(
    r'[\u06DD\u06DE\u06E9\u06D7\u06D8\u06D9\u06DA\u06DB\u06DC\u06DF\u06E0\u06E1\u06E2\u06E3\u06E4\u06E5\u06E6\u06E7\u06E8\u06EA\u06EB\u06EC\u06ED\u0640]'
    r'|[﴿﴾]'
    r'|\(\d+\)'
    r'|\[\d+\]',
  );

  String _arabicDisplayText(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .replaceAll(_quranMarkers, '')
        .replaceAll(_arabicIndicDigits, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  const AyahCard({
    super.key,
    required this.ayah,
    required this.index,
    required this.playingIndexNotifier,
    this.backgroundColor = Colors.white,
    this.onPlayPressed,
    this.showTranslation = true,
    this.showTransliteration = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: playingIndexNotifier,
      builder: (context, currentPlayingIndex, _) {
        final isActive = currentPlayingIndex == index;

        final isDarkCard = _isDarkColor(backgroundColor);
        final textColor = isDarkCard ? Colors.white : AppColors.black500;
        final borderColor = isActive
            ? const Color(0xFF78B7C6)
            : (isDarkCard
                ? Colors.white.withValues(alpha: 0.16)
                : const Color(0xFFE5E7EB));
        final chipBorderColor = isDarkCard
            ? Colors.white.withValues(alpha: 0.75)
            : const Color(0xFF111827);

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: chipBorderColor),
                      ),
                      child: Text(
                        '${ayah.numberInSurah}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => onPlayPressed?.call(index),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: chipBorderColor),
                        ),
                        child: Center(
                          child: Icon(
                            isActive ? Icons.stop : Icons.play_arrow_rounded,
                            size: 20,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _arabicDisplayText(ayah.text),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      height: 2,
                      color: textColor,
                    ),
                  ),
                ),
                if (showTransliteration &&
                    (ayah.transliteration ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ayah.transliteration!.trim(),
                      textAlign: TextAlign.left,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (showTranslation &&
                    (ayah.translation ?? '').trim().isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ayah.translation!.trim(),
                      textAlign: TextAlign.left,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// class AyahCard extends StatefulWidget {
//   final Ayah ayah;
//   final int index;
//   final bool isPlaying;
//   final void Function(int)? onPlayPressed;

//   const AyahCard({
//     super.key,
//     required this.ayah,
//     required this.index,
//     this.isPlaying = false,
//     this.onPlayPressed,
//   });

//   @override
//   State<AyahCard> createState() => _AyahCardState();
// }

// class _AyahCardState extends State<AyahCard>
//     with SingleTickerProviderStateMixin {
//   final audioServices = AudioServices();

//   bool isPlayingInternal = false;
//   Duration currentPosition = Duration.zero;
//   Duration totalDuration = Duration.zero;
//   bool showTranslation = false;

//   @override
//   void initState() {
//     super.initState();

//     audioServices.audioPlayer.playerStateStream.listen((state) {
//       final playing =
//           state.playing && state.processingState != ProcessingState.completed;
//       if (mounted) setState(() => isPlayingInternal = playing);
//     });

//     audioServices.audioPlayer.durationStream.listen((duration) {
//       if (duration != null) {
//         setState(() => totalDuration = duration);
//       }
//     });

//     audioServices.audioPlayer.positionStream.listen((position) {
//       if (mounted) {
//         setState(() => currentPosition = position);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     audioServices.audioPlayer.stop();
//     super.dispose();
//   }

//   Future<void> handlePlayPause() async {
//     widget.onPlayPressed?.call(widget.index);
//     if (isPlayingInternal && widget.isPlaying) {
//       await audioServices.pause();
//     } else {
//       await audioServices.setAudioSource(widget.ayah.audioSource);
//       await audioServices.play();
//     }
//   }

//   String getDecoratedAyahNumber(int number) {
//     final arabicNumber = NumberFormat('#', 'ar_EG').format(number);
//     return String.fromCharCodes(Runes('\u{fd3f}$arabicNumber\u{fd3e}'));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isActive = isPlayingInternal && widget.isPlaying;
//     final progress = totalDuration.inMilliseconds == 0
//         ? 0.0
//         : currentPosition.inMilliseconds / totalDuration.inMilliseconds;

//     return Stack(
//       children: [
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 const Color(0xfffdf6e3),
//                 const Color(0xfffefae0),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: Colors.brown.shade200, width: 0.3),
//             boxShadow: isActive
//                 ? [
//                     BoxShadow(
//                       color: Colors.green.withOpacity(0.2),
//                       blurRadius: 12,
//                       spreadRadius: 1,
//                       offset: const Offset(0, 2),
//                     ),
//                   ]
//                 : [],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               // Arabic Text + Number
//               Text.rich(
//                 textDirection: TextDirection.rtl,
//                 textAlign: TextAlign.center,
//                 TextSpan(
//                   children: [
//                     TextSpan(
//                       text: widget.ayah.text,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontFamily: 'Quran',
//                         color: Color(0xFF2F2F2F),
//                         height: 1.6,
//                       ),
//                     ),
//                     TextSpan(
//                       text:
//                           "  ${getDecoratedAyahNumber(widget.ayah.numberInSurah)}",
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontFamily: 'Quran',
//                         fontWeight: FontWeight.bold,
//                         color: Colors.brown,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               // Translation Toggle
//               // if (showTranslation && widget.ayah.translation != null)
//               //   Padding(
//               //     padding: const EdgeInsets.only(top: 6.0),
//               //     child: Text(
//               //       widget.ayah.translation!,
//               //       textAlign: TextAlign.right,
//               //       style: const TextStyle(
//               //         fontSize: 15,
//               //         fontStyle: FontStyle.italic,
//               //         color: Colors.black87,
//               //       ),
//               //     ),
//               //   ),
//               const SizedBox(height: 10),
//               // Progress Bar
//               if (isActive)
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: LinearProgressIndicator(
//                     value: progress.clamp(0.0, 1.0),
//                     minHeight: 4,
//                     backgroundColor: Colors.brown.shade100,
//                     valueColor:
//                         AlwaysStoppedAnimation<Color>(Colors.green.shade700),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         // Play/Stop Floating Button
//         Positioned(
//           top: 8,
//           right: 18,
//           child: GestureDetector(
//             onTap: handlePlayPause,
//             child: Container(
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isActive ? Colors.green.shade600 : Colors.brown.shade300,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 4,
//                     offset: const Offset(2, 2),
//                   ),
//                 ],
//               ),
//               padding: const EdgeInsets.all(8),
//               child: Icon(
//                 isActive ? Icons.stop : Icons.play_arrow,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//           ),
//         ),
//         // Translation toggle button (bottom left)
//         Positioned(
//           bottom: 8,
//           left: 18,
//           child: GestureDetector(
//             onTap: () => setState(() => showTranslation = !showTranslation),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(20),
//                 color: Colors.brown.shade100.withOpacity(0.3),
//               ),
//               child: Text(
//                 showTranslation ? 'Hide Translation' : 'Show Translation',
//                 style: const TextStyle(fontSize: 12, color: Colors.brown),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
