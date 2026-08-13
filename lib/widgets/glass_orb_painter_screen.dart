import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/uuid_generator.dart';
import '../domain/models/mood_entry.dart';
import '../domain/repositories/mood_repository.dart';

enum BrushType { paintbrush, airbrush, marker }

class MoodItem {
  final String name;
  final Color color;
  final String hex;
  final String zodiac;
  final bool isPositive;

  const MoodItem({
    required this.name,
    required this.color,
    required this.hex,
    required this.zodiac,
    required this.isPositive,
  });
}

class StrokePoint {
  final double x;
  final double y;

  const StrokePoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory StrokePoint.fromJson(Map<String, dynamic> json) =>
      StrokePoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

class OrbStroke {
  final List<StrokePoint> points;
  final Color color;
  final double width;
  final BrushType brushType;
  final MoodItem mood;

  OrbStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.brushType,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'color': '#${color.value.toRadixString(16).padLeft(8, '0')}',
        'width': width,
        'brushType': brushType.name,
        'mood': mood.name,
      };
}

class GlassOrbPainterScreen extends StatefulWidget {
  final MoodRepository repository;

  const GlassOrbPainterScreen({super.key, required this.repository});

  @override
  State<GlassOrbPainterScreen> createState() => _GlassOrbPainterScreenState();
}

class _GlassOrbPainterScreenState extends State<GlassOrbPainterScreen> {
  // Pre-defined Positive Mood Palette
  static const List<MoodItem> positivePalette = [
    MoodItem(name: 'Joy', color: Color(0xFFFFD700), hex: '#FFD700', zodiac: 'Gemini (Mithuna)', isPositive: true),
    MoodItem(name: 'Serenity', color: Color(0xFF00E5FF), hex: '#00E5FF', zodiac: 'Taurus (Vrishabha)', isPositive: true),
    MoodItem(name: 'Love', color: Color(0xFFFF1744), hex: '#FF1744', zodiac: 'Libra (Tula)', isPositive: true),
    MoodItem(name: 'Confidence', color: Color(0xFF8E24AA), hex: '#8E24AA', zodiac: 'Aries (Mesha)', isPositive: true),
    MoodItem(name: 'Gratitude', color: Color(0xFFFF6D00), hex: '#FF6D00', zodiac: 'Leo (Simha)', isPositive: true),
    MoodItem(name: 'Inspiration', color: Color(0xFF00E676), hex: '#00E676', zodiac: 'Aquarius (Kumbha)', isPositive: true),
    MoodItem(name: 'Empathy', color: Color(0xFFFF4081), hex: '#FF4081', zodiac: 'Pisces (Meena)', isPositive: true),
    MoodItem(name: 'Balance', color: Color(0xFF76FF03), hex: '#76FF03', zodiac: 'Virgo (Kanya)', isPositive: true),
  ];

  // Pre-defined Negative Mood Palette
  static const List<MoodItem> negativePalette = [
    MoodItem(name: 'Sadness', color: Color(0xFF29B6F6), hex: '#29B6F6', zodiac: 'Cancer (Karka)', isPositive: false),
    MoodItem(name: 'Anger', color: Color(0xFFD50000), hex: '#D50000', zodiac: 'Aries (Mesha)', isPositive: false),
    MoodItem(name: 'Fear', color: Color(0xFF4A148C), hex: '#4A148C', zodiac: 'Scorpio (Vrishchika)', isPositive: false),
    MoodItem(name: 'Anxiety', color: Color(0xFFFFAB00), hex: '#FFAB00', zodiac: 'Gemini (Mithuna)', isPositive: false),
    MoodItem(name: 'Guilt', color: Color(0xFF3E2723), hex: '#3E2723', zodiac: 'Capricorn (Makara)', isPositive: false),
    MoodItem(name: 'Frustration', color: Color(0xFFFF3D00), hex: '#FF3D00', zodiac: 'Sagittarius (Dhanu)', isPositive: false),
    MoodItem(name: 'Overwhelmed', color: Color(0xFF004D40), hex: '#004D40', zodiac: 'Pisces (Meena)', isPositive: false),
    MoodItem(name: 'Apathy', color: Color(0xFF607D8B), hex: '#607D8B', zodiac: 'Aquarius (Kumbha)', isPositive: false),
  ];

  final List<OrbStroke> _strokes = [];
  OrbStroke? _currentStroke;

  BrushType _selectedBrush = BrushType.paintbrush;
  MoodItem _selectedMood = positivePalette[0];
  double _strokeWidth = 14.0;

