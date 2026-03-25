// ============================================================================
// SKY PAINTER - CELESTIAL RENDERING
// ============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sky_map/models/models.dart';
import 'package:sky_map/models/sky_calculator.dart';

class SkyPainter extends CustomPainter {
  final List<RenderedObject> objects;
  final List<Constellation> constellations;
  final SkyState state;
  final String? selectedObjectName;
  final bool nightVisionMode;
  final double baseAzimuthFov;
  final double baseAltitudeFov;
  final double azimuthFovScale;
  final double altitudeFovScale;

  SkyPainter(
    this.objects,
    this.selectedObjectName, {
    this.constellations = const [],
    required this.state,
    this.nightVisionMode = false,
    this.baseAzimuthFov = 60.0,
    this.baseAltitudeFov = 130.0,
    this.azimuthFovScale = 1.0,
    this.altitudeFovScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = nightVisionMode ? const Color(0xFF1a0000) : Colors.black,
    );
    _drawAtmosphere(canvas, size);
    _drawConstellations(canvas, size);
    _drawObjects(canvas, size);
    _drawCompassLabels(canvas, size);
  }

  void _drawObjects(Canvas canvas, Size size) {
    for (final item in objects) {
      final center = _scale(item.offset, size);
      
      // Dynamic Scaling: Objects grow as you zoom in
      final zoomFactor = 1.0 / azimuthFovScale;
      double radius = item.radius * zoomFactor * (item.object.name == selectedObjectName ? 1.2 : 1.0);
      
      // Star safety cap (stars should stay relatively small)
      if (item.object.type == 'star') {
        radius = radius.clamp(0.5, 4.0);
      }
      final isSelected = selectedObjectName != null && item.object.name == selectedObjectName;
      final baseColor = item.object.color;

      _drawGlow(canvas, center, radius, baseColor);
      if (item.object.type == 'sun') {
        _drawSun(canvas, center, radius);
      } else if (item.object.type == 'moon') {
        _drawMoon(canvas, center, radius, baseColor, item.moonPhase ?? 0.0);
      } else if (item.object.type == 'star') {
        canvas.drawCircle(center, radius, Paint()..color = Colors.white);
      } else {
        _drawPlanet(canvas, center, radius, baseColor, id: item.object.id);
      }

      if (isSelected) {
        canvas.drawCircle(center, radius + 8, Paint()..color = Colors.white.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
      }

      final isMajor = item.object.type == 'planet' || item.object.type == 'sun' || item.object.type == 'moon' || item.object.type == 'star';
      if (isSelected || isMajor) {
        final isSun = item.object.type == 'sun';
        final isPlanet = item.object.type == 'planet';
        final isSpecial = isSun || isPlanet;

        final tp = TextPainter(
          text: TextSpan(
            text: item.object.name,
            style: TextStyle(
              color: isSelected 
                ? Colors.amber 
                : (isPlanet ? Colors.yellowAccent : Colors.white.withValues(alpha: 0.9)),
              fontSize: item.object.type == 'star' ? 10 : 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              decoration: isSpecial ? TextDecoration.underline : null,
              decorationThickness: 1.5,
              decorationColor: isPlanet ? Colors.yellowAccent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final offset = isSpecial
            ? Offset(-radius - 12 - tp.width, -tp.height / 2)
            : Offset(radius + 6, -radius - 4 - tp.height);
        final rect = (center + offset) & tp.size;

        if (!isSpecial) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(4)), Paint()..color = Colors.black.withValues(alpha: 0.5));
        }
        tp.paint(canvas, rect.topLeft);
      }
    }
  }

  void _drawConstellations(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.6;
    final nameStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 11,
      letterSpacing: 1.8,
      fontWeight: FontWeight.w300,
    );
    for (final c in constellations) {
      final pos = List<Offset?>.filled(c.stars.length, null);
      final labelPoints = <Offset>[];
      for (var i = 0; i < c.stars.length; i++) {
        final h = SkyCalculator.toHorizontal(c.stars[i].ra, c.stars[i].dec, state.latitude, state.lstDegrees);
        final p = SkyCalculator.projectToScreen(h.$1, h.$2, state.heading, state.pitch, baseAzimuthFov, baseAltitudeFov, azimuthFovScale, altitudeFovScale, clip: false);
        pos[i] = p;
        if (p != null) {
          final scaled = _scale(p, size);
          // Only use points that are actually on-screen for calculating the label center
          if (scaled.dx >= 0 && scaled.dx <= size.width && scaled.dy >= 0 && scaled.dy <= size.height) {
            labelPoints.add(scaled);
          }
        }
      }
      for (final conn in c.connections) {
        if (conn[0] < pos.length && conn[1] < pos.length && pos[conn[0]] != null && pos[conn[1]] != null) {
          final p1 = pos[conn[0]]!;
          final p2 = pos[conn[1]]!;
          
          final azFov = baseAzimuthFov * azimuthFovScale;
          final wrapThreshold = 180 / (azFov / 2);
          if ((p1.dx - p2.dx).abs() < wrapThreshold * 0.8) {
            canvas.drawLine(_scale(p1, size), _scale(p2, size), linePaint);
          }
        }
      }
      for (final p in pos) {
        if (p != null) {
          final scaled = _scale(p, size);
          if (scaled.dx >= 0 && scaled.dx <= size.width && scaled.dy >= 0 && scaled.dy <= size.height) {
            canvas.drawCircle(scaled, 2.8, Paint()..color = Colors.white.withValues(alpha: 0.7));
          }
        }
      }
      if (labelPoints.isNotEmpty) {
        final center = labelPoints.reduce((a, b) => a + b) / labelPoints.length.toDouble();
        final tp = TextPainter(text: TextSpan(text: c.name.toUpperCase(), style: nameStyle), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, center + const Offset(10, 10));
      }
    }
  }

