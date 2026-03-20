// ============================================================================
// MAIN - MINIMAL ENTRY POINT
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sky_map/providers/sky_provider.dart';
import 'package:sky_map/themes/night_vision_theme.dart';
import 'package:sky_map/ui/sky_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SkyProvider()..initialize(),
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
      home: SkyScreen(
        nightVisionMode: _nightVisionMode,
        onNightVisionChanged: (value) {
          setState(() => _nightVisionMode = value);
        },
      ),
    );
  }
}
