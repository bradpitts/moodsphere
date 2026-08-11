import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../widgets/orb_painter.dart';

class MoodPaletteItem {
  final String name;
  final Color color;

  const MoodPaletteItem(this.name, this.color);
}

class CreateWizardScreen extends ConsumerStatefulWidget {
  const CreateWizardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateWizardScreen> createState() => _CreateWizardScreenState();
}

class _CreateWizardScreenState extends ConsumerState<CreateWizardScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Painting & Palette
  bool _isPositivePalette = true;
  late MoodPaletteItem _selectedMood;
  BrushTool _selectedTool = BrushTool.paintbrush;
  double _brushSize = 24.0;
  final List<PaintStroke> _strokes = [];
  PaintStroke? _currentStroke;
  final List<String> _strokeMoodNames = [];
  String? _currentMoodName;
  final Map<String, double> _moodPercentages = {};

  static const List<MoodPaletteItem> positivePalette = [
    MoodPaletteItem('Joy', Color(0xFFFFD700)),
    MoodPaletteItem('Serenity', Color(0xFF50E3C2)),
    MoodPaletteItem('Love', Color(0xFFFF5A5F)),
    MoodPaletteItem('Longing', Color(0xFF4A90E2)),
    MoodPaletteItem('Confidence', Color(0xFF9013FE)),
    MoodPaletteItem('Hope', Color(0xFF7ED321)),
  ];

  static const List<MoodPaletteItem> negativePalette = [
    MoodPaletteItem('Sadness', Color(0xFF4A90E2)),
    MoodPaletteItem('Anger', Color(0xFFFF3B30)),
    MoodPaletteItem('Disgust', Color(0xFF34C759)),
    MoodPaletteItem('Fear', Color(0xFFAF52DE)),
    MoodPaletteItem('Anxiety', Color(0xFFD1A36A)),
    MoodPaletteItem('Neutral', Color(0xFFE5E5EA)),
  ];

  // Step 2: Media Attachments
  final List<String> _photoPaths = [];
  final ImagePicker _picker = ImagePicker();

  // Step 3: Diary Note
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  late AnimationController _flyAnimationController;
  late Animation<double> _flyScaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedMood = positivePalette.first;
    _recalculatePercentages();

    _flyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flyScaleAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _flyAnimationController,
        curve: Curves.easeInBack,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
    _flyAnimationController.dispose();
    super.dispose();
  }

  void _recalculatePercentages() {
    final allStrokes = [..._strokes];
    if (_currentStroke != null) allStrokes.add(_currentStroke!);

    if (allStrokes.isEmpty) {
      _moodPercentages.clear();
      _moodPercentages[_selectedMood.name] = 100.0;
      return;
    }

    final counts = <String, int>{};
    int totalPoints = 0;

    for (int i = 0; i < _strokes.length; i++) {
      final moodName = i < _strokeMoodNames.length ? _strokeMoodNames[i] : _selectedMood.name;
      final ptsCount = _strokes[i].points.length;
      counts[moodName] = (counts[moodName] ?? 0) + ptsCount;
      totalPoints += ptsCount;
    }

    if (_currentStroke != null && _currentMoodName != null) {
      final ptsCount = _currentStroke!.points.length;
      counts[_currentMoodName!] = (counts[_currentMoodName!] ?? 0) + ptsCount;
      totalPoints += ptsCount;
    }

    if (totalPoints == 0) {
      _moodPercentages.clear();
      _moodPercentages[_selectedMood.name] = 100.0;
      return;
    }

    _moodPercentages.clear();
    counts.forEach((name, count) {
      _moodPercentages[name] = ((count / totalPoints.toDouble()) * 100).roundToDouble();
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() {
          _photoPaths.add(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image picker error ($e)')),
        );
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    await _flyAnimationController.forward();

    final strokeJson = _strokes.isNotEmpty
        ? jsonEncode(_strokes.map((s) => s.toJson()).toList())
        : null;

    final newEntry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      primaryColorValue: _selectedMood.color.value,
      moodPercentages: Map.from(_moodPercentages),
      stateTags: const [], // Default empty state tags for 3-step wizard
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      photoPaths: _photoPaths.isEmpty ? null : List.from(_photoPaths),
      strokeData: strokeJson,
    );

    await ref.read(moodNotifierProvider.notifier).addEntry(newEntry);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Step ${_currentStep + 1} of 3',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3.0,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(_selectedMood.color),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        children: [
          _buildStep1PaintCanvas(context),
          _buildStep2MediaAttachments(context),
          _buildStep3DiaryNote(context),
        ],
      ),
    );
  }

  // --- STEP 1 OF 3: PAINT CANVAS & DUAL ARC PALETTE ---
  Widget _buildStep1PaintCanvas(BuildContext context) {
    final activePalette =
        _isPositivePalette ? positivePalette : negativePalette;

    return Column(
      children: [
        const SizedBox(height: 12),

        // Positive / Negative Toggle Pills
        Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPositivePalette = true;
                    _selectedMood = positivePalette.first;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPositivePalette
                        ? const Color(0xFFFFD700)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Positive',
                    style: GoogleFonts.inter(
                      color: _isPositivePalette ? Colors.black : Colors.white60,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPositivePalette = false;
                    _selectedMood = negativePalette.first;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: !_isPositivePalette
                        ? const Color(0xFF4A90E2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Negative',
                    style: GoogleFonts.inter(
                      color: !_isPositivePalette ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Interactive Orb Finger Painting Canvas
        GestureDetector(
          onPanStart: (details) {
            final localPos = details.localPosition;

            setState(() {
              _currentMoodName = _selectedMood.name;
              _currentStroke = PaintStroke(
                points: [localPos],
                color: _selectedMood.color,
                strokeWidth: _brushSize,
                tool: _selectedTool,
              );
              _recalculatePercentages();
            });
          },
          onPanUpdate: (details) {
            final localPos = details.localPosition;

            if (_currentStroke != null) {
              setState(() {
                _currentStroke!.points.add(localPos);
                _recalculatePercentages();
              });
            }
          },
          onPanEnd: (_) {
            if (_currentStroke != null) {
              setState(() {
                _strokes.add(_currentStroke!);
                if (_currentMoodName != null) {
                  _strokeMoodNames.add(_currentMoodName!);
                }
                _currentStroke = null;
                _currentMoodName = null;
                _recalculatePercentages();
              });
            }
          },
          child: SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: OrbPainter(
                strokes: _strokes,
                currentStroke: _currentStroke,
              ),
            ),
          ),
        ),

        const Spacer(),

        // Realtime Mood Percentage Curved Arc Bar
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: activePalette.map((item) {
              final isSelected = _selectedMood.name == item.name;
              final percentage = _moodPercentages[item.name] ?? 0.0;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMood = item;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(isSelected ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? item.color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.name} ${percentage > 0 ? '${percentage.toInt()}%' : ''}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Bottom Controls: Brush Drawer Popup & Next Button ("Next: Attachments")
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.brush, color: Colors.white),
                onPressed: () => _showBrushSettingsDialog(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMood.color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Next: Attachments',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBrushSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECT BRUSH TOOL',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildToolChip(BrushTool.paintbrush, 'Paintbrush', setSheetState),
                      const SizedBox(width: 8),
                      _buildToolChip(BrushTool.spray, 'Airbrush', setSheetState),
                      const SizedBox(width: 8),
                      _buildToolChip(BrushTool.marker, 'Marker', setSheetState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'BRUSH SIZE (${_brushSize.round()}px)',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: _brushSize,
                    min: 10.0,
                    max: 50.0,
                    activeColor: _selectedMood.color,
                    onChanged: (val) {
                      setSheetState(() => _brushSize = val);
                      setState(() => _brushSize = val);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToolChip(BrushTool tool, String label, StateSetter setSheetState) {
    final isSelected = _selectedTool == tool;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: _selectedMood.color,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFF121212),
      onSelected: (_) {
        setSheetState(() => _selectedTool = tool);
        setState(() => _selectedTool = tool);
      },
    );
  }

  // --- STEP 2 OF 3: MEDIA ATTACHMENTS ---
  Widget _buildStep2MediaAttachments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attach Photos',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add memories from today to embed alongside your mood orb.',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _photoPaths.length + 1,
              itemBuilder: (context, index) {
                if (index == _photoPaths.length) {
                  return GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  );
                }

                final path = _photoPaths[index];
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _photoPaths.removeAt(index);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedMood.color,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Next: Diary Reflection',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3 OF 3: DIARY REFLECTION NOTE & SAVE ---
  Widget _buildStep3DiaryNote(BuildContext context) {
    return ScaleTransition(
      scale: _flyScaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diary Reflection',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Write your thoughts and reflections for today.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Lined Paper Style Journal Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLength: 400,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write your thoughts for today...',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMood.color,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        'Save to Galaxy',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
