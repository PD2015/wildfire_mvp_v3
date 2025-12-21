import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// MapSourceChip displays the data source and freshness indicator
///
/// Shows where the fire data is coming from (EFFIS/SEPA/Cache/Mock)
/// and when it was last updated. Displays prominent indicator chips:
/// - "DEMO DATA" when in demo mode (tappable to switch to live)
/// - "OFFLINE" when live mode enabled but API failed
/// - "LIVE DATA" when successfully fetching live data (tappable to switch to demo)
/// - "CACHED" when displaying cached data (distinct from live)
///
/// **Interactive Mode**: When `onTap` is provided, the chip becomes tappable
/// allowing users to toggle between live and demo data modes. A small toggle
/// icon appears to indicate interactivity.
///
/// **Styling**: Uses Material 3 ColorScheme tokens from theme:
/// - Demo/Offline: tertiaryContainer (amber) for warning states
/// - Live: primaryContainer (forest green) for active/healthy states
/// - Cached: secondaryContainer (mint) for stale/cached states
///
/// Constitutional compliance:
/// - C3: Accessible with semantic labels and ≥44dp touch targets
/// - C4: Trust & Transparency - clear demo data indicator
/// - C5: Mock-first development principle
class MapSourceChip extends StatelessWidget {
  final Freshness source;
  final DateTime lastUpdated;
  final bool isOffline;

  /// Optional callback when chip is tapped (for live/demo toggle)
  /// When provided, shows a toggle indicator on the chip
  final VoidCallback? onTap;

  const MapSourceChip({
    super.key,
    required this.source,
    required this.lastUpdated,
    this.isOffline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Show prominent warning chip in four scenarios:
    // 1. Offline: Live mode but API failed (no data available)
    // 2. Demo mode: Deliberate testing mode with mock data
    // 3. Live mode: Successfully fetching live data
    // 4. Cached mode: Displaying cached data (stale but valid)

    // Offline state: Live mode enabled but API failed - no data shown
    // Not tappable when offline (need retry, not mode switch)
    if (isOffline) {
      return Semantics(
        label:
            'Offline - Unable to fetch live fire data. Tap retry to try again.',
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(
            Icons.cloud_off,
            size: 16,
            color: scheme.onTertiaryContainer,
          ),
          label: Text(
            'OFFLINE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onTertiaryContainer,
                  letterSpacing: 1.0,
                ),
          ),
          backgroundColor: scheme.tertiaryContainer,
          side: BorderSide(color: scheme.tertiary, width: 1.5),
          elevation: 4,
          shadowColor: scheme.shadow.withValues(alpha: 0.3),
        ),
      );
    }

    // Demo mode: Showing mock data for testing
    if (source == Freshness.mock) {
      return _buildTappableChip(
        context: context,
        label: 'DEMO DATA',
        icon: Icons.science_outlined,
        backgroundColor: scheme.tertiaryContainer,
        borderColor: scheme.tertiary,
        textColor: scheme.onTertiaryContainer,
        semanticLabel: onTap != null
            ? 'Demo Data mode - Tap to switch to Live Data'
            : 'Demo Data - For testing purposes only',
      );
    }

    // Cached mode: Displaying cached data (stale but valid)
    if (source == Freshness.cached) {
      return _buildTappableChip(
        context: context,
        label: 'CACHED',
        icon: Icons.cached,
        backgroundColor: scheme.secondaryContainer,
        borderColor: scheme.secondary,
        textColor: scheme.onSecondaryContainer,
        semanticLabel: onTap != null
            ? 'Cached Data mode - Tap to switch to Demo Data'
            : 'Cached Data - Displaying previously fetched data',
      );
    }

    // Live mode: Successfully fetching live data
    return _buildTappableChip(
      context: context,
      label: 'LIVE DATA',
      icon: Icons.cloud_done,
      backgroundColor: scheme.primaryContainer,
      borderColor: scheme.primary,
      textColor: scheme.onPrimaryContainer,
      semanticLabel: onTap != null
          ? 'Live Data mode - Tap to switch to Demo Data'
          : 'Live Data - Fetching real-time fire data',
    );
  }

  /// Build a chip that can optionally be tapped to toggle data mode
  Widget _buildTappableChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required String semanticLabel,
  }) {
    final chip = Chip(
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.only(left: 4, right: 2),
      avatar: Icon(icon, size: 16, color: textColor),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 1.0,
                ),
          ),
          // Show toggle icon when tappable
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.swap_horiz,
              size: 14,
              color: textColor.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(color: borderColor, width: 1.5),
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
    );

    // Wrap in tappable widget if callback provided
    if (onTap != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: chip,
          ),
        ),
      );
    }

    return Semantics(label: semanticLabel, child: chip);
  }
}
