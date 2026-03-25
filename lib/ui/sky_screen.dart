// ============================================================================
// SKY SCREEN - UI & INTERACTION
// ============================================================================

// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sky_map/providers/sky_provider.dart';
import 'package:sky_map/ui/sky_painter.dart';
import 'package:sky_map/models/models.dart';

class SkyScreen extends StatefulWidget {
  final bool nightVisionMode;
  final Function(bool) onNightVisionChanged;

  const SkyScreen({
    super.key,
    this.nightVisionMode = false,
    required this.onNightVisionChanged,
  });

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> {
  Offset? _lastFocalPoint;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkyProvider>();
    final status = provider.statusLine;
    final allConstellations = provider.constellations;
    final availableConstellationNames = allConstellations
        .map((c) => c.name)
        .toSet()
        .toList()
      ..sort();
    final selectedKey = provider.selectedConstellationKey;
    final selectedExists = selectedKey != null &&
        allConstellations.any((c) => c.name == selectedKey || c.id == selectedKey);
    final visibleConstellations = !provider.showConstellations
        ? const <Constellation>[]
        : (selectedExists
              ? allConstellations
                    .where((c) => c.name == selectedKey || c.id == selectedKey)
                    .toList()
              : allConstellations);

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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Open search dialog
              showSearch(
                context: context,
                delegate: SkySearchDelegate(provider),
              );
            },
            tooltip: 'Find Object',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              status,
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
                    final selected = provider.state.selectedObject;
                    if (selected == null) return;

                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent, // Transparent for blur
                      barrierColor: Colors.black26,
                      isScrollControlled: true,
                      builder: (ctx) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Color(0xCC101010), // Semi-transparent
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      selected.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      selected.description,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (provider.riseSetString.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.amber),
                                            const SizedBox(width: 8),
                                            Text(
                                              provider.riseSetString,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ).then((_) {
                      provider.selectObject(null);
                    });
                  },
                  onScaleStart: (details) {
                    _lastFocalPoint = details.localFocalPoint;
                  },
                  onScaleUpdate: (details) {
                    // 1. Zoom (FOV scale)
                    provider.updateFovScale(details.scale);

                    // 2. Pan (Nudge)
                    if (_lastFocalPoint != null) {
                      final delta = details.localFocalPoint - _lastFocalPoint!;
                      // Normalize delta relative to screen size for provider
                      final deltaNormalized = Offset(
                        delta.dx / size.width,
                        delta.dy / size.height,
                      );
                      provider.updateManualPan(deltaNormalized);
                    }
                    _lastFocalPoint = details.localFocalPoint;
                  },
                  onScaleEnd: (details) {
                    _lastFocalPoint = null;
                  },
                  child: CustomPaint(
                    painter: SkyPainter(
                      provider.state.visibleObjects,
                      provider.state.selectedObject?.name,
                      constellations: provider.visibleConstellations,
                      state: provider.state,
                      nightVisionMode: widget.nightVisionMode,
                      baseAzimuthFov: provider.baseAzimuthFov,
                      baseAltitudeFov: provider.baseAltitudeFov,
                      azimuthFovScale: provider.azimuthFovScale,
                      altitudeFovScale: provider.altitudeFovScale,
                    ),
                    child: Container(),
                  ),
                );
              },
            ),
          ),

          // Sensor status indicator
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00FFA3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00FFA3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SENSORS ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Guidance Arrow for search target
          if (provider.guidanceAngle != null)
            Center(
              child: Transform.rotate(
                angle: (provider.guidanceAngle! + 90) * 3.14159 / 180, // Rotate arrow to point
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 250), // Position arrow away from center
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation, color: Colors.amber, size: 40),
                      const SizedBox(height: 4),
                      Text(
                        provider.searchTarget?.name ?? "",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Time Travel Slider
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display adjusted time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    "TIME: ${provider.state.dateTimeUtc.toLocal().toString().substring(11, 16)} "
                    "(${provider.manualTimeOffsetHours >= 0 ? '+' : ''}${provider.manualTimeOffsetHours.toStringAsFixed(1)}h)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: Colors.amber,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.amber,
                        ),
                        child: Slider(
                          value: provider.manualTimeOffsetHours,
                          min: -12.0,
                          max: 12.0,
                          divisions: 48, // 30 min increments
                          onChanged: (val) {
                            provider.setTimeOffset(val);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkySearchDelegate extends SearchDelegate {
  final SkyProvider provider;

  SkySearchDelegate(this.provider);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final list = provider.catalog
        .where((obj) => obj.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: const Color(0xFF101010),
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final obj = list[index];
          return ListTile(
            title: Text(obj.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(obj.type, style: const TextStyle(color: Colors.white60)),
            onTap: () {
              provider.setSearchTarget(obj);
              close(context, obj);
            },
          );
        },
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white60),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: Colors.white),
      ),
    );
  }
}
