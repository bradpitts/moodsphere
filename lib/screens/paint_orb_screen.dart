import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mood_color_preset.dart';
import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../widgets/orb_painter.dart';

class PaintOrbScreen extends ConsumerStatefulWidget {
  const PaintOrbScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaintOrbScreen> createState() => _PaintOrbScreenState();
}

class _PaintOrbScreenState extends ConsumerState<PaintOrbScreen>
    with SingleTickerProviderStateMixin {
  late Color _selectedColor;
  final TextEditingController _noteController = TextEditingController();
  String? _selectedPhotoPath;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  late AnimationController _flyAnimationController;
  late Animation<double> _flyScaleAnimation;
  late Animation<Offset> _flySlideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedColor = Color(MoodColorPreset.defaultPresets.first.colorValue);

    _flyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _flyScaleAnimation = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _flyAnimationController,
        curve: Curves.easeInBack,
      ),
    );

    _flySlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.6),
    ).animate(
      CurvedAnimation(
        parent: _flyAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _flyAnimationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedPhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selection skipped or unavailable ($e)'),
            backgroundColor: Colors.grey.shade900,
          ),
        );
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    // 1. Play Spring Save & Fly Animation
    await _flyAnimationController.forward();

    // 2. Write to Hive via Riverpod
    final newEntry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      colorValue: _selectedColor.value,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      photoPath: _selectedPhotoPath,
    );

    await ref.read(moodNotifierProvider.notifier).addEntry(newEntry);

    // 3. Navigate back to Home Galaxy Sphere
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = MoodColorPreset.defaultPresets;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Paint Your Mood',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Animated Interactive Canvas Orb (with Save & Fly transition)
              SlideTransition(
                position: _flySlideAnimation,
                child: ScaleTransition(
                  scale: _flyScaleAnimation,
                  child: Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: OrbPainter(
                          strokes: [
                            PaintStroke(
                              points: const [Offset(120, 120)],
                              color: _selectedColor,
                              strokeWidth: 200,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 32),

              // Color Preset Selector Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SELECT MOOD COLOR',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Horizontal list of color presets
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final preset = presets[index];
                    final color = Color(preset.colorValue);
                    final isSelected = _selectedColor.value == color.value;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isSelected ? 44 : 38,
                            height: isSelected ? 44 : 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: isSelected ? 3 : 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(isSelected ? 0.6 : 0.25),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset.name,
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Optional Note Input
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'OPTIONAL NOTE',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _noteController,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Reflect on how you feel right now...',
                  hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2C),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _selectedColor.withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Photo Picker Button / Preview
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(
                        _selectedPhotoPath != null
                            ? Icons.photo_outlined
                            : Icons.add_a_photo_outlined,
                        color: _selectedColor,
                        size: 18,
                      ),
                      label: Text(
                        _selectedPhotoPath != null
                            ? 'Change Photo'
                            : 'Attach Photo',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedPhotoPath != null) ...[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(
                            File(_selectedPhotoPath!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPhotoPath = null;
                              });
                            },
                            child: Container(
                              color: Colors.black54,
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 36),

              // Save & Fly Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.black,
                    elevation: 8,
                    shadowColor: _selectedColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Save & Fly to Sphere',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
