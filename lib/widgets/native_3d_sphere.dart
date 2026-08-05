import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import 'orb_painter.dart'; // Assuming OrbPainter is used for bead textures

class Native3DSphere extends StatefulWidget {
  final List<MoodEntry> entries;
  final ValueChanged<MoodEntry> onEntryTap;

  const Native3DSphere({
    super.key,
    required this.entries,
    required this.onEntryTap,
  });

  @override
  State<Native3DSphere> createState() => _Native3DSphereState();
}

class _Native3DSphereState extends State<Native3DSphere> with SingleTickerProviderStateMixin {
  late AnimationController _autoRotationController;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  Offset? _lastPanOffset;

  // Sphere parameters
  final int _totalBeads = 100;
  final double _sphereRadius = 120.0;
  final double _beadRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _autoRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _autoRotationController.dispose();
    super.dispose();
  }

  // 3D Point projection helper
  Offset _project(double x, double y, double z, double width, double height) {
    // Basic perspective projection
    double perspective = 500 / (500 + z);
    return Offset(
      (x * perspective) + width / 2,
      (y * perspective) + height / 2,
    );
  }

  void _handleTap(TapUpDetails details, Size size) {
    // 1. Map entries to specific bead indices (Fibonacci spiral)
    // For simplicity, we match by date index.
    final now = DateTime.now();
    
    // 2. Animate and rotate points based on current rotation
    double angleY = _rotationY + (_autoRotationController.value * 2 * math.pi);
    double angleX = _rotationX;

    for (int i = 0; i < _totalBeads; i++) {
      // a. Calculate base Fibonacci point
      double y = 1 - (i / (_totalBeads - 1)) * 2;
      double radiusAtY = math.sqrt(1 - y * y);
      double theta = (math.pi * (1 + math.sqrt(5))) * i;
      double x = math.cos(theta) * radiusAtY;
      double z = math.sin(theta) * radiusAtY;

      // Scale to sphere radius
      x *= _sphereRadius;
      y *= _sphereRadius;
      z *= _sphereRadius;

      // b. Apply 3D Rotations (Y-axis, then X-axis)
      // Y-axis rotation
      double nextX = x * math.cos(angleY) + z * math.sin(angleY);
      double nextZ = -x * math.sin(angleY) + z * math.cos(angleY);
      x = nextX;
      z = nextZ;

      // X-axis rotation
      double nextY = y * math.cos(angleX) - z * math.sin(angleX);
      nextZ = y * math.sin(angleX) + z * math.cos(angleX);
      y = nextY;
      z = nextZ;

      // c. Project to 2D screen coordinates
      Offset projected = _project(x, y, z, size.width, size.height);

      // d. Check if tap is within bead radius (hit detection)
      if ((details.localPosition - projected).distance <= _beadRadius * 1.5) {
        // e. Check if this bead has an entry (simple mapping based on date index for demo)
        // In production, MoodEntry should store its intended bead index.
        final targetDate = now.subtract(Duration(days: i));
        final MoodEntry? match = widget.entries.where((e) {
          return e.date.year == targetDate.year &&
                 e.date.month == targetDate.month &&
                 e.date.day == targetDate.day;
        }).firstOrNull;

        if (match != null) {
          widget.onEntryTap(match);
          return; // Stop checking after finding the first hit
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: (details) {
            _autoRotationController.stop();
            _lastPanOffset = details.localPosition;
          },
          onPanUpdate: (details) {
            if (_lastPanOffset != null) {
              setState(() {
                // Adjust sensitivity
                _rotationY += (details.localPosition.dx - _lastPanOffset!.dx) * 0.01;
                _rotationX += (details.localPosition.dy - _lastPanOffset!.dy) * 0.01;
                _lastPanOffset = details.localPosition;
              });
            }
          },
          onPanEnd: (_) {
            _lastPanOffset = null;
            _autoRotationController.repeat();
          },
          onTapUp: (details) => _handleTap(details, size),
          child: Container(
            color: Colors.transparent, // Ensure full area is tappable
            child: AnimatedBuilder(
              animation: _autoRotationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _SpherePainter(
                    entries: widget.entries,
                    rotationX: _rotationX,
                    rotationY: _rotationY + (_autoRotationController.value * 2 * math.pi),
                    sphereRadius: _sphereRadius,
                    beadRadius: _beadRadius,
                    totalBeads: _totalBeads,
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

class _SpherePainter extends CustomPainter {
  final List<MoodEntry> entries;
  final double rotationX;
  final double rotationY;
  final double sphereRadius;
  final double beadRadius;
  final int totalBeads;

  _SpherePainter({
    required this.entries,
    required this.rotationX,
    required this.rotationY,
    required this.sphereRadius,
    required this.beadRadius,
    required this.totalBeads,
  });

  // 3D Point projection helper
  Offset _project(double x, double y, double z, double width, double height) {
    double perspective = 500 / (500 + z);
    return Offset(
      (x * perspective) + width / 2,
      (y * perspective) + height / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    // 1. Calculate and store all projected points with depth
    List<_BeadProjected> projectedBeads = [];

    for (int i = 0; i < totalBeads; i++) {
      // Fibonacci spiral point distribution
      double y = 1 - (i / (totalBeads - 1)) * 2;
      double radiusAtY = math.sqrt(1 - y * y);
      double theta = (math.pi * (1 + math.sqrt(5))) * i;
      double x = math.cos(theta) * radiusAtY;
      double z = math.sin(theta) * radiusAtY;

      // Scale to sphere radius
      x *= sphereRadius;
      y *= sphereRadius;
      z *= sphereRadius;

      // 3D Rotations
      // Y-axis
      double nextX = x * math.cos(rotationY) + z * math.sin(rotationY);
      double nextZ = -x * math.sin(rotationY) + z * math.cos(rotationY);
      x = nextX;
      z = nextZ;

      // X-axis
      double nextY = y * math.cos(rotationX) - z * math.sin(rotationX);
      nextZ = y * math.sin(rotationX) + z * math.cos(rotationX);
      y = nextY;
      z = nextZ;

      // Match entry (simple date fallback for demo)
      final targetDate = now.subtract(Duration(days: i));
      final MoodEntry? match = entries.where((e) {
        return e.date.year == targetDate.year &&
               e.date.month == targetDate.month &&
               e.date.day == targetDate.day;
      }).firstOrNull;

      // Project
      Offset projectedPoint = _project(x, y, z, size.width, size.height);
      
      projectedBeads.add(_BeadProjected(
        point: projectedPoint,
        depth: z, // Used for sorting and scaling
        entry: match,
      ));
    }

    // 2. Sort beads by depth ( Painter's Algorithm: back to front)
    projectedBeads.sort((a, b) => b.depth.compareTo(a.depth));

    // 3. Paint beads
    final glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final glassBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var bead in projectedBeads) {
      // Perspective scaling for radius
      double perspectiveFactor = 500 / (500 + bead.depth);
      double scaledRadius = beadRadius * perspectiveFactor;

      // Transparency fades based on depth (distant = dimmer)
      double depthOpacity = ((sphereRadius - bead.depth) / (2 * sphereRadius)).clamp(0.2, 1.0);

      if (bead.entry != null) {
        // Render Painted Orb (Texture)
        // For simplicity in this example, we paint a solid glow.
        // Production should use the pre-rendered texture image.
        final primaryColor = Color(bead.entry!.primaryColorValue);
        
        // Ambient glow
        canvas.drawCircle(
          bead.point,
          scaledRadius * 1.8,
          Paint()
            ..color = primaryColor.withOpacity(0.3 * depthOpacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );

        // Core color
        canvas.drawCircle(
          bead.point,
          scaledRadius,
          Paint()..color = primaryColor.withOpacity(depthOpacity),
        );

        // Glass specular shine overlay
        canvas.drawCircle(
          bead.point,
          scaledRadius,
          glassBorderPaint..color = Colors.white.withOpacity(0.4 * depthOpacity),
        );
      } else {
        // Render empty glass bead
        canvas.drawCircle(bead.point, scaledRadius, glassPaint..color = Colors.white.withOpacity(0.1 * depthOpacity));
        canvas.drawCircle(bead.point, scaledRadius, glassBorderPaint..color = Colors.white.withOpacity(0.2 * depthOpacity));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpherePainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
           oldDelegate.rotationY != rotationY ||
           oldDelegate.entries != entries;
  }
}

class _BeadProjected {
  final Offset point;
  final double depth;
  final MoodEntry? entry;

  _BeadProjected({
    required this.point,
    required this.depth,
    this.entry,
  });
}
