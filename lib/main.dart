import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SkyMapProvider()..initialize(),
      child: const SkyMapApp(),
    ),
  );
}

class SkyMapApp extends StatelessWidget {
  const SkyMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sky Map',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const SkyMapPage(),
    );
  }
}

class SkyMapPage extends StatelessWidget {
  const SkyMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkyMapProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Sky Map'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              provider.statusLine,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTapUp: (details) => provider.onTap(details.localPosition),
              child: CustomPaint(
                painter: SkyPainter(
                  provider.visibleObjects,
                  provider.constellationLines,
                  provider.selectedObject?.name,
                ),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: provider.selectedObject == null
          ? null
          : Container(
              color: const Color(0xFF101010),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.selectedObject!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.selectedObject!.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
    );
  }
}

class SkyMapProvider extends ChangeNotifier {
  static const _degToRad = pi / 180;

  Position? _position;
  AccelerometerEvent? _accelerometerEvent;
  MagnetometerEvent? _magnetometerEvent;
  Timer? _timer;

  final List<CelestialObject> _catalog = [];
  final List<RenderedObject> _visibleObjects = [];
  final List<LineSegment> _constellationLines = [];

  late final double _baseJulian;
  double? _lastSunAz;
  double? _lastSunAlt;
  double _smoothAzimuth = 0;
  double _smoothPitch = 0;

  RenderedObject? selectedObject;

  List<RenderedObject> get visibleObjects => List.unmodifiable(_visibleObjects);

  List<LineSegment> get constellationLines =>
      List.unmodifiable(_constellationLines);

  String get statusLine {
    final position = _position;
    if (position == null) {
      return 'Отримання GPS...';
    }

    if (_lastSunAz != null && _lastSunAlt != null) {
      return 'Lat ${position.latitude.toStringAsFixed(3)}, '
          'Lon ${position.longitude.toStringAsFixed(3)} · '
          'Sun az ${_lastSunAz!.toStringAsFixed(0)}°, '
          'alt ${_lastSunAlt!.toStringAsFixed(0)}° · 10 Гц';
    }
    return 'Lat ${position.latitude.toStringAsFixed(3)}, '
        'Lon ${position.longitude.toStringAsFixed(3)} · Оновлення: 10 Гц';
  }

