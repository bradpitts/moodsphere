import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/orb_painter.dart';

class PaintOrbScreen extends ConsumerStatefulWidget {
  const PaintOrbScreen({super.key});

  @override
  ConsumerState<PaintOrbScreen> createState() => _PaintOrbScreenState();
}

class _PaintOrbScreenState extends ConsumerState<PaintOrbScreen> {
  Color _selectedColor = const Color(0xFF6C63FF);
  double _brushSize = 16.0;
  final List<PaintPoint> _points = [];
  final TextEditingController _noteController = TextEditingController();
  String? _photoPath;

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paint Today\'s Orb'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _points.clear()),
            tooltip: 'Clear Brush Strokes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Interactive Painting Canvas
            Center(
              child: GestureDetector(
                onPanUpdate: (details) {
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  // Local coordinates adjustment
                  final localPosition = details.localPosition;
                  setState(() {
                    _points.add(PaintPoint(localPosition, _selectedColor, _brushSize));
                  });
                },
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: CustomPaint(
                    painter: OrbPainter(points: _points, baseColor: _selectedColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Drag your finger across the orb to paint with the brush!', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),

            // Color Palette Picker
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final color = Color(preset.colorValue);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Note Input
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a reflection note for today...',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                final newEntry = MoodEntry(
                  id: DateTime.now().toIso8601String(),
                  date: DateTime.now(),
                  colorValue: _selectedColor.value,
                  note: _noteController.text.isEmpty ? null : _noteController.text,
                  photoPath: _photoPath,
                );
                await ref.read(moodEntriesProvider.notifier).addEntry(newEntry);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Save & Fly to Galaxy Sphere'),
            ),
          ],
        ),
      ),
    );
  }
}
