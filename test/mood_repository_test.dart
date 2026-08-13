import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:orb_mood_journal/domain/models/mood_entry.dart';

void main() {
  group('MoodEntry Domain Model Tests', () {
    test('creates MoodEntry with correct fields and methods', () {
      final now = DateTime(2026, 8, 13, 17, 30);
      final vectors = [
        {'x': 10, 'y': 20, 'pressure': 0.5},
        {'x': 15, 'y': 25, 'pressure': 0.8},
      ];

      final entry = MoodEntry(
        id: 'test-uuid-1234',
        timestamp: now,
        strokeData: jsonEncode(vectors),
        dominantColor: '#FF5733',
        moodBreakdown: {'calm': 0.8, 'joy': 0.6},
        photoPaths: ['/local/docs/photo1.jpg'],
        note: 'Feeling tranquil.',
        zodiacSign: 'Leo',
      );

      expect(entry.id, equals('test-uuid-1234'));
      expect(entry.year, equals(2026));
      expect(entry.month, equals(8));
      expect(entry.strokeVectors.length, equals(2));
      expect(entry.dominantColor, equals('#FF5733'));
      expect(entry.moodBreakdown['calm'], equals(0.8));
      expect(entry.photoPaths, contains('/local/docs/photo1.jpg'));
    });

    test('serializes to and from Map correctly', () {
      final now = DateTime(2026, 8, 13, 17, 30);
      final entry = MoodEntry(
        id: 'uuid-5678',
        timestamp: now,
        strokeData: '[{"x":1,"y":2}]',
        dominantColor: '#8B5CF6',
        moodBreakdown: {'focus': 0.9},
        photoPaths: [],
        note: 'Testing serialization.',
        zodiacSign: 'Virgo',
      );

      final map = entry.toMap();
      final restored = MoodEntry.fromMap(map);

      expect(restored.id, equals(entry.id));
      expect(restored.timestamp, equals(entry.timestamp));
      expect(restored.strokeData, equals(entry.strokeData));
      expect(restored.dominantColor, equals(entry.dominantColor));
      expect(restored.moodBreakdown['focus'], equals(0.9));
      expect(restored.zodiacSign, equals('Virgo'));
    });

    test('copyWith updates specified properties while preserving others', () {
      final entry = MoodEntry(
        id: 'uuid-orig',
        timestamp: DateTime(2026, 5, 10),
        strokeData: '[]',
        dominantColor: '#000000',
        moodBreakdown: {'peace': 1.0},
        photoPaths: ['path1'],
        note: 'Original note',
        zodiacSign: 'Taurus',
      );

      final updated = entry.copyWith(
        note: 'Updated note',
        dominantColor: '#FFFFFF',
      );

      expect(updated.id, equals('uuid-orig'));
      expect(updated.note, equals('Updated note'));
      expect(updated.dominantColor, equals('#FFFFFF'));
      expect(updated.zodiacSign, equals('Taurus'));
      expect(updated.photoPaths, equals(['path1']));
    });
  });
}
