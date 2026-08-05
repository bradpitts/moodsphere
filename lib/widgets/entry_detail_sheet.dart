import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/mood_entry.dart';
import 'orb_painter.dart';

class EntryDetailSheet extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback onDelete;

  const EntryDetailSheet({
    Key? key,
    required this.entry,
    required this.onDelete,
  }) : super(key: key);

  void _openPhotoViewer(BuildContext context, String photoPath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        final TransformationController transformationController =
            TransformationController();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              // InteractiveViewer supporting pinch-to-zoom & pan
              Center(
                child: GestureDetector(
                  onDoubleTap: () {
                    transformationController.value = Matrix4.identity();
                  },
                  child: InteractiveViewer(
                    transformationController: transformationController,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.file(
                      File(photoPath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Close Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMMM yyyy').format(entry.date);
    final dayOfYear = int.parse(DateFormat('D').format(entry.date));
    final primaryColor = Color(entry.primaryColorValue);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Date & Day Stamp Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$formattedDate · Day $dayOfYear',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDelete();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Centered Large Painted Orb Preview
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: OrbPainter(
                        strokes: [],
                        moodPercentages: entry.moodPercentages,
                        primaryColorValue: entry.primaryColorValue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mood Percentage Breakdown Pills
                  if (entry.moodPercentages.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'MOOD BREAKDOWN',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.moodPercentages.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            '${e.key} ${e.value.toInt()}%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Reflection Note Card
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'REFLECTION THOUGHTS',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Text(
                        entry.note!,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Interactive Photo Tap-to-Zoom Gallery
                  if (entry.safePhotoPaths.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ATTACHED PHOTOS (TAP TO ZOOM)',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: entry.safePhotoPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final path = entry.safePhotoPaths[index];
                          return GestureDetector(
                            onTap: () => _openPhotoViewer(context, path),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(path),
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
