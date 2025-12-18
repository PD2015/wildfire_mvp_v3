import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// MapSourceChip displays the data source and freshness indicator
///
/// Shows where the fire data is coming from (EFFIS/SEPA/Cache/Mock)
/// and when it was last updated. Displays prominent indicator chips:
/// - "DEMO DATA" when MAP_LIVE_DATA=false (deliberate demo mode)
/// - "OFFLINE" when MAP_LIVE_DATA=true but API failed
/// - "LIVE" when successfully fetching live data
///
/// Constitutional compliance:
/// - C3: Accessible with semantic labels and ≥44dp touch targets
/// - C4: Trust & Transparency - clear demo data indicator
/// - C5: Mock-first development principle
class MapSourceChip extends StatelessWidget {
  final Freshness source;
  final DateTime lastUpdated;
  final bool isOffline;

  const MapSourceChip({
    super.key,
    required this.source,
    required this.lastUpdated,
    this.isOffline = false,
  });

  IconData _getSourceIcon() {
    switch (source) {
      case Freshness.live:
        return Icons.cloud_done;
      case Freshness.cached:
        return Icons.cached;
      case Freshness.mock:
        return Icons.science;
    }
  }

  Color _getSourceColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (source) {
      case Freshness.live:
        return colorScheme.primary;
      case Freshness.cached:
        return colorScheme.tertiary;
      case Freshness.mock:
        return colorScheme.secondary;
    }
  }

  String _getSourceLabel() {
    switch (source) {
      case Freshness.live:
        return 'LIVE';
      case Freshness.cached:
        return 'CACHED';
      case Freshness.mock:
        return 'MOCK';
    }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show prominent warning chip in three scenarios:
    // 1. Offline: MAP_LIVE_DATA=true but API failed (no data available)
    // 2. Demo mode: MAP_LIVE_DATA=false (deliberate testing mode with mock data)
    // 3. Mock data: source == Freshness.mock (legacy, shouldn't happen with Option C)

    // Offline state: Live mode enabled but API failed - no data shown
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

    // Demo mode: MAP_LIVE_DATA=false - showing mock data for testing
    final bool isUsingMockData = source == Freshness.mock;
    if (isUsingMockData) {
      // High-contrast amber chip for visibility against map (T-V1)
      // Same styling for both light and dark themes
      // Compact sizing to avoid overlap with FireDataModeToggle
      return Semantics(
        label: 'Demo Data - For testing purposes only',
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(
            Icons.science_outlined,
            size: 16,
            color: Color(0xFF111111), // BrandPalette.onLightHigh
          ),
          label: Text(
            'DEMO DATA',
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

    // Standard source chip for live/cached data
    final sourceColor = _getSourceColor(context);
    return Semantics(
      label: 'Data source: ${_getSourceLabel()}, updated ${_formatTimestamp()}',
      child: Chip(
        avatar: Icon(
          _getSourceIcon(),
          size: 16,
          color: sourceColor,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getSourceLabel(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: sourceColor,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimestamp(),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        backgroundColor: sourceColor.withValues(alpha: 0.1),
        side: BorderSide(color: sourceColor, width: 1),
        elevation: 4,
        shadowColor:
            Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
      ),
    );
  }
}
