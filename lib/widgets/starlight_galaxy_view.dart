import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

class StarlightGalaxyView extends StatefulWidget {
  final List<MoodEntry> entries;
  final ValueChanged<MoodEntry>? onEntryTap;

  const StarlightGalaxyView({
    super.key,
    required this.entries,
    this.onEntryTap,
  });

  @override
  State<StarlightGalaxyView> createState() => _StarlightGalaxyViewState();
}

class _StarlightGalaxyViewState extends State<StarlightGalaxyView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final int _numBackgroundStars = 200;
  List<_StarPoint> _backgroundStars = [];
  List<_StarPoint> _moodStars = [];

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
      _generateMoodStars();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateGalaxy() {
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
    _moodStars = widget.entries.map((entry) {
      return _StarPoint(
        x: (math.Random().nextDouble() - 0.5) * 400,
        y: (math.Random().nextDouble() - 0.5) * 400,
        z: (math.Random().nextDouble() - 0.5) * 400,
        size: 8.0,
        opacity: 1.0,
        entry: entry,
      );
    }).toList();
  }

  Offset _project(double x, double y, double z, double width, double height) {
    double perspective = 1000 / (1000 + z);
    return Offset(
      (x * perspective) + width / 2,
      (y * perspective) + height / 2,
    );
  }

  void _handleTap(TapUpDetails details, Size size) {
    double angleY = _viewRotationY + (_animationController.value * 2 * math.pi * 0.2);
    double angleX = _viewRotationX;

    for (var star in _moodStars) {
      double x = star.x;
      double y = star.y;
      double z = star.z;

      double nextX = x * math.cos(angleY) + z * math.sin(angleY);
      double nextZ = -x * math.sin(angleY) + z * math.cos(angleY);
      x = nextX;
      z = nextZ;

      double nextY = y * math.cos(angleX) - z * math.sin(angleX);
      nextZ = y * math.sin(angleX) + z * math.cos(angleX);
      y = nextY;
      z = nextZ;

      Offset projected = _project(x, y, z, size.width, size.height);
      double perspectiveFactor = 1000 / (1000 + z);
      double scaledRadius = star.size * perspectiveFactor;

      if ((details.localPosition - projected).distance <= math.max(scaledRadius * 2, 32.0)) {
        if (widget.onEntryTap != null && star.entry != null) {
          widget.onEntryTap!(star.entry!);
        }
        return;
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
            color: const Color(0xFF05050B),
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

  Offset _project(double x, double y, double z, double width, double height) {
    double perspective = 1000 / (1000 + z);
    return Offset(
      (x * perspective) + width / 2,
      (y * perspective) + height / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    double driftAngleY = viewRotationY + (animationValue * 2 * math.pi * 0.2);
    double rotateAngleX = viewRotationX;

    final bgPaint = Paint()..style = PaintingStyle.fill;
    for (var star in backgroundStars) {
      double x = star.x;
      double y = star.y;
      double z = star.z;

      double nextX = x * math.cos(driftAngleY) + z * math.sin(driftAngleY);
      double nextZ = -x * math.sin(driftAngleY) + z * math.cos(driftAngleY);
      x = nextX;
      z = nextZ;

      double nextY = y * math.cos(rotateAngleX) - z * math.sin(rotateAngleX);
      nextZ = y * math.sin(rotateAngleX) + z * math.cos(rotateAngleX);
      y = nextY;
      z = nextZ;

      if (z > 600) continue;

      Offset projected = _project(x, y, z, size.width, size.height);
      double perspectiveFactor = 1000 / (1000 + z);
      double scaledSize = star.size * perspectiveFactor;
      double depthOpacity = star.opacity * ((600 - z) / 1200).clamp(0.1, 1.0);

      canvas.drawCircle(
        projected,
        scaledSize,
        bgPaint..color = Colors.white.withOpacity(depthOpacity),
      );
    }

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..blendMode = BlendMode.plus);

    for (var star in moodStars) {
      if (star.entry == null) continue;

      double x = star.x;
      double y = star.y;
      double z = star.z;

      double nextX = x * math.cos(driftAngleY) + z * math.sin(driftAngleY);
      double nextZ = -x * math.sin(driftAngleY) + z * math.cos(driftAngleY);
      x = nextX;
      z = nextZ;

      double nextY = y * math.cos(rotateAngleX) - z * math.sin(rotateAngleX);
      nextZ = y * math.sin(rotateAngleX) + z * math.cos(rotateAngleX);
      y = nextY;
      z = nextZ;

      Offset projected = _project(x, y, z, size.width, size.height);
      double perspectiveFactor = 1000 / (1000 + z);
      double scaledRadius = 8.0 * perspectiveFactor;
      double depthOpacity = ((300 - z) / 500).clamp(0.3, 1.0);

      final primaryColor = Color(star.entry!.primaryColorValue);

      canvas.drawCircle(
        projected,
        scaledRadius * 2.5,
        Paint()
          ..color = primaryColor.withOpacity(0.4 * depthOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      canvas.drawCircle(
        projected,
        scaledRadius * 1.5,
        Paint()
          ..color = primaryColor.withOpacity(0.7 * depthOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      canvas.drawCircle(
        projected,
        scaledRadius * 0.7,
        Paint()..color = Colors.white.withOpacity(0.9 * depthOpacity),
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
