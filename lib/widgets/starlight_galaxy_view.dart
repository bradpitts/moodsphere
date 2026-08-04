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
  double _userYaw = 0.0;
  double _userPitch = 0.0;
  double _scale = 1.0;
  Offset _lastTouch = Offset.zero;

  late AnimationController _rotationTickerController;

  @override
  void initState() {
    super.initState();
    // Continuous 60 FPS Ticker Animation Controller for Cosmic Slow Motion
    _rotationTickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationTickerController.dispose();
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
              _userYaw += delta.dx * 0.006;
              _userPitch += delta.dy * 0.006;
              _lastTouch = details.focalPoint;
            });
          },
          child: Container(
            color: const Color(0xFF05050B),
            child: AnimatedBuilder(
              animation: _rotationTickerController,
              builder: (context, child) {
                // Combine continuous cosmic background rotation with user touch rotation
                final cosmicAutoYaw = _rotationTickerController.value * 2 * math.pi;
                final totalYaw = _userYaw + cosmicAutoYaw * 0.15;
                final totalPitch = _userPitch + math.sin(cosmicAutoYaw) * 0.05;

                return CustomPaint(
                  size: size,
                  painter: _GalaxyConstellationPainter(
                    entries: widget.entries,
                    yaw: totalYaw,
                    pitch: totalPitch,
                    scale: _scale,
                    tickerVal: _rotationTickerController.value,
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
  final double tickerVal;

  _GalaxyConstellationPainter({
    required this.entries,
    required this.yaw,
    required this.pitch,
    required this.scale,
    required this.tickerVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5 * scale;

    // 1. Render 180+ Background Twinkling & Rotating Stardust Particles
    final starRandom = math.Random(42);
    for (int i = 0; i < 180; i++) {
      final baseAngle = starRandom.nextDouble() * 2 * math.pi;
      final distRadius = starRandom.nextDouble() * size.width * 0.7;
      final currentAngle = baseAngle + yaw * 0.3;

      final sx = center.dx + math.cos(currentAngle) * distRadius;
      final sy = center.dy + math.sin(currentAngle + pitch * 0.2) * distRadius * 0.8;

      final sSize = starRandom.nextDouble() * 2.2 + 0.6;
      final twinkleVal = math.sin((tickerVal * 2 * math.pi) + i) * 0.3 + 0.5;

      final starPaint = Paint()
        ..color = Colors.white.withOpacity(twinkleVal.clamp(0.15, 0.8));
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

    // 3. Shimmering Stardust Constellation Lines Linking Consecutive Stars
    for (int i = 0; i < starPoints.length - 1; i++) {
      final shimmerOpacity = (0.2 + (math.sin(tickerVal * 2 * math.pi + i) * 0.15)).clamp(0.1, 0.45);

      final linePaint = Paint()
        ..color = starColors[i].withOpacity(shimmerOpacity)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final lineGlowPaint = Paint()
        ..color = starColors[i].withOpacity(0.15)
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawLine(starPoints[i], starPoints[i + 1], lineGlowPaint);
      canvas.drawLine(starPoints[i], starPoints[i + 1], linePaint);
    }

    // 4. Multi-Layered Glowing Star Shaders & Warm Red Atmospheric Halos
    for (int i = 0; i < starPoints.length; i++) {
      final pos = starPoints[i];
      final color = starColors[i];

      // Outer Warm/Red Glowing Atmospheric Aura Shader
      final warmAuraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF5A5F).withOpacity(0.35),
            color.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: 26))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(pos, 26, warmAuraPaint);

      // Inner Primary Color Radial Light Halo Shader
      final innerHaloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: 14));

      canvas.drawCircle(pos, 14, innerHaloPaint);

      // Shining Star Core
      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(pos, 5.5, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyConstellationPainter oldDelegate) => true;
}