  void _drawGlow(Canvas canvas, Offset c, double r, Color col) {
    canvas.drawCircle(c, r * 1.8, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.4), col.withValues(alpha: 0.1), Colors.transparent]).createShader(Rect.fromCircle(center: c, radius: r * 1.8)));
  }

  void _drawSun(Canvas canvas, Offset c, double r) {
    // 1. Large soft halo
    final haloPaint = Paint()
      ..shader = RadialGradient(colors: [
        Colors.amber.withValues(alpha: 0.35),
        Colors.amber.withValues(alpha: 0.1),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: c, radius: r * 4));
    canvas.drawCircle(c, r * 4, haloPaint);

    // 2. Flare rays
    final rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 12; i++) {
        final angle = (i * 30) * pi / 180;
        final len = r * (2.5 + (i % 3 == 0 ? 1.5 : 0.5));
        canvas.drawLine(
            c + Offset(cos(angle) * r, sin(angle) * r),
            c + Offset(cos(angle) * len, sin(angle) * len),
            rayPaint,
        );
    }

    // 3. Bright core
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    
    // 4. Tight corona
    final coronaPaint = Paint()
      ..shader = RadialGradient(colors: [
        Colors.white,
        Colors.amber.withValues(alpha: 0.8),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: c, radius: r * 1.4));
    canvas.drawCircle(c, r * 1.4, coronaPaint);
  }

  void _drawPlanet(Canvas canvas, Offset c, double r, Color col, {String? id}) {
    // 1. Draw back half of rings for Saturn
    if (id == 'saturn') {
      _drawSaturnRings(canvas, c, r, isFront: false);
    }

    // 2. 3D Spherical paint with Rim Light for visibility against black sky
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9), // Specular highlight
          col,                           // Base color
          col.withValues(alpha: 0.2),          // Deep shadow
          col.withValues(alpha: 0.4),          // Rim light on shadow side
        ],
        stops: const [0.0, 0.4, 0.9, 1.0],
        center: const Alignment(-0.5, -0.5),
      ).createShader(Rect.fromCircle(center: c, radius: r));
    
    canvas.drawCircle(c, r, paint);

    // 3. Draw front half of rings for Saturn
    if (id == 'saturn') {
      _drawSaturnRings(canvas, c, r, isFront: true);
    }
  }

  void _drawSaturnRings(Canvas canvas, Offset c, double r, {required bool isFront}) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.15 // Thinner rings
      ..shader = SweepGradient(
        colors: [
          Colors.white12,
          Colors.white.withValues(alpha: 0.4),
          Colors.white12,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 2.2));

    // Outer and Inner ring simulator
    final outerRect = Rect.fromCenter(center: c, width: r * 4.8, height: r * 0.9);
    final innerRect = Rect.fromCenter(center: c, width: r * 3.8, height: r * 0.7);
    
    if (isFront) {
      canvas.drawArc(outerRect, 0, pi, false, ringPaint);
      canvas.drawArc(innerRect, 0, pi, false, ringPaint..strokeWidth = r * 0.1);
    } else {
      canvas.drawArc(outerRect, pi, pi, false, ringPaint);
      canvas.drawArc(innerRect, pi, pi, false, ringPaint..strokeWidth = r * 0.1);
    }
  }

  void _drawMoon(Canvas canvas, Offset c, double r, Color col, double ph) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF151515));
    final litPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    if (ph == 0.5) {
      canvas.drawCircle(c, r, litPaint);
      return;
    }
    final rect = Rect.fromCircle(center: c, radius: r);
    final path = Path();
    if (ph < 0.5) {
      path.addArc(rect, -pi / 2, pi);
      final bulge = r * cos(ph * 2 * pi);
      final tRect = Rect.fromLTRB(c.dx - bulge.abs(), c.dy - r, c.dx + bulge.abs(), c.dy + r);
      if (ph < 0.25) {
        path.addArc(tRect, pi / 2, -pi);
      } else {
        path.addArc(tRect, pi / 2, pi);
      }
    } else {
      path.addArc(rect, pi / 2, pi);
      final bulge = r * cos(ph * 2 * pi);
      final tRect = Rect.fromLTRB(c.dx - bulge.abs(), c.dy - r, c.dx + bulge.abs(), c.dy + r);
      if (ph < 0.75) {
        path.addArc(tRect, -pi / 2, pi);
      } else {
        path.addArc(tRect, -pi / 2, -pi);
      }
    }
    canvas.drawPath(path, litPaint);
  }

  void _drawAtmosphere(Canvas canvas, Size s) {
    final horizonY = s.height / 2 - ((0.0 - state.pitch) / (baseAltitudeFov * altitudeFovScale)) * s.height;
    final horizonColor = nightVisionMode ? const Color(0xFF3A0000) : const Color(0xFF1A3A5C);
    if (horizonY < s.height) {
      final rect = Rect.fromLTRB(0, horizonY.clamp(0, s.height), s.width, s.height);
      canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [horizonColor.withValues(alpha: 0.8), Colors.transparent]).createShader(rect));
    }
    if (horizonY >= 0 && horizonY <= s.height) {
      canvas.drawLine(
        Offset(0, horizonY),
        Offset(s.width, horizonY),
        Paint()
          ..color = horizonColor.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }
  }

  Offset _scale(Offset n, Size s) => Offset(s.width / 2 + n.dx * (s.width / 2), s.height / 2 - n.dy * (s.height / 2));

  void _drawCompassLabels(Canvas canvas, Size s) {
    final azFov = baseAzimuthFov * azimuthFovScale;
    final directions = {0.0: 'N', 90.0: 'E', 180.0: 'S', 270.0: 'W'};
    for (final e in directions.entries) {
      double rel = (e.key - state.heading + 540) % 360 - 180;
      if (rel.abs() > azFov) continue;
      final x = (rel / azFov + 1) / 2 * s.width;
      final tp = TextPainter(text: TextSpan(text: e.value, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, s.height - 40));
    }
  }

  @override
  bool shouldRepaint(covariant SkyPainter old) => true;
}
