import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app mark: an open book with an orange sun rising over it, on a
/// blue tile. Source artwork lives in `assets/icon/logo.svg`.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.27);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D2446C7),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4466EA), Color(0xFF1A2D85)],
            ),
          ),
          child: CustomPaint(painter: const BrandGlyphPainter()),
        ),
      ),
    );
  }
}

/// Paints the "book + rising sun" glyph, scaled to fit its canvas.
class BrandGlyphPainter extends CustomPainter {
  final Color page;
  final Color sun;
  final double scale;

  const BrandGlyphPainter({
    this.page = Colors.white,
    this.sun = const Color(0xFFF26A1E),
    this.scale = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Artwork is drawn in a 1024 box, matching logo.svg.
    final k = size.shortestSide / 1024 * scale;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(k)
      ..translate(-512, -512 + 18);
    canvas.drawCircle(const Offset(512, 290), 72, Paint()..color = sun);
    final left = Path()
      ..moveTo(480, 452)
      ..cubicTo(418, 410, 336, 400, 262, 416)
      ..lineTo(262, 712)
      ..cubicTo(336, 700, 418, 708, 480, 750)
      ..close();
    final right = Path()
      ..moveTo(544, 452)
      ..cubicTo(606, 410, 688, 400, 762, 416)
      ..lineTo(762, 712)
      ..cubicTo(688, 700, 606, 708, 544, 750)
      ..close();
    final paint = Paint()
      ..color = page
      ..style = PaintingStyle.fill;
    final edge = Paint()
      ..color = page
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeJoin = StrokeJoin.round;
    for (final p in [left, right]) {
      canvas
        ..drawPath(p, paint)
        ..drawPath(p, edge);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandGlyphPainter old) =>
      old.page != page || old.sun != sun || old.scale != scale;
}

/// Brand mark + wordmark, light variant for use on the emerald hero.
class BrandLockup extends StatelessWidget {
  final bool light;

  const BrandLockup({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(),
        const SizedBox(width: 11),
        Text(
          'Exam Assistant',
          style: TextStyle(
            color: light ? Colors.white : AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
