import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/main_menu.dart';
import 'package:hafiz_test/onboarding_screen.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late final IStorageService _storage;

  static const String _verseTitle = 'Al-Qamar (57): Verse 20';
  static const String _verseArabic =
      'وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ';
  static const String _verseTranslation =
      "And We have certainly made the Qur'an easy for remembrance, so is there anyone who will be mindful?";

  @override
  void initState() {
    super.initState();

    _storage = getIt<IStorageService>();

    // Track splash screen view
    AnalyticsService.trackScreenView('Splash Screen');

    _iconController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      final completedOnboarding =
          _storage.getString(OnboardingScreen.completedKey) == 'true';

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) {
            return completedOnboarding
                ? const MainMenu()
                : const OnboardingScreen();
          },
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Container(
          color: AppColors.green500,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double bottomSectionHeight =
                  min(260.0, constraints.maxHeight * 0.35);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: GridPainter(),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: StarPainter(),
                      ),
                    ),
                  ),
                  Center(
                    child: AnimatedBuilder(
                      animation: _iconController,
                      builder: (context, child) {
                        final double scale =
                            1 + (sin(_iconController.value * 2 * pi) * 0.015);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/logo.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Master The Quran, One ayah at a time',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.gray50,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: bottomSectionHeight,
                      width: double.infinity,
                      color: AppColors.green500,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _VerseCard(
                          title: _verseTitle,
                          arabic: _verseArabic,
                          translation: _verseTranslation,
                        ),
                      ),
                    ),
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

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.title,
    required this.arabic,
    required this.translation,
  });

  final String title;
  final String arabic;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.green100,
        border: Border.all(
          color: AppColors.black100,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3DE4E5E7),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.black500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              arabic,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 24,
                color: AppColors.black500,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              translation,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.black500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .5
      ..color = Colors.white.withValues(alpha: 0.08);

    const double step = 48;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  StarPainter() : _random = Random(7) {
    _stars = List.generate(70, (_) {
      return _Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        r: _random.nextDouble() * 1.3 + 0.2,
        a: _random.nextDouble() * 0.35 + 0.05,
      );
    });
  }

  late final Random _random;
  late final List<_Star> _stars;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in _stars) {
      paint.color = Colors.white.withValues(alpha: s.a);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.r,
    required this.a,
  });

  final double x;
  final double y;
  final double r;
  final double a;
}
