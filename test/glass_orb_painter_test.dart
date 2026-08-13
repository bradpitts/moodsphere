import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orb_mood_journal/widgets/glass_orb_painter_screen.dart';

void main() {
  group('GlassOrbPainterScreen & Stroke Model Tests', () {
    test('StrokePoint serializes to JSON correctly', () {
      const point = StrokePoint(120.5, 230.1);
      final json = point.toJson();
      final restored = StrokePoint.fromJson(json);

      expect(restored.x, equals(120.5));
      expect(restored.y, equals(230.1));
    });

    test('OrbStroke creates correct stroke structure', () {
      const mood = MoodItem(
        name: 'Joy',
        color: Color(0xFFFFD700),
        hex: '#FFD700',
        zodiac: 'Gemini (Mithuna)',
        isPositive: true,
      );

      final stroke = OrbStroke(
        points: [const StrokePoint(50, 50), const StrokePoint(60, 60)],
        color: mood.color,
        width: 12.0,
        brushType: BrushType.paintbrush,
        mood: mood,
      );

      expect(stroke.points.length, equals(2));
      expect(stroke.brushType, equals(BrushType.paintbrush));
      expect(stroke.mood.name, equals('Joy'));
      expect(stroke.mood.zodiac, equals('Gemini (Mithuna)'));
    });
  });
}
