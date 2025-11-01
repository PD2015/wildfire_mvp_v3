import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';

/// MapSourceChip displays the data source and freshness indicator
///
/// Shows where the fire data is coming from (EFFIS/SEPA/Cache/Mock)
/// and when it was last updated. Displays prominent "Demo Data" chip
/// when MAP_LIVE_DATA=false for user transparency (T019, C4).
///
/// Constitutional compliance:
/// - C3: Accessible with semantic labels and ≥44dp touch targets
/// - C4: Trust & Transparency - clear demo data indicator
/// - C5: Mock-first development principle
class MapSourceChip extends StatelessWidget {
  final Freshness source;
  final DateTime lastUpdated;

  const MapSourceChip({
    super.key,
    required this.source,
    required this.lastUpdated,
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
    switch (source) {
      case Freshness.live:
        return Colors.green;
      case Freshness.cached:
        return Colors.orange;
      case Freshness.mock:
        return Colors.blue;
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
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show prominent "Demo Data" chip when using mock data in development mode
    final bool isDemoMode =
        !FeatureFlags.mapLiveData && source == Freshness.mock;

    if (isDemoMode) {
      return Semantics(
        label: 'Demo Data - For testing purposes only',
        child: Card(
          elevation: 6,
          color: Colors.amber.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.amber.shade700, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 20,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                Text(
                  'DEMO DATA',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Standard source chip for live/cached data
    return Semantics(
      label: 'Data source: ${_getSourceLabel()}, updated ${_formatTimestamp()}',
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getSourceIcon(), size: 16, color: _getSourceColor(context)),
              const SizedBox(width: 8),
              Text(
                _getSourceLabel(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getSourceColor(context),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
