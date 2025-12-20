import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/main_menu.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String completedKey = 'onboarding_completed';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _storage = getIt<IStorageService>();

  int _index = 0;

  final _pages = const <_OnboardingPageData>[
    _OnboardingPageData(
      imageAsset: 'assets/img/onboarding/1.png',
      title: 'Immerse yourself in the\nwords of Allah\\u',
      subtitle: 'Read, listen, and reflect on the\nQuran — anytime, anywhere.',
      cta: 'Start Reading',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/img/onboarding/2.png',
      title: 'Listen\\u to beautiful\nrecitations and follow\nalong',
      subtitle: 'Choose your favorite reciter and feel\nthe verses come alive.',
      cta: 'Start Listening',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/img/onboarding/3.png',
      title: 'Test your knowledge of the\nQur\u2019an',
      subtitle:
          'Guess the Surah or Ayah from what\nyou hear — by Juz, Surah, or\nrandomly.',
      cta: 'Start Playing',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await _storage.setString(OnboardingScreen.completedKey, 'true');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const MainMenu(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _nextOrFinish() {
    if (_index >= _pages.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : AppColors.gray500,
      body: Container(
        decoration: isDark
            ? const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.85, -0.85),
                  radius: 1.4,
                  colors: [
                    Color(0x33205B5F),
                    Color(0xFF0E0E0E),
                  ],
                ),
              )
            : null,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                _ProgressIndicator(current: _index, total: _pages.length),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final p = _pages[i];

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(p.imageAsset),
                          const SizedBox(height: 13),
                          _MarkedUnderlineText(
                            text: p.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF020617),
                            ),
                            underlineColor: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF58667B),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _nextOrFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green500,
                      foregroundColor:
                          isDark ? Colors.white : AppColors.gray500,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _pages[_index].cta,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  final String imageAsset;
  final String title;
  final String subtitle;
  final String cta;
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final bool active = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 4,
          width: 64,
          decoration: BoxDecoration(
            color: active
                ? AppColors.green500
                : (isDark ? const Color(0xFF2A2A2A) : AppColors.black100),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _MarkedUnderlineText extends StatelessWidget {
  const _MarkedUnderlineText({
    required this.text,
    required this.style,
    required this.underlineColor,
    required this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Color underlineColor;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final parsed = _parseMarkedText(text);

    final textScaler = MediaQuery.textScalerOf(context);

    return CustomPaint(
      foregroundPainter: _MarkedUnderlinePainter(
        text: parsed.text,
        ranges: parsed.ranges,
        style: style,
        underlineColor: underlineColor,
        textAlign: textAlign,
        textScaler: textScaler,
      ),
      child: Text(
        parsed.text,
        textAlign: textAlign,
        style: style,
      ),
    );
  }

  _ParsedMarkedText _parseMarkedText(String input) {
    final out = StringBuffer();
    final ranges = <TextRange>[];

    final segments = <String>[];
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == ' ' || ch == '\n') {
        if (buffer.isNotEmpty) {
          segments.add(buffer.toString());
          buffer.clear();
        }
        segments.add(ch);
      } else {
        buffer.write(ch);
      }
    }

    if (buffer.isNotEmpty) segments.add(buffer.toString());

    for (final seg in segments) {
      if (seg == ' ' || seg == '\n') {
        out.write(seg);
        continue;
      }

      final bool marked = seg.endsWith(r'\u');
      final String visible = marked ? seg.substring(0, seg.length - 2) : seg;
      final int start = out.length;
      out.write(visible);
      final int end = out.length;
      if (marked && end > start) {
        ranges.add(TextRange(start: start, end: end));
      }
    }

    return _ParsedMarkedText(text: out.toString(), ranges: ranges);
  }
}

class _ParsedMarkedText {
  const _ParsedMarkedText({required this.text, required this.ranges});

  final String text;
  final List<TextRange> ranges;
}

class _MarkedUnderlinePainter extends CustomPainter {
  const _MarkedUnderlinePainter({
    required this.text,
    required this.ranges,
    required this.style,
    required this.underlineColor,
    required this.textAlign,
    required this.textScaler,
  });

  final String text;
  final List<TextRange> ranges;
  final TextStyle style;
  final Color underlineColor;
  final TextAlign textAlign;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: size.width);

    final paint = Paint()
      ..color = underlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final range in ranges) {
      final boxes = tp.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );

      for (final b in boxes) {
        final left = b.left;
        final right = b.right;
        final y = b.bottom - 10;
        final w = right - left;
        if (w <= 0) continue;

        final start = Offset(left, y);
        final end = Offset(right, y);
        final control = Offset(left + (w * 0.5), y - 7);

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MarkedUnderlinePainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.ranges != ranges ||
        oldDelegate.style != style ||
        oldDelegate.underlineColor != underlineColor ||
        oldDelegate.textAlign != textAlign ||
        oldDelegate.textScaler != textScaler;
  }
}
