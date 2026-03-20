// ============================================================================
// CORE DATA MODELS
// ============================================================================

import 'package:flutter/material.dart';

/// Celestial object types.
enum ObjectType { sun, moon, planet }

/// A celestial object (planet, sun, moon, star, etc.)
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

/// A celestial object rendered on screen with position and size.
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

/// A line connecting two constellation stars.
class LineSegment {
  final Offset start;
  final Offset end;
  final String constellation;

  LineSegment(this.start, this.end, this.constellation);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineSegment &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          constellation == other.constellation;

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ constellation.hashCode;
}

/// Complete sky state snapshot.
class SkyState {
  final double latitude;
  final double longitude;
  final double heading; // device azimuth in degrees
  final double pitch; // device pitch in degrees
  final List<RenderedObject> visibleObjects;
  final List<RenderedStar> visibleHipStars;
  final List<LineSegment> constellationLines;
  final CelestialObject? selectedObject;
  final DateTime dateTimeUtc;
  final double julianDate;
  final double lstDegrees;
  final double fovScale;

  SkyState({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.pitch,
    required this.visibleObjects,
    required this.visibleHipStars,
    required this.constellationLines,
    this.selectedObject,
    required this.dateTimeUtc,
    required this.julianDate,
    required this.lstDegrees,
    this.fovScale = 1.0,
  });

  SkyState copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? pitch,
    List<RenderedObject>? visibleObjects,
    List<RenderedStar>? visibleHipStars,
    List<LineSegment>? constellationLines,
    CelestialObject? selectedObject,
    DateTime? dateTimeUtc,
    double? julianDate,
    double? lstDegrees,
    double? fovScale,
  }) {
    return SkyState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      pitch: pitch ?? this.pitch,
      visibleObjects: visibleObjects ?? this.visibleObjects,
      visibleHipStars: visibleHipStars ?? this.visibleHipStars,
      constellationLines: constellationLines ?? this.constellationLines,
      selectedObject: selectedObject,
      dateTimeUtc: dateTimeUtc ?? this.dateTimeUtc,
      julianDate: julianDate ?? this.julianDate,
      lstDegrees: lstDegrees ?? this.lstDegrees,
      fovScale: fovScale ?? this.fovScale,
    );
  }
}
