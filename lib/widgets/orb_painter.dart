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
    final sphereRect = Rect.fromCircle(center: center, radius: radius);

    // 1. Outer Ambient Glow
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

    // 2. Blank Canvas Start Inside Glass Circle (Subtle Glass Outline Ring Only)
    canvas.save();
    final clipPath = Path()..addOval(sphereRect);
    canvas.clipPath(clipPath);

    // 3. Soft Watercolor Bleeding via Offscreen saveLayer (BlendMode.srcOver)
    canvas.saveLayer(Rect.largest, Paint()..blendMode = BlendMode.srcOver);

    final stampPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36.0);

    if (strokePoints.isNotEmpty) {
      for (var point in strokePoints) {
        final stampRadius = point.size * 1.8;

        stampPaint.shader = RadialGradient(
          colors: [
            point.color.withOpacity(0.85),
            point.color.withOpacity(0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: point.offset, radius: stampRadius));

        canvas.drawCircle(point.offset, stampRadius, stampPaint);
      }
    } else {
      stampPaint.shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.85),
          primaryColor.withOpacity(0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(sphereRect);

      canvas.drawCircle(center, radius * 0.9, stampPaint);
    }

    canvas.restore(); // Restore saveLayer

    // 4. Embedded Specular Glass Core Shine
    final highlightCenter = Offset(center.dx - radius * 0.32, center.dy - radius * 0.35);
    final glassShinePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: highlightCenter, radius: radius * 0.42));

    canvas.drawCircle(highlightCenter, radius * 0.4, glassShinePaint);

    // 5. Glass Rim Line (1px)
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

    canvas.restore(); // Restore clipPath
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
