# Sky Map 🌌

A high-performance astronomical rendering engine for Flutter. Displays a real-time, interactive map of the night sky with 60 FPS performance and cinematic visual effects.

## Core Features

- **60 FPS Rendering**: Optimized custom painter core for ultra-smooth celestial navigation.
- **Natural Interaction**: 
  - **Natural Scroll**: Intuitive panning logic where the sky follows your touch.
  - **Natural Zoom**: 200x magnification with focal-point scaling.
  - **Sensor Motion**: Real-time stabilization across GPS, accelerometer, and magnetometer sensors.
- **Visual Fidelity**:
  - 12-ray solar flare system and dynamic star radius scaling.
  - High-precision planet rendering (including Saturn's rings).
  - Artifact-free constellation rendering with azimuth wrap-around protection.
- **Night Vision Mode**: Pruned, professional red-light theme to preserve dark adaptation.
- **Clean Architecture**: 
  - **State Management**: Powered by the `Provider` pattern.
  - **Data Driven**: All celestial data (stars, planets, 6+ constellations) loaded from a clean `assets/celestial_objects.json`.
  - **Zero Junk**: No legacy catalogs or redundant error handlers; the project passes `flutter analyze` with 0 warnings.

## Getting Started

1. **Setup Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on Device**:
   ```bash
   flutter run
   ```
   *(Physical device recommended for sensor-based navigation)*

## Technical Implementation

- **Coordinate System**: Uses J2000 Right Ascension / Declination converted to Horizontal Alt/Az using real-time GPS and LST (Local Sidereal Time) calculations.
- **Orbital Mechanics**: Simplified Keplerian models for planetary positions, optimized for mobile performance.
- **UI & State**: Immutable state snapshots with `copyWith` and `ChangeNotifier` for reactive and predictable updates.

## Offline Support
The application is **100% offline-ready**. No external APIs are required after installation, making it ideal for stargazing sessions in remote locations.
