import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/utils/date_utils.dart';
import '../domain/models/mood_entry.dart';

/// Monthly Insights screen displaying interactive calendar grid with mini mood orb badges,
/// logged days completion ratio, dominant monthly emotion, and emotion chip breakdown.
class MonthlyInsightsView extends StatelessWidget {
  final List<MoodEntry> entries;
  final int year;
  final int month;
  final ValueChanged<DateTime>? onDateSelected;

  const MonthlyInsightsView({
    super.key,
    required this.entries,
    required this.year,
    required this.month,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    // Group entries by day of month
    final Map<int, MoodEntry> entryByDay = {};
    final Set<int> uniqueLoggedDays = {};
    final Map<String, int> moodCounts = {};

    for (final entry in entries) {
      final day = entry.timestamp.day;
      entryByDay[day] = entry;
      uniqueLoggedDays.add(day);

      // Aggregate mood counts
      entry.moodBreakdown.forEach((mood, _) {
        final key = mood.toLowerCase();
        moodCounts[key] = (moodCounts[key] ?? 0) + 1;
      });
    }

    final loggedDaysCount = uniqueLoggedDays.length;
    final completionRatio = loggedDaysCount / daysInMonth;

    // Find dominant monthly mood
    String dominantMoodName = 'Serenity';
    int maxCount = -1;
    moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantMoodName = mood;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Monthly Calendar Grid Card
          Card(
            color: const Color(0xFF161726).withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppDateUtils.formatMonthYear(year, month),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$loggedDaysCount / $daysInMonth Days Logged',
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Weekday Header Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _WeekdayLabel('M'),
                      _WeekdayLabel('T'),
                      _WeekdayLabel('W'),
                      _WeekdayLabel('T'),
                      _WeekdayLabel('F'),
                      _WeekdayLabel('S'),
                      _WeekdayLabel('S'),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: (firstWeekday - 1) + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < firstWeekday - 1) {
                        return const SizedBox.shrink();
                      }

                      final dayNum = index - (firstWeekday - 2);
                      final entry = entryByDay[dayNum];
                      final hasEntry = entry != null;
                      final date = DateTime(year, month, dayNum);

                      return GestureDetector(
                        onTap: () {
                          if (onDateSelected != null) onDateSelected!(date);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: hasEntry
                                ? const Color(0xFF23253B)
                                : const Color(0xFF10111A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasEntry
                                  ? _parseHexColor(entry.dominantColor)
                                  : Colors.white10,
                              width: hasEntry ? 1.5 : 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '$dayNum',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasEntry
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: hasEntry
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (hasEntry)
                                Positioned(
                                  bottom: 4,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _parseHexColor(entry.dominantColor),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _parseHexColor(entry.dominantColor),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Monthly Logging Progress Card
          Card(
            color: const Color(0xFF161726).withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Consistency',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${(completionRatio * 100).toInt()}% Complete',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: completionRatio,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF10111A),
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Dominant Monthly Mood Card
          Card(
            color: const Color(0xFF1E1430).withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withOpacity(0.25),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF8B5CF6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dominant Emotion',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dominantMoodName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. Emotion Breakdown Chip Tags
          const Text(
            'Felt Emotions Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          moodCounts.isEmpty
              ? const Text(
                  'No mood data logged for this month yet.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: moodCounts.entries.map((entry) {
                    final moodName = toBeginningOfSentenceCase(entry.key);
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFF8B5CF6),
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      label: Text('$moodName (${entry.value} entries)'),
                      backgroundColor: const Color(0xFF161726),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white38,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
