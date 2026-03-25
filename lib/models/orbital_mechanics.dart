// ============================================================================
// 3️⃣ IMPROVED ORBITAL MECHANICS (Kepler's Equation)
// ============================================================================

import 'dart:math';

/// Orbital elements for a planet used to estimate its position.
/// Based on a simplified two-body model and Kepler's laws.
class OrbitalElements {
  final String name;
  final double semiMajorAxis;      // a (AU)
  final double eccentricity;        // e (0..1)
  final double inclination;         // i (degrees)
  final double longitudeAscendingNode; // Ω (degrees)
  final double argumentOfPerihelion;   // ω (degrees)
  final double meanAnomalyAtEpoch;     // M0 (degrees) at epoch
  final double meanMotion;             // n (degrees/day)
  final DateTime epoch;                // Epoch (e.g., J2000.0)

  const OrbitalElements({
    required this.name,
    required this.semiMajorAxis,
    required this.eccentricity,
    required this.inclination,
    required this.longitudeAscendingNode,
    required this.argumentOfPerihelion,
    required this.meanAnomalyAtEpoch,
    required this.meanMotion,
    required this.epoch,
  });

  /// Compute an estimated equatorial position (RA, Dec) for a given Julian date.
  /// Returns (RA, Dec) in degrees.
  (double ra, double dec) getEquatorialPosition(double julianDate) {
    // Convert heliocentric planetary coordinates to geocentric before RA/Dec.
    // Apply a light-time correction so we observe the planet where it appears,
    // not where it is "now" in barycentric time.
    var (xEarth, yEarth, zEarth) = earth._heliocentricEcliptic(julianDate);
    var (xPlanet, yPlanet, zPlanet) = _heliocentricEcliptic(julianDate);

    // Speed of light in AU/day.
    const cAuPerDay = 173.1446326846693;

    // 2-iteration light-time refinement is a good accuracy/perf compromise.
    for (var i = 0; i < 2; i++) {
      final dx = xPlanet - xEarth;
      final dy = yPlanet - yEarth;
      final dz = zPlanet - zEarth;
      final distanceAu = sqrt(dx * dx + dy * dy + dz * dz);
      final lightTimeDays = distanceAu / cAuPerDay;

      (xPlanet, yPlanet, zPlanet) =
          _heliocentricEcliptic(julianDate - lightTimeDays);
      (xEarth, yEarth, zEarth) = earth._heliocentricEcliptic(julianDate);
    }

    final xGeo = xPlanet - xEarth;
    final yGeo = yPlanet - yEarth;
    final zGeo = zPlanet - zEarth;

    // Transform ecliptic -> equatorial
    const epsilon = 23.4393 * pi / 180; // Obliquity of the ecliptic

    final xEquatorial = xGeo;
    final yEquatorial = yGeo * cos(epsilon) - zGeo * sin(epsilon);
    final zEquatorial = yGeo * sin(epsilon) + zGeo * cos(epsilon);

    // 9) RA/Dec
    final ra = atan2(yEquatorial, xEquatorial);
    final dec =
        atan2(zEquatorial, sqrt(xEquatorial * xEquatorial + yEquatorial * yEquatorial));

    // Convert to degrees and normalize
    final raGrades = (ra * 180 / pi + 360) % 360;
    final decGrades = dec * 180 / pi;

    return (raGrades, decGrades);
  }

  /// Heliocentric ecliptic rectangular coordinates (AU).
  (double x, double y, double z) _heliocentricEcliptic(double julianDate) {
    // 1) Days since epoch
    final daysSinceEpoch = julianDate - _epochToJulian(epoch);

    // 2) Mean anomaly (M): M = M0 + n * (JD - JD0)
    final meanAnomaly =
        (meanAnomalyAtEpoch + meanMotion * daysSinceEpoch) % 360;
    final meanAnomalyRad = meanAnomaly * pi / 180;

    // 3) Solve Kepler's equation for eccentric anomaly (Newton-Raphson)
    final eccentricAnomaly =
        _solveKeplersEquation(meanAnomalyRad, eccentricity);

    // 4) True anomaly (v)
    final trueAnomaly = 2 *
        atan2(
          sqrt(1 + eccentricity) * sin(eccentricAnomaly / 2),
          sqrt(1 - eccentricity) * cos(eccentricAnomaly / 2),
        );

    // 5) Heliocentric distance (r)
    final distance = semiMajorAxis * (1 - eccentricity * cos(eccentricAnomaly));

    // 6) Coordinates in orbital plane
    final xOrbital = distance * cos(trueAnomaly);
    final yOrbital = distance * sin(trueAnomaly);

    // 7) Transform to ecliptic coordinates
    final omegaRad = longitudeAscendingNode * pi / 180;
    final omegaPrimRad = argumentOfPerihelion * pi / 180;
    final iRad = inclination * pi / 180;

    final xEcliptic = (cos(omegaRad) * cos(omegaPrimRad) -
            sin(omegaRad) * sin(omegaPrimRad) * cos(iRad)) *
        xOrbital +
        (-cos(omegaRad) * sin(omegaPrimRad) -
            sin(omegaRad) * cos(omegaPrimRad) * cos(iRad)) *
        yOrbital;

    final yEcliptic = (sin(omegaRad) * cos(omegaPrimRad) +
            cos(omegaRad) * sin(omegaPrimRad) * cos(iRad)) *
        xOrbital +
        (-sin(omegaRad) * sin(omegaPrimRad) +
            cos(omegaRad) * cos(omegaPrimRad) * cos(iRad)) *
        yOrbital;

    final zEcliptic = sin(omegaPrimRad) * sin(iRad) * xOrbital +
        cos(omegaPrimRad) * sin(iRad) * yOrbital;

    return (xEcliptic, yEcliptic, zEcliptic);
  }

