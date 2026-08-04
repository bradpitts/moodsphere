import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrbPainter extends CustomPainter {
  final Color baseColor;
  final double pulseProgress;

  OrbPainter({
    required this.baseColor,
    this.pulseProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.2;

    // 1. Outer Glow / Ambient Aura
    final outerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withOpacity(0.45 + (pulseProgress * 0.1)),
          baseColor.withOpacity(0.2),
          baseColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius * 1.45),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    canvas.drawCircle(center, radius * 1.45, outerGlowPaint);

    // 2. Main Orb Body Radial Gradient
    final orbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          HSLColor.fromColor(baseColor).withLightness(math.min(1.0, HSLColor.fromColor(baseColor).lightness + 0.35)).toColor(),
          baseColor,
          HSLColor.fromColor(baseColor).withLightness(math.max(0.0, HSLColor.fromColor(baseColor).lightness - 0.25)).toColor(),
          const Color(0xFF0F0F1A),
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, orbPaint);

    // 3. Specular Highlight (Inner Core Reflection)
    final highlightCenter = Offset(
      center.dx - radius * 0.28,
      center.dy - radius * 0.32,
    );

    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.65),
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(
        Rect.fromCircle(center: highlightCenter, radius: radius * 0.45),
      );

    canvas.drawCircle(highlightCenter, radius * 0.4, highlightPaint);

    // 4. Subtle Outer Ring Edge
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.4),
          baseColor.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}
