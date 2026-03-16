# Sky Map

A Flutter app that renders a simple real-time sky view on a black canvas (updates at ~10 Hz).

## Features

- **State management**: `provider` (`SkyMapProvider`)
- **Sensors & location**
  - GPS via `geolocator`
  - Accelerometer + magnetometer via `sensors_plus`
- **Realtime updates**: object positions recalculated every ~100 ms
- **Planet details**: mass/gravity fetched from a public API
  - `https://api.le-systeme-solaire.net/rest/bodies/`
- **Objects on the canvas**
  - Sun
  - Moon
  - All Solar System planets (Mercury → Neptune)
  - 3 constellations as line segments (Orion, Ursa Major, Cassiopeia)
- **Interaction**: tap an object to open a bottom sheet with a short description

## Run

```bash
flutter pub get
flutter run
```

## Notes

- On Android/iOS you must grant location permissions at the platform level.
- The sky/object coordinate calculations are approximate (educational level), but they provide a believable dynamic sky view that responds to time and device orientation.
