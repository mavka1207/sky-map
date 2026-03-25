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
    final ha = (lstDegrees - ra + 360) % 360;
    final haRad = ha * _degToRad;
    final decRad = dec * _degToRad;
    final latRad = latitude * _degToRad;

    final sinAlt = (sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(haRad)).clamp(-1.0, 1.0);
    final altitude = asin(sinAlt);

    final azimuth = atan2(
      -sin(haRad),
      cos(latRad) * tan(decRad) - sin(latRad) * cos(haRad)
    );

    return ((azimuth / _degToRad + 360) % 360, altitude / _degToRad);
  }

  /// Topocentric horizontal coordinates for the Moon.
  /// Applies observer parallax correction (largest for nearby bodies like Moon).
  static (double, double) toHorizontalMoonTopocentric(
    double ra,
    double dec,
    double latitude,
    double lstDegrees,
  ) {
    final latRad = latitude * _degToRad;
    final raRad = ra * _degToRad;
    final decRad = dec * _degToRad;
    final hRad = ((lstDegrees - ra + 360) % 360) * _degToRad;

    // Approx mean equatorial horizontal parallax of the Moon.
    const moonParallaxDeg = 0.9507;
    final sinPi = sin(moonParallaxDeg * _degToRad);

    // Geocentric latitude helpers (WGS84 flattening approximation).
    final u = atan(0.99664719 * tan(latRad));
    final rhoSinPhiPrime = 0.99664719 * sin(u);
    final rhoCosPhiPrime = cos(u);

    // Topocentric RA correction (Meeus-style approximation).
    final deltaAlpha = atan2(
      -rhoCosPhiPrime * sinPi * sin(hRad),
      cos(decRad) - rhoCosPhiPrime * sinPi * cos(hRad),
    );

    final raTopocentric = raRad + deltaAlpha;

    // Topocentric declination.
    final decTopocentric = atan2(
      (sin(decRad) - rhoSinPhiPrime * sinPi) * cos(deltaAlpha),
      cos(decRad) - rhoCosPhiPrime * sinPi * cos(hRad),
    );

    final raTopDeg = (raTopocentric / _degToRad + 360) % 360;
    final decTopDeg = decTopocentric / _degToRad;
    return toHorizontal(raTopDeg, decTopDeg, latitude, lstDegrees);
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
    bool clip = true,
  }) {
    // Horizon limit removed to allow viewing objects "below feet" as in professional apps
    if (!allowBelowHorizon && altitude < -90) {
      return null;
    }

    final relAz = ((azimuth - phoneAzimuth + 540) % 360) - 180;
    final relAlt = altitude - phonePitch;
    final azimuthFov = baseAzimuthFov * azimuthFovScale;
    final altitudeFov = baseAltitudeFov * altitudeFovScale;
    final halfAzimuthFov = azimuthFov / 2;
    final halfAltitudeFov = altitudeFov / 2;

    if (clip && (relAz.abs() > halfAzimuthFov || relAlt.abs() > halfAltitudeFov)) {
      return null;
    }

    final xNorm = relAz / halfAzimuthFov;
    final yNorm = relAlt / halfAltitudeFov;
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
    double altitudeFovScale, {
    bool clip = true,
  }) {
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
      clip: clip,
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

  /// Calculate Moon phase (0.0 to 1.0).
  /// 0.0 = New Moon, 0.25 = First Quarter, 0.5 = Full Moon, 0.75 = Last Quarter.
  static double calculateMoonPhase(double julian) {
    const double referenceJD = 2451550.26;
    const double synodicMonth = 29.530588853;
    final phase = (julian - referenceJD) % synodicMonth;
    return (phase < 0 ? phase + synodicMonth : phase) / synodicMonth;
  }

  /// Approximate Rise/Set times for a given RA/Dec and Latitude.
  /// Returns (riseHourLST, setHourLST) in degrees.
  /// If the object never rises or never sets, return null.
  static (double, double)? calculateRiseSetLST(double ra, double dec, double lat) {
    final decRad = dec * _degToRad;
    final latRad = lat * _degToRad;
    const h0 = -0.833 * _degToRad; // Standard altitude for horizon

    final cosH = (sin(h0) - sin(latRad) * sin(decRad)) / (cos(latRad) * cos(decRad));

    if (cosH > 1) return null; // Never rises
    if (cosH < -1) return null; // Never sets (circumpolar)

    final h = acos(cosH) / _degToRad;
    return ((ra - h + 360) % 360, (ra + h + 360) % 360);
  }

  /// Calculate guidance vector (angle in degrees) for an off-screen object.
  static double getGuidanceAngle(Offset targetOffset) {
    // targetOffset is in normalized -1..1 coordinates
    // screen center is 0,0. y is up (+1), x is right (+1)
    return atan2(targetOffset.dy, targetOffset.dx) / _degToRad;
  }
}