  /// Solve Kepler's equation for E (radians) using Newton-Raphson.
  static double _solveKeplersEquation(double meanAnomalyRad, double e) {
    const tolerance = 1e-10;
    const maxIterations = 100;

    // Initial guess
    var E = meanAnomalyRad;

    for (int i = 0; i < maxIterations; i++) {
      // f(E) = E - e·sin(E) - M
      final f = E - e * sin(E) - meanAnomalyRad;

      // f'(E) = 1 - e·cos(E)
      final fPrime = 1 - e * cos(E);

      // Newton-Raphson: E_{n+1} = E_n - f(E_n) / f'(E_n)
      final delta = f / fPrime;
      E = E - delta;

      // Convergence check
      if (delta.abs() < tolerance) {
        return E;
      }
    }

    return E; // Best effort
  }

  /// Approx distance to the planet from Earth (placeholder).
  double getDistanceFromEarth(double julianDate) {
    // Simplified: return semi-major axis as a rough estimate.
    return semiMajorAxis;
  }

  /// Apparent magnitude estimate (placeholder).
  double getApparentMagnitude(double julianDate) {
    // A real model needs phase angle, distances, albedo, etc.
    return 0.0;
  }

  /// Convert a DateTime to Julian date.
  static double _epochToJulian(DateTime dt) {
    final days = dt.millisecondsSinceEpoch / (86400 * 1000);
    return 2440587.5 + days;
  }

  /// ========================================================================
  /// PREDEFINED PLANET ELEMENTS (J2000.0-ish)
  /// Source: NASA/JPL (educational, simplified)
  /// ========================================================================

  // NOTE: DateTime is not a compile-time constant in Dart, so these cannot be
  // `const`. Keep them as `static final` so they remain singletons.
  static final OrbitalElements mercury = OrbitalElements(
    name: 'Mercury',
    semiMajorAxis: 0.387098,
    eccentricity: 0.205633,
    inclination: 7.0047,
    longitudeAscendingNode: 48.3313,
    argumentOfPerihelion: 29.1241,
    meanAnomalyAtEpoch: 174.7947,
    meanMotion: 4.0923344,
    epoch: DateTime.utc(2000, 1, 1, 12, 0, 0),
  );

  static final OrbitalElements venus = OrbitalElements(
    name: 'Venus',
    semiMajorAxis: 0.723330,
    eccentricity: 0.006773,
    inclination: 3.3946,
    longitudeAscendingNode: 76.6799,
    argumentOfPerihelion: 54.8910,
    meanAnomalyAtEpoch: 50.4084,
    meanMotion: 1.6021302,
    epoch: DateTime.utc(2000, 1, 1, 12, 0, 0),
  );

  static final OrbitalElements mars = OrbitalElements(
    name: 'Mars',
    semiMajorAxis: 1.523688,
    eccentricity: 0.093405,
    inclination: 1.8497,
    longitudeAscendingNode: 49.5574,
    argumentOfPerihelion: 286.5016,
    meanAnomalyAtEpoch: 19.3881,
    meanMotion: 0.5240208,
    epoch: DateTime.utc(2000, 1, 1, 12, 0, 0),
  );

  static final OrbitalElements jupiter = OrbitalElements(
    name: 'Jupiter',
    semiMajorAxis: 5.20256,
    eccentricity: 0.048498,
    inclination: 1.3030,
    longitudeAscendingNode: 100.4542,
    argumentOfPerihelion: 273.8677,
    meanAnomalyAtEpoch: 20.0196,
    meanMotion: 0.0830853,
    epoch: DateTime.utc(2000, 1, 1, 12, 0, 0),
  );

