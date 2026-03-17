// ============================================================================
// 2️⃣ REALISTIC STAR DATA (HIP catalog + spectral classes)
// ============================================================================

// ignore_for_file: non_constant_identifier_names, unused_element

import 'package:flutter/material.dart';
import 'dart:math';

/// A star from the Hipparcos catalog.
class HIPStar {
  final int hipNumber;           // Hipparcos ID
  final String? properName;      // Proper name (if available)
  final double ra;               // Right Ascension (0-360°)
  final double dec;              // Declination (-90 to +90°)
  final double apparentMagnitude; // Apparent magnitude (-26.7 to +6.0)
  final String spectralClass;    // O, B, A, F, G, K, M
  final double? absoluteMagnitude; // Absolute magnitude
  final double? parallax;        // Parallax (mas)

  HIPStar({
    required this.hipNumber,
    this.properName,
    required this.ra,
    required this.dec,
    required this.apparentMagnitude,
    required this.spectralClass,
    this.absoluteMagnitude,
    this.parallax,
  });

  /// Get star color by spectral class.
  Color getColorBySpectralClass() {
    if (spectralClass.isEmpty) return Colors.white;

    return switch (spectralClass[0]) {
      'O' => Colors.blue,              // O-type: 30000+ K (very hot)
      'B' => Colors.lightBlue,         // B-type: 10000 K
      'A' => Colors.white,             // A-type: 7500 K (e.g., Sirius)
      'F' => Colors.yellow.shade200,   // F-type: 6000 K
      'G' => Colors.yellow,            // G-type: 5500 K (Sun-like)
      'K' => Colors.orange.shade400,   // K-type: 3700 K
      'M' => Colors.red,               // M-type: 2400 K (cool)
      _ => Colors.white,
    };
  }

  /// Compute relative brightness (Sirius ≈ 1.0 by default).
  /// Uses: brightness = 10^(-0.4 * magnitudeDifference)
  double getBrightness({double referenceMagnitude = -1.46}) {
    // Sirius has magnitude -1.46
    final magnitudeDifference = referenceMagnitude - apparentMagnitude;
    return pow(10, magnitudeDifference * 0.4).toDouble();
  }

  /// Get a visual radius for drawing (based on brightness).
  double getVisualRadius() {
    final brightness = getBrightness();
    if (brightness > 100) return 8.0;   // Very bright (Sirius, Vega)
    if (brightness > 10) return 6.0;    // Bright
    if (brightness > 2) return 4.0;     // Medium
    if (brightness > 0.5) return 2.5;   // Dim
    return 1.5;                         // Very dim
  }

  /// Get opacity for drawing (based on magnitude).
  double getOpacity() {
    if (apparentMagnitude < 2) return 1.0;
    if (apparentMagnitude < 3) return 0.9;
    if (apparentMagnitude < 4) return 0.8;
    if (apparentMagnitude < 5) return 0.6;
    if (apparentMagnitude < 6) return 0.4;
    return 0.2;
  }

  /// Name to display.
  String getDisplayName() {
    return properName ?? 'HIP $hipNumber';
  }
}

