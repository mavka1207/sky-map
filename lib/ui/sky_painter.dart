// ============================================================================
// SKY PAINTER - CELESTIAL RENDERING
// ============================================================================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:sky_map/models/models.dart';
import 'package:sky_map/models/sky_calculator.dart';

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
      // Position from projection (az/alt converted to screen coordinates)
      final center = _scale(item.offset, size);

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

    const baseAzimuthFov = 260.0;
    const baseAltitudeFov = 150.0;

    for (final constellation in constellations) {
      // Project all stars for this constellation
      final positions = <Offset?>[];
      final relAzimuths = <double>[];

      for (final star in constellation.stars) {
        // Constellation stars stored as RA/DEC, convert to Az/Alt
        final horizontal = SkyCalculator.toHorizontal(
          star.az, // stored as RA
          star.alt, // stored as DEC
          state.latitude,
          state.lstDegrees,
        );

        final projected = SkyCalculator.projectToScreen(
          horizontal.$1, // azimuth
          horizontal.$2, // altitude
          state.heading,
          state.pitch,
          baseAzimuthFov,
          baseAltitudeFov,
          azimuthFovScale,
          altitudeFovScale,
        );

        positions.add(projected);

        if (projected != null) {
          final relAz = (horizontal.$1 - state.heading + 540) % 360 - 180;
          relAzimuths.add(relAz);
        } else {
          relAzimuths.add(-999); // invalid marker
        }
      }

      // Draw lines between connected stars
      for (final connection in constellation.connections) {
        final idx1 = connection[0];
        final idx2 = connection[1];

        if (idx1 >= positions.length || idx2 >= positions.length) continue;

        final p1 = positions[idx1];
        final p2 = positions[idx2];
        if (p1 == null || p2 == null) continue;
        if (relAzimuths[idx1] == -999 || relAzimuths[idx2] == -999) continue;

        // Skip lines that wrap around 0°/360° (causes visual artifacts)
        final azDiff = (relAzimuths[idx1] - relAzimuths[idx2]).abs();
        if (azDiff > 180) continue;

        // Convert normalized coordinates to screen pixels
        final s1 = _scale(p1, size);
        final s2 = _scale(p2, size);
        canvas.drawLine(s1, s2, linePaint);
      }

      // Draw constellation stars
      for (var i = 0; i < positions.length; i++) {
        final pos = positions[i];
        if (pos == null || relAzimuths[i] == -999) continue; // star not visible

        final screenPos = _scale(pos, size);
        canvas.drawCircle(screenPos, 3.0, starGlowPaint); // glow
        canvas.drawCircle(screenPos, 1.5, starPaint); // star
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
