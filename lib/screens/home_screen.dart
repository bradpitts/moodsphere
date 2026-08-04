import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/mood_entry.dart';
import '../models/general_entry.dart';
import '../providers/mood_provider.dart';
import '../providers/general_entry_provider.dart';
import '../widgets/galaxy_3d_view.dart';
import '../widgets/calendar_view_widget.dart';
import 'paint_orb_screen.dart';
import 'general_entry_screen.dart';
import 'settings_screen.dart';

enum ViewMode { galaxy3d, timelineList, calendar }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ViewMode _viewMode = ViewMode.galaxy3d;
  int _activeTabIndex = 0; // 0: Mood Orbs, 1: Freeform Journal

  void _showMoodDetailSheet(MoodEntry entry) {
    final color = Color(entry.colorValue);
    final formattedDate =
        DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(entry.date);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood Entry',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref
                          .read(moodNotifierProvider.notifier)
                          .deleteEntry(entry.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Mood entry deleted'),
                          backgroundColor: Colors.grey.shade900,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (entry.note != null && entry.note!.isNotEmpty) ...[
                Text(
                  'REFLECTION',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Text(
                    entry.note!,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              if (entry.photoPath != null &&
                  File(entry.photoPath!).existsSync()) ...[
                Text(
                  'ATTACHED PHOTO',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(entry.photoPath!),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodEntries = ref.watch(moodNotifierProvider);
    final generalEntries = ref.watch(generalEntryNotifierProvider);
    final hasLoggedToday = ref.watch(hasLoggedTodayProvider);

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
              'MoodSphere',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _activeTabIndex == 0
                  ? '3D Galaxy & Mood History'
                  : 'Freeform Reflection Journal',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (_activeTabIndex == 0) ...[
            // View Mode Cycle Toggle (3D Galaxy -> List -> Calendar)
            IconButton(
              icon: Icon(
                _viewMode == ViewMode.galaxy3d
                    ? Icons.blur_circular
                    : _viewMode == ViewMode.timelineList
                        ? Icons.format_list_bulleted
                        : Icons.calendar_month_outlined,
                color: const Color(0xFFFFD700),
                size: 22,
              ),
              tooltip: 'Cycle View Mode',
              onPressed: () {
                setState(() {
                  if (_viewMode == ViewMode.galaxy3d) {
                    _viewMode = ViewMode.timelineList;
                  } else if (_viewMode == ViewMode.timelineList) {
                    _viewMode = ViewMode.calendar;
                  } else {
                    _viewMode = ViewMode.galaxy3d;
                  }
                });
              },
            ),
          ],

          // Settings Screen Button
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Switcher Bar (Mood Orbs vs General Journal)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 0
                              ? const Color(0xFFFFD700)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Mood Galaxy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: _activeTabIndex == 0
                                ? Colors.black
                                : Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 1
                              ? const Color(0xFFFFD700)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Journal Entries',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: _activeTabIndex == 1
                                ? Colors.black
                                : Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: _activeTabIndex == 0
                  ? _buildMoodTabContent(context, moodEntries)
                  : _buildGeneralJournalTabContent(context, generalEntries),
            ),
          ],
        ),
      ),
      floatingActionButton: _activeTabIndex == 0
          ? _buildFAB(context, hasLoggedToday)
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GeneralEntryScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.edit_note, color: Colors.black),
              label: Text(
                'New Journal',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
    );
  }

  Widget _buildMoodTabContent(BuildContext context, List<MoodEntry> entries) {
    if (entries.isEmpty) return _buildEmptyState(context);

    switch (_viewMode) {
      case ViewMode.galaxy3d:
        return Galaxy3DView(
          entries: entries,
          onBeadSelected: (entryId) {
            final match = entries.firstWhere(
              (e) => e.id == entryId,
              orElse: () => entries.first,
            );
            _showMoodDetailSheet(match);
          },
        );
      case ViewMode.calendar:
        return CalendarViewWidget(
          entries: entries,
          onDateSelected: (entry) => _showMoodDetailSheet(entry),
        );
      case ViewMode.timelineList:
        return _buildEntryList(context, entries);
    }
  }

  Widget _buildGeneralJournalTabContent(
      BuildContext context, List<GeneralEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.book_outlined,
                size: 54,
                color: Colors.white38,
              ),
              const SizedBox(height: 16),
              Text(
                'No Freeform Entries Yet',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Write personal notes, thoughts, and longform journal entries stored safely offline.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final formattedDate =
            DateFormat('EEEE, MMM d, yyyy • h:mm a').format(entry.date);

        return Dismissible(
          key: Key(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.redAccent.shade700,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
          ),
          onDismissed: (_) {
            ref
                .read(generalEntryNotifierProvider.notifier)
                .deleteEntry(entry.id);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                if (entry.photoPath != null &&
                    File(entry.photoPath!).existsSync()) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(entry.photoPath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.6),
                    const Color(0xFF121212),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.blur_circular,
                size: 54,
                color: Colors.white,
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'No Mood Orbs in Orbit',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to paint your first mood entry into the 3D Galaxy Sphere.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList(BuildContext context, List<MoodEntry> entries) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final color = Color(entry.colorValue);
        final formattedDate =
            DateFormat('EEEE, MMM d, yyyy • h:mm a').format(entry.date);

        return GestureDetector(
          onTap: () => _showMoodDetailSheet(entry),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (entry.note != null && entry.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          entry.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (entry.photoPath != null &&
                    File(entry.photoPath!).existsSync()) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(entry.photoPath!),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (index * 60).ms),
        );
      },
    );
  }

  Widget _buildFAB(BuildContext context, bool hasLoggedToday) {
    if (hasLoggedToday) {
      return Tooltip(
        message: 'You have already logged your mood today!',
        child: FloatingActionButton.extended(
          onPressed: null,
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white38,
          elevation: 0,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white38),
          label: Text(
            'Logged Today',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white38,
            ),
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PaintOrbScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFFFFD700),
      foregroundColor: Colors.black,
      elevation: 6,
      icon: const Icon(Icons.add, color: Colors.black),
      label: Text(
        'Paint Mood',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Colors.black,
        ),
      ),
    );
  }
}
