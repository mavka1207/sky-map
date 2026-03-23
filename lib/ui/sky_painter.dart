// ============================================================================
// SKY PAINTER - CELESTIAL RENDERING
// ============================================================================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:sky_map/models/models.dart';

class SkyPainter extends CustomPainter {
  final List<RenderedObject> objects;
  final List<RenderedStar> hipStars;
  final List<Constellation> constellations;
  final SkyState state;
  final String? selectedObjectName;
  final bool nightVisionMode;
  final double azimuthFovScale;
  final double altitudeFovScale;

  SkyPainter(
    this.objects,
    this.selectedObjectName, {
    this.hipStars = const [],
    this.constellations = const [],
    required this.state,
    this.nightVisionMode = false,
    this.azimuthFovScale = 1.0,
    this.altitudeFovScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Black background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = nightVisionMode ? const Color(0xFF1a0000) : Colors.black,
    );

    // 2. Atmospheric gradient (before stars!)
    _drawAtmosphere(canvas, size);

    // 3. HIP stars (faint background starfield)
    _drawHipStars(canvas, size);

    // 4. Constellation lines
    _drawConstellations(canvas, size);

    // 5. Celestial objects (Sun, Moon, Planets)
    _drawObjects(canvas, size);

    // 6. Compass directions with horizon line
    _drawCompassLabels(canvas, size);
  }

  /// Draw HIP stars (faint background starfield)
  void _drawHipStars(Canvas canvas, Size size) {
    final starPaint = Paint();
    for (final star in hipStars) {
      starPaint.color = star.color.withOpacity(star.opacity);
      canvas.drawCircle(_scale(star.offset, size), star.radius, starPaint);
    }
  }

