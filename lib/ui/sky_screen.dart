// ============================================================================
// SKY SCREEN - UI & INTERACTION
// ============================================================================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sky_map/models/constellation_data.dart';
import 'package:sky_map/providers/sky_provider.dart';
import 'package:sky_map/ui/sky_painter.dart';

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
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkyProvider>();
    final status = provider.statusLine;

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
                  onScaleUpdate: (details) {
                    // Pinch-zoom: update FOV scale based on pinch distance
                    provider.updateFovScale(details.scale);
                  },
                  child: CustomPaint(
                    painter: SkyPainter(
                      provider.state.visibleObjects,
                      provider.state.selectedObject?.name,
                      hipStars: provider.state.visibleHipStars,
                      constellations: provider.constellations,
                      state: provider.state,
                      nightVisionMode: widget.nightVisionMode,
                      azimuthFovScale: provider.azimuthFovScale,
                      altitudeFovScale: provider.altitudeFovScale,
                    ),
                    child: Container(),
                  ),
                );
              },
            ),
          ),
          // Bottom controls
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                if (provider.showConstellations)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: provider.selectedConstellationKey,
                          hint: const Text(
                            'All Constellations',
                            style: TextStyle(color: Colors.white54),
                          ),
                          dropdownColor: Colors.grey.shade900,
                          style: const TextStyle(color: Colors.white70),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Constellations'),
                            ),
                            ...ConstellationCatalog.getConstellationNames().map(
                              (name) => DropdownMenuItem<String?>(
                                value: name,
                                child: Text(name),
                              ),
                            ),
                          ],
                          onChanged: provider.setSelectedConstellation,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    provider.showConstellations
                        ? Icons.star
                        : Icons.star_outline,
                    color: Colors.white70,
                  ),
                  onPressed: () => provider.setShowConstellations(
                    !provider.showConstellations,
                  ),
                  tooltip: 'Toggle Constellations',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
