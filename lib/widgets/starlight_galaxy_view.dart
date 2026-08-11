import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/mood_entry.dart';

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

class _StarlightGalaxyViewState extends State<StarlightGalaxyView>
    with SingleTickerProviderStateMixin {
  double _userYaw = 0.0;
  double _userPitch = 0.0;
  double _scale = 1.0;
  Offset _lastTouch = Offset.zero;

  late AnimationController _spaceDriftController;

  @override
  void initState() {
    super.initState();
    // Continuous 60 FPS Space Drift Ticker Animation
    _spaceDriftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
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
    final goldenRatio = (1 + math.sqrt(5)) / 2;

    final driftVal = _spaceDriftController.value * 2 * math.pi;
    final yaw = _userYaw + driftVal * 0.12;
    final pitch = _userPitch + math.sin(driftVal) * 0.04;

    MoodEntry? tappedEntry;
    double minDistance = 32.0;

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
              animation: _spaceDriftController,
              builder: (context, child) {
                final driftVal = _spaceDriftController.value;
                final totalYaw = _userYaw + driftVal * 2 * math.pi * 0.12;
                final totalPitch = _userPitch + math.sin(driftVal * 2 * math.pi) * 0.04;

                return CustomPaint(
                  size: size,
                  painter: _GalaxySpaceDriftPainter(
                    entries: widget.entries,
                    yaw: totalYaw,
                    pitch: totalPitch,
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

    // 1. Render 5 Parallax Nebula Dust Clouds Drifting & Looping Across Screen Boundaries
    _drawParallaxDustClouds(canvas, size);

    // 2. Render 220 Background Stars Scattered Uniformly Across Vast 3D Volume [-600, 600]
    final starRandom = math.Random(101);
    final driftOffsetZ = (driftVal * 300) % 600;

    for (int i = 0; i < 220; i++) {
      // Uniform 3D Cartesian coordinates in [-600, 600]
      final rawX = (starRandom.nextDouble() - 0.5) * 1200;
      final rawY = (starRandom.nextDouble() - 0.5) * 1200;
      final rawZ = (starRandom.nextDouble() - 0.5) * 1200 + driftOffsetZ;

      // Wrap Z depth seamlessly
      final wrappedZ = ((rawZ + 600) % 1200) - 600;

      // 3D Matrix Yaw/Pitch rotation
      final rotX = rawX * math.cos(yaw) - wrappedZ * math.sin(yaw);
      final rotZ = rawX * math.sin(yaw) + wrappedZ * math.cos(yaw);
      final rotY = rawY * math.cos(pitch) - rotZ * math.sin(pitch);

      final perspectiveFactor = (800.0 / (800.0 + rotZ)).clamp(0.2, 2.0);
      final sx = center.dx + rotX * perspectiveFactor * 0.7;
      final sy = center.dy + rotY * perspectiveFactor * 0.7;

      if (sx >= -20 && sx <= size.width + 20 && sy >= -20 && sy <= size.height + 20) {
        final sSize = (starRandom.nextDouble() * 2.0 + 0.8) * perspectiveFactor;
        final twinkle = math.sin((driftVal * 4 * math.pi) + i) * 0.35 + 0.55;

        final starPaint = Paint()
          ..color = Colors.white.withOpacity(twinkle.clamp(0.15, 0.9));
        canvas.drawCircle(Offset(sx, sy), sSize, starPaint);
      }
    }

    if (entries.isEmpty) return;

    // 3. Project Mood Entries into 3D Independent Celestial Stars (No Lines)
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

    // 4. Render Mood Stars with Multi-Layered Radial Light Halos
    for (int i = 0; i < starPoints.length; i++) {
      final pos = starPoints[i];
      final primaryColor = starColors[i];

      // Outer ambient atmospheric glow halo
      canvas.drawCircle(
        pos,
        28.0,
        Paint()
          ..color = primaryColor.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );

      // Inner color core
      canvas.drawCircle(
        pos,
        14.0,
        Paint()
          ..color = primaryColor.withOpacity(0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Bright central hot spot
      canvas.drawCircle(
        pos,
        6.0,
        Paint()..color = Colors.white.withOpacity(0.95),
      );
    }
  }

  void _drawParallaxDustClouds(Canvas canvas, Size size) {
    // 5 Parallax Nebula Dust Cloud Layers drifting at varied speeds across screen boundaries
    final clouds = [
      // Cosmic Purple #2A004F
      _DustCloudSpec(
        baseCenter: Offset(size.width * 0.2, size.height * 0.3),
        radius: size.width * 0.7,
        color: const Color(0xFF2A004F),
        speedX: 0.25,
        speedY: 0.1,
      ),
      // Deep Teal #002A38
      _DustCloudSpec(
        baseCenter: Offset(size.width * 0.75, size.height * 0.65),
        radius: size.width * 0.8,
        color: const Color(0xFF002A38),
        speedX: -0.3,
        speedY: 0.15,
      ),
      // Magenta #3B0029
      _DustCloudSpec(
        baseCenter: Offset(size.width * 0.4, size.height * 0.8),
        radius: size.width * 0.65,
        color: const Color(0xFF3B0029),
        speedX: 0.35,
        speedY: -0.2,
      ),
      // Indigo Nebula
      _DustCloudSpec(
        baseCenter: Offset(size.width * 0.85, size.height * 0.25),
        radius: size.width * 0.6,
        color: const Color(0xFF16003B),
        speedX: -0.2,
        speedY: -0.15,
      ),
    ];

    for (var cloud in clouds) {
      // Parallax drifting & looping offset math
      final offsetX = (driftVal * size.width * cloud.speedX) % (size.width * 1.4);
      final offsetY = (driftVal * size.height * cloud.speedY) % (size.height * 1.4);

      final currentPos = Offset(
        (cloud.baseCenter.dx + offsetX) % (size.width + cloud.radius) - (cloud.radius * 0.5),
        (cloud.baseCenter.dy + offsetY) % (size.height + cloud.radius) - (cloud.radius * 0.5),
      );

      final cloudPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            cloud.color.withOpacity(0.55),
            cloud.color.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: currentPos, radius: cloud.radius));

      canvas.drawCircle(currentPos, cloud.radius, cloudPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxySpaceDriftPainter oldDelegate) => true;
}

class _DustCloudSpec {
  final Offset baseCenter;
  final double radius;
  final Color color;
  final double speedX;
  final double speedY;

  _DustCloudSpec({
    required this.baseCenter,
    required this.radius,
    required this.color,
    required this.speedX,
    required this.speedY,
  });
}