  static final OrbitalElements saturn = OrbitalElements(
    name: 'Saturn',
    semiMajorAxis: 9.55475,
    eccentricity: 0.055546,
    inclination: 2.4886,
    longitudeAscendingNode: 113.6655,
    argumentOfPerihelion: 339.3939,
    meanAnomalyAtEpoch: 317.0172,
    meanMotion: 0.0334442,
    epoch: DateTime.utc(2000, 1, 1, 12, 0, 0),
  );

  static final OrbitalElements uranus = OrbitalElements(
    name: 'Uranus',
    semiMajorAxis: 19.18171,
    eccentricity: 0.047318,
    inclination: 0.7733,
    longitudeAscendingNode: 74.0005,
    argumentOfPerihelion: 96.6612,
    meanAnomalyAtEpoch: 142.6081,
    meanMotion: 0.0117258,
    epoch: DateTime.utc(2000, 1, 1, 12, 0, 0),
  );

  static final OrbitalElements neptune = OrbitalElements(
    name: 'Neptune',
    semiMajorAxis: 30.05826,
    eccentricity: 0.008606,
    inclination: 1.7700,
    longitudeAscendingNode: 131.7806,
    argumentOfPerihelion: 272.8461,
    meanAnomalyAtEpoch: 260.2561,
    meanMotion: 0.0059951,
    epoch: DateTime.utc(2000, 1, 1, 12, 0, 0),
  );

  static final OrbitalElements earth = OrbitalElements(
    name: 'Earth',
    semiMajorAxis: 1.000000,
    eccentricity: 0.016709,
    inclination: 0.0000,
    longitudeAscendingNode: 0.0,
    argumentOfPerihelion: 102.9404,
    meanAnomalyAtEpoch: 357.5254,
    meanMotion: 0.9856003,
    epoch: DateTime.utc(2000, 1, 1, 12, 0, 0),
  );

  /// Отримати всі планети
  static List<OrbitalElements> getAllPlanets() {
    return [mercury, venus, mars, jupiter, saturn, uranus, neptune];
  }

  /// Отримати планету за назвою
  static OrbitalElements? getPlanetByName(String name) {
    return getAllPlanets()
        .cast<OrbitalElements?>()
        .firstWhere((p) => p?.name == name, orElse: () => null);
  }
}

// ============================================================================
// УТИЛІТАРНІ ФУНКЦІЇ ДЛЯ РОБОТИ З ОРБІТАЛЬНИМИ ЕЛЕМЕНТАМИ
// ============================================================================

class OrbitalUtils {
  static const _ln10 = 2.302585092994046; // ln(10)

  static double _log10(double x) => log(x) / _ln10;

  /// Approximate apparent magnitude (simplified Meeus-style formula).
  static double getApparentMagnitude(
    String planetName,
    double distanceFromEarth, // AU
    double distanceFromSun,   // AU
    double phasAngle,         // degrees (0..180)
  ) {
    // V = V₀ + 5·log₁₀(r·Δ) + β
    // V₀ - базова величина
    // r - відстань від Сонця (AU)
    // Δ - відстань від Землі (AU)
    // β - коефіцієнт фази

    final v0 = switch (planetName) {
      'Mercury' => -0.42,
      'Venus' => -4.40,
      'Mars' => -2.01,
      'Jupiter' => -9.40,
      'Saturn' => -8.94,
      'Uranus' => -7.19,
      'Neptune' => -6.87,
      _ => 0.0,
    };

    final phaseFactor = phasAngle * phasAngle / 180; // Simplified

    final magnitude = v0 +
        5 * _log10(distanceFromSun * distanceFromEarth) +
        phaseFactor * 0.1;

    return magnitude;
  }

  /// Phase angle helper (placeholder).
  static double getPhaseAngle(
    double raEarth,
    double decEarth,
    double rEarth,
    double raPlanet,
    double decPlanet,
    double rPlanet,
  ) {
    // Placeholder.
    return 0.0;
  }

  /// Sidereal period estimate (days), using Kepler's 3rd law: P^2 = a^3.
  static double getSiderealPeriod(double semiMajorAxisAU) {
    // P = sqrt(a^3) years = sqrt(a^3) * 365.25 days
    return sqrt(pow(semiMajorAxisAU, 3)) * 365.25;
  }

  /// Eccentricity vector helper (placeholder).
  static double getEccentricityVector(double eccentricity) {
    return eccentricity;
  }

  /// Simple visibility check by altitude.
  static bool isPlanetVisible(
    double altitude,
    {double minAltitude = -2.0} // Planets may be visible slightly below the horizon
  ) {
    return altitude > minAltitude;
  }
}

