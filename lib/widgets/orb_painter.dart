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

    // 1. Outer Ambient Glow (Using primary color accent if strokes exist)
    final outerGlowColor = strokePoints.isNotEmpty ? primaryColor : const Color(0xFF4A90E2);
    final outerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          outerGlowColor.withOpacity(0.35),
          outerGlowColor.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.45))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24.0);

    canvas.drawCircle(center, radius * 1.45, outerGlowPaint);

    // 2. Initial Blank/Translucent Charcoal Sphere Base Fill (#1A1A2A)
    final baseCharcoalPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.95,
        colors: [
          const Color(0xFF242436), // Soft translucent charcoal
          const Color(0xFF1A1A2A),
          const Color(0xFF0D0D18),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(sphereRect);

    canvas.drawCircle(center, radius, baseCharcoalPaint);

    // 3. True Offscreen Radial Color Blending with ui.ImageFilter.blur(24.0) & BlendMode.screen
    if (strokePoints.isNotEmpty) {
      canvas.save();
      final clipPath = Path()..addOval(sphereRect);
      canvas.clipPath(clipPath);

      // Offscreen layer with Gaussian Blur for organic color bleeding & smooth gradient transitions
      final layerPaint = Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0);

      canvas.saveLayer(sphereRect, layerPaint);

      final stampPaint = Paint()..blendMode = BlendMode.screen;

      for (var point in strokePoints) {
        final stampRadius = point.size * 1.4;

        switch (point.tool) {
          case BrushTool.paintbrush:
            // Soft radial gradient stamp allowing yellow + blue to dynamically blend into green transitions
            stampPaint.shader = RadialGradient(
              colors: [
                point.color.withOpacity(0.95),
                point.color.withOpacity(0.45),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(Rect.fromCircle(center: point.offset, radius: stampRadius));

            canvas.drawCircle(point.offset, stampRadius, stampPaint);
            break;

          case BrushTool.spray:
            stampPaint.shader = null;
            stampPaint.color = point.color.withOpacity(0.45);
            final random = math.Random(point.offset.dx.toInt());
            for (int i = 0; i < 12; i++) {
              final dx = (random.nextDouble() - 0.5) * point.size * 2.6;
              final dy = (random.nextDouble() - 0.5) * point.size * 2.6;
              canvas.drawCircle(
                  point.offset + Offset(dx, dy), point.size / 3.0, stampPaint);
            }
            break;

          case BrushTool.marker:
            stampPaint.shader = RadialGradient(
              colors: [
                point.color.withOpacity(0.95),
                point.color.withOpacity(0.35),
                Colors.transparent,
              ],
            ).createShader(
                Rect.fromCircle(center: point.offset, radius: stampRadius * 1.1));

            canvas.drawRect(
              Rect.fromCenter(
                  center: point.offset,
                  width: point.size * 1.5,
                  height: point.size * 0.75),
              stampPaint,
            );
            break;
        }
      }

      canvas.restore(); // Restore offscreen blur layer
      canvas.restore(); // Restore sphere clip path
    }

    // 4. Embedded Specular Glass Core Shine
    final highlightCenter = Offset(center.dx - radius * 0.32, center.dy - radius * 0.35);
    final glassShinePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: highlightCenter, radius: radius * 0.42));

    canvas.drawCircle(highlightCenter, radius * 0.4, glassShinePaint);

    // 5. Subtle Glass Rim Line (1px)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
      ).createShader(sphereRect);

    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
