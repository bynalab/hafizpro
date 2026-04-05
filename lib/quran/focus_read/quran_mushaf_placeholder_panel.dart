import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Placeholder until mushaf / slate layout is implemented.
class QuranMushafPlaceholderPanel extends StatelessWidget {
  const QuranMushafPlaceholderPanel({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: const Color(0xFFC9A961).withValues(alpha: 0.85),
            ),
            const SizedBox(height: 20),
            Text(
              'Mushaf view',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A page-by-page mushaf-style reading experience is coming soon. '
              'Use “Standard list” or “Verse focus” in reading settings for now.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
