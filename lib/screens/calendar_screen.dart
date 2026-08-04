import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../widgets/entry_detail_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  MoodEntry? _getEntryForDay(List<MoodEntry> entries, DateTime day) {
    for (var e in entries) {
      if (isSameDay(e.date, day)) return e;
    }
    return null;
  }

  void _showDetailSheet(MoodEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EntryDetailSheet(
        entry: entry,
        onDelete: () {
          ref.read(moodNotifierProvider.notifier).deleteEntry(entry.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(moodNotifierProvider);
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);

    final monthEntries = entries.where((e) {
      return e.date.year == _focusedDay.year &&
          e.date.month == _focusedDay.month;
    }).toList();

    // Calculate dominant mood & overall mood percentage breakdown for month
    final moodCountMap = <String, double>{};
    for (var e in monthEntries) {
      e.moodPercentages.forEach((name, val) {
        moodCountMap[name] = (moodCountMap[name] ?? 0) + val;
      });
    }

    String dominantMood = 'None';
    if (moodCountMap.isNotEmpty) {
      dominantMood = moodCountMap.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Calendar & Month Report',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              // Monthly Calendar Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    final match = _getEntryForDay(entries, selectedDay);
                    if (match != null) _showDetailSheet(match);
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white70),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white70),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.inter(color: Colors.white),
                    weekendTextStyle: GoogleFonts.inter(color: Colors.white70),
                    outsideTextStyle: GoogleFonts.inter(color: Colors.white24),
                  ),
                  calendarBuilders: CalendarBuilders(
                    prioritizedBuilder: (context, day, focusedDay) {
                      final match = _getEntryForDay(entries, day);
                      if (match != null) {
                        final color = Color(match.primaryColorValue);
                        return Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Month Report Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTH REPORT (${DateFormat('MMMM yyyy').format(_focusedDay)})',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Logged Days',
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${monthEntries.length} / $daysInMonth Days',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Dominant Mood',
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dominantMood,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFFD700),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (moodCountMap.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 10),

                      Text(
                        'Mood Distribution',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: moodCountMap.entries.map((e) {
                          return Chip(
                            label: Text('${e.key} ${e.value.toInt()} pts'),
                            backgroundColor: const Color(0xFF121212),
                            labelStyle: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.1)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
