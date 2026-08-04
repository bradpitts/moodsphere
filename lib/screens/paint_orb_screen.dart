import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../widgets/orb_painter.dart';

class PaintOrbScreen extends ConsumerStatefulWidget {
  const PaintOrbScreen({super.key});

  @override
  ConsumerState<PaintOrbScreen> createState() => _PaintOrbScreenState();
}

class _PaintOrbScreenState extends ConsumerState<PaintOrbScreen> {
  Color _selectedColor = const Color(0xFFFFD700);
  final double _brushSize = 16.0;
  final List<PaintPoint> _points = [];
  final TextEditingController _noteController = TextEditingController();

  // Preset palette fallback list
  final List<Color> _presetColors = const [
    Color(0xFFFFD700), // Joy
    Color(0xFF4A90E2), // Calm
    Color(0xFF50E3C2), // Serene
    Color(0xFFFF5A5F), // Energy
    Color(0xFF9013FE), // Creative
    Color(0xFF7ED321), // Peaceful
    Color(0xFFE91E63), // Passion
    Color(0xFF00BCD4), // Focus
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Paint Today\'s Orb', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _points.clear()),
            tooltip: 'Clear Canvas',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Interactive Finger-Paint Canvas
            Center(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.globalPosition);
                  setState(() {
                    _points.add(PaintPoint(localPosition, _selectedColor, _brushSize));
                  });
                },
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: CustomPaint(
                    painter: OrbPainter(points: _points, baseColor: _selectedColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Drag your finger across the orb to paint with the brush',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Color Palette Selector Row
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presetColors.length,
                itemBuilder: (context, index) {
                  final color = _presetColors[index];
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Note Input Field
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a reflection note for today...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save & Fly Action Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final newEntry = MoodEntry(
                  id: DateTime.now().toIso8601String(),
                  date: DateTime.now(),
                  colorValue: _selectedColor.value,
                  note: _noteController.text.isEmpty ? null : _noteController.text,
                );
                
                // Uses moodNotifierProvider from mood_provider.dart
                await ref.read(moodNotifierProvider.notifier).addEntry(newEntry);
                
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Save & Fly to Sphere',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
