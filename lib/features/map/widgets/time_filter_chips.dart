import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

/// Filter chips that change based on the current fire data mode
///
/// Per decision D2 (021-live-fire-data):
/// - Hotspots mode: "Today" | "This Week" filters
/// - Burnt Areas mode: "This Season" | "Last Season" filters
///
/// Features:
/// - Dynamic chips based on current mode
/// - Single-select behavior (mutually exclusive)
/// - Accessible: semantic labels for screen readers
/// - Touch targets ≥44dp (C3 compliance)
/// - Compact horizontal layout
///
/// Part of 021-live-fire-data feature implementation.
class TimeFilterChips extends StatelessWidget {
  /// Current fire data mode (determines which filter set to show)
  final FireDataMode mode;

  /// Currently selected hotspot time filter (when mode is hotspots)
  final HotspotTimeFilter hotspotFilter;

  /// Currently selected burnt area season filter (when mode is burntAreas)
  final BurntAreaSeasonFilter burntAreaFilter;

  /// Callback when hotspot filter changes
  final ValueChanged<HotspotTimeFilter> onHotspotFilterChanged;

  /// Callback when burnt area filter changes
  final ValueChanged<BurntAreaSeasonFilter> onBurntAreaFilterChanged;

  /// Whether the chips are enabled
  final bool enabled;

  const TimeFilterChips({
    super.key,
    required this.mode,
    required this.hotspotFilter,
    required this.burntAreaFilter,
    required this.onHotspotFilterChanged,
    required this.onBurntAreaFilterChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label:
          'Time filter for ${mode == FireDataMode.hotspots ? 'hotspots' : 'burnt areas'}',
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
        child: mode == FireDataMode.hotspots
            ? _buildHotspotFilters(context, colorScheme)
            : _buildBurntAreaFilters(context, colorScheme),
      ),
    );
  }

  Widget _buildHotspotFilters(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterChip(
          context: context,
          colorScheme: colorScheme,
          label: 'Today',
          isSelected: hotspotFilter == HotspotTimeFilter.today,
          onSelected: enabled
              ? () => onHotspotFilterChanged(HotspotTimeFilter.today)
              : null,
          tooltip: 'Show hotspots from the last 24 hours',
        ),
        const SizedBox(width: 4),
        _buildFilterChip(
          context: context,
          colorScheme: colorScheme,
          label: 'This Week',
          isSelected: hotspotFilter == HotspotTimeFilter.thisWeek,
          onSelected: enabled
              ? () => onHotspotFilterChanged(HotspotTimeFilter.thisWeek)
              : null,
          tooltip: 'Show hotspots from the last 7 days',
        ),
      ],
    );
  }

  Widget _buildBurntAreaFilters(BuildContext context, ColorScheme colorScheme) {
    final thisSeasonYear = BurntAreaSeasonFilter.thisSeason.year;
    final lastSeasonYear = BurntAreaSeasonFilter.lastSeason.year;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterChip(
          context: context,
          colorScheme: colorScheme,
          label: '$thisSeasonYear',
          isSelected: burntAreaFilter == BurntAreaSeasonFilter.thisSeason,
          onSelected: enabled
              ? () => onBurntAreaFilterChanged(BurntAreaSeasonFilter.thisSeason)
              : null,
          tooltip: 'Show burnt areas from $thisSeasonYear fire season',
        ),
        const SizedBox(width: 4),
        _buildFilterChip(
          context: context,
          colorScheme: colorScheme,
          label: '$lastSeasonYear',
          isSelected: burntAreaFilter == BurntAreaSeasonFilter.lastSeason,
          onSelected: enabled
              ? () => onBurntAreaFilterChanged(BurntAreaSeasonFilter.lastSeason)
              : null,
          tooltip: 'Show burnt areas from $lastSeasonYear fire season',
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String label,
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
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                // Match NavigationBar active icon color (forest900)
                color: isSelected
                    ? BrandPalette.forest900
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
