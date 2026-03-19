// ============================================================================
// SKY MAP - INTEGRATION OF ALL IMPROVEMENTS
// ============================================================================

// ignore_for_file: deprecated_member_use, unused_element

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:sky_map/error_handling/error_handling.dart';
import 'package:sky_map/models/constellation_data.dart';
import 'package:sky_map/models/hip_star_catalog.dart';
import 'package:sky_map/models/orbital_mechanics.dart';
import 'package:sky_map/themes/night_vision_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SkyMapProvider()..initialize(),
      child: const SkyMapApp(),
    ),
  );
}

class SkyMapApp extends StatefulWidget {
  const SkyMapApp({super.key});

  @override
  State<SkyMapApp> createState() => _SkyMapAppState();
}

class _SkyMapAppState extends State<SkyMapApp> {
  bool _nightVisionMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sky Map',
      theme: _nightVisionMode
          ? NightVisionTheme.getNightVisionTheme()
          : ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: SkyMapPage(
        nightVisionMode: _nightVisionMode,
        onNightVisionChanged: (value) {
          setState(() => _nightVisionMode = value);
        },
      ),
    );
  }
}

class SkyMapPage extends StatefulWidget {
  final bool nightVisionMode;
  final Function(bool) onNightVisionChanged;

  const SkyMapPage({
    super.key,
    this.nightVisionMode = false,
    required this.onNightVisionChanged,
  });

  @override
  State<SkyMapPage> createState() => _SkyMapPageState();
}