class HIPCatalog {
  /// A curated subset of the Hipparcos catalog (bright stars, mag < 5.5).
  /// The full catalog contains 118,322 stars.
  static final List<HIPStar> stars = [
    // ========================================================================
    // BRIGHTEST STARS
    // ========================================================================

    // Sirius (α Canis Majoris) - the brightest star in the night sky
    HIPStar(
      hipNumber: 32349,
      properName: 'Sirius',
      ra: 101.287,
      dec: -16.643,
      apparentMagnitude: -1.46,
      spectralClass: 'A1V',
      absoluteMagnitude: 1.42,
      parallax: 379.21,
    ),

    // Canopus (α Carinae) - second brightest
    HIPStar(
      hipNumber: 30438,
      properName: 'Canopus',
      ra: 95.988,
      dec: -52.696,
      apparentMagnitude: -0.62,
      spectralClass: 'F0Ia',
      absoluteMagnitude: -2.50,
      parallax: 10.43,
    ),

    // Rigil Kentaurus (α Centauri) - among the brightest
    HIPStar(
      hipNumber: 71683,
      properName: 'Rigil Kentaurus',
      ra: 219.901,
      dec: -60.837,
      apparentMagnitude: -0.27,
      spectralClass: 'G2V',
      absoluteMagnitude: 4.37,
      parallax: 742.12,
    ),

    // Arcturus (α Boötis) - a red giant
    HIPStar(
      hipNumber: 69673,
      properName: 'Arcturus',
      ra: 213.915,
      dec: 19.182,
      apparentMagnitude: -0.04,
      spectralClass: 'K1.5III',
      absoluteMagnitude: -0.30,
      parallax: 88.85,
    ),

    // Vega (α Lyrae) - one of the brightest northern stars
    HIPStar(
      hipNumber: 91262,
      properName: 'Vega',
      ra: 279.235,
      dec: 38.785,
      apparentMagnitude: 0.03,
      spectralClass: 'A0V',
      absoluteMagnitude: 0.58,
      parallax: 128.93,
    ),

    // Rigel (β Orionis) - a hot blue supergiant
    HIPStar(
      hipNumber: 24436,
      properName: 'Rigel',
      ra: 78.634,
      dec: -8.201,
      apparentMagnitude: 0.18,
      spectralClass: 'B8Iae',
      absoluteMagnitude: -6.69,
      parallax: 3.78,
    ),

    // Procyon (α Canis Minoris)
    HIPStar(
      hipNumber: 37279,
      properName: 'Procyon',
      ra: 114.829,
      dec: 5.225,
      apparentMagnitude: 0.40,
      spectralClass: 'F5IV-V',
      absoluteMagnitude: 2.66,
      parallax: 285.93,
    ),

    // Achernar (α Eridani)
    HIPStar(
      hipNumber: 7588,
      properName: 'Achernar',
      ra: 24.429,
      dec: -57.237,
      apparentMagnitude: 0.46,
      spectralClass: 'B6Vpe',
      absoluteMagnitude: -1.16,
      parallax: 22.68,
    ),

    // Betelgeuse (α Orionis) - a red supergiant
    HIPStar(
      hipNumber: 27989,
      properName: 'Betelgeuse',
      ra: 88.793,
      dec: 7.407,
      apparentMagnitude: 0.42,
      spectralClass: 'M1-2Ia-ab',
      absoluteMagnitude: -5.85,
      parallax: 4.51,
    ),

    // Pollux (β Geminorum)
    HIPStar(
      hipNumber: 36850,
      properName: 'Pollux',
      ra: 116.327,
      dec: 28.026,
      apparentMagnitude: 1.14,
      spectralClass: 'K0IIIb',
      absoluteMagnitude: 1.04,
      parallax: 96.49,
    ),

    // ========================================================================
    // BRIGHT STARS (magnitude ~1.0–2.5)
    // ========================================================================

    HIPStar(
      hipNumber: 26311,
      properName: 'Albireo',
      ra: 82.921,
      dec: 5.600,
      apparentMagnitude: 1.25,
      spectralClass: 'K3II',
      absoluteMagnitude: -1.94,
      parallax: 5.69,
    ),

    HIPStar(
      hipNumber: 21421,
      properName: 'Antares',
      ra: 246.359,
      dec: -26.432,
      apparentMagnitude: 0.96,
      spectralClass: 'M1Ib',
      absoluteMagnitude: -5.28,
      parallax: 5.22,
    ),

    HIPStar(
      hipNumber: 65474,
      properName: 'Altair',
      ra: 297.696,
      dec: 8.868,
      apparentMagnitude: 0.76,
      spectralClass: 'A7V',
      absoluteMagnitude: 2.20,
      parallax: 194.44,
    ),

    HIPStar(
      hipNumber: 37826,
      properName: 'Albireo',
      ra: 84.053,
      dec: -1.202,
      apparentMagnitude: 1.69,
      spectralClass: 'B0Ia',
      absoluteMagnitude: -6.01,
      parallax: 2.86,
    ),

    HIPStar(
      hipNumber: 54061,
      properName: 'Dubhe',
      ra: 165.46,
      dec: 61.45,
      apparentMagnitude: 1.79,
      spectralClass: 'K0III',
      absoluteMagnitude: -1.03,
      parallax: 29.84,
    ),

    // ========================================================================
    // MEDIUM-BRIGHT STARS (magnitude ~2.5–4.0)
    // ========================================================================

    HIPStar(
      hipNumber: 677,
      properName: 'Sheratan',
      ra: 2.097,
      dec: 20.808,
      apparentMagnitude: 2.64,
      spectralClass: 'A5V',
      absoluteMagnitude: 2.04,
      parallax: 56.48,
    ),

    HIPStar(
      hipNumber: 3179,
      properName: 'Hamal',
      ra: 2.097,
      dec: 23.462,
      apparentMagnitude: 2.00,
      spectralClass: 'K2III',
      absoluteMagnitude: 0.48,
      parallax: 49.19,
    ),

    HIPStar(
      hipNumber: 15457,
      properName: 'Menkar',
      ra: 48.640,
      dec: 4.229,
      apparentMagnitude: 2.53,
      spectralClass: 'M6.5III',
      absoluteMagnitude: -3.38,
      parallax: 10.26,
    ),

    HIPStar(
      hipNumber: 78401,
      properName: 'Deneb',
      ra: 310.358,
      dec: 45.280,
      apparentMagnitude: 1.25,
      spectralClass: 'A2Iae',
      absoluteMagnitude: -8.38,
      parallax: 2.60,
    ),

    // ========================================================================
    // DIM STARS (magnitude ~4.0–5.5) - near naked-eye limit
    // ========================================================================

    HIPStar(
      hipNumber: 24436,
      properName: 'Alnilam',
      ra: 85.265,
      dec: -2.599,
      apparentMagnitude: 1.74,
      spectralClass: 'B0Ia',
      absoluteMagnitude: -7.19,
      parallax: 1.49,
    ),

    HIPStar(
      hipNumber: 42913,
      properName: 'Castor',
      ra: 113.649,
      dec: 31.789,
      apparentMagnitude: 1.58,
      spectralClass: 'A2V',
      absoluteMagnitude: 0.49,
      parallax: 64.09,
    ),

    HIPStar(
      hipNumber: 78820,
      properName: 'Sadr',
      ra: 296.625,
      dec: 40.256,
      apparentMagnitude: 2.20,
      spectralClass: 'F8Ib',
      absoluteMagnitude: -6.21,
      parallax: 4.23,
    ),
  ];

