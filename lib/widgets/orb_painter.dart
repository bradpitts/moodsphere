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

    // 1. Outer Ambient Glow
    final outerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.45),
          primaryColor.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.45))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    canvas.drawCircle(center, radius * 1.45, outerGlowPaint);

    // 2. Base Sphere Fill
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.95,
        colors: [
          primaryColor.withOpacity(0.85),
          primaryColor.withOpacity(0.55),
          const Color(0xFF0F0F1A),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, basePaint);

    // 3. Organic Soft Color Bleeding & Gradient Blending Layer
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // Soft blur mask for smooth color bleeding
    final softBlendPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0)
      ..blendMode = BlendMode.srcOver;

    for (var point in strokePoints) {
      final pointRadius = point.size * 1.2;

      switch (point.tool) {
        case BrushTool.paintbrush:
          // Soft radial gradient stamp for organic bleeding
          softBlendPaint.shader = RadialGradient(
            colors: [
              point.color.withOpacity(0.85),
              point.color.withOpacity(0.4),
              point.color.withOpacity(0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: point.offset, radius: pointRadius));

          canvas.drawCircle(point.offset, pointRadius, softBlendPaint);
          break;

        case BrushTool.spray:
          softBlendPaint.shader = null;
          softBlendPaint.color = point.color.withOpacity(0.35);
          final random = math.Random(point.offset.dx.toInt());
          for (int i = 0; i < 10; i++) {
            final dx = (random.nextDouble() - 0.5) * point.size * 2.5;
            final dy = (random.nextDouble() - 0.5) * point.size * 2.5;
            canvas.drawCircle(point.offset + Offset(dx, dy), point.size / 3.5, softBlendPaint);
          }
          break;

        case BrushTool.marker:
          softBlendPaint.shader = RadialGradient(
            colors: [
              point.color.withOpacity(0.9),
              point.color.withOpacity(0.3),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: point.offset, radius: pointRadius * 1.1));

          canvas.drawRect(
            Rect.fromCenter(
                center: point.offset, width: point.size * 1.4, height: point.size * 0.7),
            softBlendPaint,
          );
          break;
      }
    }

    canvas.restore();

    // 4. Embedded Specular Glass Core Shine
    final highlightCenter = Offset(center.dx - radius * 0.32, center.dy - radius * 0.35);
    final glassShinePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.65),
          Colors.white.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: highlightCenter, radius: radius * 0.42));

    canvas.drawCircle(highlightCenter, radius * 0.4, glassShinePaint);

    // 5. Subtle Glass Rim Edge
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.55),
          primaryColor.withOpacity(0.2),
          Colors.white.withOpacity(0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
