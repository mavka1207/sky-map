// ============================================================================
// SKY PAINTER - CELESTIAL RENDERING
// ============================================================================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:sky_map/models/models.dart';

class SkyPainter extends CustomPainter {
  final List<RenderedObject> objects;
  final List<RenderedStar> hipStars;
  final List<LineSegment> constellationLines;
  final String? selectedObjectName;
  final bool nightVisionMode;

  SkyPainter(
    this.objects,
    this.constellationLines,
    this.selectedObjectName, {
    this.hipStars = const [],
    this.nightVisionMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final background = Paint()
      ..color = nightVisionMode ? const Color(0xFF1a0000) : Colors.black;
    canvas.drawRect(Offset.zero & size, background);

    // HIP stars (faint background starfield)
    final starPaint = Paint();
    for (final star in hipStars) {
      starPaint.color = star.color.withOpacity(star.opacity);
      canvas.drawCircle(_scale(star.offset, size), star.radius, starPaint);
    }

    // Constellation lines
    final linePaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2;
    for (final line in constellationLines) {
      canvas.drawLine(
        _scale(line.start, size),
        _scale(line.end, size),
        linePaint,
      );
    }

    final placedLabelRects = <Rect>[];

    // Celestial objects (Sun, Moon, Planets)
    for (final item in objects) {
      final isSelected = item.object.name == selectedObjectName;
      final baseColor = item.object.color;
      var center = _scale(item.offset, size);

      // Apply deterministic jitter offset for planets (visual variety)
      if (item.object.type == 'planet' || item.object.type == 'moon') {
        center += item.object.screenOffset;
      }

      final radius = isSelected ? item.radius * 1.8 : item.radius;

      // Render planet with glow and 3D sphere effect
      _drawGlow(canvas, center, radius, baseColor);
      _drawPlanet(canvas, center, radius, baseColor);

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.object.name,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const gap = 4.0;
      Offset labelOffset = switch (item.object.type) {
        'sun' => Offset(-(radius + gap + textPainter.width), radius + gap),
        'moon' => Offset(radius + gap, radius + gap),
        'planet' => Offset(radius + gap, -radius - gap - textPainter.height),
        _ => Offset(radius + gap, radius + gap),
      };

      Rect labelRect = (center + labelOffset) & textPainter.size;
      const maxTries = 12;
      var tries = 0;
      while (tries < maxTries &&
          placedLabelRects.any((r) => r.overlaps(labelRect))) {
        labelOffset += Offset(0, textPainter.height + 2);
        labelRect = (center + labelOffset) & textPainter.size;
        tries++;
      }
      placedLabelRects.add(labelRect);

      // Label background
      final bgRect = labelRect.inflate(3);
      final bgPaint = Paint()..color = Colors.black.withOpacity(0.55);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
        bgPaint,
      );
      textPainter.paint(canvas, labelRect.topLeft);
    }
  }

  /// Draw atmospheric glow/halo around celestial body
  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    final glowRadius = radius * 1.8;
    final rect = Rect.fromCircle(center: center, radius: glowRadius);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.4),
          color.withOpacity(0.1),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, glowRadius, glowPaint);
  }

  /// Draw planet with 3D sphere effect using radial gradient
  void _drawPlanet(
    Canvas canvas,
    Offset center,
    double radius,
    Color baseColor,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = RadialGradient(
      colors: [
        baseColor.withOpacity(0.1), // dark side / shadow
        baseColor, // main color
        Colors.white.withOpacity(0.8), // bright side (sun-lit)
      ],
      stops: const [0.0, 0.6, 1.0],
      center: const Alignment(-0.4, -0.4), // light from top-left
      radius: 0.95,
    );

    final paint = Paint()..shader = gradient.createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  /// Scale normalized coordinates (-1 to 1) to screen coordinates.
  Offset _scale(Offset normalized, Size size) {
    final x = size.width / 2 + normalized.dx * (size.width / 2);
    final y = size.height / 2 - normalized.dy * (size.height / 2);
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant SkyPainter oldDelegate) =>
      oldDelegate.selectedObjectName != selectedObjectName ||
      oldDelegate.objects != objects ||
      oldDelegate.hipStars != hipStars ||
      oldDelegate.constellationLines != constellationLines ||
      oldDelegate.nightVisionMode != nightVisionMode;
}
