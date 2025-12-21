import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// MapSourceChip displays the data source and freshness indicator
///
/// Shows where the fire data is coming from (EFFIS/SEPA/Cache/Mock)
/// and when it was last updated. Displays prominent indicator chips:
/// - "DEMO DATA" when in demo mode (tappable to switch to live)
/// - "OFFLINE" when live mode enabled but API failed
/// - "LIVE DATA" when successfully fetching live data (tappable to switch to demo)
///
/// **Interactive Mode**: When `onTap` is provided, the chip becomes tappable
/// allowing users to toggle between live and demo data modes. A small toggle
/// icon appears to indicate interactivity.
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
    // Show prominent warning chip in three scenarios:
    // 1. Offline: Live mode but API failed (no data available)
    // 2. Demo mode: Deliberate testing mode with mock data
    // 3. Mock data: source == Freshness.mock (legacy, shouldn't happen with Option C)

    // Offline state: Live mode enabled but API failed - no data shown
    // Not tappable when offline (need retry, not mode switch)
    if (isOffline) {
      return Semantics(
        label:
            'Offline - Unable to fetch live fire data. Tap retry to try again.',
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(
            Icons.cloud_off,
            size: 16,
            color: Color(0xFF111111), // BrandPalette.onLightHigh
          ),
          label: Text(
            'OFFLINE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111111), // BrandPalette.onLightHigh
                  letterSpacing: 1.0,
                ),
          ),
          backgroundColor: const Color(0xFFF5A623), // BrandPalette.amber500
          side: const BorderSide(
            color: Color(0xFFE59414), // BrandPalette.amber600 (darker border)
            width: 1.5,
          ),
          elevation: 4,
          shadowColor:
              Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
        ),
      );
    }

    // Demo mode: Showing mock data for testing
    final bool isUsingMockData = source == Freshness.mock;
    if (isUsingMockData) {
      return _buildTappableChip(
        context: context,
        label: 'DEMO DATA',
        icon: Icons.science_outlined,
        backgroundColor: const Color(0xFFF5A623), // BrandPalette.amber500
        borderColor: const Color(0xFFE59414), // BrandPalette.amber600
        textColor: const Color(0xFF111111), // BrandPalette.onLightHigh
        semanticLabel: onTap != null
            ? 'Demo Data mode - Tap to switch to Live Data'
            : 'Demo Data - For testing purposes only',
      );
    }

    // Live mode: Successfully fetching live data
    return _buildTappableChip(
      context: context,
      label: 'LIVE DATA',
      icon: Icons.cloud_done,
      backgroundColor:
          const Color(0xFF4CAF50).withValues(alpha: 0.15), // Green tint
      borderColor: const Color(0xFF4CAF50), // Green
      textColor: const Color(0xFF2E7D32), // Dark green
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
      avatar: Icon(
        icon,
        size: 16,
        color: textColor,
      ),
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
      side: BorderSide(
        color: borderColor,
        width: 1.5,
      ),
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

    return Semantics(
      label: semanticLabel,
      child: chip,
    );
  }
}
