import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../widgets/entry_detail_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(moodEntriesProvider);

    // Filter entries for selected month & year
    final monthEntries = entries.where((e) {
      return e.date.year == _selectedMonth.year &&
             e.date.month == _selectedMonth.month;
    }).toList();

    // Calculate aggregated mood statistics safely
    final Map<String, double> aggregatedMoods = {};
    double totalWeight = 0;

    for (var e in monthEntries) {
      final percentages = e.moodPercentages ?? {};
      percentages.forEach((name, val) {
        aggregatedMoods[name] = (aggregatedMoods[name] ?? 0) + val;
        totalWeight += val;
      });
    }

    // Calculate normalized percentages for the month report
    final Map<String, int> finalMoodPercentages = {};
    String dominantMood = "None";
    double maxVal = -1;

    if (totalWeight > 0) {
      aggregatedMoods.forEach((name, totalVal) {
        final percentage = ((totalVal / totalWeight) * 100).round();
        if (percentage > 0) {
          finalMoodPercentages[name] = percentage;
        }
        if (totalVal > maxVal) {
          maxVal = totalVal;
          dominantMood = name;
        }
      });
    }

    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Screen Title
              const Text(
                'Calendar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),

              // Month Selector Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                          );
                        });
                      },
                    ),
                    Text(
                      '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Days of Week Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((day) => SizedBox(
                          width: 38,
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Calendar Grid
              _buildMonthGrid(daysInMonth, monthEntries),
              const SizedBox(height: 28),

              // Month Report Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your moods this month',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mood percentage chips
                    if (finalMoodPercentages.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: finalMoodPercentages.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              '${e.key} ${e.value}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const Text(
                        'No logged entries for this month.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // Day count row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Day count',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '${monthEntries.length} / $daysInMonth',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Dominant mood row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dominant mood',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          dominantMood,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(int daysInMonth, List<MoodEntry> monthEntries) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final leadingEmptyDays = (firstDayOfMonth.weekday - 1) % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leadingEmptyDays + daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        if (index < leadingEmptyDays) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - leadingEmptyDays + 1;
        final dateForCell = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);

        // Find match for this day
        final MoodEntry? match = monthEntries.where((e) {
          return e.date.year == dateForCell.year &&
                 e.date.month == dateForCell.month &&
                 e.date.day == dateForCell.day;
        }).firstOrNull;

        return GestureDetector(
          onTap: match != null
              ? () {
                  EntryDetailSheet.show(
                    context,
                    match,
                    onDelete: () {
                      ref.read(moodNotifierProvider.notifier).deleteEntry(match.id);
                    },
                  );
                }
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: match != null
                      ? Color(match.primaryColorValue)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: match != null
                        ? Color(match.primaryColorValue).withOpacity(0.8)
                        : Colors.white12,
                  ),
                  boxShadow: match != null
                      ? [
                          BoxShadow(
                            color: Color(match.primaryColorValue).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$dayNumber',
                style: TextStyle(
                  color: match != null ? Colors.white : Colors.white38,
                  fontSize: 11,
                  fontWeight: match != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
