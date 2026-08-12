import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import 'orb_painter.dart';

class StarlightGalaxyView extends StatefulWidget {
  final List<MoodEntry> entries;
  final ValueChanged<MoodEntry>? onStarTap;
  final ValueChanged<MoodEntry>? onEntryTap;

  const StarlightGalaxyView({
    Key? key,
    required this.entries,
    this.onStarTap,
    this.onEntryTap,
  }) : super(key: key);

  @override
  State<StarlightGalaxyView> createState() => _StarlightGalaxyViewState();
}

class _StarlightGalaxyViewState extends State<StarlightGalaxyView> with SingleTickerProviderStateMixin {
  double _userYaw = 0.0;
  double _userPitch = 0.0;
  double _scale = 1.0;
  Offset _lastTouch = Offset.zero;

  late AnimationController _spaceDriftController;

  @override
  void initState() {
    super.initState();
    _spaceDriftController = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  }

  @override
  void dispose() {
    _spaceDriftController.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details, Size size) {
    if (widget.entries.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5 * _scale;
    final driftVal = _spaceDriftController.value * 2 * math.pi;
    final yaw = _userYaw + driftVal * 0.12;
    final pitch = _userPitch + math.sin(driftVal) * 0.04;

    MoodEntry? tappedEntry;
    double minDistance = 32.0;

    for (int i = 0; i < widget.entries.length; i++) {
      final y = 1 - (i / math.max(1, widget.entries.length - 1)) * 1.8;
      final radiusAtY = math.sqrt(math.max(0, 1 - y * y));
      final theta = 2 * math.pi * i / ((1 + math.sqrt(5)) / 2);

      final x0 = math.cos(theta) * radiusAtY;
      final z0 = math.sin(theta) * radiusAtY;

      final x1 = x0;
      final y1 = y * math.cos(pitch) - z0 * math.sin(pitch);
      final z1 = y * math.sin(pitch) + z0 * math.cos(pitch);

      final x2 = x1 * math.cos(yaw) + z1 * math.sin(yaw);
      final screenPos = Offset(center.dx + x2 * radius, center.dy + y1 * radius);

      final dist = (details.localPosition - screenPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        tappedEntry = widget.entries[i];
      }
    }

    if (tappedEntry != null) {
      widget.onStarTap?.call(tappedEntry);
      widget.onEntryTap?.call(tappedEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapUp: (details) => _handleTapUp(details, size),
          onScaleStart: (details) => _lastTouch = details.focalPoint,
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_scale * details.scale).clamp(0.6, 2.5);
              final delta = details.focalPoint - _lastTouch;
              _userYaw += delta.dx * 0.006;
              _userPitch += delta.dy * 0.006;
              _lastTouch = details.focalPoint;
            });
          },
          child: Container(
            color: const Color(0xFF05050B),
            child: AnimatedBuilder(
              animation: _spaceDriftController,
              builder: (context, child) {
                final driftVal = _spaceDriftController.value;
                return CustomPaint(
                  size: size,
                  painter: _GalaxySpaceDriftPainter(
                    entries: widget.entries,
                    yaw: _userYaw + driftVal * 2 * math.pi * 0.12,
                    pitch: _userPitch + math.sin(driftVal * 2 * math.pi) * 0.04,
                    scale: _scale,
                    driftVal: driftVal,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _GalaxySpaceDriftPainter extends CustomPainter {
  final List<MoodEntry> entries;
  final double yaw;
  final double pitch;
  final double scale;
  final double driftVal;

  _GalaxySpaceDriftPainter({
    required this.entries,
    required this.yaw,
    required this.pitch,
    required this.scale,
    required this.driftVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5 * scale;

    // Constellation tracking
    Map<String, List<Offset>> rashiConstellations = {};
    final starPoints = <Offset>[];
    final starEntries = <MoodEntry>[];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final y = 1 - (i / math.max(1, entries.length - 1)) * 1.8;
      final radiusAtY = math.sqrt(math.max(0, 1 - y * y));
      final theta = 2 * math.pi * i / ((1 + math.sqrt(5)) / 2);

      final x0 = math.cos(theta) * radiusAtY;
      final z0 = math.sin(theta) * radiusAtY;

      final x1 = x0;
      final y1 = y * math.cos(pitch) - z0 * math.sin(pitch);
      final z1 = y * math.sin(pitch) + z0 * math.cos(pitch);

      final x2 = x1 * math.cos(yaw) + z1 * math.sin(yaw);
      final screenPos = Offset(center.dx + x2 * radius, center.dy + y1 * radius);
      
      starPoints.add(screenPos);
      starEntries.add(entry);

      // Group stars into Zodiacs based on dominant mood
      String dominantMood = '';
      double maxVal = -1;
      if (entry.moodPercentages.isNotEmpty) {
        entry.moodPercentages.forEach((key, val) {
          if (val > maxVal) { maxVal = val; dominantMood = key; }
        });
      }
      if (dominantMood.isNotEmpty) {
        String rashi = OrbPainter.getRashiForMood(dominantMood);
        rashiConstellations.putIfAbsent(rashi, () => []).add(screenPos);
      }
    }

    // DRAW CONSTELLATION LINES FIRST (so they are under the stars)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    for (var rashiGroup in rashiConstellations.entries) {
      if (rashiGroup.value.length >= 2) {
        final path = Path();
        path.moveTo(rashiGroup.value.first.dx, rashiGroup.value.first.dy);
        for (int i = 1; i < rashiGroup.value.length; i++) {
          path.lineTo(rashiGroup.value[i].dx, rashiGroup.value[i].dy);
        }
        canvas.drawPath(path, linePaint);
        
        // Connect the last star back to the first to form closed shapes if >=3 stars
        if (rashiGroup.value.length >= 3) {
           canvas.drawLine(rashiGroup.value.last, rashiGroup.value.first, linePaint);
        }
      }
    }

    // DRAW MOOD STARS
    for (int i = 0; i < starPoints.length; i++) {
      final pos = starPoints[i];
      final entry = starEntries[i];
      List<Color> colors = [];
      if (entry.moodPercentages.isNotEmpty) {
        entry.moodPercentages.forEach((key, val) {
          if (val > 0) colors.add(OrbPainter.getMoodColor(key));
        });
      }
      if (colors.isEmpty) {
        colors = [Color(entry.primaryColorValue), Color(entry.primaryColorValue)];
      } else if (colors.length == 1) colors.add(colors.first);

      canvas.drawCircle(pos, 24.0, Paint()..color = colors.first.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      canvas.drawCircle(pos, 10.0, Paint()..shader = SweepGradient(colors: colors).createShader(Rect.fromCircle(center: pos, radius: 10.0)));
      canvas.drawCircle(pos, 4.0, Paint()..color = Colors.white.withOpacity(0.95));
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxySpaceDriftPainter oldDelegate) => true;
}