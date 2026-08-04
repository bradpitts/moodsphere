import 'dart:math' as math;
import 'dart:ui' as ui;
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
    final sphereRect = Rect.fromCircle(center: center, radius: radius);

    // 1. Ambient Outer Radial Glow
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
      ).createShader(sphereRect);

    canvas.drawCircle(center, radius, basePaint);

    // 3. True Offscreen Canvas Color Blending with ui.ImageFilter.blur
    canvas.save();
    final clipPath = Path()..addOval(sphereRect);
    canvas.clipPath(clipPath);

    // Offscreen layer with Gaussian Blur for organic color bleeding & smooth gradient transitions
    final layerPaint = Paint()
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0);

    canvas.saveLayer(sphereRect, layerPaint);

    final stampPaint = Paint()..blendMode = BlendMode.srcOver;

    for (var point in strokePoints) {
      final stampRadius = point.size * 1.35;

      switch (point.tool) {
        case BrushTool.paintbrush:
          // Soft radial gradient stamp allowing adjacent colors to bleed naturally (yellow + blue -> green)
          stampPaint.shader = RadialGradient(
            colors: [
              point.color.withOpacity(0.9),
              point.color.withOpacity(0.45),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: point.offset, radius: stampRadius));

          canvas.drawCircle(point.offset, stampRadius, stampPaint);
          break;

        case BrushTool.spray:
          stampPaint.shader = null;
          stampPaint.color = point.color.withOpacity(0.4);
          final random = math.Random(point.offset.dx.toInt());
          for (int i = 0; i < 10; i++) {
            final dx = (random.nextDouble() - 0.5) * point.size * 2.5;
            final dy = (random.nextDouble() - 0.5) * point.size * 2.5;
            canvas.drawCircle(point.offset + Offset(dx, dy), point.size / 3.2, stampPaint);
          }
          break;

        case BrushTool.marker:
          stampPaint.shader = RadialGradient(
            colors: [
              point.color.withOpacity(0.95),
              point.color.withOpacity(0.35),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: point.offset, radius: stampRadius * 1.1));

          canvas.drawRect(
            Rect.fromCenter(
                center: point.offset, width: point.size * 1.4, height: point.size * 0.7),
            stampPaint,
          );
          break;
      }
    }

    canvas.restore(); // Restore offscreen blur layer
    canvas.restore(); // Restore sphere clip path

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

    // 5. Glass Rim Edge
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
      ).createShader(sphereRect);

    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
