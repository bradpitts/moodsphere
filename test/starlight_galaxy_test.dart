import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orb_mood_journal/domain/models/mood_entry.dart';
import 'package:orb_mood_journal/widgets/starlight_galaxy_view.dart';

void main() {
  group('StarlightGalaxyView Widget Tests', () {
    final sampleEntries = [
      MoodEntry(
        id: 'entry-1',
        timestamp: DateTime(2026, 8, 13),
        strokeData: '[]',
        dominantColor: '#FF1744',
        moodBreakdown: {'love': 0.9},
        photoPaths: [],
        note: 'Love star',
        zodiacSign: 'Libra (Tula)',
      ),
      MoodEntry(
        id: 'entry-2',
        timestamp: DateTime(2026, 8, 13),
        strokeData: '[]',
        dominantColor: '#00E5FF',
        moodBreakdown: {'serenity': 0.8},
        photoPaths: [],
        note: 'Serenity star',
        zodiacSign: 'Taurus (Vrishabha)',
      ),
    ];

    testWidgets('renders StarlightGalaxyView and CustomPaint canvas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarlightGalaxyView(
              entries: sampleEntries,
              child: const Text('Overlay Child'),
            ),
          ),
        ),
      );

      expect(find.text('Overlay Child'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('handles scale and drag gestures without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarlightGalaxyView(
              entries: sampleEntries,
            ),
          ),
        ),
      );

      final gestureFinder = find.byType(StarlightGalaxyView);
      expect(gestureFinder, findsOneWidget);

      // Simulate drag gesture for 3D rotation
      await tester.drag(gestureFinder, const Offset(100.0, 50.0));
      await tester.pump();
    });
  });
}
