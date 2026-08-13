import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models/mood_entry.dart';

/// 3D Position in Cartesian Space
class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);
}

/// Projected 2D screen coordinate with depth scale factor
class ProjectedPoint {
  final Offset screenOffset;
  final double scale;
  final double depth;

  const ProjectedPoint({
    required this.screenOffset,
    required this.scale,
    required this.depth,
  });
}

/// Interactive 3D Background Widget rendering Starlight Galaxy, floating dust,
/// nebula clouds, mood star halos, and Rashi constellation lines.
class StarlightGalaxyView extends StatefulWidget {
  final List<MoodEntry> entries;
  final Widget? child;
  final void Function(MoodEntry entry)? onStarSelected;

  const StarlightGalaxyView({
    super.key,
    required this.entries,
    this.child,
    this.onStarSelected,
  });

  @override
  State<StarlightGalaxyView> createState() => _StarlightGalaxyViewState();
}

class _StarlightGalaxyViewState extends State<StarlightGalaxyView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;

  // Interactive 3D Camera Controls
  double _yaw = 0.3;
  double _pitch = 0.2;
  double _zoom = 1.0;

  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _baseZoom = _zoom;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.pointerCount == 1) {
            // Drag gesture for 3D yaw/pitch rotation
            _yaw += details.focalPointDelta.dx * 0.005;
            _pitch += details.focalPointDelta.dy * 0.005;
            // Clamp pitch to prevent gimbal flip
            _pitch = _pitch.clamp(-math.pi / 2.2, math.pi / 2.2);
          } else if (details.pointerCount >= 2) {
            // Pinch gesture for camera zoom
            _zoom = (_baseZoom * details.scale).clamp(0.5, 3.0);
          }
        });
      },
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, child) {
          final ambientAngle = _ambientController.value * 2 * math.pi;

          return Stack(
            children: [
              // CustomPainter 3D Galaxy Canvas
              Positioned.fill(
                child: CustomPaint(
                  painter: StarlightGalaxyPainter(
                    entries: widget.entries,
                    yaw: _yaw + (ambientAngle * 0.1),
                    pitch: _pitch,
                    zoom: _zoom,
                    ambientTime: ambientAngle,
                  ),
                ),
              ),
              // Foreground child overlay
              if (widget.child != null) widget.child!,
            ],
          );
        },
      ),
    );
  }
}

/// CustomPainter executing 3D perspective projection, nebula layers,
/// stardust field, mood stars, and Rashi constellation lines.
class StarlightGalaxyPainter extends CustomPainter {
  final List<MoodEntry> entries;
  final double yaw;
  final double pitch;
  final double zoom;
  final double ambientTime;

  // Pre-calculated deterministic stardust 3D points
  static final List<Point3D> _stardustField = _generateStardust(180);

  StarlightGalaxyPainter({
    required this.entries,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.ambientTime,
  });

  static List<Point3D> _generateStardust(int count) {
    final rand = math.Random(42); // Deterministic seed
    final List<Point3D> list = [];
    for (int i = 0; i < count; i++) {
      final radius = 150.0 + rand.nextDouble() * 350.0;
      final theta = rand.nextDouble() * 2 * math.pi;
      final phi = (rand.nextDouble() - 0.5) * math.pi;

      final x = radius * math.cos(phi) * math.cos(theta);
      final y = radius * math.sin(phi);
      final z = radius * math.cos(phi) * math.sin(theta);
      list.add(Point3D(x, y, z));
    }
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw Deep Space Background Base
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: const [
          Color(0xFF141526),
          Color(0xFF0A0B12),
          Color(0xFF040407),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Draw Multi-Colored Looping Nebula Cloud Layers
    _drawNebulaClouds(canvas, size, center);

    // 3. Render Floating Stardust 3D Field
    _drawStardust(canvas, center);

    // 4. Project Mood Entries to 3D Coordinates
    final List<_ProjectedStar> projectedStars = [];
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final pos3d = _get3DPositionForEntry(entry, i);
      final proj = _project3D(pos3d, center);
      if (proj != null) {
        projectedStars.add(_ProjectedStar(entry: entry, projected: proj));
      }
    }

    // Sort by depth (far to near) for proper 3D depth rendering
    projectedStars.sort((a, b) => b.projected.depth.compareTo(a.projected.depth));

    // 5. Draw Rashi / Zodiac Constellation Lines across space
    _drawRashiConstellations(canvas, projectedStars);

    // 6. Draw Mood Stars with Glowing Aura Halos
    for (final pStar in projectedStars) {
      _drawMoodStar(canvas, pStar);
    }
  }

