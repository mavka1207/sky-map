// ============================================================================
// CORE DATA MODELS
// ============================================================================

import 'package:flutter/material.dart';

/// Celestial object types.
enum ObjectType { sun, moon, planet }

/// A celestial object (planet, sun, moon, constellation star, etc.)
class CelestialObject {
  final String id;
  final String name;
  final String type; // 'sun', 'moon', 'planet', 'constellation', 'star'
  final String description;
  final double ra; // Right Ascension in degrees
  final double dec; // Declination in degrees
  final Color color;
  final double displayRadius;
  final Offset screenOffset;

  CelestialObject({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.ra,
    required this.dec,
    this.color = const Color(0xFFFFFFFF),
    this.displayRadius = 10.0,
    this.screenOffset = Offset.zero,
  });

  CelestialObject copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    double? ra,
    double? dec,
    Color? color,
    double? displayRadius,
    Offset? screenOffset,
  }) {
    return CelestialObject(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      ra: ra ?? this.ra,
      dec: dec ?? this.dec,
      color: color ?? this.color,
      displayRadius: displayRadius ?? this.displayRadius,
      screenOffset: screenOffset ?? this.screenOffset,
    );
  }
}

/// A celestial object rendered on screen with position and size.
class RenderedObject {
  final CelestialObject object;
  final Offset offset;
  final double radius;
  final double? moonPhase; // 0.0 to 1.0 (0/1=New, 0.5=Full)
  final double? horizontalAz; // Real-time calculated azimuth
  final double? horizontalAlt; // Real-time calculated altitude

  String get name => object.name;
  String get description => object.description;

  RenderedObject({
    required this.object,
    required this.offset,
    required this.radius,
    this.moonPhase,
    this.horizontalAz,
    this.horizontalAlt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderedObject &&
          runtimeType == other.runtimeType &&
          object.name == other.object.name &&
          offset == other.offset &&
          radius == other.radius;

  @override
  int get hashCode => object.name.hashCode ^ offset.hashCode ^ radius.hashCode;
}

/// A star from HIP catalog rendered on screen.
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderedStar &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          radius == other.radius &&
          color == other.color &&
          opacity == other.opacity;

  @override
  int get hashCode =>
      offset.hashCode ^ radius.hashCode ^ color.hashCode ^ opacity.hashCode;
}

/// A constellation with its component stars and connections.
class Constellation {
  final String id;
  final String name;
  final String description;
  final List<CelestialObject> stars;
  final List<List<int>> connections; // pairs of star indices

  Constellation({
    required this.id,
    required this.name,
    required this.description,
    required this.stars,
    required this.connections,
  });
}

/// Complete sky state snapshot.
class SkyState {
  final double latitude;
  final double longitude;
  final double heading; // device azimuth in degrees
  final double pitch; // device pitch in degrees
  final List<RenderedObject> visibleObjects;
  final CelestialObject? selectedObject;
  final DateTime dateTimeUtc;
  final double julianDate;
  final double lstDegrees;
  final double fovScale;
  final double? moonPhase; // Global current moon phase

  SkyState({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.pitch,
    required this.visibleObjects,
    this.selectedObject,
    required this.dateTimeUtc,
    required this.julianDate,
    required this.lstDegrees,
    this.fovScale = 1.0,
    this.moonPhase,
  });

  SkyState copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? pitch,
    List<RenderedObject>? visibleObjects,
    CelestialObject? selectedObject,
    bool clearSelectedObject = false,
    DateTime? dateTimeUtc,
    double? julianDate,
    double? lstDegrees,
    double? fovScale,
    double? moonPhase,
  }) {
    return SkyState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      pitch: pitch ?? this.pitch,
      visibleObjects: visibleObjects ?? this.visibleObjects,
      selectedObject: clearSelectedObject ? null : (selectedObject ?? this.selectedObject),
      dateTimeUtc: dateTimeUtc ?? this.dateTimeUtc,
      julianDate: julianDate ?? this.julianDate,
      lstDegrees: lstDegrees ?? this.lstDegrees,
      fovScale: fovScale ?? this.fovScale,
      moonPhase: moonPhase ?? this.moonPhase,
    );
  }
}
