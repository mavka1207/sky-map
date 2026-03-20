// ============================================================================
// SKY PROVIDER - STATE MANAGEMENT & SENSOR LOGIC
// ============================================================================

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:convert';

import 'package:sky_map/models/hip_star_catalog.dart';
import 'package:sky_map/models/models.dart';
import 'package:sky_map/models/sky_calculator.dart';

class SkyProvider extends ChangeNotifier {
  SkyState _state = SkyState(
    latitude: 0,
    longitude: 0,
    heading: 0,
    pitch: 0,
    visibleObjects: [],
    visibleHipStars: [],
    dateTimeUtc: DateTime.now().toUtc(),
    julianDate: 0,
    lstDegrees: 0,
  );

  SkyState get state => _state;

  List<Constellation> get constellations => _constellations;

  // Sensors
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<dynamic>? _posSub;
  Timer? _updateTimer;

  AccelerometerEvent? _accelerometerEvent;
  MagnetometerEvent? _magnetometerEvent;
  double? _headingDegrees;

  // Orientation smoothing
  double _smoothAzimuth = 0;
  double _smoothPitch = 0;
  bool _hasOrientationSeed = false;
  double? _lastRawAzimuth;
  double? _lastRawPitch;
  int _stillCounter = 0;
  bool _isDeviceStill = false;

  // Caching for performance
  double? _cachedJulian;
  double? _cachedLstDegrees;
  DateTime? _lastTimeUpdateUtc;
  Position? _lastPositionForTimeUpdate;
  late final double _baseJulian;
  bool _hasLocation = false;

  // FOV scaling (with zoom constraints)
  final double baseAzimuthFov = 260.0;
  final double baseAltitudeFov = 150.0;
  static const double _minFovScale = 0.5; // Max zoom in
  static const double _maxFovScale = 3.0; // Max zoom out
  double azimuthFovScale = 1.0;
  double altitudeFovScale = 1.0;

  // Settings
  bool showAllPlanets = true;
  bool showConstellations = true;
  String? selectedConstellationKey;

  // Catalog
  final List<CelestialObject> _catalog = [];
  final List<Constellation> _constellations = [];

  SkyProvider();

  Future<void> initialize() async {
    _baseJulian = SkyCalculator.calculateJulianDate(DateTime.now().toUtc());
    await _loadCelestialObjects();
    await _loadConstellations();
    await _initLocation();
    _listenSensors();
    _startUpdateTimer();
  }

  /// Load celestial objects (planets, sun, moon) from JSON with Az/Alt coordinates
  Future<void> _loadCelestialObjects() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/celestial_objects.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Load Sun
      if (data['sun'] != null) {
        final sun = data['sun'] as Map<String, dynamic>;
        _catalog.add(
          CelestialObject(
            id: sun['id'] as String? ?? 'sun',
            name: sun['name'] as String? ?? 'Sun',
            type: 'sun',
            description: sun['description'] as String? ?? 'The Sun',
            az: (sun['az'] as num?)?.toDouble() ?? 0.0,
            alt: (sun['alt'] as num?)?.toDouble() ?? 0.0,
            color: _colorFromString(sun['color'] as String? ?? '#FFD700'),
            displayRadius: (sun['radius'] as num?)?.toDouble() ?? 12.0,
            screenOffset: _computeJitter(sun['id'] as String? ?? 'sun'),
          ),
        );
      }

      // Load Moon
      if (data['moon'] != null) {
        final moon = data['moon'] as Map<String, dynamic>;
        _catalog.add(
          CelestialObject(
            id: moon['id'] as String? ?? 'moon',
            name: moon['name'] as String? ?? 'Moon',
            type: 'moon',
            description: moon['description'] as String? ?? 'The Moon',
            az: (moon['az'] as num?)?.toDouble() ?? 0.0,
            alt: (moon['alt'] as num?)?.toDouble() ?? 0.0,
            color: _colorFromString(moon['color'] as String? ?? '#E0E0E0'),
            displayRadius: (moon['radius'] as num?)?.toDouble() ?? 8.0,
            screenOffset: _computeJitter(moon['id'] as String? ?? 'moon'),
          ),
        );
      }

