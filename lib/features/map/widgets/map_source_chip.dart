import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// MapSourceChip displays the data source and freshness indicator
///
/// Shows where the fire data is coming from (EFFIS/SEPA/Cache/Mock)
/// and when it was last updated.
///
/// Constitutional compliance:
/// - C3: Accessible with semantic labels
/// - C4: Uses theme colors for consistency
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
    return Semantics(
      label: 'Data source: ${_getSourceLabel()}, updated ${_formatTimestamp()}',
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSourceIcon(),
                size: 16,
                color: _getSourceColor(context),
              ),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
