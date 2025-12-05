import 'package:flutter/material.dart';

/// A toggle chip for showing/hiding burnt area polygons on the map
///
/// Provides a visual toggle control that allows users to show or hide
/// the polygon overlays representing burnt areas. Uses Material Design
/// chip styling consistent with other map overlay controls.
///
/// Constitutional compliance:
/// - C3: Accessible with semantic labels and ≥44dp touch targets
/// - C4: Clear visual feedback for toggle state
class PolygonToggleChip extends StatelessWidget {
  /// Whether polygons are currently visible
  final bool showPolygons;

  /// Callback when the toggle is tapped
  final VoidCallback onToggle;

  /// Whether the toggle is enabled (e.g., disabled at low zoom)
  final bool enabled;

  const PolygonToggleChip({
    super.key,
    required this.showPolygons,
    required this.onToggle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use fire icons to match app branding (same as markers)
    final iconData = showPolygons
        ? Icons.local_fire_department
        : Icons.local_fire_department_outlined;
    final label = showPolygons ? 'Hide burn areas' : 'Show burn areas';
    final semanticLabel = showPolygons
        ? 'Burnt areas visible. Tap to hide.'
        : 'Burnt areas hidden. Tap to show.';

    // Use grey to match Google Maps native controls (zoom, GPS buttons)
    final contentColor = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: enabled,
      child: Container(
        key: const Key('polygon_toggle_container'),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onToggle : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48, // Match IconButton size
                minWidth: 48,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconData,
                    size: 24,
                    color: contentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: contentColor,
                          fontWeight: showPolygons
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
