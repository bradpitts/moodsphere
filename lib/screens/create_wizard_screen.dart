import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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

class _CreateWizardScreenState extends ConsumerState<CreateWizardScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

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
    MoodPaletteItem('Confidence', Color(0xFF9013FE)),
    MoodPaletteItem('Gratitude', Color(0xFFFF80AB)),
    MoodPaletteItem('Inspiration', Color(0xFFB39DDB)),
    MoodPaletteItem('Empathy', Color(0xFF81D4FA)),
    MoodPaletteItem('Balance', Color(0xFFAED581)),
  ];

  static const List<MoodPaletteItem> negativePalette = [
    MoodPaletteItem('Sadness', Color(0xFF4A90E2)),
    MoodPaletteItem('Anger', Color(0xFFFF3B30)),
    MoodPaletteItem('Fear', Color(0xFFAF52DE)),
    MoodPaletteItem('Anxiety', Color(0xFFD1A36A)),
    MoodPaletteItem('Guilt', Color(0xFF78909C)),
    MoodPaletteItem('Frustration', Color(0xFFEC407A)),
    MoodPaletteItem('Overwhelmed', Color(0xFF5C6BC0)),
    MoodPaletteItem('Apathy', Color(0xFFBDBDBD)),
  ];

  final List<String> _photoPaths = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMood = positivePalette.first;
    _recalculatePercentages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
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

    _moodPercentages.clear();
    counts.forEach((name, count) {
      _moodPercentages[name] = ((count / totalPoints.toDouble()) * 100).roundToDouble();
    });
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() { _photoPaths.add(file.path); });
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    List<String> permanentPaths = [];
    final docDir = await getApplicationDocumentsDirectory();
    for (String tempPath in _photoPaths) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${tempPath.split('/').last}';
      final savedFile = await File(tempPath).copy('${docDir.path}/$fileName');
      permanentPaths.add(savedFile.path);
    }

    int calculatedPrimaryColor = 0xFFFFD700;
    if (_moodPercentages.isNotEmpty) {
      double maxVal = -1;
      String dominantMood = _moodPercentages.keys.first;
      _moodPercentages.forEach((mood, val) {
        if (val > maxVal) { maxVal = val; dominantMood = mood; }
      });
      calculatedPrimaryColor = OrbPainter.getMoodColorValue(dominantMood);
    }

    final newEntry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      primaryColorValue: calculatedPrimaryColor,
      moodPercentages: Map.from(_moodPercentages),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      photoPaths: permanentPaths.isEmpty ? null : permanentPaths,
      strokeData: _strokes.isNotEmpty ? jsonEncode(_strokes.map((s) => s.toJson()).toList()) : null,
    );

    await ref.read(moodNotifierProvider.notifier).addEntry(newEntry);
    if (mounted) Navigator.of(context).pop();
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: Text('Step ${_currentStep + 1} of 3'),
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
        onPageChanged: (idx) => setState(() => _currentStep = idx),
        children: [
          _buildStep1(context),
          _buildStep2(context),
          _buildStep3(context),
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final activePalette = _isPositivePalette ? positivePalette : negativePalette;
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() { _isPositivePalette = true; _selectedMood = positivePalette.first; }),
              child: Text('Positive', style: TextStyle(color: _isPositivePalette ? Colors.yellow : Colors.grey)),
            ),
            TextButton(
              onPressed: () => setState(() { _isPositivePalette = false; _selectedMood = negativePalette.first; }),
              child: Text('Negative', style: TextStyle(color: !_isPositivePalette ? Colors.blue : Colors.grey)),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onPanStart: (details) {
            setState(() {
              _currentMoodName = _selectedMood.name;
              _currentStroke = PaintStroke(points: [details.localPosition], color: _selectedMood.color, strokeWidth: _brushSize, tool: _selectedTool);
              _recalculatePercentages();
            });
          },
          onPanUpdate: (details) {
            if (_currentStroke != null) {
              setState(() { _currentStroke!.points.add(details.localPosition); _recalculatePercentages(); });
            }
          },
          onPanEnd: (_) {
            if (_currentStroke != null) {
              setState(() {
                _strokes.add(_currentStroke!);
                _strokeMoodNames.add(_currentMoodName!);
                _currentStroke = null;
                _currentMoodName = null;
                _recalculatePercentages();
              });
            }
          },
          child: SizedBox(
            width: 250, height: 250,
            child: CustomPaint(painter: OrbPainter(strokes: _strokes, currentStroke: _currentStroke, isInteractiveWizard: true)),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: activePalette.map((item) {
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = item),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(_selectedMood.name == item.name ? 0.3 : 0.1),
                    border: Border.all(color: _selectedMood.name == item.name ? item.color : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${item.name} ${_moodPercentages[item.name]?.toInt() ?? 0}%'),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(onPressed: _nextPage, child: const Text('Next: Attachments')),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('Attach Photos', style: TextStyle(fontSize: 20))),
        Expanded(
          child: GridView.builder(
            itemCount: _photoPaths.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemBuilder: (context, index) {
              if (index == _photoPaths.length) {
                return GestureDetector(onTap: _pickImage, child: const Icon(Icons.add_a_photo));
              }
              return Image.file(File(_photoPaths[index]), fit: BoxFit.cover);
            },
          ),
        ),
        ElevatedButton(onPressed: _nextPage, child: const Text('Next: Reflection')),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Diary Reflection', style: TextStyle(fontSize: 20)),
          Expanded(child: TextField(controller: _noteController, maxLines: null, expands: true)),
          ElevatedButton(onPressed: _isSaving ? null : _saveEntry, child: const Text('Save to Galaxy')),
        ],
      ),
    );
  }
}