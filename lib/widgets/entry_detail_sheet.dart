import 'dart:io';
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

class EntryDetailSheet extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback? onDelete;

  const EntryDetailSheet({
    super.key,
    required this.entry,
    this.onDelete,
  });

  static void show(BuildContext context, MoodEntry entry, {VoidCallback? onDelete}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => EntryDetailSheet(entry: entry, onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(entry.primaryColorValue);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${entry.date.day} ${_monthName(entry.date.month)} ${entry.date.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (entry.moodPercentages != null && entry.moodPercentages!.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: entry.moodPercentages!.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            '${e.key} ${(e.value * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        entry.note!,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (entry.safePhotoPaths.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: entry.safePhotoPaths.length,
                        itemBuilder: (context, index) {
                          final path = entry.safePhotoPaths[index];
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: InteractiveViewer(
                                    child: Image.file(File(path)),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(File(path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete!();
                      },
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      label: const Text('Delete Entry', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
