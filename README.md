# Sky Map

A Flutter app that renders a real-time sky view on a black canvas (updates at ~10 Hz). Works offline with bundled celestial data.

## Features

- **State management**: `provider` (`SkyMapProvider`)
- **Sensors & location**
  - GPS via `geolocator`
  - Accelerometer + magnetometer via `sensors_plus`
- **Realtime updates**: object positions recalculated every ~100 ms
- **Celestial objects**: complete astronomical data loaded from local JSON asset (`assets/celestial_objects.json`)
- **Offline support**: all planet/star data bundled with the app — no internet required
- **Star field**: curated HIP (Hipparcos) star catalog rendered with spectral-color styling
- **Constellations**: 15+ constellations rendered as line segments (visibility filtered by location/time)
- **Orbital mechanics**: planets use a Kepler-based orbital elements model (educational / simplified)
- **Night Vision mode**: red-light theme to preserve dark adaptation
- **Error handling**: user-friendly dialogs for common location/sensor failures
- **Objects on the canvas**
  - Sun
  - Moon
  - All Solar System planets (Mercury → Neptune)
- **Interaction**: tap an object to open a bottom sheet with detailed description

## Run

```bash
flutter pub get
flutter run
```

## Data Sources

- **Planets & celestial objects**: bundled JSON asset (`assets/celestial_objects.json`) with azimuth/altitude coordinates
- **Stars**: Hipparcos (HIP) catalog with spectral classification
- **Constellations**: IAU constellation boundaries and line patterns

## Notes

- On Android/iOS you must grant location permissions at the platform level.
- The app works **completely offline** — all astronomical data is bundled with the application.
- The sky/object coordinate calculations are approximate (educational level), intended for learning and a believable dynamic sky view that responds to time and device orientation.
- No internet connection is required after installation.
