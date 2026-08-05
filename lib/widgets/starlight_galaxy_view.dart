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
    // Generate static background stardust (vast 3D space volume ∈ [-600, 600])
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
    // Generate glowing celestial bodies closer to view (volume z ∈ [-200, 200])
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
    // Continuous slow drift animation angle
    double angleY = _viewRotationY + (_animationController.value * 2 * math.pi * 0.2);
    double angleX = _viewRotationX;

    for (var star in _moodStars) {
      double x = star.x;
      double y = star.y;
      double z = star.z;

      // a. Apply Rotations (Slow Drift Y-axis, User X-axis drag)
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
      // Stars are small visual targets, so we use a wider tap target (32px radius)
      if ((details.localPosition - projected).distance <= math.max(scaledRadius * 2, 32.0)) {
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
                // Adjust pan sensitivity for vast space volume drift
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
            color: const Color(0xFF05050B), // Deep space black
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
    required this.animationValue,
    required this.viewRotationX,
    required this.viewRotationY,
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
    // Process Y-axis drift and X-axis rotation angles
    double driftAngleY = viewRotationY + (animationValue * 2 * math.pi * 0.2);
    double rotateAngleX = viewRotationX;

    // 1. Process Background Stars
    final bgPaint = Paint()..style = PaintingStyle.fill;
    for (var star in backgroundStars) {
      double x = star.x;
      double y = star.y;
      double z = star.z;

      // Apply rotations (Slow drift Y, User X)
      double nextX = x * math.cos(driftAngleY) + z * math.sin(driftAngleY);
      double nextZ = -x * math.sin(driftAngleY) + z * math.cos(driftAngleY);
      x = nextX;
      z = nextZ;

      double nextY = y * math.cos(rotateAngleX) - z * math.sin(rotateAngleX);
      nextZ = y * math.sin(rotateAngleX) + z * math.cos(rotateAngleX);
      y = nextY;
      z = nextZ;

      // Depth clipping forward check (volume z ∈ [-600, 600])
      if (z > 600) continue; 

      Offset projected = _project(x, y, z, size.width, size.height);

      // Perspective scaling and depth fading
      double perspectiveFactor = 1000 / (1000 + z);
      double scaledSize = star.size * perspectiveFactor;
      double depthOpacity = star.opacity * ((600 - z) / 1200).clamp(0.1, 1.0);

      // Draw random background stardust dot
      canvas.drawCircle(
        projected,
        scaledSize,
        bgPaint..color = Colors.white.withOpacity(depthOpacity),
      );
    }

    // 2. Process Mood Stars (Additively blended glowing celestial bodies Closer Volume)
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..blendMode = BlendMode.plus);

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
      
      // perspective scaling and depth fading (volume z ∈ [-200, 200])
      double perspectiveFactor = 1000 / (1000 + z);
      double scaledRadius = 8.0 * perspectiveFactor; // base size 8.0
      double depthOpacity = ((300 - z) / 500).clamp(0.3, 1.0);

      final primaryColor = Color(star.entry!.primaryColorValue);

      // Render glowing star (additive blending)
      // Ambient warm glow atmospheric aura
      canvas.drawCircle(
        projected,
        scaledRadius * 2.5,
        Paint()
          ..color = primaryColor.withOpacity(0.4 * depthOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Inner glow core
      canvas.drawCircle(
        projected,
        scaledRadius * 1.5,
        Paint()
          ..color = primaryColor.withOpacity(0.7 * depthOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Bright white central hot spot core
      canvas.drawCircle(
        projected,
        scaledRadius * 0.7,
        Paint()
          ..color = Colors.white.withOpacity(0.9 * depthOpacity),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.viewRotationX != viewRotationX ||
           oldDelegate.viewRotationY != viewRotationY ||
           oldDelegate.moodStars != moodStars;
  }
}
