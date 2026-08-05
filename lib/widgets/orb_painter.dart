import 'dart:ui';
import 'package:flutter/material.dart';

enum BrushTool { paintbrush, spray, marker }

class PaintStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final BrushTool tool;

  PaintStroke({
    required this.points,
    required this.color,
    this.strokeWidth = 36.0,
    this.tool = BrushTool.paintbrush,
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

    // 1. Glass Rim Outer Border
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, rimPaint);

    // 2. Clip all painting strictly inside glass sphere
    canvas.save();
    canvas.clipPath(circlePath);

    // Blank Glass Interior Base (Translucent)
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white.withOpacity(0.04),
    );

    // 3. Render Freehand Strokes on Offscreen Blending Layer
    canvas.saveLayer(circleRect, Paint()..blendMode = BlendMode.srcOver);

    final allStrokes = [...strokes];
    if (currentStroke != null) allStrokes.add(currentStroke!);

    for (var stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      double blurRadius = 18.0;
      double opacity = 0.85;

      switch (stroke.tool) {
        case BrushTool.spray:
          blurRadius = 32.0;
          opacity = 0.55;
          break;
        case BrushTool.marker:
          blurRadius = 6.0;
          opacity = 0.95;
          break;
        case BrushTool.paintbrush:
        default:
          blurRadius = 18.0;
          opacity = 0.85;
          break;
      }

      final strokePaint = Paint()
        ..color = stroke.color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.strokeWidth / 2,
          Paint()
            ..color = stroke.color.withOpacity(opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius),
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

    canvas.restore(); // Restore stroke layer

    // 4. Glass Specular 3D Shine
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
