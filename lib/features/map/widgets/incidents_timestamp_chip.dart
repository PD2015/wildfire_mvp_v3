import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/utils/time_format.dart';

/// IncidentsTimestampChip: Displays when fire incident data was last updated
///
/// **Purpose**: Shows data freshness for fire incidents on the map to improve
/// user trust and transparency (C4 constitutional gate).
///
/// **Usage**:
/// ```dart
/// IncidentsTimestampChip(
///   lastUpdated: state.lastUpdated,  // DateTime from MapSuccess.lastUpdated
/// )
/// ```
///
/// **Display Format**:
/// - "Incidents updated Just now" (<45 seconds)
/// - "Incidents updated 5 min ago" (<60 minutes)
/// - "Incidents updated 2 hours ago" (<24 hours)
/// - "Incidents updated 3 days ago" (≥24 hours)
///
/// **Auto-Refresh**: Timer.periodic updates display every minute to keep
/// relative time accurate. Timer is properly managed in State lifecycle
/// (initState creates, dispose cancels).
///
/// **Accessibility (C3 compliance)**:
/// - Touch target: ≥44dp height (Material Design minimum)
/// - Semantic label: "Incidents last updated X minutes ago"
/// - Screen reader support via Semantics widget
///
/// **Styling**:
/// - Chip widget with subtle elevation (2.0)
/// - surfaceContainerHighest background (theme-aware)
/// - onSurface text color (high contrast)
/// - Clock icon (Icons.access_time) for visual clarity
///
/// **Updates**:
/// - External: When MapSuccess.lastUpdated changes (new data fetch)
/// - Internal: Every minute via Timer.periodic (keeps relative time accurate)
class IncidentsTimestampChip extends StatefulWidget {
  final DateTime lastUpdated;

  const IncidentsTimestampChip({
    super.key,
    required this.lastUpdated,
  });

  @override
  State<IncidentsTimestampChip> createState() => _IncidentsTimestampChipState();
}

class _IncidentsTimestampChipState extends State<IncidentsTimestampChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh timestamp every minute for accurate relative time
    // Example: "Just now" → "1 min ago" → "2 min ago" without manual refresh
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          // Triggers rebuild to recalculate relative time in build()
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Clean up timer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Format timestamp using existing utility (handles UTC to local conversion)
    final now = DateTime.now().toUtc();
    final relativeTime = formatRelativeTime(
      utcNow: now,
      updatedUtc:
          widget.lastUpdated, // Access via widget property in StatefulWidget
    );

    // Display text: "Incidents updated X min ago"
    final displayText = 'Incidents updated $relativeTime';

    // Semantic label for screen readers (more descriptive)
    final semanticLabel = 'Incidents last updated $relativeTime';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true, // Prevent double-reading of text
      child: Chip(
        avatar: Icon(
          Icons.access_time,
          size: 18,
          color: colorScheme.onSurface,
        ),
        label: Text(
          displayText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        elevation: 2.0,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        materialTapTargetSize: MaterialTapTargetSize.padded, // Ensures ≥44dp
      ),
    );
  }
}
