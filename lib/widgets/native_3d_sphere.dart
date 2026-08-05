import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/mood_entry.dart';

class Native3DSphere extends StatefulWidget {
  final List<MoodEntry> entries;
  final ValueChanged<MoodEntry>? onBeadTap;
  final ValueChanged<MoodEntry>? onEntryTap;

  const Native3DSphere({
    Key? key,
    required this.entries,
    this.onBeadTap,
    this.onEntryTap,
  }) : super(key: key);

  @override
  State<Native3DSphere> createState() => _Native3DSphereState();
}

class _Native3DSphereState extends State<Native3DSphere>
    with SingleTickerProviderStateMixin {
  double _yaw = 0.0;
  double _pitch = 0.0;
  Offset _lastTouchPos = Offset.zero;

  late AnimationController _autoRotateController;

  @override
  void initState() {
    super.initState();
    _autoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..addListener(() {
        setState(() {
          _yaw += 0.005;
        });
      })
    ..repeat();
  }

  @override
  void dispose() {
    _autoRotateController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.2;
    final totalBeads = 100;
    final goldenRatio = (1 + math.sqrt(5)) / 2;

    MoodEntry? hitEntry;
    double closestDistance = 30.0;

    for (int i = 0; i < totalBeads; i++) {
      final y = 1 - (i / (totalBeads - 1)) * 2;
      final radiusAtY = math.sqrt(math.max(0, 1 - y * y));
      final theta = 2 * math.pi * i / goldenRatio;

      final x0 = math.cos(theta) * radiusAtY;
      final z0 = math.sin(theta) * radiusAtY;

      // Rotate around Pitch (X) and Yaw (Y)
      final x1 = x0;
      final y1 = y * math.cos(_pitch) - z0 * math.sin(_pitch);
      final z1 = y * math.sin(_pitch) + z0 * math.cos(_pitch);

      final x2 = x1 * math.cos(_yaw) + z1 * math.sin(_yaw);
      final y2 = y1;
      final z2 = -x1 * math.sin(_yaw) + z1 * math.cos(_yaw);

      // Project to 2D Screen
      final screenX = center.dx + x2 * radius;
      final screenY = center.dy + y2 * radius;
      final dist = (Offset(screenX, screenY) - details.localPosition).distance;

      // Only hit beads facing forward (z2 > -0.2)
      if (z2 > -0.2 && dist < closestDistance && i < widget.entries.length) {
        closestDistance = dist;
        hitEntry = widget.entries[i];
      }
    }

    if (hitEntry != null) {
      widget.onBeadTap?.call(hitEntry);
      widget.onEntryTap?.call(hitEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: (details) {
            _lastTouchPos = details.localPosition;
            _autoRotateController.stop();
          },
          onPanUpdate: (details) {
            final delta = details.localPosition - _lastTouchPos;
            setState(() {
              _yaw += delta.dx * 0.008;
              _pitch += delta.dy * 0.008;
            });
            _lastTouchPos = details.localPosition;
          },
          onPanEnd: (_) {
            _autoRotateController.repeat();
          },
          onTapUp: (details) => _handleTap(details, size),
          child: Container(
            color: const Color(0xFF121212),
            child: CustomPaint(
              size: size,
              painter: _SpherePainter(
                entries: widget.entries,
                yaw: _yaw,
                pitch: _pitch,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpherePainter extends CustomPainter {
  final List<MoodEntry> entries;
  final double yaw;
  final double pitch;

  _SpherePainter({
    required this.entries,
    required this.yaw,
    required this.pitch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.3;
    final totalBeads = 100;
    final goldenRatio = (1 + math.sqrt(5)) / 2;

    // Draw central glowing wireframe core
    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(center, radius, wirePaint);

    final points = <_Bead3D>[];

    for (int i = 0; i < totalBeads; i++) {
      final y = 1 - (i / (totalBeads - 1)) * 2;
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
      final z2 = -x1 * math.sin(yaw) + z1 * math.cos(yaw);

      final hasEntry = i < entries.length;
      final entry = hasEntry ? entries[i] : null;

      points.add(_Bead3D(
        x: x2,
        y: y2,
        z: z2,
        entry: entry,
      ));
    }

    // Sort by Z depth for 3D painter ordering
    points.sort((a, b) => a.z.compareTo(b.z));

    for (var bead in points) {
      final screenX = center.dx + bead.x * radius;
      final screenY = center.dy + bead.y * radius;
      final depthFactor = ((bead.z + 1) / 2.0).clamp(0.1, 1.0);

      final beadRadius = (10.0 + (depthFactor * 6.0));
      final opacity = (0.2 + (depthFactor * 0.8)).clamp(0.1, 1.0);

      final color = bead.entry != null
          ? Color(bead.entry!.primaryColorValue)
          : Colors.white.withOpacity(0.15);

      final beadPaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(screenX, screenY), beadRadius, beadPaint);

      // Glass specular highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(screenX - beadRadius * 0.3, screenY - beadRadius * 0.3),
        beadRadius * 0.35,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpherePainter oldDelegate) => true;
}

class _Bead3D {
  final double x, y, z;
  final MoodEntry? entry;

  _Bead3D({required this.x, required this.y, required this.z, this.entry});
}
