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
  final List<Constellation> constellations;
  final SkyState state;
  final String? selectedObjectName;
  final bool nightVisionMode;

  SkyPainter(
    this.objects,
    this.constellationLines,
    this.selectedObjectName, {
    this.hipStars = const [],
    this.constellations = const [],
    required this.state,
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

    // Constellation lines (pre-computed from provider)
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

    // Custom constellation lines with wrap-around check (projected every frame)
    _drawConstellations(canvas, size);

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

  /// Project star from azimuth/altitude to screen coordinates.
  /// Relative azimuth is calculated based on device heading.
  Offset? _projectStar(double az, double alt, Size size) {
    // Calculate relative azimuth from device heading
    final relAz = (az - state.heading + 360) % 360;
    final relAlt = alt - state.pitch;

    // Simple cylindrical projection: az -> x, alt -> y
    final x = (relAz / 360.0) * size.width;
    final y = size.height / 2 - (relAlt / 90.0) * (size.height / 2);

    // Check if within visible bounds (with some margin)
    const margin = 50.0;
    if (x < -margin || x > size.width + margin) return null;
    if (y < -margin || y > size.height + margin) return null;

    return Offset(x, y);
  }

  /// Draw constellation lines with projections recalculated every frame.
  /// Includes wrap-around check to avoid long lines across screen.
  void _drawConstellations(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.0;

    final starGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final starPaint = Paint()..color = Colors.white;

    for (final constellation in constellations) {
      // Project all stars for this constellation
      final positions = <Offset>[];
      final relAzimuths = <double>[];

      for (final star in constellation.stars) {
        final pos = _projectStar(star.az, star.alt, size);
        if (pos != null) {
          positions.add(pos);
          final relAz = (star.az - state.heading + 360) % 360;
          relAzimuths.add(relAz);
        } else {
          positions.add(Offset.zero); // placeholder
          relAzimuths.add(-1); // invalid marker
        }
      }

      // Draw lines between connected stars
      for (final connection in constellation.connections) {
        final idx1 = connection[0];
        final idx2 = connection[1];

        if (idx1 >= positions.length || idx2 >= positions.length) continue;
        if (relAzimuths[idx1] < 0 || relAzimuths[idx2] < 0) continue;

        // Skip lines that wrap around 0°/360° (causes visual artifacts)
        final azDiff = (relAzimuths[idx1] - relAzimuths[idx2]).abs();
        if (azDiff > 180) continue;

        final p1 = positions[idx1];
        final p2 = positions[idx2];
        canvas.drawLine(p1, p2, linePaint);
      }

      // Draw constellation stars
      for (var i = 0; i < positions.length; i++) {
        if (relAzimuths[i] < 0) continue; // star not visible
        final pos = positions[i];
        canvas.drawCircle(pos, 3.0, starGlowPaint); // glow
        canvas.drawCircle(pos, 1.5, starPaint); // star
      }
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
      oldDelegate.constellations != constellations ||
      oldDelegate.state.heading != state.heading ||
      oldDelegate.state.pitch != state.pitch ||
      oldDelegate.nightVisionMode != nightVisionMode;
}
