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

    // 1. Outer Glass Rim
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, rimPaint);

    // 2. Clip all rendering inside glass sphere
    canvas.save();
    canvas.clipPath(circlePath);

    // Dark Translucent Glass Sphere Base
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF161622),
    );

    final allStrokes = [...strokes];
    if (currentStroke != null) allStrokes.add(currentStroke!);

    canvas.saveLayer(circleRect, Paint()..blendMode = BlendMode.srcOver);

    if (allStrokes.isNotEmpty) {
      // TIER 1: Live Freehand Touch Strokes
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
    } else {
      // TIER 2 & 3: Overlapping 3D Radial Clouds (Saved Entries / App Restart)
      final activeMoods = <MapEntry<Color, double>>[];

      if (moodPercentages != null && moodPercentages!.isNotEmpty) {
        moodPercentages!.forEach((key, val) {
          if (val > 0) {
            activeMoods.add(MapEntry(_getMoodColor(key), val));
          }
        });
      }

      if (activeMoods.isEmpty) {
        final fallbackVal = (primaryColorValue != null && primaryColorValue != 0)
            ? primaryColorValue!
            : 0xFFFFD700;
        activeMoods.add(MapEntry(Color(fallbackVal), 100.0));
      }

      // Render soft overlapping radial clouds (eliminates pie chart sharp lines)
      final offsets = [
        Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
        Offset(center.dx + radius * 0.3, center.dy + radius * 0.3),
        Offset(center.dx + radius * 0.2, center.dy - radius * 0.3),
        Offset(center.dx - radius * 0.3, center.dy + radius * 0.3),
      ];

      for (int i = 0; i < activeMoods.length; i++) {
        final color = activeMoods[i].key;
        final pos = offsets[i % offsets.length];

        final radialGradient = RadialGradient(
          colors: [
            color.withOpacity(0.95),
            color.withOpacity(0.5),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        canvas.drawCircle(
          pos,
          radius * 1.1,
          Paint()
            ..shader = radialGradient.createShader(Rect.fromCircle(center: pos, radius: radius * 1.1))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0),
        );
      }
    }

    canvas.restore(); // Restore stroke layer

    // 3. Glass Specular Highlight (3D Shine)
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
