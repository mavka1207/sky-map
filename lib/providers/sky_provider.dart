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

import 'package:sky_map/models/models.dart';
import 'package:sky_map/models/sky_calculator.dart';

class SkyProvider extends ChangeNotifier {
  SkyState _state = SkyState(
    latitude: 0,
    longitude: 0,
    heading: 0,
    pitch: 0,
    visibleObjects: [],
    dateTimeUtc: DateTime.now().toUtc(),
    julianDate: 0,
    lstDegrees: 0,
  );

  SkyState get state => _state;
  List<Constellation> get constellations => _constellations;
  List<RenderedObject> get visibleObjects => _state.visibleObjects;
  List<Constellation> get visibleConstellations => _constellations;

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

  // Caching
  double? _cachedJulian;
  double? _cachedLstDegrees;
  late final double _baseJulian;

  // FOV scaling
  final double baseAzimuthFov = 60.0;
  final double baseAltitudeFov = 130.0;
  static const double _minFovScale = 0.005;
  static const double _maxFovScale = 5.0;
  double azimuthFovScale = 1.0;
  double altitudeFovScale = 1.0;

  // Settings
  bool showConstellations = true;
  String? selectedConstellationKey;

  // Manual Offset
  double _manualAzimuthOffset = 0.0;
  double _manualPitchOffset = 0.0;

  // Animation targets
  double? _targetAzimuthOffset;
  double? _targetPitchOffset;
  final double _lerpSpeed = 0.15;



  // Catalog
  final List<CelestialObject> _catalog = [];
  List<CelestialObject> get catalog => _catalog;
  final List<Constellation> _constellations = [];



  SkyProvider();



  void selectObject(CelestialObject? object) {
    _state = _state.copyWith(
      selectedObject: object,
      clearSelectedObject: object == null,
    );
    notifyListeners();
  }



  Future<void> initialize() async {
    _baseJulian = SkyCalculator.calculateJulianDate(DateTime.now().toUtc());
    final approxLon = DateTime.now().timeZoneOffset.inMinutes / 4.0;
    _state = _state.copyWith(latitude: 45.0, longitude: approxLon);

    await _loadCelestialObjects();
    await _loadConstellations();
    _initLocation();
    _listenSensors();
    _startUpdateTimer();
  }

  Future<void> _loadCelestialObjects() async {
    try {
      final jsonString = await rootBundle.loadString('assets/celestial_objects.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (data['sun'] != null) {
        final sun = data['sun'];
        _catalog.add(CelestialObject(
          id: sun['id']?.toString() ?? 'sun',
          name: sun['name']?.toString() ?? 'Sun',
          type: 'sun',
          description: sun['description']?.toString() ?? '',
          ra: (sun['ra'] as num?)?.toDouble() ?? 0.0,
          dec: (sun['dec'] as num?)?.toDouble() ?? 0.0,
          color: _colorFromString(sun['color']?.toString() ?? '#FFD700'),
          displayRadius: (sun['radius'] as num?)?.toDouble() ?? 14.0,
          screenOffset: Offset.zero,
        ));
      }

      if (data['moon'] != null) {
        final moon = data['moon'];
        _catalog.add(CelestialObject(
          id: moon['id']?.toString() ?? 'moon',
          name: moon['name']?.toString() ?? 'Moon',
          type: 'moon',
          description: moon['description']?.toString() ?? '',
          ra: (moon['ra'] as num?)?.toDouble() ?? 0.0,
          dec: (moon['dec'] as num?)?.toDouble() ?? 0.0,
          color: _colorFromString(moon['color']?.toString() ?? '#E0E0E0'),
          displayRadius: (moon['radius'] as num?)?.toDouble() ?? 10.0,
          screenOffset: Offset.zero,
        ));
      }

      final planets = data['planets'] as List? ?? [];
      for (final p in planets) {
        _catalog.add(CelestialObject(
          id: p['id']?.toString() ?? 'unknown',
          name: p['name']?.toString() ?? 'Unknown',
          type: 'planet',
          description: p['description']?.toString() ?? '',
          ra: (p['ra'] as num?)?.toDouble() ?? 0.0,
          dec: (p['dec'] as num?)?.toDouble() ?? 0.0,
          color: _colorFromString(p['color']?.toString() ?? '#4A90E2'),
          displayRadius: (p['radius'] as num?)?.toDouble() ?? 10.0,
          screenOffset: Offset.zero,
        ));
      }


    } catch (e) {
      if (kDebugMode) print('Load error: $e');
    }
  }