  Future<void> initialize() async {
    _buildBaseCatalog();
    _baseJulian = _julianDate(DateTime.now().toUtc());
    await _loadPlanetDescriptions();
    await _setupLocation();
    _listenSensors();
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateSky(),
    );
  }

  void _buildBaseCatalog() {
    _catalog
      ..clear()
      ..addAll([
        CelestialObject(
          name: 'Sun',
          type: ObjectType.sun,
          color: Colors.orangeAccent,
          baseDescription: 'Наша зоря.',
        ),
        CelestialObject(
          name: 'Moon',
          type: ObjectType.moon,
          color: Colors.blueGrey.shade100,
          baseDescription: 'Природний супутник Землі.',
        ),
        CelestialObject(
          name: 'Mercury',
          type: ObjectType.planet,
          color: Colors.grey,
          baseDescription: 'Найближча планета до Сонця.',
        ),
        CelestialObject(
          name: 'Venus',
          type: ObjectType.planet,
          color: Colors.amber.shade200,
          baseDescription: 'Друга планета від Сонця.',
        ),
        CelestialObject(
          name: 'Earth',
          type: ObjectType.planet,
          color: Colors.blue,
          baseDescription: 'Наша планета.',
        ),
        CelestialObject(
          name: 'Mars',
          type: ObjectType.planet,
          color: Colors.redAccent,
          baseDescription: 'Червона планета.',
        ),
        CelestialObject(
          name: 'Jupiter',
          type: ObjectType.planet,
          color: Colors.brown.shade200,
          baseDescription: 'Найбільша планета.',
        ),
        CelestialObject(
          name: 'Saturn',
          type: ObjectType.planet,
          color: Colors.yellow.shade300,
          baseDescription: 'Планета з кільцями.',
        ),
        CelestialObject(
          name: 'Uranus',
          type: ObjectType.planet,
          color: Colors.lightBlueAccent,
          baseDescription: 'Крижаний гігант.',
        ),
        CelestialObject(
          name: 'Neptune',
          type: ObjectType.planet,
          color: Colors.indigoAccent,
          baseDescription: 'Найдальша планета.',
        ),
      ]);
  }

  Future<void> _loadPlanetDescriptions() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.le-systeme-solaire.net/rest/bodies/'),
      );
      if (response.statusCode != 200) {
        return;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> bodies = decoded['bodies'] as List<dynamic>;
      for (final object in _catalog) {
        final matched = bodies
            .cast<Map<String, dynamic>?>()
            .whereType<Map<String, dynamic>>()
            .firstWhere(
              (body) =>
                  (body['englishName'] as String?)?.toLowerCase() ==
                  object.name.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
        if (matched.isNotEmpty) {
          final mass = (matched['mass']?['massValue'] ?? 'n/a').toString();
          final gravity = (matched['gravity'] ?? 'n/a').toString();
          object.description =
              '${object.baseDescription} Маса: $mass; Гравітація: $gravity';
        }
      }
    } catch (_) {
      // Keep fallback descriptions.
    }
  }

  Future<void> _setupLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return;
    }

    _position = await Geolocator.getCurrentPosition();
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((p) {
      _position = p;
    });
  }

  void _listenSensors() {
    accelerometerEventStream().listen((event) {
      _accelerometerEvent = event;
    });
    magnetometerEventStream().listen((event) {
      _magnetometerEvent = event;
    });
  }

  void _updateSky() {
    final position = _position;
    if (position == null) {
      notifyListeners();
      return;
    }

    final now = DateTime.now().toUtc();
    final julian = _julianDate(now);
    final gmst = (18.697374558 + 24.06570982441908 * (julian - 2451545.0));
    final gmstWrapped = (gmst % 24 + 24) % 24;
    final lstDegrees = ((gmstWrapped * 15) + position.longitude) % 360;

    final orientation = _estimateOrientation();
    final azimuth = orientation.$1;
    final pitch = orientation.$2;

    _visibleObjects.clear();
    _constellationLines.clear();

    for (final object in _catalog) {
      final equatorial = _equatorialForObject(object.name, julian);
      final horizontal = _toHorizontal(
        equatorial.$1,
        equatorial.$2,
        position.latitude,
        lstDegrees,
      );

      // Store Sun's coordinates for display
      if (object.name == 'Sun') {
        _lastSunAz = horizontal.$1;
        _lastSunAlt = horizontal.$2;
      }

      final projected = _projectToScreen(
        horizontal.$1,
        horizontal.$2,
        azimuth,
        pitch,
      );
      if (projected != null) {
        _visibleObjects.add(
          RenderedObject(
            object: object,
            offset: projected,
            radius: object.type == ObjectType.sun ? 8 : 5,
          ),
        );
      }
    }

    _buildConstellation('Orion', [
      _projectStar(
        83.822,
        -5.391,
        position.latitude,
        lstDegrees,
        azimuth,
        pitch,
      ),
      _projectStar(
        78.634,
        -8.201,
        position.latitude,
        lstDegrees,
        azimuth,
        pitch,
      ),
      _projectStar(
        88.793,
        7.407,
        position.latitude,
        lstDegrees,
        azimuth,
        pitch,
      ),
    ]);

    _buildConstellation('Ursa Major', [
      _projectStar(
        165.46,
        56.38,
        position.latitude,
        lstDegrees,
        azimuth,
        pitch,
      ),
      _projectStar(
        183.86,
        57.03,
        position.latitude,
        lstDegrees,
        azimuth,
        pitch,
      ),
      _projectStar(
        193.51,
        55.96,
        position.latitude,
        lstDegrees,
        azimuth,
        pitch,
      ),
    ]);

    _buildConstellation('Cassiopeia', [
      _projectStar(10.13, 56.54, position.latitude, lstDegrees, azimuth, pitch),
      _projectStar(17.43, 60.72, position.latitude, lstDegrees, azimuth, pitch),
      _projectStar(28.60, 63.67, position.latitude, lstDegrees, azimuth, pitch),
    ]);

    notifyListeners();
  }

  (double, double) _estimateOrientation() {
    final a = _accelerometerEvent;
    final m = _magnetometerEvent;
    if (a == null || m == null) {
      return (_smoothAzimuth, _smoothPitch);
    }

    final pitch = atan2(-a.x, sqrt((a.y * a.y) + (a.z * a.z))) * 180 / pi;
    final azimuth = (atan2(m.y, m.x) * 180 / pi + 360) % 360;

    const alpha = 0.15; // 0..1, чем меньше — тем плавнее
    _smoothAzimuth = _lerpAngle(_smoothAzimuth, azimuth, alpha);
    _smoothPitch = _smoothPitch * (1 - alpha) + pitch * alpha;

    return (_smoothAzimuth, _smoothPitch);
  }

  double _lerpAngle(double from, double to, double t) {
    var diff = ((to - from + 540) % 360) - 180;
    return (from + diff * t + 360) % 360;
  }

  (double, double) _equatorialForObject(String name, double julian) {
    final deltaDays = julian - _baseJulian;
    if (name == 'Sun') {
      final n = (_baseJulian - 2451545.0) + deltaDays;
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
      final d = (_baseJulian - 2451543.5) + deltaDays;
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

    final map = {
      'Mercury': 75.0,
      'Venus': 272.0,
      'Earth': 0.0,
      'Mars': 40.0,
      'Jupiter': 120.0,
      'Saturn': 210.0,
      'Uranus': 300.0,
      'Neptune': 330.0,
    };
    final phase = map[name] ?? 0.0;
    final speed = switch (name) {
      'Mercury' => 1.2,
      'Venus' => 0.9,
      'Mars' => 0.5,
      'Jupiter' => 0.2,
      'Saturn' => 0.15,
      'Uranus' => 0.1,
      'Neptune' => 0.08,
      _ => 0.2,
    };
    final ra = (phase + deltaDays * speed) % 360;
    final dec = 15 * sin((ra + phase) * _degToRad);
    return (ra, dec);
  }

  (double, double) _toHorizontal(
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

  Offset? _projectToScreen(
    double azimuth,
    double altitude,
    double phoneAzimuth,
    double phonePitch,
  ) {
    if (altitude < -5) {
      return null;
    }

    final relAz = ((azimuth - phoneAzimuth + 540) % 360) - 180;
    final relAlt = altitude - phonePitch;
    const azimuthFov = 160.0;
    const altitudeFov = 100.0;

    if (relAz.abs() > azimuthFov || relAlt.abs() > altitudeFov) {
      return null;
    }

    final xNorm = relAz / azimuthFov; // -1..1
    final yNorm = relAlt / altitudeFov; // -1..1
    return Offset(xNorm, yNorm);
  }

  Offset? _projectStar(
    double ra,
    double dec,
    double lat,
    double lst,
    double phoneAzimuth,
    double phonePitch,
  ) {
    final horizontal = _toHorizontal(ra, dec, lat, lst);
    return _projectToScreen(
      horizontal.$1,
      horizontal.$2,
      phoneAzimuth,
      phonePitch,
    );
  }

  void _buildConstellation(String name, List<Offset?> stars) {
    for (var i = 0; i < stars.length - 1; i++) {
      if (stars[i] != null && stars[i + 1] != null) {
        _constellationLines.add(LineSegment(stars[i]!, stars[i + 1]!, name));
      }
    }
  }

  double _julianDate(DateTime date) {
    return date.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  }

  void onTap(Offset tap) {
    for (final object in _visibleObjects) {
      if ((object.offset - tap).distance < 30) {
        selectedObject = object;
        notifyListeners();
        return;
      }
    }
    selectedObject = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class SkyPainter extends CustomPainter {
  final List<RenderedObject> objects;
  final List<LineSegment> constellationLines;
  final String? selectedObjectName;

  SkyPainter(this.objects, this.constellationLines, this.selectedObjectName);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, background);

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (final line in constellationLines) {
      canvas.drawLine(
        _scale(line.start, size),
        _scale(line.end, size),
        linePaint,
      );
    }

    for (final item in objects) {
      final isSelected = item.object.name == selectedObjectName;
      final paint = Paint()..color = item.object.color;
      final radius = isSelected ? item.radius * 1.8 : item.radius;

      // Draw glow for selected object
      if (isSelected) {
        final glowPaint = Paint()
          ..color = item.object.color.withOpacity(0.3)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(_scale(item.offset, size), radius + 4, glowPaint);
      }

      canvas.drawCircle(_scale(item.offset, size), radius, paint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.object.name,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        _scale(item.offset, size) + const Offset(6, -6),
      );
    }
  }

  Offset _scale(Offset normalized, Size size) {
    final x = size.width / 2 + normalized.dx * (size.width / 2);
    final y = size.height / 2 - normalized.dy * (size.height / 2);
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant SkyPainter oldDelegate) =>
      oldDelegate.selectedObjectName != selectedObjectName ||
      oldDelegate.objects != objects ||
      oldDelegate.constellationLines != constellationLines;
}

enum ObjectType { sun, moon, planet }

class CelestialObject {
  final String name;
  final ObjectType type;
  final Color color;
  final String baseDescription;
  String description;

  CelestialObject({
    required this.name,
    required this.type,
    required this.color,
    required this.baseDescription,
  }) : description = baseDescription;
}

class RenderedObject {
  final CelestialObject object;
  final Offset offset;
  final double radius;

  String get name => object.name;

  String get description => object.description;

  RenderedObject({
    required this.object,
    required this.offset,
    required this.radius,
  });
}

class LineSegment {
  final Offset start;
  final Offset end;
  final String constellation;

  LineSegment(this.start, this.end, this.constellation);
}
