import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/models/mood_entry.dart';

/// 7-Day horizontal quick-status top ribbon widget displaying Monday - Sunday
/// of the current week with dominant mood color badges.
class HomeTopRibbon extends StatelessWidget {
  final List<MoodEntry> entries;
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateSelected;

  const HomeTopRibbon({
    super.key,
    required this.entries,
    required this.selectedDate,
    this.onDateSelected,
  });

  List<DateTime> _getCurrentWeekDates() {
    final now = DateTime.now();
    // Find Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  MoodEntry? _findEntryForDate(DateTime date, List<MoodEntry> allEntries) {
    final target = DateTime(date.year, date.month, date.day);
    for (final entry in allEntries) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      if (entryDate == target) return entry;
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    final weekDates = _getCurrentWeekDates();
    final today = DateTime.now();

    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131422).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDates.map((date) {
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final entry = _findEntryForDate(date, entries);
          final hasEntry = entry != null;
          final moodColor = hasEntry
              ? _parseHexColor(entry.dominantColor)
              : Colors.transparent;

          final dayName = DateFormat('E').format(date).toUpperCase(); // e.g. MON
          final dayNum = DateFormat('d').format(date); // e.g. 13

          return GestureDetector(
            onTap: () {
              if (onDateSelected != null) onDateSelected!(date);
            },
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF8B5CF6).withOpacity(0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFF8B5CF6)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dominant Mood Badge Dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasEntry ? moodColor : Colors.white24,
                      boxShadow: hasEntry
                          ? [
                              BoxShadow(
                                color: moodColor.withOpacity(0.8),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
