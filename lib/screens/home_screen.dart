import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../widgets/native_3d_sphere.dart';
import '../widgets/starlight_galaxy_view.dart';
import '../widgets/entry_detail_sheet.dart';
import '../widgets/orb_painter.dart';
import 'create_wizard_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

enum View3DMode { glassSphere, constellation }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  View3DMode _viewMode = View3DMode.glassSphere;

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(moodNotifierProvider);

    MoodEntry? todayEntry;
    final now = DateTime.now();
    for (var e in entries) {
      if (e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day) {
        todayEntry = e;
        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            Text(
              'MoodSphere · Galaxy Explorer',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),

            // Top 7-Day Week Ribbon (Mon–Sun)
            _buildWeekRibbon(context, entries),

            const SizedBox(height: 12),

            // Today's Mood Breakdown Header
            if (todayEntry != null && todayEntry.moodPercentages.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CustomPaint(
                          painter: OrbPainter(
                            strokes: [
                              PaintStroke(
                                points: const [Offset(16, 16)],
                                color: Color(todayEntry.primaryColorValue),
                                strokeWidth: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: todayEntry.moodPercentages.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: const Color(0xFF121212),
                                  label: Text(
                                    '${e.key} ${e.value.toInt()}%',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  side: BorderSide(
                                    color: Color(todayEntry!.primaryColorValue)
                                        .withOpacity(0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Dual 3D Visual Engine (Glass Sphere vs Starlight Constellation)
            Expanded(
              child: Stack(
                children: [
                  _viewMode == View3DMode.glassSphere
                      ? Native3DSphere(
                          entries: entries,
                          onBeadTap: (entry) => _showDetailSheet(entry),
                        )
                      : StarlightGalaxyView(
                          entries: entries,
                          onStarTap: (entry) => _showDetailSheet(entry),
                        ),

                  // Floating Toggle Switch: Glass Sphere <-> Constellation
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _viewMode = View3DMode.glassSphere),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _viewMode == View3DMode.glassSphere
                                    ? const Color(0xFFFFD700)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '3D Sphere',
                                style: GoogleFonts.inter(
                                  color: _viewMode == View3DMode.glassSphere
                                      ? Colors.black
                                      : Colors.white60,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                () => _viewMode = View3DMode.constellation),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _viewMode == View3DMode.constellation
                                    ? const Color(0xFF7C3AED)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Constellation',
                                style: GoogleFonts.inter(
                                  color: _viewMode == View3DMode.constellation
                                      ? Colors.white
                                      : Colors.white60,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildWeekRibbon(BuildContext context, List<MoodEntry> entries) {
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final dayDate = monday.add(Duration(days: index));
          final dayName = DateFormat('E').format(dayDate).substring(0, 3);

          MoodEntry? entryForDay;
          for (var e in entries) {
            if (e.date.year == dayDate.year &&
                e.date.month == dayDate.month &&
                e.date.day == dayDate.day) {
              entryForDay = e;
              break;
            }
          }

          final isLogged = entryForDay != null;

          return Column(
            children: [
              Text(
                dayName,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              isLogged
                  ? GestureDetector(
                      onTap: () => _showDetailSheet(entryForDay!),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(entryForDay.primaryColorValue),
                          boxShadow: [
                            BoxShadow(
                              color: Color(entryForDay.primaryColorValue)
                                  .withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                    ),
            ],
          );
        }),
      ),
    );
  }

  // Unlocked Floating Action Button for Testing (Always Enabled "+ Paint New Mood Orb")
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreateWizardScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFFFFD700),
      foregroundColor: Colors.black,
      elevation: 6,
      icon: const Icon(Icons.palette_outlined, color: Colors.black),
      label: Text(
        '+ Paint New Mood Orb',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Colors.black,
        ),
      ),
    );
  }
}
