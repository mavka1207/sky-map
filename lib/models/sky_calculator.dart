// ============================================================================
// SKY CALCULATION ENGINE - ALL ASTRONOMICAL MATH
// ============================================================================

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sky_map/models/orbital_mechanics.dart';

class SkyCalculator {
  static const double _degToRad = pi / 180;

  /// Calculate Julian Date from DateTime.
  static double calculateJulianDate(DateTime date) {
    return date.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  }

  /// Calculate Local Sidereal Time (in degrees) given Julian Date and longitude.
  static double calculateLst(double julian, double longitudeDegrees) {
    final gmst = (18.697374558 + 24.06570982441908 * (julian - 2451545.0));
    final gmstWrapped = (gmst % 24 + 24) % 24;
    return ((gmstWrapped * 15) + longitudeDegrees) % 360;
  }

  /// Get equatorial coordinates (RA, DEC) for a celestial object.
  static (double, double) getEquatorialForObject(
    String name,
    double julian,
    double baseJulian,
  ) {
    final deltaDays = julian - baseJulian;

    if (name == 'Sun') {
      final n = (baseJulian - 2451545.0) + deltaDays;
      final l = (280.46 + 0.9856474 * n) % 360;
      final g = (357.528 + 0.9856003 * n) % 360;
      final lambda =
          l + 1.915 * sin(g * _degToRad) + 0.020 * sin(2 * g * _degToRad);
      final epsilon = 23.439 - 0.0000004 * n;
      final ra =
          atan2(
            cos(epsilon * _degToRad) * sin(lambda * _degToRad),
            cos(lambda * _degToRad),
          ) /
          _degToRad;
      final dec =
          asin(sin(epsilon * _degToRad) * sin(lambda * _degToRad)) / _degToRad;
      return ((ra + 360) % 360, dec);
    }

    if (name == 'Moon') {
      final d = (baseJulian - 2451543.5) + deltaDays;
      final n = (125.1228 - 0.0529538083 * d) % 360;
      final i = 5.1454;
      final w = (318.0634 + 0.1643573223 * d) % 360;
      final a = 60.2666;
      final e = 0.0549;
      final m = (115.3654 + 13.0649929509 * d) % 360;
      final eAnomaly =
          m +
          (180 / pi) * e * sin(m * _degToRad) * (1 + e * cos(m * _degToRad));
      final xv = a * (cos(eAnomaly * _degToRad) - e);
      final yv = a * (sqrt(1 - e * e) * sin(eAnomaly * _degToRad));
      final v = atan2(yv, xv) / _degToRad;
      final r = sqrt(xv * xv + yv * yv);
      final xh =
          r *
          (cos(n * _degToRad) * cos((v + w) * _degToRad) -
              sin(n * _degToRad) *
                  sin((v + w) * _degToRad) *
                  cos(i * _degToRad));
      final yh =
          r *
          (sin(n * _degToRad) * cos((v + w) * _degToRad) +
              cos(n * _degToRad) *
                  sin((v + w) * _degToRad) *
                  cos(i * _degToRad));
      final ecl = 23.4393;
      final ra = atan2(yh * cos(ecl * _degToRad), xh) / _degToRad;
      final dec =
          atan2(yh * sin(ecl * _degToRad), sqrt(xh * xh + yh * yh)) / _degToRad;
      return ((ra + 360) % 360, dec);
    }

    final elements = OrbitalElements.getPlanetByName(name);
    if (elements != null) {
      return elements.getEquatorialPosition(julian);
    }

    // Fallback
    final ra = (deltaDays * 0.2) % 360;
    final dec = 10 * sin(ra * _degToRad);
    return (ra, dec);
  }

  /// Convert equatorial (RA, DEC) to horizontal (AZ, ALT) coordinates.
  static (double, double) toHorizontal(
    double ra,
    double dec,
    double latitude,
    double lstDegrees,
  ) {
    final hourAngle = (lstDegrees - ra + 360) % 360;
    final haRad = hourAngle * _degToRad;
    final decRad = dec * _degToRad;
    final latRad = latitude * _degToRad;

    final altitude = asin(
      sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(haRad),
    );
    final azimuth = atan2(
      -sin(haRad),
      tan(decRad) * cos(latRad) - sin(latRad) * cos(haRad),
    );

    return ((azimuth / _degToRad + 360) % 360, altitude / _degToRad);
  }

  /// Project sky coordinates to screen normalized coordinates (-1 to 1).
  /// Project celestial object to screen coordinates.
  /// All angle parameters (azimuth, altitude, phoneAzimuth, phonePitch) MUST BE IN DEGREES!
  static Offset? projectToScreen(
    double azimuth, // degrees
    double altitude, // degrees
    double phoneAzimuth, // degrees
    double phonePitch, // degrees (MUST BE IN DEGREES, NOT RADIANS!)
    double baseAzimuthFov,
    double baseAltitudeFov,
    double azimuthFovScale,
    double altitudeFovScale, {
    bool allowBelowHorizon = false,
  }) {
    if (!allowBelowHorizon && altitude < -5) {
      return null;
    }

    final relAz = ((azimuth - phoneAzimuth + 540) % 360) - 180;
    final relAlt = altitude - phonePitch;
    final azimuthFov = baseAzimuthFov * azimuthFovScale;
    final altitudeFov = baseAltitudeFov * altitudeFovScale;

    if (relAz.abs() > azimuthFov || relAlt.abs() > altitudeFov) {
      return null;
    }

    final xNorm = relAz / azimuthFov;
    final yNorm = relAlt / altitudeFov;
    return Offset(xNorm, yNorm);
  }

  /// Project a star to screen coordinates.
  static Offset? projectStar(
    double ra,
    double dec,
    double lat,
    double lst,
    double phoneAzimuth,
    double phonePitch,
    double baseAzimuthFov,
    double baseAltitudeFov,
    double azimuthFovScale,
    double altitudeFovScale,
  ) {
    final horizontal = toHorizontal(ra, dec, lat, lst);
    return projectToScreen(
      horizontal.$1,
      horizontal.$2,
      phoneAzimuth,
      phonePitch,
      baseAzimuthFov,
      baseAltitudeFov,
      azimuthFovScale,
      altitudeFovScale,
    );
  }

  /// Normalize angle difference to [-180, 180).
  static double normalizeAngleDiff(double from, double to) {
    return ((to - from + 540) % 360) - 180;
  }

  /// Lerp between two angles (handles wrap-around).
  static double lerpAngle(double from, double to, double t) {
    final diff = normalizeAngleDiff(from, to);
    return (from + diff * t + 360) % 360;
  }
}
