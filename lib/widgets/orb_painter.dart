import 'package:flutter/material.dart';

class PaintPoint {
  final Offset point;
  final Color color;
  final double strokeWidth;

  PaintPoint(this.point, this.color, this.strokeWidth);
}

class OrbPainter extends CustomPainter {
  final List<PaintPoint> points;
  final Color baseColor;

  OrbPainter({required this.points, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer Ambient Glow
    final glowPaint = Paint()
      ..color = baseColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, radius + 8, glowPaint);

    // 2. Base Orb Circle
    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: [baseColor, baseColor.withOpacity(0.7), Colors.black87],
        stops: const [0.2, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, basePaint);

    // 3. Freehand Brush / Spray Strokes Painted Inside the Orb
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final strokePaint = Paint()
          ..color = points[i].color
          ..strokeWidth = points[i].strokeWidth
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;
        canvas.drawLine(points[i].point, points[i + 1].point, strokePaint);
      }
    }
    canvas.restore();

    // 4. Inner Specular Highlight (Glass Reflection)
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.4), Colors.transparent],
        stops: const [0.0, 0.7],
      ).createShader(Rect.fromCircle(center: Offset(center.dx - radius * 0.3, center.dy - radius * 0.3), radius: radius * 0.5));
    canvas.drawCircle(center, radius, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) {
    return oldDelegate.points.length != points.length || oldDelegate.baseColor != baseColor;
  }
}
