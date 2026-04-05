import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/util/app_colors.dart';

/// Previous / next controls for jumping between adjacent Surahs or Juz in the reader.
///
/// Used by list, verse-focus, mushaf, and juz list layouts. Pass localized labels
/// from the parent (e.g. `AppLocalizations.of(context).quranReadPreviousSurah`).
class QuranAdjacentReaderNavBar extends StatelessWidget {
  const QuranAdjacentReaderNavBar({
    super.key,
    this.previousLabel,
    this.onPrevious,
    this.nextLabel,
    this.onNext,
  });

  final String? previousLabel;
  final VoidCallback? onPrevious;

  final String? nextLabel;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final prev = onPrevious;
    final next = onNext;
    if (prev == null && next == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF78B7C6) : const Color(0xFF1D353B);
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.black500.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: muted.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: prev != null && previousLabel != null
                      ? TextButton(
                          onPressed: prev,
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            previousLabel!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: next != null && nextLabel != null
                      ? TextButton(
                          onPressed: next,
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            nextLabel!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
