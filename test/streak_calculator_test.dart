import 'package:flutter_test/flutter_test.dart';
import 'package:orb_mood_journal/core/utils/streak_calculator.dart';
import 'package:orb_mood_journal/domain/models/mood_entry.dart';

void main() {
  group('StreakCalculator Tests', () {
    test('returns 0 for empty entries list', () {
      final streak = StreakCalculator.calculateStreak([]);
      expect(streak, equals(0));
    });

    test('calculates 1-day streak if only today is logged', () {
      final now = DateTime.now();
      final entries = [
        MoodEntry(
          id: '1',
          timestamp: now,
          strokeData: '[]',
          dominantColor: '#FF1744',
          moodBreakdown: {'love': 1.0},
          photoPaths: [],
          note: 'Today entry',
          zodiacSign: 'Libra',
        ),
      ];

      final streak = StreakCalculator.calculateStreak(entries);
      expect(streak, equals(1));
    });

    test('calculates 3-day consecutive streak for today, yesterday, and day before', () {
      final now = DateTime.now();
      final entries = [
        MoodEntry(
          id: '1',
          timestamp: now,
          strokeData: '[]',
          dominantColor: '#FF1744',
          moodBreakdown: {'love': 1.0},
          photoPaths: [],
          note: 'Today',
          zodiacSign: 'Libra',
        ),
        MoodEntry(
          id: '2',
          timestamp: now.subtract(const Duration(days: 1)),
          strokeData: '[]',
          dominantColor: '#00E5FF',
          moodBreakdown: {'serenity': 1.0},
          photoPaths: [],
          note: 'Yesterday',
          zodiacSign: 'Taurus',
        ),
        MoodEntry(
          id: '3',
          timestamp: now.subtract(const Duration(days: 2)),
          strokeData: '[]',
          dominantColor: '#FFD700',
          moodBreakdown: {'joy': 1.0},
          photoPaths: [],
          note: 'Day before yesterday',
          zodiacSign: 'Gemini',
        ),
      ];

      final streak = StreakCalculator.calculateStreak(entries);
      expect(streak, equals(3));
    });

    test('returns 0 if last logged entry was 3 days ago', () {
      final now = DateTime.now();
      final entries = [
        MoodEntry(
          id: '1',
          timestamp: now.subtract(const Duration(days: 3)),
          strokeData: '[]',
          dominantColor: '#FF1744',
          moodBreakdown: {'love': 1.0},
          photoPaths: [],
          note: 'Old entry',
          zodiacSign: 'Libra',
        ),
      ];

      final streak = StreakCalculator.calculateStreak(entries);
      expect(streak, equals(0));
    });
  });
}
