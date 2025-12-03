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

    // Determine colors based on state
    final backgroundColor = enabled
        ? (showPolygons
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final foregroundColor = enabled
        ? (showPolygons
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant)
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    final iconData = showPolygons ? Icons.layers : Icons.layers_outlined;
    final label = showPolygons ? 'Areas ON' : 'Areas OFF';
    final semanticLabel = showPolygons
        ? 'Burnt areas visible. Tap to hide.'
        : 'Burnt areas hidden. Tap to show.';

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: enabled,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          onTap: enabled ? onToggle : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 44, // C3: Minimum touch target
              minWidth: 44,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconData,
                  size: 18,
                  color: foregroundColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight:
                            showPolygons ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
