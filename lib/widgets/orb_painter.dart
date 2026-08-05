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
    this.strokeWidth = 32.0,
    this.tool = BrushTool.paintbrush,
  });
}

class OrbPainter extends CustomPainter {
  final List<PaintStroke> strokes;
  final PaintStroke? currentStroke;
  final Map<String, double>? moodPercentages;
  final int? primaryColorValue;

  OrbPainter({
    required this.strokes,
    this.currentStroke,
    this.moodPercentages,
    this.primaryColorValue,
  });

  static Color _getMoodColor(String key) {
    final normalized = key.trim().toLowerCase();
    switch (normalized) {
      case 'joy': return const Color(0xFFFFD700);
      case 'serenity': return const Color(0xFF4EECD5);
      case 'love': return const Color(0xFFFF5252);
      case 'longing': return const Color(0xFF448AFF);
      case 'sadness': return const Color(0xFF29B6F6);
      case 'anger': return const Color(0xFFFF3D00);
      case 'disgust': return const Color(0xFF66BB6A);
      case 'fear': return const Color(0xFFAB47BC);
      default: return const Color(0xFFFFD700);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final circlePath = Path()..addOval(circleRect);

    // 1. Glass Outer Rim
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, rimPaint);

    // 2. Clip all rendering strictly inside glass sphere
    canvas.save();
    canvas.clipPath(circlePath);

    // Dark Translucent Glass Base
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF161622),
    );

    final allStrokes = [...strokes];
    if (currentStroke != null) allStrokes.add(currentStroke!);

    canvas.saveLayer(circleRect, Paint()..blendMode = BlendMode.srcOver);

    if (allStrokes.isNotEmpty) {
      // TIER 1: Live Freehand Touch Painting
      for (var stroke in allStrokes) {
        if (stroke.points.isEmpty) continue;

        double blur = 16.0;
        switch (stroke.tool) {
          case BrushTool.spray: blur = 28.0; break;
          case BrushTool.marker: blur = 4.0; break;
          case BrushTool.paintbrush: default: blur = 16.0; break;
        }

        final strokePaint = Paint()
          ..color = stroke.color.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

        if (stroke.points.length == 1) {
          canvas.drawCircle(
            stroke.points.first,
            stroke.strokeWidth / 2,
            Paint()
              ..color = stroke.color.withOpacity(0.85)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
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
    } else if (moodPercentages != null && moodPercentages!.isNotEmpty) {
      // TIER 2: Saved Entry Multi-Color Radial Blended Gradient
      List<Color> colors = [];
      moodPercentages!.forEach((key, val) {
        if (val > 0) {
          colors.add(_getMoodColor(key));
        }
      });

      if (colors.isEmpty) {
        final fallback = primaryColorValue != null ? Color(primaryColorValue!) : const Color(0xFFFFD700);
        colors = [fallback, fallback];
      } else if (colors.length == 1) {
        colors.add(colors.first);
      }

      final sweepGradient = SweepGradient(
        colors: colors,
        center: Alignment.center,
      );

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = sweepGradient.createShader(circleRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0),
      );
    } else {
      // TIER 3: Safety Fallback using Primary Color
      final fallbackColor = primaryColorValue != null 
          ? Color(primaryColorValue!) 
          : const Color(0xFFFFD700);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = fallbackColor.withOpacity(0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0),
      );
    }

    canvas.restore(); // Restore stroke layer

    // 3. Glass Specular 3D Reflection Highlight
    final highlightPath = Path()
      ..addOval(Rect.fromLTWH(
        center.dx - radius * 0.45,
        center.dy - radius * 0.6,
        radius * 0.4,
        radius * 0.22,
      ));

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

    canvas.restore(); // Restore clip
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