      // Load Planets
      final planets = data['planets'] as List<dynamic>? ?? [];
      for (final p in planets) {
        final id = p['id'] as String;
        _catalog.add(
          CelestialObject(
            id: id,
            name: p['name'] as String? ?? 'Unknown',
            type: 'planet',
            description: p['description'] as String? ?? 'A planet',
            az: (p['az'] as num?)?.toDouble() ?? 0.0,
            alt: (p['alt'] as num?)?.toDouble() ?? 0.0,
            color: _colorFromString(p['color'] as String? ?? '#4A90E2'),
            displayRadius: (p['radius'] as num?)?.toDouble() ?? 10.0,
            screenOffset: _computeJitter(id),
          ),
        );
      }

      if (kDebugMode) print('Loaded ${_catalog.length} celestial objects');
    } catch (e) {
      if (kDebugMode) print('Failed to load celestial objects: $e');
    }
  }

  /// Load constellations from JSON with star positions and connections
  Future<void> _loadConstellations() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/celestial_objects.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final constellationsData = data['constellations'] as List<dynamic>? ?? [];
      for (final c in constellationsData) {
        final id = c['id'] as String;
        final name = c['name'] as String;
        final desc = c['description'] as String;

        final starsJson = c['stars'] as List<dynamic>? ?? [];
        final stars = <CelestialObject>[];

        for (var s in starsJson) {
          stars.add(
            CelestialObject(
              id: '${id}_${s['name']}',
              name: s['name'] as String,
              type: 'star',
              description: desc,
              az: (s['az'] as num).toDouble(),
              alt: (s['alt'] as num).toDouble(),
              color: const Color(0xFFFFFFFF),
              displayRadius: 2.0,
              screenOffset: Offset.zero,
            ),
          );
        }

        final connections = <List<int>>[];
        final connectionsJson = c['connections'] as List<dynamic>? ?? [];
        for (var pair in connectionsJson) {
          connections.add([(pair[0] as num).toInt(), (pair[1] as num).toInt()]);
        }

        _constellations.add(
          Constellation(
            id: id,
            name: name,
            description: desc,
            stars: stars,
            connections: connections,
          ),
        );
      }

      if (kDebugMode) print('Loaded ${_constellations.length} constellations');
    } catch (e) {
      if (kDebugMode) print('Failed to load constellations: $e');
    }
  }

  Color _colorFromString(String hexColor) {
    final buffer = StringBuffer();
    if (!hexColor.startsWith('#')) buffer.write('ff');
    buffer.write(hexColor.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Generate deterministic jitter offset based on name/id
  /// Same input always produces same output (reproducible)
  Offset _computeJitter(String id) {
    // Deterministic "random" using string hash
    int sum = id.codeUnits.fold(0, (a, b) => a + b);
    final rand = Random(sum);

    const double maxJitter = 15.0; // pixels
    final double dx = (rand.nextDouble() * 2 - 1) * maxJitter;
    final double dy = (rand.nextDouble() * 2 - 1) * maxJitter;

    return Offset(dx, dy);
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _state = _state.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _hasLocation = true;
        notifyListeners();

        _posSub = Geolocator.getPositionStream().listen((pos) {
          _state = _state.copyWith(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
          _hasLocation = true;
          _updateSky();
        });
      }
    } catch (e) {
      if (kDebugMode) print('Location error: $e');
    }
  }

  void _listenSensors() {
    _accelSub = accelerometerEventStream().listen((event) {
      _accelerometerEvent = event;
    });

    _magSub = magnetometerEventStream().listen((event) {
      _magnetometerEvent = event;
    });

    _compassSub = FlutterCompass.events?.listen((event) {
      _headingDegrees = event.heading;
    });
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateSky();
    });
  }

  void _updateSky() {
    // Skip if location not yet determined
    if (!_hasLocation) return;

    final orientation = _estimateOrientation();
    final azimuth = orientation.$1;
    final pitch = orientation.$2;

    final nowUtc = DateTime.now().toUtc();
    final lastPos = _lastPositionForTimeUpdate;
    final movedInGps = lastPos == null
        ? true
        : Geolocator.distanceBetween(
                lastPos.latitude,
                lastPos.longitude,
                _state.latitude,
                _state.longitude,
              ) >
              5.0;

    const maxTimeHoldMs = 30000;
    final staleByTime =
        _lastTimeUpdateUtc == null ||
        nowUtc.difference(_lastTimeUpdateUtc!).inMilliseconds >= maxTimeHoldMs;

    final shouldUpdateTime =
        _cachedJulian == null ||
        _cachedLstDegrees == null ||
        movedInGps ||
        !_isDeviceStill ||
        staleByTime;

    if (shouldUpdateTime) {
      _lastTimeUpdateUtc = nowUtc;
      _lastPositionForTimeUpdate = Position(
        latitude: _state.latitude,
        longitude: _state.longitude,
        timestamp: nowUtc,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _cachedJulian = SkyCalculator.calculateJulianDate(nowUtc);
      _cachedLstDegrees = SkyCalculator.calculateLst(
        _cachedJulian!,
        _state.longitude,
      );
    }

    final julian = _cachedJulian!;
    final lstDegrees = _cachedLstDegrees!;

    final visibleObjects = <RenderedObject>[];
    final visibleHipStars = <RenderedStar>[];

    // Render celestial objects
    for (final object in _catalog) {
      final equatorial = SkyCalculator.getEquatorialForObject(
        object.name,
        julian,
        _baseJulian,
      );
      final horizontal = SkyCalculator.toHorizontal(
        equatorial.$1,
        equatorial.$2,
        _state.latitude,
        lstDegrees,
      );

      final projected = SkyCalculator.projectToScreen(
        horizontal.$1,
        horizontal.$2,
        azimuth,
        pitch,
        baseAzimuthFov,
        baseAltitudeFov,
        azimuthFovScale,
        altitudeFovScale,
        allowBelowHorizon: showAllPlanets && object.type == 'planet',
      );

      if (projected != null) {
        visibleObjects.add(
          RenderedObject(
            object: object,
            offset: projected,
            radius: object.displayRadius,
          ),
        );
      }
    }

    // HIP stars
    final hipStars = HIPCatalog.getVisibleStars(
      _state.latitude,
      lstDegrees,
      maxMagnitude: 5.5,
      minAltitude: -5.0,
    );

    for (final star in hipStars) {
      final projected = SkyCalculator.projectStar(
        star.ra,
        star.dec,
        _state.latitude,
        lstDegrees,
        azimuth,
        pitch,
        baseAzimuthFov,
        baseAltitudeFov,
        azimuthFovScale,
        altitudeFovScale,
      );
      if (projected == null) continue;

      visibleHipStars.add(
        RenderedStar(
          offset: projected,
          radius: star.getVisualRadius(),
          color: star.getColorBySpectralClass(),
          opacity: star.getOpacity(),
        ),
      );
    }

    // Auto-FOV based on planet clustering
    final planetPoints = visibleObjects
        .where((o) => o.object.type == 'planet')
        .map((o) => o.offset)
        .toList();

    if (planetPoints.length >= 2) {
      double sum = 0;
      int cnt = 0;
      for (var i = 0; i < planetPoints.length; i++) {
        for (var j = i + 1; j < planetPoints.length; j++) {
          sum += (planetPoints[i] - planetPoints[j]).distance;
          cnt++;
        }
      }
      final avgDist = sum / cnt;

      if (avgDist < 0.12) {
        azimuthFovScale = 1.2;
      } else if (avgDist > 0.2) {
        azimuthFovScale = 1.0;
      }
    }

    _state = _state.copyWith(
      heading: azimuth,
      pitch: pitch,
      visibleObjects: visibleObjects,
      visibleHipStars: visibleHipStars,
      dateTimeUtc: nowUtc,
      julianDate: julian,
      lstDegrees: lstDegrees,
      fovScale: azimuthFovScale,
    );

    notifyListeners();
  }

  (double, double) _estimateOrientation() {
    final a = _accelerometerEvent;
    if (a == null) {
      return (_smoothAzimuth, _smoothPitch);
    }

    final pitch = atan2(-a.x, sqrt((a.y * a.y) + (a.z * a.z))) * 180 / pi;
    double? azimuth = _headingDegrees;
    if (azimuth == null && _magnetometerEvent != null) {
      final m = _magnetometerEvent!;
      azimuth = (atan2(m.y, m.x) * 180 / pi + 360) % 360;
    }
    if (azimuth == null) {
      return (_smoothAzimuth, _smoothPitch);
    }

    if (!_hasOrientationSeed) {
      _hasOrientationSeed = true;
      _smoothAzimuth = azimuth;
      _smoothPitch = pitch;
      _lastRawAzimuth = azimuth;
      _lastRawPitch = pitch;
      return (_smoothAzimuth, _smoothPitch);
    }

    const deadbandDeg = 0.35;
    const stillRawDeg = 0.25;
    const stillFramesToFreeze = 8;

    final prevRawAz = _lastRawAzimuth ?? azimuth;
    final prevRawPitch = _lastRawPitch ?? pitch;
    final rawAzDelta = (((azimuth - prevRawAz + 540) % 360) - 180).abs();
    final rawPitchDelta = (pitch - prevRawPitch).abs();

    _lastRawAzimuth = azimuth;
    _lastRawPitch = pitch;

    if (rawAzDelta < stillRawDeg && rawPitchDelta < stillRawDeg) {
      _stillCounter++;
    } else {
      _stillCounter = 0;
    }

    if (_stillCounter >= stillFramesToFreeze) {
      _isDeviceStill = true;
      return (_smoothAzimuth, _smoothPitch);
    }
    _isDeviceStill = false;

    const alpha = 0.06;
    final smoothAzDelta = (((azimuth - _smoothAzimuth + 540) % 360) - 180)
        .abs();
    if (smoothAzDelta >= deadbandDeg) {
      _smoothAzimuth = SkyCalculator.lerpAngle(_smoothAzimuth, azimuth, alpha);
    }

    final smoothPitchDelta = (pitch - _smoothPitch).abs();
    if (smoothPitchDelta >= deadbandDeg) {
      _smoothPitch = _smoothPitch * (1 - alpha) + pitch * alpha;
    }

    return (_smoothAzimuth, _smoothPitch);
  }

  void setShowAllPlanets(bool value) {
    showAllPlanets = value;
    notifyListeners();
  }

  void setShowConstellations(bool value) {
    showConstellations = value;
    notifyListeners();
  }

  void setSelectedConstellation(String? key) {
    selectedConstellationKey = key;
    notifyListeners();
  }

  /// Update FOV scale factors via pinch-zoom gesture.
  /// [scaleFactorDelta] is the change in pinch scale (1.0 = no change).
  void updateFovScale(double scaleFactorDelta) {
    // Invert: pinch-in (scale < 1) zooms in (expands view), pinch-out (scale > 1) zooms out
    final newScale = azimuthFovScale / scaleFactorDelta;
    azimuthFovScale = newScale.clamp(_minFovScale, _maxFovScale);
    altitudeFovScale = newScale.clamp(_minFovScale, _maxFovScale);
    notifyListeners();
  }

  /// Reset FOV to 1.0 (normal zoom).
  void resetFovScale() {
    azimuthFovScale = 1.0;
    altitudeFovScale = 1.0;
    notifyListeners();
  }

  void selectObject(CelestialObject? obj) {
    _state = _state.copyWith(selectedObject: obj);
    notifyListeners();
  }

  void onTap(Offset tap, Size size) {
    const hitRadius = 20.0;
    for (final obj in _state.visibleObjects) {
      final screenPos = _normalize(obj.offset, size);
      if ((screenPos - tap).distance <= hitRadius) {
        selectObject(obj.object);
        return;
      }
    }
    selectObject(null);
  }

  Offset _normalize(Offset normalized, Size size) {
    final x = size.width / 2 + normalized.dx * (size.width / 2);
    final y = size.height / 2 - normalized.dy * (size.height / 2);
    return Offset(x, y);
  }

  String get statusLine {
    final lat = _state.latitude.toStringAsFixed(2);
    final lon = _state.longitude.toStringAsFixed(2);
    final azInt = _state.heading.toStringAsFixed(0);
    final altInt = _state.pitch.toStringAsFixed(0);
    return 'Lat $lat, Lon $lon · Sun az $azInt°, alt $altInt° · 10 Hz';
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _compassSub?.cancel();
    _posSub?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }
}
