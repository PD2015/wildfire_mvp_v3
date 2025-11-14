import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Time range filter chip for limiting fire incident display.
///
/// Provides quick filtering options:
/// - Last 6 hours
/// - Last 12 hours
/// - Last 24 hours
/// - Last 48 hours
///
/// C3 Compliance: Semantic labels and ≥44dp touch targets
/// C4 Compliance: Clear visual indication of active filter
class TimeFilterChip extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;

  const TimeFilterChip({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Time filter: ${selectedRange.label}',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: TimeRange.values.map((range) {
            final isSelected = range == selectedRange;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Semantics(
                label: 'Filter by ${range.label}',
                button: true,
                selected: isSelected,
                child: FilterChip(
                  key: Key('time_filter_${range.name}'),
                  label: Text(range.label),
                  selected: isSelected,
                  onSelected: (_) => onRangeChanged(range),
                  selectedColor: RiskPalette.blueAccent.withValues(alpha: 0.2),
                  checkmarkColor: RiskPalette.blueAccent,
                  backgroundColor: RiskPalette.lightGray.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? RiskPalette.blueAccent : RiskPalette.darkGray,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? RiskPalette.blueAccent : RiskPalette.midGray,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.comfortable,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Time range enumeration for fire incident filtering.
enum TimeRange {
  last6Hours(Duration(hours: 6), 'Last 6h'),
  last12Hours(Duration(hours: 12), 'Last 12h'),
  last24Hours(Duration(hours: 24), 'Last 24h'),
  last48Hours(Duration(hours: 48), 'Last 48h');

  const TimeRange(this.duration, this.label);

  final Duration duration;
  final String label;

  /// Get cutoff timestamp for filtering.
  ///
  /// Returns UTC timestamp representing the earliest time to include.
  DateTime get cutoffTime => DateTime.now().toUtc().subtract(duration);

  /// Check if a timestamp is within this time range.
  bool includes(DateTime timestamp) {
    return timestamp.isAfter(cutoffTime);
  }
}
