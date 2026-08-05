import 'dart:ui';
import 'package:flutter/material.dart';

class PaintStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  PaintStroke({
    required this.points,
    required this.color,
    this.strokeWidth = 36.0,
  });
}

class OrbPainter extends CustomPainter {
  final List<PaintStroke> strokes;
  final PaintStroke? currentStroke;

  OrbPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final circlePath = Path()..addOval(circleRect);

    // 1. Glass Rim Border
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, rimPaint);

    // 2. Clip all paint strokes strictly inside the glass sphere
    canvas.save();
    canvas.clipPath(circlePath);

    // Glass Interior Base (100% Blank Translucent Fill)
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white.withOpacity(0.04),
    );

    // 3. Render Watercolor Brush Strokes on Offscreen Layer
    canvas.saveLayer(circleRect, Paint()..blendMode = BlendMode.srcOver);

    final allStrokes = [...strokes];
    if (currentStroke != null) allStrokes.add(currentStroke!);

    for (var stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      final strokePaint = Paint()
        ..color = stroke.color.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0);

      if (stroke.points.length == 1) {
        // Draw single dab point
        canvas.drawCircle(
          stroke.points.first,
          stroke.strokeWidth / 2,
          Paint()
            ..color = stroke.color.withOpacity(0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0),
        );
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, strokePaint);
      }
    }

    canvas.restore(); // Restore stroke blending layer

    // 4. Glass Specular Reflection Highlight (Top Left 3D Shine)
    final highlightPath = Path()
      ..addOval(Rect.fromLTWH(
        center.dx - radius * 0.5,
        center.dy - radius * 0.65,
        radius * 0.45,
        radius * 0.25,
      ));

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
    );

    canvas.restore(); // Restore clip
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
