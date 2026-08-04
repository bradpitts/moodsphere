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

  void _handleTapUp(TapUpDetails details, Size size) {
    if (widget.entries.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5 * _scale;
    final goldenRatio = (1 + math.sqrt(5)) / 2;

    final cosmicAutoYaw = _rotationTickerController.value * 2 * math.pi;
    final yaw = _userYaw + cosmicAutoYaw * 0.15;
    final pitch = _userPitch + math.sin(cosmicAutoYaw) * 0.05;

    MoodEntry? tappedEntry;
    double minDistance = 32.0; // 32px hit radius threshold

    for (int i = 0; i < widget.entries.length; i++) {
      final entry = widget.entries[i];
      final y = 1 - (i / math.max(1, widget.entries.length - 1)) * 1.8;
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
      final dist = (details.localPosition - screenPos).distance;

      if (dist < minDistance) {
        minDistance = dist;
        tappedEntry = entry;
      }
    }

    if (tappedEntry != null) {
      widget.onStarTap(tappedEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapUp: (details) => _handleTapUp(details, size),
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

    // 1. Rich Deep Space Nebula Universe Backdrop (Indigo #0B001A, Magenta #1A002C, Navy #020B1A)
    final nebulaPaint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        radius: 1.2,
        colors: [
          const Color(0xFF1A002C).withOpacity(0.75), // Cosmic Magenta
          const Color(0xFF0B001A).withOpacity(0.55), // Deep Indigo
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebulaPaint1);

    final nebulaPaint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.5, 0.4),
        radius: 1.3,
        colors: [
          const Color(0xFF020B1A).withOpacity(0.85), // Deep Navy
          const Color(0xFF0B001A).withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebulaPaint2);

    // 2. Multilayered Star Field (1px to 3.5px) with Opacity Twinkling
    final starRandom = math.Random(42);
    for (int i = 0; i < 200; i++) {
      final baseAngle = starRandom.nextDouble() * 2 * math.pi;
      final distRadius = starRandom.nextDouble() * size.width * 0.8;
      final currentAngle = baseAngle + yaw * 0.25;

      final sx = center.dx + math.cos(currentAngle) * distRadius;
      final sy = center.dy + math.sin(currentAngle + pitch * 0.2) * distRadius * 0.8;

      final sSize = starRandom.nextDouble() * 2.5 + 1.0;
      final twinkleVal = math.sin((tickerVal * 2 * math.pi) + i) * 0.35 + 0.55;

      final starPaint = Paint()
        ..color = Colors.white.withOpacity(twinkleVal.clamp(0.2, 0.9));
      canvas.drawCircle(Offset(sx, sy), sSize, starPaint);
    }

    if (entries.isEmpty) return;

    // 3. Project Logged Mood Entries into 3D Independent Celestial Mood Stars (No Connecting Lines)
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

    // 4. Render Independent Celestial Mood Stars with Glowing Radial Light Halos
    for (int i = 0; i < starPoints.length; i++) {
      final pos = starPoints[i];
      final color = starColors[i];

      // Multi-layered radial light halo shader
      final outerHaloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.75),
            color.withOpacity(0.25),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: 24))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(pos, 24, outerHaloPaint);

      // Inner Core Highlight
      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(pos, 5.5, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyConstellationPainter oldDelegate) => true;
}
