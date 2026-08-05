import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

class StarlightGalaxyView extends StatefulWidget {
  final List<MoodEntry> entries;
  final ValueChanged<MoodEntry> onEntryTap;

  const StarlightGalaxyView({
    super.key,
    required this.entries,
    required this.onEntryTap,
  });

  @override
  State<StarlightGalaxyView> createState() => _StarlightGalaxyViewState();
}

class _StarlightGalaxyViewState extends State<StarlightGalaxyView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final int _numBackgroundStars = 200;
  List<_StarPoint> _backgroundStars = [];
  List<_StarPoint> _moodStars = [];

  // Animation states
  double _viewRotationY = 0.0;
  double _viewRotationX = 0.0;
  Offset? _lastPanOffset;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat();
    _generateGalaxy();
  }

  @override
  void didUpdateWidget(StarlightGalaxyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _generateMoodStars(); // Regenerate mood stars if entries change
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateGalaxy() {
    // Generate static background stardust (vast 3D space volume)
    _backgroundStars = List.generate(_numBackgroundStars, (index) {
      return _StarPoint(
        x: (math.Random().nextDouble() - 0.5) * 1200,
        y: (math.Random().nextDouble() - 0.5) * 1200,
        z: (math.Random().nextDouble() - 0.5) * 1200,
        size: math.Random().nextDouble() * 2.5 + 0.5,
        opacity: math.Random().nextDouble() * 0.6 + 0.2,
      );
    });
    _generateMoodStars();
  }

  void _generateMoodStars() {
    // Generate star points for logged entries (closer volume)
    _moodStars = widget.entries.map((entry) {
      return _StarPoint(
        x: (math.Random().nextDouble() - 0.5) * 400,
        y: (math.Random().nextDouble() - 0.5) * 400,
        z: (math.Random().nextDouble() - 0.5) * 400,
        size: 8.0, // Base size, projected later
        opacity: 1.0,
        entry: entry,
      );
    }).toList();
  }

  // 3D Point projection helper (Vast Space perspective)
  Offset _project(double x, double y, double z, double width, double height) {
    double perspective = 1000 / (1000 + z);
    return Offset(
      (x * perspective) + width / 2,
      (y * perspective) + height / 2,
    );
  }

  void _handleTap(TapUpDetails details, Size size) {
    // Animate and rotate points based on current animation/drag rotation
    double angleY = _viewRotationY + (_animationController.value * 2 * math.pi * 0.2); // Slow drift
    double angleX = _viewRotationX;

    for (var star in _moodStars) {
      double x = star.x;
      double y = star.y;
      double z = star.z;

      // a. Apply 3D Rotations (Y-axis slow drift, then User X-axis drag)
      // Y-axis
      double nextX = x * math.cos(angleY) + z * math.sin(angleY);
      double nextZ = -x * math.sin(angleY) + z * math.cos(angleY);
      x = nextX;
      z = nextZ;

      // X-axis
      double nextY = y * math.cos(angleX) - z * math.sin(angleX);
      nextZ = y * math.sin(angleX) + z * math.cos(angleX);
      y = nextY;
      z = nextZ;

      // b. Project to 2D screen coordinates
      Offset projected = _project(x, y, z, size.width, size.height);
      
      // c. perspective scaling for radius (needed for hit test)
      double perspectiveFactor = 1000 / (1000 + z);
      double scaledRadius = star.size * perspectiveFactor;

      // d. Check if tap is within glowing star vicinity
      // Stars are small, so we use a wider tap target (32px radius)
      if ((details.localPosition - projected).distance <= math.max(scaledRadius * 2, 24.0)) {
        widget.onEntryTap(star.entry!);
        return; // Stop checking after finding the first hit
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
            _lastPanOffset = details.localPosition;
          },
          onPanUpdate: (details) {
            if (_lastPanOffset != null) {
              setState(() {
                // Adjust pan sensitivity for vast space
                _viewRotationY += (details.localPosition.dx - _lastPanOffset!.dx) * 0.003;
                _viewRotationX += (details.localPosition.dy - _lastPanOffset!.dy) * 0.003;
                _lastPanOffset = details.localPosition;
              });
            }
          },
          onPanEnd: (_) {
            _lastPanOffset = null;
          },
          onTapUp: (details) => _handleTap(details, size),
          child: Container(
            color: const Color(0xFF05050B), // Deep space background
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _GalaxyPainter(
                    backgroundStars: _backgroundStars,
                    moodStars: _moodStars,
                    animationValue: _animationController.value,
                    viewRotationX: _viewRotationX,
                    viewRotationY: _viewRotationY,
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

class _StarPoint {
  final double x, y, z;
  final double size;
  final double opacity;
  final MoodEntry? entry;

  _StarPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.opacity,
    this.entry,
  });
}

class _GalaxyPainter extends CustomPainter {
  final List<_StarPoint> backgroundStars;
  final List<_StarPoint> moodStars;
  final double animationValue;
  final double viewRotationX;
  final double viewRotationY;

  _GalaxyPainter({
    required this.backgroundStars,
    required this.moodStars,
    required this.animationValue;
    required this.viewRotationX;
    required this.viewRotationY;
  });

  // 3D Point projection helper (Vast Space perspective)
  Offset _project(double x, double y, double z, double width, double height) {
    double perspective = 1000 / (1000 + z);
    return Offset(
      (x * perspective) + width / 2,
      (y * perspective) + height / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Continuous slow drift animation angle
    double driftAngleY = viewRotationY + (animationValue * 2 * math.pi * 0.2);
    double rotateAngleX = viewRotationX;

    // 1. Process Background Stars
    final bgPaint = Paint()..style = PaintingStyle.fill;
    for (var star in backgroundStars) {
      double x = star.x;
      double y = star.y;
      double z = star.z;

      // Apply rotations (Drift Y, then User X)
      double nextX = x * math.cos(driftAngleY) + z * math.sin(driftAngleY);
      double nextZ = -x * math.sin(driftAngleY) + z * math.cos(driftAngleY);
      x = nextX;
      z = nextZ;

      double nextY = y * math.cos(rotateAngleX) - z * math.sin(rotateAngleX);
      nextZ = y * math.sin(rotateAngleX) + z * math.cos(rotateAngleX);
      y = nextY;
      z = nextZ;

      // Depth check (vast volume z ∈ [-600, 600])
      if (z > 600) continue; // Clipped behind view volume

      Offset projected = _project(x, y, z, size.width, size.height);

      // Perspective scaling
      double perspectiveFactor = 1000 / (1000 + z);
      double scaledSize = star.size * perspectiveFactor;
      
      // Depth fading (distant = dimmer)
      double depthOpacity = star.opacity * ((600 - z) / 1200).clamp(0.1, 1.0);

      // Draw faint background dot
      canvas.drawCircle(
        projected,
        scaledSize,
        bgPaint..color = Colors.white.withOpacity(depthOpacity),
      );
    }

    // 2. Process Mood Stars (Glowing celestial bodies closer volume z ∈ [-200, 200])
    // Collect projected points for sorting (Painter's algorithm front-to-back sorting not critical here due to additive blending but useful for future depth mapping)
    List<_ProjectedStar> projectedMoodStars = [];

    for (var star in moodStars) {
      double x = star.x;
      double y = star.y;
      double z = star.z;

      // Apply rotations
      double nextX = x * math.cos(driftAngleY) + z * math.sin(driftAngleY);
      double nextZ = -x * math.sin(driftAngleY) + z * math.cos(driftAngleY);
      x = nextX;
      z = nextZ;

      double nextY = y * math.cos(rotateAngleX) - z * math.sin(rotateAngleX);
      nextZ = y * math.sin(rotateAngleX) + z * math.cos(rotateAngleX);
      y = nextY;
      z = nextZ;

      Offset projected = _project(x, y, z, size.width, size.height);
      
      projectedMoodStars.add(_ProjectedStar(
        point: projected,
        depth: z,
        entry: star.entry!,
        baseSize: star.size,
      ));
    }

    // 3. Paint Mood Stars (Glowing Orbs)
    // Additive blending looks good for stars
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint().You are getting this build error on GitHub because `HomeScreen` is trying to pass a parameter called `onEntryTap` to `Native3DSphere` and `StarlightGalaxyView`, but the constructors of these widgets haven't been updated to accept it.

The Antigravity super-prompt below provides the full, corrected code for both widgets. Updating **`lib/widgets/native_3d_sphere.dart`** and **`lib/widgets/starlight_galaxy_view.dart`** on GitHub will resolve these compiler errors by enabling the widgets to accept and handle entry taps.

### Copy & Paste into Antigravity Agent Manager:

```text
Update the two 3D visual engines to accept the `onEntryTap` callback required by `HomeScreen`, and implement hit-detection logic within the `GestureDetectors`.

====================================================================
1. UPDATE `lib/widgets/native_3d_sphere.dart` (Full File)
====================================================================
Replace entire file. Add `final ValueChanged<MoodEntry> onEntryTap` to the widget constructor (required). Implement `onTapUp` within the `GestureDetector`. Use 3D-to-2D point projection (project current rotation angles Y and X) within `GestureDetector` to check if the tap coordinate is within the radius of any displayed orb that has an associated `MoodEntry`. Call `widget.onEntryTap(entry)` upon a successful hit. Retain full CustomPainter 3D spiral rendering, rotation matrix inertia, and glass bead textures.

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

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
    // Match entries to specific bead indices (Fibonacci spiral fallback)
    final now = DateTime.now();
    
    // Animate and rotate points based on current rotation
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
      // Beads are small, so we use a wider tap target (1.5x radius)
      if ((details.localPosition - projected).distance <= _beadRadius * 1.5) {
        
        // e. Check if this bead has an entry (mapping fallback for demo)
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
        // Render Painted Orb glow core
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

        // Glass border shine overlay
        canvas.drawCircle(
          bead.point,
          scaledRadius,
          glassBorderPaint..color = Colors.white.withOpacity(0.4 * depthOpacity),
        );
      } else {
        // Render empty translucent glass bead
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
