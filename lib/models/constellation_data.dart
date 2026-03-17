// ============================================================================
// 1️⃣ EXTENDED CONSTELLATIONS (15+ constellations)
// ============================================================================

import 'dart:math';

/// A star within a constellation with astronomical coordinates.
class ConstellationStar {
  final String name;
  final double ra;        // Right Ascension (0-360°)
  final double dec;       // Declination (-90 to +90°)
  final double magnitude; // Apparent magnitude (-2 to +6)

  const ConstellationStar({
    required this.name,
    required this.ra,
    required this.dec,
    required this.magnitude,
  });
}

/// A line connecting two stars in a constellation.
class ConstellationLine {
  final int starIndex1;
  final int starIndex2;

  const ConstellationLine(this.starIndex1, this.starIndex2);
}

/// Full constellation info.
class ConstellationInfo {
  final String name;              // Display name
  final String latinName;         // Latin name
  final String englishName;       // English name
  final String symbolism;         // What it represents
  final List<ConstellationStar> stars;
  final List<ConstellationLine> lines;
  final String description;

  const ConstellationInfo({
    required this.name,
    required this.latinName,
    required this.englishName,
    required this.symbolism,
    required this.stars,
    required this.lines,
    required this.description,
  });
}

class ConstellationCatalog {
  /// Catalog of 15+ constellations with coordinates.
  static final Map<String, ConstellationInfo> allConstellations = {
    // ========================================================================
    // 1. ORION
    // ========================================================================
    'Orion': ConstellationInfo(
      name: 'Orion',
      latinName: 'Orion',
      englishName: 'Orion',
      symbolism: 'A hunter in Greek mythology',
      stars: [
        ConstellationStar(
          name: 'Rigel',           // Left foot
          ra: 83.822,
          dec: -8.201,
          magnitude: 0.18,
        ),
        ConstellationStar(
          name: 'Betelgeuse',      // Left shoulder (red supergiant)
          ra: 88.793,
          dec: 7.407,
          magnitude: 0.42,
        ),
        ConstellationStar(
          name: 'Bellatrix',       // Right shoulder
          ra: 81.273,
          dec: 6.349,
          magnitude: 1.64,
        ),
        ConstellationStar(
          name: 'Saiph',           // Right foot
          ra: 85.265,
          dec: -2.599,
          magnitude: 2.07,
        ),
        ConstellationStar(
          name: 'Mintaka',         // Belt star 1
          ra: 82.921,
          dec: -0.299,
          magnitude: 2.23,
        ),
        ConstellationStar(
          name: 'Alnilam',         // Belt star 2
          ra: 84.053,
          dec: -1.202,
          magnitude: 1.69,
        ),
        ConstellationStar(
          name: 'Alnitak',         // Belt star 3
          ra: 85.265,
          dec: -2.599,
          magnitude: 1.74,
        ),
      ],
      lines: [
        ConstellationLine(0, 1),  // Rigel to Betelgeuse
        ConstellationLine(1, 2),  // Betelgeuse to Bellatrix
        ConstellationLine(2, 3),  // Bellatrix to Saiph
        ConstellationLine(3, 0),  // Saiph to Rigel
        ConstellationLine(4, 5),  // Mintaka to Alnilam
        ConstellationLine(5, 6),  // Alnilam to Alnitak
      ],
      description: 'One of the brightest constellations, visible from both hemispheres.',
    ),

    // ========================================================================
    // 2. URSA MAJOR
    // ========================================================================
    'Ursa Major': ConstellationInfo(
      name: 'Ursa Major',
      latinName: 'Ursa Major',
      englishName: 'Big Dipper / Great Bear',
      symbolism: 'The Great Bear; includes the Big Dipper asterism',
      stars: [
        ConstellationStar(name: 'Dubhe',   ra: 165.46, dec: 61.45, magnitude: 1.79),
        ConstellationStar(name: 'Merak',   ra: 164.74, dec: 56.38, magnitude: 2.37),
        ConstellationStar(name: 'Phecda',  ra: 178.46, dec: 53.41, magnitude: 2.44),
        ConstellationStar(name: 'Megrez',  ra: 186.45, dec: 57.03, magnitude: 3.31),
        ConstellationStar(name: 'Alioth',  ra: 193.51, dec: 55.96, magnitude: 1.77),
        ConstellationStar(name: 'Mizar',   ra: 201.02, dec: 54.92, magnitude: 2.06),
        ConstellationStar(name: 'Alkaid',  ra: 206.88, dec: 49.32, magnitude: 1.86),
      ],
      lines: [
        ConstellationLine(0, 1), // Dubhe to Merak
        ConstellationLine(1, 2), // Merak to Phecda
        ConstellationLine(2, 3), // Phecda to Megrez
        ConstellationLine(3, 4), // Megrez to Alioth
        ConstellationLine(4, 5), // Alioth to Mizar
        ConstellationLine(5, 6), // Mizar to Alkaid
      ],
      description: 'A famous northern constellation often used for navigation.',
    ),

    // ========================================================================
    // 3. CASSIOPEIA
    // ========================================================================
    'Cassiopeia': ConstellationInfo(
      name: 'Cassiopeia',
      latinName: 'Cassiopeia',
      englishName: 'Cassiopeia (W-shape)',
      symbolism: 'The Queen of Ethiopia in Greek mythology',
      stars: [
        ConstellationStar(name: 'Scheherazade (α)',  ra: 10.126,  dec: 56.537, magnitude: 2.23),
        ConstellationStar(name: 'Caph (β)',          ra: 2.296,   dec: 59.150, magnitude: 2.27),
        ConstellationStar(name: 'Gamma Cas',         ra: 14.177,  dec: 60.717, magnitude: 2.47),
        ConstellationStar(name: 'Ruchbah (δ)',       ra: 20.759,  dec: 60.439, magnitude: 2.68),
        ConstellationStar(name: 'Segin (ε)',         ra: 25.417,  dec: 63.670, magnitude: 3.38),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(1, 2),
        ConstellationLine(2, 3),
        ConstellationLine(3, 4),
      ],
      description: 'A distinctive W-shaped constellation, visible most of the year in the north.',
    ),

    // ========================================================================
    // 4. CYGNUS
    // ========================================================================
    'Cygnus': ConstellationInfo(
      name: 'Cygnus',
      latinName: 'Cygnus',
      englishName: 'Swan (Northern Cross)',
      symbolism: 'A swan; commonly recognized as the Northern Cross',
      stars: [
        ConstellationStar(name: 'Deneb (α)',    ra: 310.358, dec: 45.280, magnitude: 1.25),
        ConstellationStar(name: 'Sadr (γ)',     ra: 296.625, dec: 40.256, magnitude: 2.20),
        ConstellationStar(name: 'Gienah (ε)',   ra: 284.825, dec: 33.971, magnitude: 2.48),
        ConstellationStar(name: 'Albireo (β)',  ra: 292.686, dec: 27.957, magnitude: 3.18),
        ConstellationStar(name: 'Delta Cyg',    ra: 301.505, dec: 43.193, magnitude: 2.86),
      ],
      lines: [
        ConstellationLine(0, 1), // Deneb to Sadr (spine)
        ConstellationLine(1, 2), // Sadr to Gienah (wing)
        ConstellationLine(1, 3), // Sadr to Albireo (wing)
        ConstellationLine(1, 4), // Sadr to Delta Cyg (wing)
      ],
      description: 'Often seen as the Northern Cross in summer skies.',
    ),

    // ========================================================================
    // 5. LYRA
    // ========================================================================
    'Lyra': ConstellationInfo(
      name: 'Lyra',
      latinName: 'Lyra',
      englishName: 'Lyre (Harp)',
      symbolism: 'A lyre/harp from Greek legend',
      stars: [
        ConstellationStar(name: 'Vega (α)',       ra: 279.235, dec: 38.785, magnitude: 0.03),
        ConstellationStar(name: 'Sheliak (β)',    ra: 281.460, dec: 43.183, magnitude: 3.52),
        ConstellationStar(name: 'Sulafat (γ)',    ra: 288.802, dec: 32.689, magnitude: 3.24),
        ConstellationStar(name: 'Ζ Lyrae',        ra: 282.465, dec: 37.627, magnitude: 4.34),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(1, 2),
        ConstellationLine(2, 0),
      ],
      description: 'Home to Vega, one of the brightest stars in the sky.',
    ),

    // ========================================================================
    // 6. AQUILA
    // ========================================================================
    'Aquila': ConstellationInfo(
      name: 'Aquila',
      latinName: 'Aquila',
      englishName: 'Eagle',
      symbolism: 'An eagle in Greek mythology',
      stars: [
        ConstellationStar(name: 'Altair (α)',    ra: 297.696, dec: 8.868, magnitude: 0.76),
        ConstellationStar(name: 'Alshain (β)',   ra: 299.239, dec: 6.406, magnitude: 3.71),
        ConstellationStar(name: 'Tarazed (γ)',   ra: 308.315, dec: 10.613, magnitude: 2.72),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(0, 2),
      ],
      description: 'A Milky Way constellation prominent in summer.',
    ),

    // ========================================================================
    // 7. SCORPIUS
    // ========================================================================
    'Scorpius': ConstellationInfo(
      name: 'Scorpius',
      latinName: 'Scorpius',
      englishName: 'Scorpion',
      symbolism: 'The scorpion associated with Orion in myth',
      stars: [
        ConstellationStar(name: 'Antares (α)',  ra: 246.359, dec: -26.432, magnitude: 0.96),
        ConstellationStar(name: 'Graffias (β)', ra: 241.359, dec: -25.591, magnitude: 2.62),
        ConstellationStar(name: 'Dschubba (δ)', ra: 244.506, dec: -22.622, magnitude: 2.29),
        ConstellationStar(name: 'Sargas (θ)',   ra: 263.029, dec: -42.998, magnitude: 1.86),
        ConstellationStar(name: 'Shaula (λ)',   ra: 263.540, dec: -37.103, magnitude: 1.62),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(1, 2),
        ConstellationLine(0, 3),
        ConstellationLine(3, 4),
      ],
      description: 'A southern constellation best seen in summer.',
    ),

    // ========================================================================
    // 8. SAGITTARIUS
    // ========================================================================
    'Sagittarius': ConstellationInfo(
      name: 'Sagittarius',
      latinName: 'Sagittarius',
      englishName: 'Archer',
      symbolism: 'A centaur archer',
      stars: [
        ConstellationStar(name: 'Kaus Australis (ε)',  ra: 276.359, dec: -34.384, magnitude: 1.85),
        ConstellationStar(name: 'Kaus Media (δ)',      ra: 275.246, dec: -29.828, magnitude: 2.70),
        ConstellationStar(name: 'Kaus Borealis (λ)',   ra: 273.961, dec: -25.422, magnitude: 2.81),
        ConstellationStar(name: 'Nunki (σ)',           ra: 299.059, dec: -26.296, magnitude: 2.05),
        ConstellationStar(name: 'Ascella (ζ)',         ra: 276.945, dec: -29.248, magnitude: 2.60),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(1, 2),
        ConstellationLine(0, 4),
      ],
      description: 'Located toward the center of the Milky Way.',
    ),

    // ========================================================================
    // 9. VIRGO
    // ========================================================================
    'Virgo': ConstellationInfo(
      name: 'Virgo',
      latinName: 'Virgo',
      englishName: 'Maiden',
      symbolism: 'Associated with harvest deities in mythology',
      stars: [
        ConstellationStar(name: 'Spica (α)',    ra: 201.299, dec: -11.161, magnitude: 0.98),
        ConstellationStar(name: 'Zavijava (β)', ra: 181.762, dec: 1.440, magnitude: 3.59),
        ConstellationStar(name: 'Porrima (γ)',  ra: 192.660, dec: -1.449, magnitude: 2.97),
        ConstellationStar(name: 'Auva (δ)',     ra: 199.850, dec: 3.397, magnitude: 3.38),
        ConstellationStar(name: 'Minelauva (ε)', ra: 213.254, dec: 10.957, magnitude: 2.80),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(1, 2),
        ConstellationLine(2, 3),
        ConstellationLine(0, 4),
      ],
      description: 'The largest constellation of the zodiac.',
    ),

    // ========================================================================
    // 10. LEO
    // ========================================================================
    'Leo': ConstellationInfo(
      name: 'Leo',
      latinName: 'Leo',
      englishName: 'Lion',
      symbolism: 'The Nemean Lion from Greek mythology',
      stars: [
        ConstellationStar(name: 'Regulus (α)',      ra: 152.093, dec: 11.967, magnitude: 1.35),
        ConstellationStar(name: 'Denebola (β)',     ra: 177.265, dec: 14.572, magnitude: 2.14),
        ConstellationStar(name: 'Algieba (γ)',      ra: 154.549, dec: 19.841, magnitude: 2.01),
        ConstellationStar(name: 'Adhafera (ζ)',     ra: 149.435, dec: 23.417, magnitude: 3.44),
        ConstellationStar(name: 'Chort (δ)',        ra: 160.393, dec: 20.525, magnitude: 2.56),
      ],
      lines: [
        ConstellationLine(0, 2), // Regulus to Algieba (body)
        ConstellationLine(2, 3), // Algieba to Adhafera (front)
        ConstellationLine(0, 1), // Regulus to Denebola (tail)
      ],
      description: 'A prominent zodiac constellation representing a lion.',
    ),

    // ========================================================================
    // 11. TAURUS
    // ========================================================================
    'Taurus': ConstellationInfo(
      name: 'Taurus',
      latinName: 'Taurus',
      englishName: 'Bull',
      symbolism: 'A bull in Greek mythology',
      stars: [
        ConstellationStar(name: 'Aldebaran (α)',  ra: 68.985, dec: 16.507, magnitude: 0.87),
        ConstellationStar(name: 'Elnath (β)',     ra: 88.790, dec: 28.608, magnitude: 1.65),
        ConstellationStar(name: 'Alcyone (η)',    ra: 56.623, dec: 24.105, magnitude: 2.87),
        ConstellationStar(name: 'Electra (17)',   ra: 57.265, dec: 24.118, magnitude: 3.72),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(0, 2),
      ],
      description: 'Contains the Pleiades, a young open star cluster.',
    ),

    // ========================================================================
    // 12. GEMINI
    // ========================================================================
    'Gemini': ConstellationInfo(
      name: 'Gemini',
      latinName: 'Gemini',
      englishName: 'Twins',
      symbolism: 'The twins Castor and Pollux',
      stars: [
        ConstellationStar(name: 'Pollux (β)',     ra: 116.327, dec: 28.026, magnitude: 1.14),
        ConstellationStar(name: 'Castor (α)',     ra: 113.649, dec: 31.789, magnitude: 1.58),
        ConstellationStar(name: 'Alhena (γ)',     ra: 99.428,  dec: 16.399, magnitude: 1.93),
        ConstellationStar(name: 'Wasat (δ)',      ra: 110.488, dec: 21.985, magnitude: 3.53),
      ],
      lines: [
        ConstellationLine(0, 1), // Pollux to Castor
        ConstellationLine(1, 2), // Castor to Alhena
      ],
      description: 'A zodiac constellation representing twins.',
    ),

    // ========================================================================
    // 13. PISCES
    // ========================================================================
    'Pisces': ConstellationInfo(
      name: 'Pisces',
      latinName: 'Pisces',
      englishName: 'Fishes',
      symbolism: 'Two fishes tied together in myth',
      stars: [
        ConstellationStar(name: 'Alrescha (α)', ra: 2.796,  dec: 2.760, magnitude: 3.62),
        ConstellationStar(name: 'Samakah (β)',  ra: 347.649, dec: 3.813, magnitude: 4.53),
        ConstellationStar(name: 'Kaff al Muzarr (γ)', ra: 23.402, dec: 3.314, magnitude: 3.70),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(0, 2),
      ],
      description: 'A zodiac constellation representing two fishes.',
    ),

    // ========================================================================
    // 14. PEGASUS
    // ========================================================================
    'Pegasus': ConstellationInfo(
      name: 'Pegasus',
      latinName: 'Pegasus',
      englishName: 'Winged Horse',
      symbolism: 'The winged horse from Greek mythology',
      stars: [
        ConstellationStar(name: 'Enif (ε)',     ra: 337.290, dec: 9.875, magnitude: 2.38),
        ConstellationStar(name: 'Scheat (β)',   ra: 345.403, dec: 27.714, magnitude: 2.42),
        ConstellationStar(name: 'Algenib (γ)',  ra: 0.225,   dec: 15.183, magnitude: 2.83),
        ConstellationStar(name: 'Markab (α)',   ra: 346.102, dec: 15.185, magnitude: 2.49),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(1, 2),
        ConstellationLine(2, 3),
      ],
      description: 'Notable for the Great Square of Pegasus in northern skies.',
    ),

    // ========================================================================
    // 15. PERSEUS
    // ========================================================================
    'Perseus': ConstellationInfo(
      name: 'Perseus',
      latinName: 'Perseus',
      englishName: 'Hero',
      symbolism: 'The hero Perseus in Greek mythology',
      stars: [
        ConstellationStar(name: 'Mirfak (α)',   ra: 51.800, dec: 49.861, magnitude: 1.79),
        ConstellationStar(name: 'Algol (β)',    ra: 47.042, dec: 40.955, magnitude: 2.12),
        ConstellationStar(name: 'Atik (c)',     ra: 45.005, dec: 40.008, magnitude: 4.98),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(1, 2),
      ],
      description: 'Contains Algol, a famous eclipsing binary.',
    ),

    // ========================================================================
    // 16. ANDROMEDA
    // ========================================================================
    'Andromeda': ConstellationInfo(
      name: 'Andromeda',
      latinName: 'Andromeda',
      englishName: 'Chained Maiden',
      symbolism: 'Princess Andromeda in Greek mythology',
      stars: [
        ConstellationStar(name: 'Sirrah (α)',   ra: 0.142,   dec: 29.090, magnitude: 2.06),
        ConstellationStar(name: 'Mirach (β)',   ra: 1.161,   dec: 35.623, magnitude: 2.06),
        ConstellationStar(name: 'Almach (γ)',   ra: 2.098,   dec: 42.330, magnitude: 2.26),
      ],
      lines: [
        ConstellationLine(0, 1),
        ConstellationLine(1, 2),
      ],
      description: 'Home to the Andromeda Galaxy, our nearest major neighbor.',
    ),
  };