  /// Get stars visible for a latitude and local sidereal time.
  static List<HIPStar> getVisibleStars(
    double latitude,
    double lst, // Local Sidereal Time
    {
      double maxMagnitude = 5.5, // Naked-eye-ish limit
      double minAltitude = -5.0,  // Minimum altitude above horizon
    }
  ) {
    return stars.where((star) {
      // Brightness filter
      if (star.apparentMagnitude > maxMagnitude) return false;

      // Altitude filter
      final altitude = _calculateAltitude(
        star.ra,
        star.dec,
        latitude,
        lst,
      );

      return altitude >= minAltitude;
    }).toList();
  }

  /// Find a star by name or HIP number.
  static HIPStar? getStarByName(String name) {
    try {
      return stars.firstWhere(
        (star) =>
            star.properName?.toLowerCase() == name.toLowerCase() ||
            star.hipNumber.toString() == name,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the brightest stars (top N).
  static List<HIPStar> getBrightestStars({int limit = 50}) {
    final sorted = List<HIPStar>.from(stars);
    sorted.sort((a, b) => a.apparentMagnitude.compareTo(b.apparentMagnitude));
    return sorted.take(limit).toList();
  }

  /// Get stars by spectral class prefix.
  static List<HIPStar> getStarsBySpectralClass(String spectralClass) {
    return stars
        .where((star) => star.spectralClass.startsWith(spectralClass))
        .toList();
  }

  /// ========================================================================
  /// ASTRONOMY UTILITIES
  /// ========================================================================

  /// Compute altitude above the horizon for a star.
  static double _calculateAltitude(
    double ra,
    double dec,
    double lat,
    double lst,
  ) {
    const degToRad = pi / 180.0;

    final ha = (lst - ra + 360) % 360;
    final ha_rad = ha * degToRad;
    final dec_rad = dec * degToRad;
    final lat_rad = lat * degToRad;

    final sin_alt = sin(dec_rad) * sin(lat_rad) +
        cos(dec_rad) * cos(lat_rad) * cos(ha_rad);

    final altitude_rad = asin(sin_alt);
    return altitude_rad / degToRad;
  }

  /// Compute azimuth for a star.
  static double _calculateAzimuth(
    double ra,
    double dec,
    double lat,
    double lst,
  ) {
    const degToRad = pi / 180.0;

    final ha = (lst - ra + 360) % 360;
    final ha_rad = ha * degToRad;
    final dec_rad = dec * degToRad;
    final lat_rad = lat * degToRad;

    final sin_az = -sin(ha_rad) /
        sqrt(1 -
            (sin(dec_rad) * sin(lat_rad) +
                    cos(dec_rad) * cos(lat_rad) * cos(ha_rad)) *
                (sin(dec_rad) * sin(lat_rad) +
                    cos(dec_rad) * cos(lat_rad) * cos(ha_rad)));

    final azimuth_rad = asin(sin_az);
    return (azimuth_rad / degToRad + 360) % 360;
  }

  /// Catalog statistics.
  static Map<String, dynamic> getCatalogStatistics() {
    return {
      'totalStars': stars.length,
      'brightestStar': stars.reduce((a, b) =>
          a.apparentMagnitude < b.apparentMagnitude ? a : b).properName,
      'dimmestStar': stars.reduce((a, b) =>
          a.apparentMagnitude > b.apparentMagnitude ? a : b).properName,
      'averageMagnitude':
          stars.map((s) => s.apparentMagnitude).reduce((a, b) => a + b) /
              stars.length,
      'spectralClassDistribution': {
        'O': stars.where((s) => s.spectralClass.startsWith('O')).length,
        'B': stars.where((s) => s.spectralClass.startsWith('B')).length,
        'A': stars.where((s) => s.spectralClass.startsWith('A')).length,
        'F': stars.where((s) => s.spectralClass.startsWith('F')).length,
        'G': stars.where((s) => s.spectralClass.startsWith('G')).length,
        'K': stars.where((s) => s.spectralClass.startsWith('K')).length,
        'M': stars.where((s) => s.spectralClass.startsWith('M')).length,
      },
    };
  }
}