  /// Draw celestial objects (Sun, Moon, Planets) with labels
  void _drawObjects(Canvas canvas, Size size) {
    final placedLabelRects = <Rect>[];

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

  /// Project star from azimuth/altitude to screen coordinates with FOV scaling.
  /// FOV-scale affects the angular width of the visible sky.
  Offset? _projectStar(double az, double alt, Size size) {
    // Get effective FOV (scaled by pinch-zoom)
    const baseAzimuthFov = 260.0;
    const baseAltitudeFov = 150.0;
    final fovAz = baseAzimuthFov * azimuthFovScale;
    final fovAlt = baseAltitudeFov * altitudeFovScale;

    // Calculate relative azimuth/altitude from device heading/pitch
    final relAz = (az - state.heading + 360) % 360;
    final relAlt = alt - state.pitch;

    // Projection: map FOV range to screen coordinates
    // x: azimuth (0-360 degrees -> array width)
    // y: altitude (-90 to +90 degrees -> screen height)
    final x = (relAz / fovAz + 0.5) * size.width;
    final y = size.height / 2 - (relAlt / fovAlt) * (size.height / 2);

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

  /// Draw atmospheric gradient and horizon line
  void _drawAtmosphere(Canvas canvas, Size size) {
    const baseAltitudeFov = 150.0;
    final altFov = baseAltitudeFov * altitudeFovScale;

    // Horizon line at altitude 0 degrees
    final double horizonY =
        size.height / 2 - ((0.0 - state.pitch) / altFov) * size.height;

    // Color scheme based on night vision mode
    final bool isNightVision = nightVisionMode;
    final Color horizonColor = isNightVision
        ? const Color(0xFF3A0000) // dark red
        : const Color(0xFF1A3A5C); // blue
    final Color midColor = isNightVision
        ? const Color(0xFF1A0000) // very dark red
        : const Color(0xFF0D1F35); // dark blue
    final Color deepColor = isNightVision
        ? const Color(0xFF0F0F0F) // almost black with red tint
        : const Color(0xFF050D18); // very dark blue

    // Atmospheric gradient below horizon
    final double gradientHeight = size.height * 0.35;
    final double gradientTop = horizonY;
    final double gradientBottom = horizonY + gradientHeight;

    if (gradientBottom > 0 && gradientTop < size.height) {
      final rect = Rect.fromLTRB(
        0,
        gradientTop.clamp(0, size.height),
        size.width,
        gradientBottom.clamp(0, size.height),
      );

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          horizonColor.withOpacity(0.85),
          midColor.withOpacity(0.70),
          deepColor.withOpacity(0.50),
          Colors.black.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(rect);

      canvas.drawRect(rect, Paint()..shader = gradient);
    }

    // Light glow above horizon
    if (horizonY > 0 && horizonY < size.height) {
      final glowRect = Rect.fromLTRB(
        0,
        (horizonY - 30).clamp(0, size.height),
        size.width,
        horizonY.clamp(0, size.height),
      );

      final glowColor = isNightVision
          ? const Color(0xFF5A2A2A) // reddish glow
          : const Color(0xFF2A5F8F); // blue glow

      final glowGradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [glowColor.withOpacity(0.6), Colors.transparent],
      ).createShader(glowRect);

      canvas.drawRect(glowRect, Paint()..shader = glowGradient);
    }

    // Horizon line
    if (horizonY >= 0 && horizonY <= size.height) {
      final lineColor = isNightVision
          ? const Color(0xFF8A4A4A)
          : const Color(0xFF4A90C8);

      canvas.drawLine(
        Offset(0, horizonY),
        Offset(size.width, horizonY),
        Paint()
          ..color = lineColor.withOpacity(0.5)
          ..strokeWidth = 1.0,
      );
    }
  }

  /// Scale normalized coordinates (-1 to 1) to screen coordinates.
  Offset _scale(Offset normalized, Size size) {
    final x = size.width / 2 + normalized.dx * (size.width / 2);
    final y = size.height / 2 - normalized.dy * (size.height / 2);
    return Offset(x, y);
  }

  /// Draw compass direction labels (N/S/E/W/NE/SE/SW/NW) with horizon line
  void _drawCompassLabels(Canvas canvas, Size size) {
    const baseAzimuthFov = 260.0;
    const baseAltitudeFov = 150.0;
    final azFov = baseAzimuthFov * azimuthFovScale;
    final altFov = baseAltitudeFov * altitudeFovScale;

    // Horizon line at altitude 0 degrees
    final double horizonY =
        size.height / 2 - ((0.0 - state.pitch) / altFov) * (size.height / 2);

    if (horizonY >= 0 && horizonY <= size.height) {
      canvas.drawLine(
        Offset(0, horizonY),
        Offset(size.width, horizonY),
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..strokeWidth = 0.8,
      );
    }

    // Compass directions: azimuth -> label
    final directions = {
      0.0: 'N',
      45.0: 'NE',
      90.0: 'E',
      135.0: 'SE',
      180.0: 'S',
      225.0: 'SW',
      270.0: 'W',
      315.0: 'NW',
    };

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    );

    for (final entry in directions.entries) {
      final dirAz = entry.key;
      final label = entry.value;

      // Relative azimuth from device heading
      double relAz = dirAz - state.heading;
      // Normalize to -180..+180 range
      relAz = (relAz + 540) % 360 - 180;

      // Skip if outside visible FOV
      if (relAz.abs() > azFov) continue;

      // Map relative azimuth to screen x coordinate
      final double x = (relAz / azFov + 1) / 2 * size.width;
      final double y = size.height - 30;

      // Draw small tick marks at horizon
      if (horizonY >= 0 && horizonY <= size.height) {
        canvas.drawLine(
          Offset(x, horizonY - 6),
          Offset(x, horizonY + 6),
          Paint()
            ..color = Colors.white.withOpacity(0.4)
            ..strokeWidth = 1.2,
        );
      }

      // Draw direction label
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }
  }

  @override
  bool shouldRepaint(covariant SkyPainter oldDelegate) =>
      oldDelegate.selectedObjectName != selectedObjectName ||
      oldDelegate.objects != objects ||
      oldDelegate.hipStars != hipStars ||
      oldDelegate.constellations != constellations ||
      oldDelegate.state.heading != state.heading ||
      oldDelegate.state.pitch != state.pitch ||
      oldDelegate.nightVisionMode != nightVisionMode ||
      oldDelegate.azimuthFovScale != azimuthFovScale ||
      oldDelegate.altitudeFovScale != altitudeFovScale;
}
