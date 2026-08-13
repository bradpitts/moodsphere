import '../../domain/models/mood_entry.dart';

class StreakCalculator {
  /// Calculate consecutive daily logging streak from a list of [MoodEntry] items.
  static int calculateStreak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;

    // Extract unique normalized dates (year, month, day)
    final Set<DateTime> loggedDates = entries.map((entry) {
      final dt = entry.timestamp;
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Determine starting date for streak calculation
    DateTime currentCheck;
    if (loggedDates.contains(today)) {
      currentCheck = today;
    } else if (loggedDates.contains(yesterday)) {
      currentCheck = yesterday;
    } else {
      return 0; // Streak broken if neither today nor yesterday is logged
    }

    int streakCount = 0;
    while (loggedDates.contains(currentCheck)) {
      streakCount++;
      currentCheck = currentCheck.subtract(const Duration(days: 1));
    }

    return streakCount;
  }
}
