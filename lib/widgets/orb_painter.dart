import 'dart:math' as math;
import 'package:flutter/material.dart';

enum BrushTool { paintbrush, spray, marker }

class StrokePoint {
  final Offset offset;
  final Color color;
  final double size;
  final BrushTool tool;
  final String moodName;

  StrokePoint({
    required this.offset,
    required this.color,
    required this.size,
    required this.tool,
    required this.moodName,
  });
}

class OrbPainter extends CustomPainter {
  final List<StrokePoint> strokePoints;
  final Color primaryColor;

  OrbPainter({
    required this.strokePoints,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.2;

    // 1. Ambient Outer Radial Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.4),
          primaryColor.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.45))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, radius * 1.45, glowPaint);

    // 2. Base Sphere Fill
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.95,
        colors: [
          primaryColor.withOpacity(0.9),
          primaryColor.withOpacity(0.6),
          const Color(0xFF0F0F1A),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, basePaint);

    // 3. Clip Path for Finger Painting Strokes inside Sphere Body
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // Draw user painted strokes
    for (var point in strokePoints) {
      final paint = Paint()
        ..color = point.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = point.size;

      switch (point.tool) {
        case BrushTool.paintbrush:
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(point.offset, point.size / 2, paint);
          break;
        case BrushTool.spray:
          paint.style = PaintingStyle.fill;
          paint.color = point.color.withOpacity(0.35);
          final random = math.Random(point.offset.dx.toInt());
          for (int i = 0; i < 8; i++) {
            final dx = (random.nextDouble() - 0.5) * point.size * 2.2;
            final dy = (random.nextDouble() - 0.5) * point.size * 2.2;
            canvas.drawCircle(point.offset + Offset(dx, dy), point.size / 4, paint);
          }
          break;
        case BrushTool.marker:
          paint.style = PaintingStyle.fill;
          paint.color = point.color.withOpacity(0.85);
          canvas.drawRect(
            Rect.fromCenter(
                center: point.offset, width: point.size * 1.2, height: point.size * 0.6),
            paint,
          );
          break;
      }
    }

    canvas.restore();

    // 4. Glass Specular Highlights
    final highlightCenter = Offset(center.dx - radius * 0.3, center.dy - radius * 0.35);
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: highlightCenter, radius: radius * 0.4));

    canvas.drawCircle(highlightCenter, radius * 0.38, highlightPaint);

    // 5. Outer Rim Border
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          primaryColor.withOpacity(0.2),
          Colors.white.withOpacity(0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
