import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import 'paint_orb_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodEntries = ref.watch(moodNotifierProvider);
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
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Your Emotional Journey',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: moodEntries.isEmpty
            ? _buildEmptyState(context)
            : _buildEntryList(context, ref, moodEntries),
      ),
      floatingActionButton: _buildFAB(context, hasLoggedToday),
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
                Icons.palette_outlined,
                size: 48,
                color: Colors.white,
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'No Mood Orbs Yet',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to paint your first mood entry for today.',
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

  Widget _buildEntryList(
      BuildContext context, WidgetRef ref, List<MoodEntry> entries) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final color = Color(entry.colorValue);
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
            ref.read(moodNotifierProvider.notifier).deleteEntry(entry.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Mood entry deleted'),
                backgroundColor: Colors.grey.shade900,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
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
                // Glowing Mood Color Swatch Orb
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

                // Details (Date & Note)
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

                // Thumbnail if photo attached
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
