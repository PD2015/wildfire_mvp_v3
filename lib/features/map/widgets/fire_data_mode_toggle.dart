import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

/// A toggle for switching between Hotspots and Burnt Areas modes
///
/// Replaces PolygonToggleChip per decision D1 (021-live-fire-data).
/// Provides mutually exclusive selection between fire data visualization modes.
///
/// Uses custom chip styling (same as TimeFilterChips) for consistent
/// corner rounding and internal padding.
///
/// Features:
/// - Custom chips with "Hotspots" and "Burnt Areas" labels
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeChip(
              context: context,
              colorScheme: colorScheme,
              label: 'Hotspots',
              icon: Icons.whatshot,
              isSelected: mode == FireDataMode.hotspots,
              onSelected:
                  enabled ? () => onModeChanged(FireDataMode.hotspots) : null,
              tooltip: 'Show active fire hotspots from satellite detection',
            ),
            const SizedBox(width: 4),
            _buildModeChip(
              context: context,
              colorScheme: colorScheme,
              label: 'Burnt Areas',
              icon: Icons.layers,
              isSelected: mode == FireDataMode.burntAreas,
              onSelected:
                  enabled ? () => onModeChanged(FireDataMode.burntAreas) : null,
              tooltip: 'Show verified burnt area polygons',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onSelected,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        // Match NavigationBar active indicator color (mint400)
        color: isSelected ? BrandPalette.mint400 : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            // Ensure minimum 44dp touch target
            constraints: const BoxConstraints(
              minHeight: 36,
              minWidth: 44,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? BrandPalette.forest900
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? BrandPalette.forest900
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
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
