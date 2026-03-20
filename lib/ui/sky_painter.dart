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
      final center = _scale(item.offset, size);

      // Glow effect
      final glowPaint = Paint()
        ..color = baseColor.withOpacity(isSelected ? 0.9 : 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, item.radius * 2.4, glowPaint);

      // Object circle
      final paint = Paint()..color = baseColor;
      final radius = isSelected ? item.radius * 1.8 : item.radius;
      canvas.drawCircle(center, radius, paint);

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
        ObjectType.sun => Offset(
          -(radius + gap + textPainter.width),
          radius + gap,
        ),
        ObjectType.moon => Offset(radius + gap, radius + gap),
        ObjectType.planet => Offset(
          radius + gap,
          -radius - gap - textPainter.height,
        ),
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