class _SkyMapPageState extends State<SkyMapPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkyMapProvider>();
    final pendingError = provider.takePendingError();
    if (pendingError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ErrorDialogHelper.showErrorDialog(context, pendingError);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky Map'),
        actions: [
          IconButton(
            icon: Icon(
              widget.nightVisionMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: () =>
                widget.onNightVisionChanged(!widget.nightVisionMode),
            tooltip: 'Night Vision',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              provider.statusLine,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Sky canvas
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    provider.onTap(details.localPosition, size);
                    final selected = provider.selectedObject;
                    if (selected == null) return;

                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF101010),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (ctx) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selected.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: CustomPaint(
                    painter: SkyPainter(
                      provider.visibleObjects,
                      provider.constellationLines,
                      provider.selectedObject?.name,
                      hipStars: provider.visibleHipStars,
                      nightVisionMode: widget.nightVisionMode,
                    ),
                    child: Container(),
                  ),
                );
              },
            ),
          ),
          // Bottom controls – compact pill
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // слева – маленький чип с планетами
                FilterChip(
                  label: const Text('Planets'),
                  selected: provider.showAllPlanets,
                  onSelected: provider.setShowAllPlanets,
                  backgroundColor: Colors.black.withOpacity(0.4),
                  selectedColor: Colors.white12,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                // по центру – выбор созвездий
                if (provider.showConstellations)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          iconSize: 18,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF101010),
                          value: provider.selectedConstellationKey ?? '__all__',
                          items: [
                            const DropdownMenuItem(
                              value: '__all__',
                              child: Text(
                                'All constellations',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            ...provider.constellationKeys.map(
                              (k) => DropdownMenuItem(
                                value: k,
                                child: Text(
                                  k,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            provider.setSelectedConstellationKey(
                              value == '__all__' ? null : value,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                // справа – маленькая иконка включения/выключения созвездий
                IconButton(
                  iconSize: 22,
                  color: Colors.white70,
                  onPressed: () {
                    provider.setShowConstellations(
                      !provider.showConstellations,
                    );
                  },
                  icon: Icon(
                    provider.showConstellations
                        ? Icons.auto_awesome
                        : Icons.auto_awesome_outlined,
                  ),
                  tooltip: 'Constellations',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SKY MAP PROVIDER - CORE LOGIC
// ============================================================================

class SkyMapProvider extends ChangeNotifier {
  static const _degToRad = pi / 180;

  Position? _position;
  AccelerometerEvent? _accelerometerEvent;
  MagnetometerEvent? _magnetometerEvent;
  StreamSubscription<CompassEvent>? _compassSub;
  double? _headingDegrees;
  Timer? _timer;

  bool showAllPlanets = true;
  bool showConstellations = true;
  String? selectedConstellationKey;

  // Dynamic FOV system (base values with scale factors)
  final double _baseAzimuthFov = 260.0;
  final double _baseAltitudeFov = 150.0;
  // ignore: prefer_final_fields
  double _azimuthFovScale = 1.0; // enabled for future gesture-based zoom
  // ignore: prefer_final_fields
  double _altitudeFovScale = 1.0; // enabled for future gesture-based zoom

  final List<CelestialObject> _catalog = [];
  final List<RenderedObject> _visibleObjects = [];
  final List<RenderedStar> _visibleHipStars = [];
  final List<LineSegment> _constellationLines = [];

  late final double _baseJulian;
  double? _lastSunAz;
  double? _lastSunAlt;
  double _smoothAzimuth = 0;
  double _smoothPitch = 0;
  bool _hasOrientationSeed = false;
  double? _lastRawAzimuth;
  double? _lastRawPitch;
  int _stillCounter = 0;

  double? _cachedJulian;
  double? _cachedLstDegrees;
  DateTime? _lastTimeUpdateUtc;
  Position? _lastPositionForTimeUpdate;
  bool _isDeviceStill = false;

  RenderedObject? selectedObject;
  SkyMapException? _pendingError;

  List<RenderedObject> get visibleObjects => List.unmodifiable(_visibleObjects);
  List<RenderedStar> get visibleHipStars => List.unmodifiable(_visibleHipStars);
  List<LineSegment> get constellationLines =>
      List.unmodifiable(_constellationLines);
  List<CelestialObject> get pickerObjects => _catalog;
  List<String> get constellationKeys {
    final keys = ConstellationCatalog.getConstellationNames();
    keys.sort();
    return keys;
  }

  SkyMapException? takePendingError() {
    final err = _pendingError;
    _pendingError = null;
    return err;
  }

  void setShowAllPlanets(bool value) {
    showAllPlanets = value;
    notifyListeners();
  }

  void setShowConstellations(bool value) {
    showConstellations = value;
    if (!value) {
      selectedConstellationKey = null;
    }
    notifyListeners();
  }

  void setSelectedConstellationKey(String? key) {
    selectedConstellationKey = key;
    notifyListeners();
  }

  void selectByName(String name) {
    // Ищем уже отрисованный объект
    final found = _visibleObjects.firstWhere(
      (r) => r.object.name == name,
      orElse: () => RenderedObject(
        object: _catalog.firstWhere((c) => c.name == name),
        offset: const Offset(0, 0),
        radius: 6,
      ),
    );
    selectedObject = found;
    notifyListeners();
  }

  String get statusLine {
    final position = _position;
    if (position == null) {
      return 'Determining location…';
    }

    final lat = position.latitude.toStringAsFixed(3);
    final lon = position.longitude.toStringAsFixed(3);

    final base = 'Lat $lat, Lon $lon';

    if (_lastSunAz != null && _lastSunAlt != null) {
      final az = _lastSunAz!.toStringAsFixed(0);
      final alt = _lastSunAlt!.toStringAsFixed(0);
      return '$base · Sun az $az°, alt $alt° · 10 Hz';
    }

    return '$base · Unknown sun position · 10 Hz';
  }

  Future<void> initialize() async {
    _buildBaseCatalog();
    _baseJulian = _julianDate(DateTime.now().toUtc());
    await _loadPlanetDescriptionsFromJson();
    await _initializeSensorsWithHandling();
    await _setupLocation();
    _listenSensors();
    _listenCompass();
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateSky(),
    );
  }

  Future<void> _initializeSensorsWithHandling() async {
    try {
      await SensorErrorHandler.initializeSensorsWithErrorHandling();
    } on SkyMapException catch (e) {
      _pendingError = e;
    } catch (_) {
      // Ignore: sensors are optional; the provider will continue with smoothing.
    }
  }

  void _buildBaseCatalog() {
    _catalog
      ..clear()
      ..addAll([
        CelestialObject(
          name: 'Sun',
          type: ObjectType.sun,
          color: Colors.orangeAccent,
          baseDescription:
              'The Sun is the star at the center of our Solar System.',
        ),
        CelestialObject(
          name: 'Moon',
          type: ObjectType.moon,
          color: Colors.blueGrey.shade100,
          baseDescription: 'The Moon is Earth\'s only natural satellite.',
        ),
        CelestialObject(
          name: 'Mercury',
          type: ObjectType.planet,
          color: Colors.grey,
          baseDescription: 'Mercury is the closest planet to the Sun.',
        ),
        CelestialObject(
          name: 'Venus',
          type: ObjectType.planet,
          color: Colors.amber.shade200,
          baseDescription: 'Venus is the second planet from the Sun.',
        ),
        CelestialObject(
          name: 'Mars',
          type: ObjectType.planet,
          color: Colors.redAccent,
          baseDescription: 'Mars is known as the Red Planet.',
        ),
        CelestialObject(
          name: 'Jupiter',
          type: ObjectType.planet,
          color: Colors.brown.shade200,
          baseDescription: 'Jupiter is the largest planet in the Solar System.',
        ),
        CelestialObject(
          name: 'Saturn',
          type: ObjectType.planet,
          color: Colors.yellow.shade300,
          baseDescription: 'Saturn is famous for its ring system.',
        ),
        CelestialObject(
          name: 'Uranus',
          type: ObjectType.planet,
          color: Colors.lightBlueAccent,
          baseDescription: 'Uranus is an ice giant.',
        ),
        CelestialObject(
          name: 'Neptune',
          type: ObjectType.planet,
          color: Colors.indigoAccent,
          baseDescription: 'Neptune is the farthest known planet.',
        ),
      ]);
  }

  Future<void> _loadPlanetDescriptionsFromJson() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/planet_data.json');
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;

      for (final object in _catalog) {
        final Map<String, dynamic> match = decoded
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (m) =>
                  (m['name'] as String?)?.toLowerCase() ==
                  object.name.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );

        if (match.isNotEmpty) {
          final mass = (match['mass'] ?? 'n/a').toString();
          final gravity = (match['gravity'] ?? 'n/a').toString();
          final extraDesc =
              (match['description'] as String?) ?? object.baseDescription;

          object.description = '$extraDesc\n\nMass: $mass\nGravity: $gravity';
        } else {
          object.description = object.baseDescription;
        }
      }
    } catch (e) {
      for (final object in _catalog) {
        object.description = object.baseDescription;
      }
    }
  }

  Future<void> _setupLocation() async {
    try {
      _position = await LocationErrorHandler.getPositionWithErrorHandling();
      if (_position == null) return;

      LocationErrorHandler.getPositionStreamWithErrorHandling().listen(
        (p) {
          _position = p;
          // чтобы статус и небо обновились сразу
          _updateSky();
        },
        onError: (e) {
          // ignore
        },
      );
    } on SkyMapException catch (e) {
      _pendingError = e;
    } catch (_) {
      // ignore
    }
  }

  void _listenSensors() {
    try {
      accelerometerEventStream().listen((event) {
        _accelerometerEvent = event;
      });
      magnetometerEventStream().listen((event) {
        _magnetometerEvent = event;
      });
    } catch (e) {
      // Silent error handling
    }
  }

  void _listenCompass() {
    _compassSub?.cancel();
    try {
      _compassSub = FlutterCompass.events?.listen((event) {
        final heading = event.heading;
        if (heading == null) return;
        _headingDegrees = (heading % 360 + 360) % 360;
      });
    } catch (e) {
      // If compass isn't available (simulator / device limitations),
      // the UI will still run but heading will stay at last known value.
    }
  }

  void _updateSky() {
    final position = _position;
    if (position == null) {
      notifyListeners();
      return;
    }

    final orientation = _estimateOrientation();
    final azimuth = orientation.$1;
    final pitch = orientation.$2;

    // Update time-dependent sky coordinates primarily when the user is moving
    // the device (or when location changes). This prevents the Sun/sky from
    // "drifting" while the phone is lying still.
    final nowUtc = DateTime.now().toUtc();
    final lastPos = _lastPositionForTimeUpdate;
    final movedInGps = lastPos == null
        ? true
        : Geolocator.distanceBetween(
                lastPos.latitude,
                lastPos.longitude,
                position.latitude,
                position.longitude,
              ) >
              5.0; // meters

    if (movedInGps && lastPos != null) {
      // GPS has moved significantly
    }

    // Fallback refresh to avoid becoming stale during long sessions.
    const maxTimeHoldMs = 30000; // 30s
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
      _lastPositionForTimeUpdate = position;
      _cachedJulian = _julianDate(nowUtc);

      final gmst =
          (18.697374558 + 24.06570982441908 * (_cachedJulian! - 2451545.0));
      final gmstWrapped = (gmst % 24 + 24) % 24;
      _cachedLstDegrees = ((gmstWrapped * 15) + position.longitude) % 360;
    }
    final julian = _cachedJulian!;
    final lstDegrees = _cachedLstDegrees!;

    _visibleObjects.clear();
    _visibleHipStars.clear();
    _constellationLines.clear();

    for (final object in _catalog) {
      final equatorial = _equatorialForObject(object.name, julian);
      final horizontal = _toHorizontal(
        equatorial.$1,
        equatorial.$2,
        position.latitude,
        lstDegrees,
      );

      if (object.name == 'Sun') {
        _lastSunAz = horizontal.$1;
        _lastSunAlt = horizontal.$2;
      }

      // DEBUG: Log planet positions (removed for production)

      final projected = _projectToScreen(
        horizontal.$1,
        horizontal.$2,
        azimuth,
        pitch,
        allowBelowHorizon: showAllPlanets && object.type == ObjectType.planet,
      );

      if (projected != null) {
        _visibleObjects.add(
          RenderedObject(
            object: object,
            offset: projected,
            radius: switch (object.type) {
              ObjectType.sun => 14,
              ObjectType.moon => 10,
              ObjectType.planet => 9,
            },
          ),
        );
      }
    }

    // Draw a star field from the HIP catalog (curated subset).
    final hipStars = HIPCatalog.getVisibleStars(
      position.latitude,
      lstDegrees,
      maxMagnitude: 5.5,
      minAltitude: -5.0,
    );

    for (final star in hipStars) {
      final projected = _projectStar(
        star.ra,
        star.dec,
        position.latitude,
        lstDegrees,
        azimuth,
        pitch,
      );
      if (projected == null) continue;

      _visibleHipStars.add(
        RenderedStar(
          offset: projected,
          radius: star.getVisualRadius(),
          color: star.getColorBySpectralClass(),
          opacity: star.getOpacity(),
        ),
      );
    }

    if (showConstellations) {
      // Constellation lines (from the local catalog).
      final List<ConstellationInfo> constellations;
      final selectedKey = selectedConstellationKey;
      if (selectedKey != null) {
        final selected = ConstellationCatalog.getConstellation(selectedKey);
        constellations = selected == null ? const [] : [selected];
      } else {
        constellations = ConstellationCatalog.getVisibleConstellations(
          position.latitude,
          lstDegrees,
        );
      }

      for (final c in constellations) {
        final projectedStars = <int, Offset>{};
        for (var i = 0; i < c.stars.length; i++) {
          final star = c.stars[i];
          final projected = _projectStar(
            star.ra,
            star.dec,
            position.latitude,
            lstDegrees,
            azimuth,
            pitch,
          );
          if (projected != null) {
            projectedStars[i] = projected;
            // Draw constellation star point.
            _visibleHipStars.add(
              RenderedStar(
                offset: projected,
                radius: 2.0,
                color: Colors.white,
                opacity: 0.85,
              ),
            );
          }
        }

        for (final line in c.lines) {
          final a = projectedStars[line.starIndex1];
          final b = projectedStars[line.starIndex2];
          if (a == null || b == null) continue;
          _constellationLines.add(LineSegment(a, b, c.englishName));
        }
      }
    }

    // Auto-adjust FOV based on planet clustering
    final planetPoints = _visibleObjects
        .where((o) => o.object.type == ObjectType.planet)
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
        _azimuthFovScale = 1.2; // planets clustered → zoom out
      } else if (avgDist > 0.2) {
        _azimuthFovScale = 1.0; // planets spread → normal zoom
      }
    }

    notifyListeners();
  }

  (double, double) _estimateOrientation() {
    final a = _accelerometerEvent;
    if (a == null) {
      return (_smoothAzimuth, _smoothPitch);
    }

    final pitch = atan2(-a.x, sqrt((a.y * a.y) + (a.z * a.z))) * 180 / pi;
    // Prefer OS-fused compass heading; fall back to raw magnetometer if needed.
    double? azimuth = _headingDegrees;
    if (azimuth == null && _magnetometerEvent != null) {
      final m = _magnetometerEvent!;
      azimuth = (atan2(m.y, m.x) * 180 / pi + 360) % 360;
    }
    if (azimuth == null) {
      return (_smoothAzimuth, _smoothPitch);
    }

    // Seed smoothing with the first real sensor reading to avoid a visible
    // "settling" movement right after launch.
    if (!_hasOrientationSeed) {
      _hasOrientationSeed = true;
      _smoothAzimuth = azimuth;
      _smoothPitch = pitch;
      _lastRawAzimuth = azimuth;
      _lastRawPitch = pitch;
      return (_smoothAzimuth, _smoothPitch);
    }

    // Magnetometer/accelerometer data is noisy even when the device is still.
    // Apply a small deadband and "stillness" gating to prevent visible jitter.
    const deadbandDeg = 0.35; // ignore tiny changes
    const stillRawDeg =
        0.25; // considered "still" if raw changes stay under this
    const stillFramesToFreeze = 8; // ~0.8s at 10Hz

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

    // Stronger smoothing than before to reduce jitter.
    const alpha = 0.06;

    final smoothAzDelta = (((azimuth - _smoothAzimuth + 540) % 360) - 180)
        .abs();
    if (smoothAzDelta >= deadbandDeg) {
      _smoothAzimuth = _lerpAngle(_smoothAzimuth, azimuth, alpha);
    }

    final smoothPitchDelta = (pitch - _smoothPitch).abs();
    if (smoothPitchDelta >= deadbandDeg) {
      _smoothPitch = _smoothPitch * (1 - alpha) + pitch * alpha;
    }

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

    final elements = OrbitalElements.getPlanetByName(name);
    if (elements != null) {
      final eq = elements.getEquatorialPosition(julian);
      return eq;
    }

    // Fallback: keep a simple educational placeholder if unknown.
    final ra = (deltaDays * 0.2) % 360;
    final dec = 10 * sin(ra * _degToRad);
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
    double phonePitch, {
    bool allowBelowHorizon = false,
  }) {
    if (!allowBelowHorizon && altitude < -5) {
      return null;
    }

    final relAz = ((azimuth - phoneAzimuth + 540) % 360) - 180;
    final relAlt = altitude - phonePitch;
    final azimuthFov = _baseAzimuthFov * _azimuthFovScale;
    final altitudeFov = _baseAltitudeFov * _altitudeFovScale;

    if (relAz.abs() > azimuthFov || relAlt.abs() > altitudeFov) {
      return null;
    }

    final xNorm = relAz / azimuthFov;
    final yNorm = relAlt / altitudeFov;
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

  double _julianDate(DateTime date) {
    return date.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  }

  void onTap(Offset tap, Size size) {
    final tapXNorm = (tap.dx - size.width / 2) / (size.width / 2);
    final tapYNorm = -(tap.dy - size.height / 2) / (size.height / 2);
    final tapNorm = Offset(tapXNorm, tapYNorm);

    const maxHitDist = 0.3;
    RenderedObject? best;
    double bestScore = double.infinity;

    for (final object in _visibleObjects) {
      final dist = (object.offset - tapNorm).distance;
      if (dist > maxHitDist) continue;

      final typePenalty = switch (object.object.type) {
        ObjectType.planet => 0.0,
        ObjectType.moon => 0.01,
        ObjectType.sun => 0.02,
      };
      final score = dist + typePenalty;

      if (score < bestScore) {
        bestScore = score;
        best = object;
      }
    }

    selectedObject = best;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

class SkyPainter extends CustomPainter {
  final List<RenderedObject> objects;
  final List<RenderedStar> hipStars;
  final List<LineSegment> constellationLines;
  final String? selectedObjectName;
  final bool nightVisionMode;

  SkyPainter(
    this.objects,
    this.constellationLines,
    this.selectedObjectName, {
    this.hipStars = const [],
    this.nightVisionMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = nightVisionMode ? const Color(0xFF1a0000) : Colors.black;
    canvas.drawRect(Offset.zero & size, background);

    final starPaint = Paint();
    // HIP stars (real-ish star field) behind planets/moon/sun.
    // These are drawn in a single pass for performance.
    for (final star in hipStars) {
      starPaint.color = star.color.withOpacity(star.opacity);
      canvas.drawCircle(_scale(star.offset, size), star.radius, starPaint);
    }

    final linePaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2;
    for (final line in constellationLines) {
      canvas.drawLine(
        _scale(line.start, size),
        _scale(line.end, size),
        linePaint,
      );
    }

    final placedLabelRects = <Rect>[];

    for (final item in objects) {
      final isSelected = item.object.name == selectedObjectName;
      final baseColor = item.object.color;
      final center = _scale(item.offset, size);

      final glowPaint = Paint()
        ..color = baseColor.withOpacity(isSelected ? 0.9 : 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, item.radius * 2.4, glowPaint);

      final paint = Paint()..color = baseColor;
      final radius = isSelected ? item.radius * 1.8 : item.radius;
      canvas.drawCircle(center, radius, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: item.object.name,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const gap = 4.0;
      Offset labelOffset = switch (item.object.type) {
        ObjectType.sun => Offset(
          -(radius + gap + textPainter.width),
          radius + gap,
        ),
        ObjectType.moon => Offset(radius + gap, radius + gap),
        ObjectType.planet => Offset(
          radius + gap,
          -radius - gap - textPainter.height,
        ),
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

      final bgRect = labelRect.inflate(3);
      final bgPaint = Paint()..color = Colors.black.withOpacity(0.55);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
        bgPaint,
      );
      textPainter.paint(canvas, labelRect.topLeft);
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
      oldDelegate.hipStars != hipStars ||
      oldDelegate.constellationLines != constellationLines ||
      oldDelegate.nightVisionMode != nightVisionMode;
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

class RenderedStar {
  final Offset offset;
  final double radius;
  final Color color;
  final double opacity;

  RenderedStar({
    required this.offset,
    required this.radius,
    required this.color,
    required this.opacity,
  });
}

class LineSegment {
  final Offset start;
  final Offset end;
  final String constellation;

  LineSegment(this.start, this.end, this.constellation);
}