  Future<void> _loadConstellations() async {
    try {
      final jsonString = await rootBundle.loadString('assets/celestial_objects.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final constellationsData = data['constellations'] as List? ?? [];

      for (final c in constellationsData) {
        final stars = <CelestialObject>[];
        for (var s in (c['stars'] as List? ?? [])) {
          stars.add(CelestialObject(
            id: '${c['id']}_${s['name']}',
            name: s['name']?.toString() ?? 'Star',
            type: 'star',
            description: c['description']?.toString() ?? '',
            ra: (s['ra'] as num?)?.toDouble() ?? 0.0,
            dec: (s['dec'] as num?)?.toDouble() ?? 0.0,
            color: Colors.white,
            displayRadius: 2.5,
            screenOffset: Offset.zero,
          ));
        }
        final conns = <List<int>>[];
        for (var p in (c['connections'] as List? ?? [])) {
          conns.add([(p[0] as num).toInt(), (p[1] as num).toInt()]);
        }
        _constellations.add(Constellation(
          id: c['id'],
          name: c['name'],
          description: c['description'],
          stars: stars,
          connections: conns,
        ));
      }
    } catch (e) {
      if (kDebugMode) print('Constellation error: $e');
    }
  }

  Color _colorFromString(String hexColor) {
    final buffer = StringBuffer();
    if (!hexColor.startsWith('#')) buffer.write('ff');
    buffer.write(hexColor.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          _state = _state.copyWith(latitude: last.latitude, longitude: last.longitude);
          _updateSky();
        }
        _posSub = Geolocator.getPositionStream().listen((pos) {
          _state = _state.copyWith(latitude: pos.latitude, longitude: pos.longitude);
          _updateSky();
        });
      }
    } catch (e) {}
  }

  void _listenSensors() {
    _accelSub = accelerometerEventStream().listen((e) => _accelerometerEvent = e);
    _magSub = magnetometerEventStream().listen((e) => _magnetometerEvent = e);
    _compassSub = FlutterCompass.events?.listen((e) => _headingDegrees = e.heading);
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _updateSky());
  }

  void _updateSky() {
    final orientation = _estimateOrientation();
    final azimuth = (orientation.$1 + _manualAzimuthOffset + 360) % 360;
    final pitch = (orientation.$2 + _manualPitchOffset).clamp(-89.0, 89.0);

    final nowUtc = DateTime.now().toUtc();
    _cachedJulian = SkyCalculator.calculateJulianDate(nowUtc);
    _cachedLstDegrees = SkyCalculator.calculateLst(_cachedJulian!, _state.longitude);

    final julian = _cachedJulian!;
    final lst = _cachedLstDegrees!;
    final visible = <RenderedObject>[];

    for (final obj in _catalog) {
      final equatorial = SkyCalculator.getEquatorialForObject(obj.name, julian, _baseJulian);
      final horizontal = obj.name == 'Moon' 
          ? SkyCalculator.toHorizontalMoonTopocentric(equatorial.$1, equatorial.$2, _state.latitude, lst)
          : SkyCalculator.toHorizontal(equatorial.$1, equatorial.$2, _state.latitude, lst);
      final projected = SkyCalculator.projectToScreen(horizontal.$1, horizontal.$2, azimuth, pitch, baseAzimuthFov, baseAltitudeFov, azimuthFovScale, altitudeFovScale, allowBelowHorizon: true);

      if (projected != null) {
        visible.add(RenderedObject(
          object: obj, offset: projected, radius: obj.displayRadius,
          moonPhase: obj.type == 'moon' ? SkyCalculator.calculateMoonPhase(julian) : null,
          horizontalAz: horizontal.$1, horizontalAlt: horizontal.$2,
        ));
      }
    }

    if (_targetAzimuthOffset != null) {
      _manualAzimuthOffset = SkyCalculator.lerpAngle(_manualAzimuthOffset, _targetAzimuthOffset!, _lerpSpeed);
      if (SkyCalculator.normalizeAngleDiff(_manualAzimuthOffset, _targetAzimuthOffset!).abs() < 0.1) _targetAzimuthOffset = null;
    }
    if (_targetPitchOffset != null) {
      _manualPitchOffset += (_targetPitchOffset! - _manualPitchOffset) * _lerpSpeed;
      if ((_targetPitchOffset! - _manualPitchOffset).abs() < 0.1) _targetPitchOffset = null;
    }



    _state = _state.copyWith(
      heading: azimuth, pitch: pitch, visibleObjects: visible,
      dateTimeUtc: nowUtc, julianDate: julian, lstDegrees: lst,
      fovScale: azimuthFovScale, moonPhase: SkyCalculator.calculateMoonPhase(julian),
    );
    notifyListeners();
  }

  (double, double) _estimateOrientation() {
    final a = _accelerometerEvent;
    if (a == null) return (_smoothAzimuth, _smoothPitch);
    final rawPitch = atan2(-a.x, sqrt(a.y * a.y + a.z * a.z)) * 180 / pi;
    double? azimuth = _headingDegrees ?? (_magnetometerEvent != null ? (atan2(_magnetometerEvent!.y, _magnetometerEvent!.x) * 180 / pi + 360) % 360 : null);
    if (azimuth == null) return (_smoothAzimuth, _smoothPitch);
    if (!_hasOrientationSeed) {
      _hasOrientationSeed = true;
      _smoothAzimuth = azimuth; _smoothPitch = rawPitch;
    }
    const alpha = 0.06;
    _smoothAzimuth = SkyCalculator.lerpAngle(_smoothAzimuth, azimuth, alpha);
    _smoothPitch += (rawPitch - _smoothPitch) * alpha;
    return (_smoothAzimuth, _smoothPitch);
  }

  void setShowConstellations(bool v) { showConstellations = v; notifyListeners(); }
  void setSelectedConstellation(String? k) { selectedConstellationKey = k; notifyListeners(); }
  void updateManualPan(Offset d) {
    _targetAzimuthOffset = _targetPitchOffset = null;
    // Natural scroll: drag right -> objects move right (azimuth decreases)
    _manualAzimuthOffset -= d.dx * (baseAzimuthFov * azimuthFovScale) / 2;
    _manualPitchOffset += d.dy * (baseAltitudeFov * altitudeFovScale) / 2;
    notifyListeners();
  }
  void resetManualPan() { _targetAzimuthOffset = _targetPitchOffset = null; _manualAzimuthOffset = _manualPitchOffset = 0.0; notifyListeners(); }
  void updateFovScale(double d) {
    // Sensitivity damping: at very high zoom, d=1.1 is still too much.
    // We dampen the delta to make it feel more linear/controllable.
    final damped = 1.0 + (d - 1.0) * 0.4; 
    azimuthFovScale = (azimuthFovScale / damped).clamp(_minFovScale, _maxFovScale);
    altitudeFovScale = azimuthFovScale;
    notifyListeners();
  }
  void resetFovScale() { azimuthFovScale = altitudeFovScale = 1.0; notifyListeners(); }

  void onTap(Offset tap, Size size) {
    const minHit = 22.0; double closest = double.infinity; CelestialObject? best;
    for (final obj in _state.visibleObjects) {
      final dist = (_normalize(obj.offset, size) - tap).distance;
      if (dist <= max(minHit, obj.radius * 2) && dist < closest) { closest = dist; best = obj.object; }
    }
    if (best == null && showConstellations) {
      for (final c in _constellations) {
        for (final s in c.stars) {
          final horizontal = SkyCalculator.toHorizontal(s.ra, s.dec, _state.latitude, _state.lstDegrees);
          final proj = SkyCalculator.projectToScreen(horizontal.$1, horizontal.$2, _state.heading, _state.pitch, baseAzimuthFov, baseAltitudeFov, azimuthFovScale, altitudeFovScale);
          if (proj != null) {
            final dist = (_normalize(proj, size) - tap).distance;
            if (dist <= minHit && dist < closest) { closest = dist; best = CelestialObject(id: c.id, name: c.name, type: 'constellation', description: c.description, ra: 0, dec: 0, color: Colors.white, displayRadius: 0, screenOffset: Offset.zero); }
          }
        }
      }
    }
    selectObject(best);
    if (best != null) {
      final rendered = _state.visibleObjects.where((o) => o.object.id == best!.id);
      if (rendered.isNotEmpty) smoothCenterOn(rendered.first);
    }
  }

  void smoothCenterOn(RenderedObject rendered) {
    if (rendered.horizontalAz == null || rendered.horizontalAlt == null) return;
    final (sensorAz, sensorPitch) = _estimateOrientation();
    _targetAzimuthOffset = SkyCalculator.normalizeAngleDiff(sensorAz, rendered.horizontalAz!);
    _targetPitchOffset = rendered.horizontalAlt! - sensorPitch;
    notifyListeners();
  }

  Offset _normalize(Offset n, Size s) => Offset(s.width / 2 + n.dx * (s.width / 2), s.height / 2 - n.dy * (s.height / 2));
  String get statusLine => 'Lat ${_state.latitude.toStringAsFixed(2)}, Lon ${_state.longitude.toStringAsFixed(2)} · ${_state.heading.toStringAsFixed(0)}°, ${_state.pitch.toStringAsFixed(0)}°';

  @override
  void dispose() { _accelSub?.cancel(); _magSub?.cancel(); _compassSub?.cancel(); _posSub?.cancel(); _updateTimer?.cancel(); super.dispose(); }
}
