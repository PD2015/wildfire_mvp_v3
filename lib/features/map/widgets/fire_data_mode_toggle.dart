import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

/// A SegmentedButton toggle for switching between Hotspots and Burnt Areas modes
///
/// Replaces PolygonToggleChip per decision D1 (021-live-fire-data).
/// Provides mutually exclusive selection between fire data visualization modes.
///
/// Features:
/// - SegmentedButton with "Hotspots" and "Burnt Areas" labels
/// - Icons for visual distinction (whatshot vs layers)
/// - Accessible: semantic labels for screen readers
/// - Touch targets ≥44dp (C3 compliance)
///
/// Part of 021-live-fire-data feature implementation.
class FireDataModeToggle extends StatelessWidget {
  /// Currently selected fire data mode
  final FireDataMode mode;

  /// Callback when mode changes
  final ValueChanged<FireDataMode> onModeChanged;

  /// Whether the toggle is enabled
  final bool enabled;

  const FireDataModeToggle({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Fire data display mode',
      hint: 'Select between hotspots and burnt areas visualization',
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SegmentedButton<FireDataMode>(
          segments: const [
            ButtonSegment<FireDataMode>(
              value: FireDataMode.hotspots,
              label: Text('Hotspots'),
              icon: Icon(Icons.whatshot, size: 18),
              tooltip: 'Show active fire hotspots from satellite detection',
            ),
            ButtonSegment<FireDataMode>(
              value: FireDataMode.burntAreas,
              label: Text('Burnt Areas'),
              icon: Icon(Icons.layers, size: 18),
              tooltip: 'Show verified burnt area polygons',
            ),
          ],
          selected: {mode},
          onSelectionChanged: enabled
              ? (Set<FireDataMode> selection) {
                  if (selection.isNotEmpty) {
                    onModeChanged(selection.first);
                  }
                }
              : null,
          showSelectedIcon: false,
          style: ButtonStyle(
            // Ensure minimum touch target of 44dp
            minimumSize: WidgetStateProperty.all(const Size(44, 44)),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            // Visual styling - matches NavigationBar active indicator (mint400)
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BrandPalette.mint400;
              }
              return colorScheme.surface;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BrandPalette.forest900;
              }
              return colorScheme.onSurface;
            }),
          ),
        ),
      ),
    );
  }
}
