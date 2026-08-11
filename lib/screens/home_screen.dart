import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../widgets/starlight_galaxy_view.dart';
import '../widgets/entry_detail_sheet.dart';
import '../widgets/orb_painter.dart';
import 'create_wizard_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Gradient? _getEntryGradient(MoodEntry? entry) {
    if (entry == null || entry.moodPercentages.isEmpty) return null;
    List<Color> colors = [];
    entry.moodPercentages.forEach((key, val) {
      if (val > 0) colors.add(OrbPainter.getMoodColor(key));
    });
    if (colors.isEmpty) return null;
    if (colors.length == 1) colors.add(colors.first);
    return SweepGradient(colors: colors);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(moodEntriesProvider);
    final now = DateTime.now();

    final MoodEntry? todayEntry = entries.where((e) {
      return e.date.year == now.year &&
             e.date.month == now.month &&
             e.date.day == now.day;
    }).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF05050B),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: StarlightGalaxyView(
                entries: entries,
                onEntryTap: (entry) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => EntryDetailSheet(
                      entry: entry,
                      onDelete: () {
                        ref.read(moodNotifierProvider.notifier).deleteEntry(entry.id);
                      },
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greetingText(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'MoodSphere · Galaxy Explorer',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.calendar_month, color: Colors.white70),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.person, color: Colors.white70),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white70),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildWeekRibbon(entries),
                  ),
                  if (todayEntry != null && todayEntry.moodPercentages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: todayEntry.moodPercentages.entries.map((e) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                '${e.key} ${e.value.toInt()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              right: 20,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateWizardScreen()),
                  );
                },
                icon: const Icon(Icons.palette, color: Colors.black),
                label: const Text(
                  '+ Paint New Mood Orb',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekRibbon(List<MoodEntry> entries) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final monday = now.subtract(Duration(days: currentWeekday - 1));

    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final dayDate = monday.add(Duration(days: index));
          final MoodEntry? dayEntry = entries.where((e) {
            return e.date.year == dayDate.year &&
                   e.date.month == dayDate.month &&
                   e.date.day == dayDate.day;
          }).firstOrNull;

          final isToday = dayDate.year == now.year &&
                          dayDate.month == now.month &&
                          dayDate.day == now.day;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekDays[index],
                style: TextStyle(
                  color: isToday ? const Color(0xFFFFD700) : Colors.white54,
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _getEntryGradient(dayEntry),
                  color: _getEntryGradient(dayEntry) == null
                      ? (dayEntry != null ? Color(dayEntry.primaryColorValue) : Colors.transparent)
                      : null,
                  border: Border.all(
                    color: isToday
                        ? const Color(0xFFFFD700)
                        : (dayEntry != null
                            ? Colors.white38
                            : Colors.white24),
                    width: isToday ? 2 : 1,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }
}