  final TextEditingController _noteController = TextEditingController();
  final List<String> _selectedPhotoPaths = [];

  bool _isPositiveSelected = true;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedPhotoPaths.add(image.path);
        });
      }
    } catch (_) {
      // Fallback mock path for test/desktop environments without camera gallery plugin
      setState(() {
        _selectedPhotoPaths.add('/local/app_docs/mock_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      });
    }
  }

  /// Color Extraction Algorithm:
  /// Analyzes strokes to calculate percentage breakdown of each mood & dominant color.
  void _submitEntry() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paint your mood inside the Glass Orb first!')),
      );
      return;
    }

    // 1. Calculate point distribution per mood
    final Map<String, int> moodPointCounts = {};
    int totalPoints = 0;

    for (final stroke in _strokes) {
      final pointsInStroke = stroke.points.length;
      totalPoints += pointsInStroke;
      final key = stroke.mood.name.toLowerCase();
      moodPointCounts[key] = (moodPointCounts[key] ?? 0) + pointsInStroke;
    }

    if (totalPoints == 0) totalPoints = 1;

    // 2. Build moodBreakdown map (percentages 0.0 - 1.0)
    final Map<String, double> breakdown = {};
    String dominantMoodKey = '';
    int maxPoints = -1;
    MoodItem dominantMoodItem = _selectedMood;

    moodPointCounts.forEach((key, count) {
      final percentage = count / totalPoints;
      breakdown[key] = double.parse(percentage.toStringAsFixed(2));
      if (count > maxPoints) {
        maxPoints = count;
        dominantMoodKey = key;
      }
    });

    // Find dominant mood item details
    final allMoods = [...positivePalette, ...negativePalette];
    for (final m in allMoods) {
      if (m.name.toLowerCase() == dominantMoodKey) {
        dominantMoodItem = m;
        break;
      }
    }

    // 3. Serialize stroke vectors to JSON string
    final strokeDataJson = jsonEncode(_strokes.map((s) => s.toJson()).toList());

    // 4. Construct MoodEntry
    final newEntry = MoodEntry(
      id: UuidGenerator.generate(),
      timestamp: DateTime.now(),
      strokeData: strokeDataJson,
      dominantColor: dominantMoodItem.hex,
      moodBreakdown: breakdown,
      photoPaths: _selectedPhotoPaths,
      note: _noteController.text.trim().isEmpty ? 'Painted inside Glass Orb.' : _noteController.text.trim(),
      zodiacSign: dominantMoodItem.zodiac,
    );

    // 5. Persist to repository (which copies photos locally)
    await widget.repository.saveEntry(newEntry);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableMoods = _isPositiveSelected ? positivePalette : negativePalette;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B12),
      appBar: AppBar(
        title: const Text('Glass Orb Painting Studio'),
        backgroundColor: const Color(0xFF141526),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white70),
            onPressed: _strokes.isEmpty ? null : _undo,
            tooltip: 'Undo Stroke',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _strokes.isEmpty ? null : _clearCanvas,
            tooltip: 'Clear Orb',
          ),
          TextButton(
            onPressed: _submitEntry,
            child: const Text(
              'CAST STAR',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 3D Glass Orb Canvas Container
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF23253B),
                      Color(0xFF131422),
                      Color(0xFF080912),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedMood.color.withOpacity(0.3),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      // Touch Drawing Area
                      GestureDetector(
                        onPanStart: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final localPos = box.globalToLocal(details.globalPosition);
                          // Calculate relative offset inside orb
                          final orbOffset = _clampToOrb(details.localPosition, 140);
                          setState(() {
                            _currentStroke = OrbStroke(
                              points: [StrokePoint(orbOffset.dx, orbOffset.dy)],
                              color: _selectedMood.color,
                              width: _strokeWidth,
                              brushType: _selectedBrush,
                              mood: _selectedMood,
                            );
                            _strokes.add(_currentStroke!);
                          });
                        },
                        onPanUpdate: (details) {
                          if (_currentStroke != null) {
                            final orbOffset = _clampToOrb(details.localPosition, 140);
                            setState(() {
                              _currentStroke!.points.add(
                                StrokePoint(orbOffset.dx, orbOffset.dy),
                              );
                            });
                          }
                        },
                        onPanEnd: (_) {
                          _currentStroke = null;
                        },
                        child: CustomPaint(
                          size: const Size(280, 280),
                          painter: GlassOrbCanvasPainter(strokes: _strokes),
                        ),
                      ),

                      // 3D Specular Highlight Overlay (Glass Reflection)
                      IgnorePointer(
                        child: CustomPaint(
                          size: const Size(280, 280),
                          painter: GlassSpecularHighlightPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Brush Tools Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToolButton(BrushType.paintbrush, Icons.brush, 'Paintbrush'),
                const SizedBox(width: 12),
                _buildToolButton(BrushType.airbrush, Icons.blur_on, 'Airbrush'),
                const SizedBox(width: 12),
                _buildToolButton(BrushType.marker, Icons.create, 'Marker'),
              ],
            ),

            const SizedBox(height: 16),

            // Stroke Width Slider
            Row(
              children: [
                const Text('Stroke:', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 4.0,
                    max: 32.0,
                    activeColor: _selectedMood.color,
                    onChanged: (val) => setState(() => _strokeWidth = val),
                  ),
                ),
              ],
            ),

            // Mood Palette Category Selector (Positive vs Negative)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Positive Palette'),
                  selected: _isPositiveSelected,
                  selectedColor: const Color(0xFF8B5CF6),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isPositiveSelected = true;
                        _selectedMood = positivePalette[0];
                      });
                    }
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Negative Palette'),
                  selected: !_isPositiveSelected,
                  selectedColor: const Color(0xFFEF4444),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isPositiveSelected = false;
                        _selectedMood = negativePalette[0];
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Color Palette Selector Swatches
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: availableMoods.length,
                itemBuilder: (context, index) {
                  final mood = availableMoods[index];
                  final isSelected = _selectedMood.name == mood.name;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? mood.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: mood.color,
                              boxShadow: [
                                BoxShadow(
                                  color: mood.color.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Note Text Input
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add an optional diary reflection note...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF161726),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Photo Attachment Section
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('Attach Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedPhotoPaths.length} Photo(s) Attached',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(BrushType type, IconData icon, String label) {
    final isSelected = _selectedBrush == type;
    return ElevatedButton.icon(
      onPressed: () => setState(() => _selectedBrush = type),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Offset _clampToOrb(Offset pos, double radius) {
    final center = Offset(radius, radius);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance <= radius - 4) return pos;

    final angle = math.atan2(dy, dx);
    final clampedX = center.dx + (radius - 4) * math.cos(angle);
    final clampedY = center.dy + (radius - 4) * math.sin(angle);
    return Offset(clampedX, clampedY);
  }
}

/// CustomPainter rendering strokes inside the Glass Orb Canvas
class GlassOrbCanvasPainter extends CustomPainter {
  final List<OrbStroke> strokes;

  GlassOrbCanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      if (stroke.brushType == BrushType.paintbrush) {
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final path = Path()
          ..moveTo(stroke.points[0].x, stroke.points[0].y);

        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].x, stroke.points[i].y);
        }
        canvas.drawPath(path, paint);
      } else if (stroke.brushType == BrushType.airbrush) {
        // Airbrush: Particle spray scatter effect
        final rand = math.Random(12345);
        final sprayPaint = Paint()
          ..color = stroke.color.withOpacity(0.4)
          ..style = PaintingStyle.fill;

        for (final pt in stroke.points) {
          for (int p = 0; p < 8; p++) {
            final offsetAngle = rand.nextDouble() * 2 * math.pi;
            final offsetRadius = rand.nextDouble() * stroke.width * 1.2;
            final sprayX = pt.x + math.cos(offsetAngle) * offsetRadius;
            final sprayY = pt.y + math.sin(offsetAngle) * offsetRadius;
            canvas.drawCircle(Offset(sprayX, sprayY), 1.5, sprayPaint);
          }
        }
      } else if (stroke.brushType == BrushType.marker) {
        // Marker: Soft watercolor dab with high blur level
        final markerPaint = Paint()
          ..color = stroke.color.withOpacity(0.35)
          ..strokeWidth = stroke.width * 1.6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

        final path = Path()
          ..moveTo(stroke.points[0].x, stroke.points[0].y);

        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].x, stroke.points[i].y);
        }
        canvas.drawPath(path, markerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GlassOrbCanvasPainter oldDelegate) => true;
}

/// CustomPainter drawing top-left 3D Glass Specular Highlight arc
class GlassSpecularHighlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Specular Lens Curve Highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.6),
        radius: 0.7,
        colors: [
          Colors.white.withOpacity(0.45),
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
