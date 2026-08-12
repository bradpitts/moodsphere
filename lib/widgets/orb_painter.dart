import 'dart:convert';
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

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'color': color.value,
    'strokeWidth': strokeWidth,
    'tool': tool.index,
  };

  factory PaintStroke.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List? ?? [])
        .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
        .toList();
    return PaintStroke(
      points: pointsList,
      color: Color(json['color'] as int? ?? 0xFFFFD700),
      strokeWidth: (json['strokeWidth'] as num? ?? 32.0).toDouble(),
      tool: BrushTool.values[(json['tool'] as int? ?? 0).clamp(0, 2)],
    );
  }
}

class OrbPainter extends CustomPainter {
  final List<PaintStroke> strokes;
  final PaintStroke? currentStroke;
  final Map<String, double>? moodPercentages;
  final int? primaryColorValue;
  final String? serializedStrokeData;
  final bool isInteractiveWizard; 

  OrbPainter({
    required this.strokes,
    this.currentStroke,
    this.moodPercentages,
    this.primaryColorValue,
    this.serializedStrokeData,
    this.isInteractiveWizard = false,
  });

  static List<PaintStroke> decodeStrokeData(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => PaintStroke.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  static Color _getMoodColor(String key) {
    final normalized = key.trim().toLowerCase();
    switch (normalized) {
      case 'joy': return const Color(0xFFFFD700);
      case 'serenity': return const Color(0xFF4EECD5);
      case 'love': return const Color(0xFFFF5252);
      case 'longing': return const Color(0xFF448AFF);
      case 'confidence': return const Color(0xFFAB47BC);
      case 'hope': return const Color(0xFF7ED321);
      case 'gratitude': return const Color(0xFFFF80AB);
      case 'inspiration': return const Color(0xFFB39DDB);
      case 'empathy': return const Color(0xFF81D4FA);
      case 'balance': return const Color(0xFFAED581);
      case 'sadness': return const Color(0xFF29B6F6);
      case 'anger': return const Color(0xFFFF3D00);
      case 'disgust': return const Color(0xFF66BB6A);
      case 'fear': return const Color(0xFF7E57C2);
      case 'anxiety': return const Color(0xFFFF7043);
      case 'guilt': return const Color(0xFF78909C);
      case 'frustration': return const Color(0xFFEC407A);
      case 'overwhelmed': return const Color(0xFF5C6BC0);
      case 'apathy': return const Color(0xFFBDBDBD);
      case 'neutral': return const Color(0xFFE5E5EA);
      default: return const Color(0xFFFFD700);
    }
  }

  static String getRashiForMood(String dominantMood) {
    final normalized = dominantMood.trim().toLowerCase();
    switch (normalized) {
      case 'anger': case 'frustration': return 'Mesha (Aries)';
      case 'serenity': case 'balance': return 'Vrishabha (Taurus)';
      case 'joy': return 'Mithuna (Gemini)';
      case 'sadness': case 'empathy': return 'Karka (Cancer)';
      case 'confidence': case 'hope': return 'Simha (Leo)';
      case 'neutral': case 'apathy': return 'Kanya (Virgo)';
      case 'love': return 'Tula (Libra)';
      case 'fear': case 'disgust': case 'overwhelmed': return 'Vrishchika (Scorpio)';
      case 'inspiration': case 'longing': return 'Dhanu (Sagittarius)';
      case 'guilt': return 'Makara (Capricorn)';
      case 'anxiety': return 'Kumbha (Aquarius)';
      case 'gratitude': case 'peace': return 'Meena (Pisces)';
      default: return 'Unknown';
    }
  }

  static Color getMoodColor(String key) => _getMoodColor(key);
  static int getMoodColorValue(String key) => _getMoodColor(key).value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final circlePath = Path()..addOval(circleRect);

    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, rimPaint);
    canvas.save();
    canvas.clipPath(circlePath);

    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF161622));

    List<PaintStroke> renderStrokes = [...strokes];
    if (renderStrokes.isEmpty && serializedStrokeData != null && !isInteractiveWizard) {
      renderStrokes = decodeStrokeData(serializedStrokeData);
    }
    if (currentStroke != null) renderStrokes.add(currentStroke!);

    if (!isInteractiveWizard && moodPercentages != null && moodPercentages!.isNotEmpty) {
      List<Color> colors = [];
      moodPercentages!.forEach((key, val) {
        if (val > 0) colors.add(_getMoodColor(key));
      });

      if (colors.isEmpty) {
        final fallback = primaryColorValue != null ? Color(primaryColorValue!) : const Color(0xFFFFD700);
        colors = [fallback, fallback];
      } else if (colors.length == 1) colors.add(colors.first);

      final sweepGradient = SweepGradient(colors: colors, center: Alignment.center);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = sweepGradient.createShader(circleRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0),
      );
    } else if (!isInteractiveWizard && renderStrokes.isEmpty) {
      final fallbackColor = primaryColorValue != null ? Color(primaryColorValue!) : const Color(0xFFFFD700);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = fallbackColor.withOpacity(0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0),
      );
    }

    canvas.saveLayer(circleRect, Paint()..blendMode = BlendMode.srcOver);
    if (renderStrokes.isNotEmpty) {
      for (var stroke in renderStrokes) {
        if (stroke.points.isEmpty) continue;
        double blur = stroke.tool == BrushTool.spray ? 28.0 : (stroke.tool == BrushTool.marker ? 4.0 : 16.0);
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
            Paint()..color = stroke.color.withOpacity(0.85)..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
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
    }
    canvas.restore(); 

    final highlightPath = Path()
      ..addOval(Rect.fromLTWH(center.dx - radius * 0.45, center.dy - radius * 0.6, radius * 0.4, radius * 0.22));
    canvas.drawPath(
      highlightPath,
      Paint()..color = Colors.white.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}
