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




        ],
      ),
    );
  }
}


