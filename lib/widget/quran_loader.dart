import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuranLoader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double iconSize;

  const QuranLoader({
    super.key,
    this.title = 'Loading...',
    this.subtitle = 'جارٍ التحميل',
    this.iconSize = 140,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = scheme.onSurface;
    final spinnerColor = scheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isDark ? 0.12 : 0.22,
              child: Image.asset(
                'assets/img/faded_vector_quran.png',
                width: iconSize,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 3.2,
                valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class QuranLoaderOverlay extends StatelessWidget {
  final bool visible;
  final Widget child;
  final String title;
  final String subtitle;

  const QuranLoaderOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.title = 'Loading...',
    this.subtitle = 'جارٍ التحميل',
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
            child: QuranLoader(
              title: title,
              subtitle: subtitle,
            ),
          ),
        ),
      ],
    );
  }
}