  /// Get all constellation keys.
  static List<String> getConstellationNames() {
    return allConstellations.keys.toList();
  }

  /// Get a constellation by key.
  static ConstellationInfo? getConstellation(String name) {
    return allConstellations[name];
  }

  /// Get constellations visible for a latitude and local sidereal time.
  static List<ConstellationInfo> getVisibleConstellations(
    double latitude,
    double lst, // Local Sidereal Time
    {
      double minAltitude = -5.0,
    }
  ) {
    final visible = <ConstellationInfo>[];

    for (final constellation in allConstellations.values) {
      // Consider the constellation visible if at least one star is above the minimum altitude.
      bool isVisible = false;

      for (final star in constellation.stars) {
        final altitude = _calculateAltitude(star.ra, star.dec, latitude, lst);
        if (altitude >= minAltitude) {
          isVisible = true;
          break;
        }
      }

      if (isVisible) {
        visible.add(constellation);
      }
    }

    return visible;
  }

  /// Calculate altitude above the horizon for a star.
  static double _calculateAltitude(
    double ra,
    double dec,
    double lat,
    double lst,
  ) {
    const degToRad = pi / 180.0;

    final ha = (lst - ra + 360) % 360;
    final haRad = ha * degToRad;
    final decRad = dec * degToRad;
    final latRad = lat * degToRad;

    final sinAlt =
        sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(haRad);

    return asin(sinAlt) / degToRad;
  }
}