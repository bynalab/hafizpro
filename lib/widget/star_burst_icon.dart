import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StarburstIcon extends StatelessWidget {
  final String text;

  const StarburstIcon({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : const Color(0xFF111827);

    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _StarburstPainter(color: color),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  _StarburstPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width * 0.48;
    final inner = size.width * 0.36;

    final path = Path();
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? outer : inner;
      final a = (-90 + (360 / (points * 2)) * i) * (pi / 180);
      final p = Offset(center.dx + r * cos(a), center.dy + r * sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarburstPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