  void _drawNebulaClouds(Canvas canvas, Size size, Offset center) {
    final nebulaColors = const [
      Color(0x3D4A0E4E), // Cosmic Purple #4A0E4E
      Color(0x3D004D40), // Deep Teal #004D40
      Color(0x3D880E4F), // Magenta #880E4F
      Color(0x3D1A237E), // Indigo #1A237E
    ];

    for (int i = 0; i < nebulaColors.length; i++) {
      final angle = ambientTime * 0.5 + (i * math.pi / 2);
      final driftX = center.dx + math.cos(angle) * (60 + i * 20);
      final driftY = center.dy + math.sin(angle * 0.7) * (40 + i * 15);
      final radius = math.max(size.width, size.height) * (0.4 + i * 0.1);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            nebulaColors[i],
            nebulaColors[i].withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(driftX, driftY), radius: radius))
        ..blendMode = BlendMode.plus;

      canvas.drawCircle(Offset(driftX, driftY), radius, paint);
    }
  }

  void _drawStardust(Canvas canvas, Offset center) {
    for (final pt in _stardustField) {
      final proj = _project3D(pt, center);
      if (proj == null) continue;

      final alpha = (proj.scale * 0.8).clamp(0.1, 0.9);
      final radius = (1.5 * proj.scale).clamp(0.8, 3.0);

      final stardustPaint = Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(proj.screenOffset, radius, stardustPaint);
    }
  }

  Point3D _get3DPositionForEntry(MoodEntry entry, int index) {
    // Deterministic golden spiral distribution in 3D space based on entry ID hash
    final hash = entry.id.hashCode.abs();
    final radius = 120.0 + (hash % 180);
    final phi = ((index * 137.5) % 360) * (math.pi / 180);
    final y = ((hash % 200) - 100).toDouble();

    final x = radius * math.cos(phi);
    final z = radius * math.sin(phi);
    return Point3D(x, y, z);
  }

  ProjectedPoint? _project3D(Point3D point, Offset center) {
    // Yaw rotation around Y-axis
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final x1 = point.x * cosY + point.z * sinY;
    final z1 = -point.x * sinY + point.z * cosY;

    // Pitch rotation around X-axis
    final cosX = math.cos(pitch);
    final sinX = math.sin(pitch);
    final y2 = point.y * cosX - z1 * sinX;
    final z2 = point.y * sinX + z1 * cosX;

    // Camera perspective projection
    final cameraDistance = 450.0 / zoom;
    final depth = z2 + cameraDistance;

    if (depth <= 20) return null; // Clipping plane

    final focalLength = 350.0;
    final scale = focalLength / depth;

    final screenX = center.dx + (x1 * scale);
    final screenY = center.dy + (y2 * scale);

    return ProjectedPoint(
      screenOffset: Offset(screenX, screenY),
      scale: scale,
      depth: depth,
    );
  }

  void _drawRashiConstellations(Canvas canvas, List<_ProjectedStar> stars) {
    // Group stars by mapped Rashi / Zodiac sign
    final Map<String, List<ProjectedPoint>> rashiGroups = {};

    for (final pStar in stars) {
      final rashi = _getEntryRashi(pStar.entry);
      rashiGroups.putIfAbsent(rashi, () => []).add(pStar.projected);
    }

    // Connect stars in each Rashi group with glowing 3D constellation lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

    for (final group in rashiGroups.values) {
      if (group.length < 2) continue;
      final path = Path()..moveTo(group[0].screenOffset.dx, group[0].screenOffset.dy);
      for (int i = 1; i < group.length; i++) {
        path.lineTo(group[i].screenOffset.dx, group[i].screenOffset.dy);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawMoodStar(Canvas canvas, _ProjectedStar pStar) {
    final offset = pStar.projected.screenOffset;
    final scale = pStar.projected.scale;
    final baseColor = _getMoodColor(pStar.entry);

    final coreRadius = (5.0 * scale).clamp(3.0, 12.0);
    final auraRadius = coreRadius * 3.5;

    // 1. Draw Outer Aura Glow Halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withOpacity(0.6),
          baseColor.withOpacity(0.2),
          baseColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: offset, radius: auraRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawCircle(offset, auraRadius, haloPaint);

    // 2. Draw Inner Star Core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, coreRadius, corePaint);

    // 3. Draw Core Color Ring
    final ringPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale;
    canvas.drawCircle(offset, coreRadius * 1.2, ringPaint);
  }

  Color _getMoodColor(MoodEntry entry) {
    // Find dominant emotion key from moodBreakdown
    String dominantMood = 'serenity';
    double maxVal = -1.0;
    entry.moodBreakdown.forEach((key, val) {
      if (val > maxVal) {
        maxVal = val;
        dominantMood = key.toLowerCase();
      }
    });

    if (dominantMood.contains('love') || dominantMood.contains('passion')) {
      return const Color(0xFFFF1744); // Red = Love
    } else if (dominantMood.contains('longing') || dominantMood.contains('desire')) {
      return const Color(0xFF29B6F6); // Blue = Longing
    } else if (dominantMood.contains('serenity') || dominantMood.contains('calm')) {
      return const Color(0xFF00E5FF); // Cyan = Serenity
    } else if (dominantMood.contains('joy') || dominantMood.contains('creativity')) {
      return const Color(0xFFFFEA00); // Yellow = Joy
    } else if (dominantMood.contains('confidence') || dominantMood.contains('focus')) {
      return const Color(0xFFD500F9); // Violet = Confidence
    }
    return const Color(0xFF8B5CF6); // Default Violet Accent
  }

  String _getEntryRashi(MoodEntry entry) {
    if (entry.zodiacSign != 'Unknown' && entry.zodiacSign.isNotEmpty) {
      return entry.zodiacSign;
    }
    // Auto-map entries to Rashis based on dominant mood:
    // Joy -> Gemini (Mithuna)
    // Anger / Frustration -> Aries (Mesha)
    // Serenity / Balance -> Taurus (Vrishabha)
    // Sadness -> Cancer (Karka)
    // Love -> Libra (Tula)
    String dominantMood = '';
    double maxVal = -1.0;
    entry.moodBreakdown.forEach((key, val) {
      if (val > maxVal) {
        maxVal = val;
        dominantMood = key.toLowerCase();
      }
    });

    if (dominantMood.contains('joy')) return 'Gemini (Mithuna)';
    if (dominantMood.contains('anger') || dominantMood.contains('frustration')) {
      return 'Aries (Mesha)';
    }
    if (dominantMood.contains('serenity') || dominantMood.contains('balance')) {
      return 'Taurus (Vrishabha)';
    }
    if (dominantMood.contains('sadness')) return 'Cancer (Karka)';
    if (dominantMood.contains('love')) return 'Libra (Tula)';

    return 'Gemini (Mithuna)';
  }

  @override
  bool shouldRepaint(covariant StarlightGalaxyPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.ambientTime != ambientTime ||
        oldDelegate.entries != entries;
  }
}

class _ProjectedStar {
  final MoodEntry entry;
  final ProjectedPoint projected;

  const _ProjectedStar({required this.entry, required this.projected});
}
