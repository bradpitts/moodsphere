import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/mood_entry.dart';

class StarlightGalaxyView extends StatefulWidget {
  final List<MoodEntry> entries;
  final Function(MoodEntry entry) onStarTap;

  const StarlightGalaxyView({
    Key? key,
    required this.entries,
    required this.onStarTap,
  }) : super(key: key);

  @override
  State<StarlightGalaxyView> createState() => _StarlightGalaxyViewState();
}

class _StarlightGalaxyViewState extends State<StarlightGalaxyView>
    with SingleTickerProviderStateMixin {
  double _yaw = 0.0;
  double _pitch = 0.0;
  double _scale = 1.0;
  Offset _lastTouch = Offset.zero;

  late AnimationController _twinkleController;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onScaleStart: (details) {
            _lastTouch = details.focalPoint;
          },
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_scale * details.scale).clamp(0.6, 2.5);
              final delta = details.focalPoint - _lastTouch;
              _yaw += delta.dx * 0.006;
              _pitch += delta.dy * 0.006;
              _lastTouch = details.focalPoint;
            });
          },
          child: Container(
            color: const Color(0xFF05050B),
            child: AnimatedBuilder(
              animation: _twinkleController,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _GalaxyConstellationPainter(
                    entries: widget.entries,
                    yaw: _yaw,
                    pitch: _pitch,
                    scale: _scale,
                    twinkle: _twinkleController.value,
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

class _GalaxyConstellationPainter extends CustomPainter {
  final List<MoodEntry> entries;
  final double yaw;
  final double pitch;
  final double scale;
  final double twinkle;

  _GalaxyConstellationPainter({
    required this.entries,
    required this.yaw,
    required this.pitch,
    required this.scale,
    required this.twinkle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5 * scale;

    // 1. Render 150+ Background Twinkling Stardust Particles
    final starRandom = math.Random(42);
    for (int i = 0; i < 160; i++) {
      final sx = (starRandom.nextDouble() - 0.5) * size.width * 1.5 + center.dx;
      final sy = (starRandom.nextDouble() - 0.5) * size.height * 1.5 + center.dy;
      final sSize = starRandom.nextDouble() * 2.2 + 0.5;
      final opacity = ((starRandom.nextDouble() + twinkle) / 2.0).clamp(0.15, 0.7);

      final starPaint = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(sx, sy), sSize, starPaint);
    }

    if (entries.isEmpty) return;

    // 2. Project Logged Mood Entries into 3D Constellation Stars
    final starPoints = <Offset>[];
    final starColors = <Color>[];

    final goldenRatio = (1 + math.sqrt(5)) / 2;

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final y = 1 - (i / math.max(1, entries.length - 1)) * 1.8;
      final radiusAtY = math.sqrt(math.max(0, 1 - y * y));
      final theta = 2 * math.pi * i / goldenRatio;

      final x0 = math.cos(theta) * radiusAtY;
      final z0 = math.sin(theta) * radiusAtY;

      // 3D Matrix Rotations
      final x1 = x0;
      final y1 = y * math.cos(pitch) - z0 * math.sin(pitch);
      final z1 = y * math.sin(pitch) + z0 * math.cos(pitch);

      final x2 = x1 * math.cos(yaw) + z1 * math.sin(yaw);
      final y2 = y1;

      final screenPos = Offset(center.dx + x2 * radius, center.dy + y2 * radius);
      starPoints.add(screenPos);
      starColors.add(Color(entry.primaryColorValue));
    }

    // 3. Draw Glowing Stardust Constellation Lines Connecting Consecutive Logged Stars
    for (int i = 0; i < starPoints.length - 1; i++) {
      final linePaint = Paint()
        ..color = starColors[i].withOpacity(0.35)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final lineGlowPaint = Paint()
        ..color = starColors[i].withOpacity(0.15)
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawLine(starPoints[i], starPoints[i + 1], lineGlowPaint);
      canvas.drawLine(starPoints[i], starPoints[i + 1], linePaint);
    }

    // 4. Draw Mood Entry Stars with Radial Shaders & Glows
    for (int i = 0; i < starPoints.length; i++) {
      final pos = starPoints[i];
      final color = starColors[i];

      // Ambient radial light glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.2),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: 18));
      canvas.drawCircle(pos, 18, glowPaint);

      // Star core
      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(pos, 5, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyConstellationPainter oldDelegate) => true;
}
