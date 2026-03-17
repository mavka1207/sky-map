# Sky Map

A Flutter app that renders a real-time sky view on a black canvas (updates at ~10 Hz).

## Features

- **State management**: `provider` (`SkyMapProvider`)
- **Sensors & location**
  - GPS via `geolocator`
  - Accelerometer + magnetometer via `sensors_plus`
- **Realtime updates**: object positions recalculated every ~100 ms
- **Planet details**: mass/gravity fetched from a public API (`le-systeme-solaire`)
- **Star field**: curated HIP (Hipparcos) star catalog rendered with spectral-color styling
- **Constellations**: 15+ constellations rendered as line segments (visibility filtered by location/time)
- **Orbital mechanics**: planets use a Kepler-based orbital elements model (educational / simplified)
- **Night Vision mode**: red-light theme to preserve dark adaptation
- **Error handling**: user-friendly dialogs for common location/sensor failures
- **Objects on the canvas**
  - Sun
  - Moon
  - All Solar System planets (Mercury → Neptune)
- **Interaction**: tap an object to open a bottom sheet with a short description

## Run

```bash
flutter pub get
flutter run
```

## Notes

- On Android/iOS you must grant location permissions at the platform level.
- Android release builds typically need the `INTERNET` permission to fetch planet details from the API.
- The sky/object coordinate calculations are approximate (educational level), intended for learning and a believable dynamic sky view that responds to time and device orientation.
