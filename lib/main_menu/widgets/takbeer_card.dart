import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hafiz_test/main_menu/takbeer_screen.dart';
import 'package:hafiz_test/main_menu/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Card widget
// ─────────────────────────────────────────────────────────────────────────────

/// Compact Islamic dashboard card for the Takbeer.
///
/// • Tapping the **play/pause button** toggles audio.
/// • Tapping **anywhere else** opens [TakbeerScreen].
class TakbeerCard extends StatefulWidget {
  const TakbeerCard({super.key});

  @override
  State<TakbeerCard> createState() => _TakbeerCardState();
}

class _TakbeerCardState extends State<TakbeerCard>
    with SingleTickerProviderStateMixin {
  final _svc = TakbeerAudioService.instance;

  // Subtle pulse on the crescent badge while playing.
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onService);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _svc.removeListener(_onService);
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onService() {
    if (!mounted) return;
    setState(() {});
    if (_svc.isPlaying) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl
        ..stop()
        ..animateTo(0, duration: const Duration(milliseconds: 250));
    }
  }

  void _openScreen() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TakbeerScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardPalette.isDark(context);
    final isPlaying = _svc.isPlaying;
    final isLoading = _svc.isLoading;

    // Gold shades that work in both modes.
    final goldBorder = isDark
        ? const Color(0xFF6B4E00)
        : const Color(0xFFD4A017);
    final cardBg1 = isDark ? const Color(0xFF1A1200) : const Color(0xFFFFFAE8);
    final cardBg2 = isDark ? const Color(0xFF2A1E00) : const Color(0xFFFFF0C0);

    return GestureDetector(
      onTap: _openScreen,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardBg1, cardBg2],
          ),
          border: Border.all(color: goldBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC9A84C)
                  .withValues(alpha: isDark ? 0.15 : 0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              // Subtle Islamic geometric texture behind content.
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardGeomPainter(isDark: isDark),
                ),
              ),

              // Main content row.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    // ── Left: animated crescent badge ─────────────────────
                    _CrescentBadge(
                      isDark: isDark,
                      isPlaying: isPlaying,
                      pulseAnim: _pulseAnim,
                    ),
                    const SizedBox(width: 12),

                    // ── Centre: Arabic + subtitle ─────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'اللهُ أَكْبَرُ',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Quran',
                              fontSize: 19,
                              height: 1.35,
                              color: isDark
                                  ? const Color(0xFFFFD766)
                                  : const Color(0xFF8B6000),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                'Takbeer',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (isPlaying)
                                const _WaveformDots()
                              else
                                Text(
                                  '· Tap to open',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ── Right: gold play button (absorbs taps) ────────────
                    GestureDetector(
                      onTap: _svc.toggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFE8C97A), Color(0xFFC9A84C)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC9A84C).withValues(
                                  alpha: isPlaying ? 0.55 : 0.20),
                              blurRadius: isPlaying ? 14 : 6,
                              spreadRadius: isPlaying ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0B0F1A)),
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 17,
                                  color: const Color(0xFF0B0F1A),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFFB8860B),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Animated crescent + star badge that pulses gently when audio is playing.
class _CrescentBadge extends StatelessWidget {
  final bool isDark;
  final bool isPlaying;
  final Animation<double> pulseAnim;

  const _CrescentBadge({
    required this.isDark,
    required this.isPlaying,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: isPlaying ? pulseAnim.value : 1.0,
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF2D2000) : const Color(0xFFFFF8E0),
          border: Border.all(
            color: const Color(0xFFC9A84C)
                .withValues(alpha: isPlaying ? 0.9 : 0.45),
            width: 1.3,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: CustomPaint(painter: _CrescentPainter(isDark: isDark)),
      ),
    );
  }
}

/// Three animated vertical bars — classic "now playing" waveform.
class _WaveformDots extends StatefulWidget {
  const _WaveformDots();

  @override
  State<_WaveformDots> createState() => _WaveformDotsState();
}

class _WaveformDotsState extends State<_WaveformDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            // Each bar is phase-shifted so they animate independently.
            final phase = (i / 3.0);
            final t = (_ctrl.value + phase) % 1.0;
            final h = 4.0 + 6.0 * math.sin(t * math.pi).abs();
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A84C),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters — zero assets, pure canvas
// ─────────────────────────────────────────────────────────────────────────────

/// Crescent moon + 4-pointed star, drawn entirely with Path operations.
class _CrescentPainter extends CustomPainter {
  final bool isDark;
  const _CrescentPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gold = isDark ? const Color(0xFFFFD766) : const Color(0xFFB8860B);
    final fill = Paint()..color = gold;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28;

    // Crescent: outer circle minus offset circle.
    final outer = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final cut = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(cx + r * 0.55, cy - r * 0.1),
        radius: r * 0.78,
      ));
    canvas.drawPath(
        Path.combine(PathOperation.difference, outer, cut), fill);

    // Small 4-pointed star beside the crescent.
    _draw4Star(canvas, fill, Offset(cx + r * 0.82, cy - r * 0.82), r * 0.2);
  }

  static void _draw4Star(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final radius = i.isEven ? r : r * 0.42;
      final x = c.dx + radius * math.cos(a);
      final y = c.dy + radius * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrescentPainter old) => old.isDark != isDark;
}

/// Very subtle repeating 8-pointed star texture painted inside the card.
class _CardGeomPainter extends CustomPainter {
  final bool isDark;
  const _CardGeomPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9A84C).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const tileSize = 36.0;
    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        _drawStar8(
          canvas,
          paint,
          Offset(col * tileSize, row * tileSize),
          tileSize * 0.3,
        );
      }
    }
  }

  static void _drawStar8(Canvas canvas, Paint paint, Offset c, double r) {
    const points = 8;
    final innerR = r * 0.42;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? r : innerR;
      final x = c.dx + radius * math.cos(a);
      final y = c.dy + radius * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CardGeomPainter old) => old.isDark != isDark;
}
