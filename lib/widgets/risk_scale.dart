import 'package:flutter/material.dart';
import '../models/risk_level.dart';

/// Visual risk scale showing all six risk levels with current level highlighted
///
/// Displays a horizontal bar chart where:
/// - All risk levels shown in sequence (Very Low → Extreme)
/// - Current risk level highlighted with full opacity and 1.25x scale
/// - Other levels shown at 35% opacity
/// - Level labels displayed below each bar
/// - Tooltips available on hover (web/desktop)
/// - Uses RiskPalette colors (no hardcoded values)
/// - Optional tap handler to navigate to help content
///
/// Accessibility:
/// - When [onTap] is provided, the scale is announced as a button
/// - Tap target meets ≥44dp minimum height requirement
/// - Screen reader announces "Learn what the wildfire risk levels mean"
class RiskScale extends StatelessWidget {
  /// Current risk level to highlight
  final RiskLevel currentLevel;

  /// Text color for labels (should match banner text color for consistency)
  final Color textColor;

  /// Height of each risk level bar
  final double barHeight;

  /// Spacing between bars
  final double barSpacing;

  /// Whether to show level labels below bars
  final bool showLabels;

  /// Optional callback when the scale is tapped
  /// When provided, wraps the scale in an InkWell for tap handling
  final VoidCallback? onTap;

  const RiskScale({
    super.key,
    required this.currentLevel,
    required this.textColor,
    this.barHeight = 8.0,
    this.barSpacing = 4.0,
    this.showLabels = true,
    this.onTap,
  });

  /// Get display name for a risk level
  String _getLevelName(RiskLevel level) {
    return switch (level) {
      RiskLevel.veryLow => 'VERY LOW',
      RiskLevel.low => 'LOW',
      RiskLevel.moderate => 'MODERATE',
      RiskLevel.high => 'HIGH',
      RiskLevel.veryHigh => 'VERY HIGH',
      RiskLevel.extreme => 'EXTREME',
    };
  }

  /// Get short label for display below bars
  String _getShortLabel(RiskLevel level) {
    return switch (level) {
      RiskLevel.veryLow => 'Very\nLow',
      RiskLevel.low => 'Low',
      RiskLevel.moderate => 'Mod',
      RiskLevel.high => 'High',
      RiskLevel.veryHigh => 'Very\nHigh',
      RiskLevel.extreme => 'Ext',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scaleContent = Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Risk level bars
          Row(
            children: RiskLevel.values.map((level) {
              final isCurrentLevel = level == currentLevel;
              final color = level.color;
              final levelName = _getLevelName(level);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: barSpacing / 2),
                  child: Tooltip(
                    message: levelName,
                    child: Semantics(
                      label: levelName,
                      selected: isCurrentLevel,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        height: isCurrentLevel ? barHeight * 1.25 : barHeight,
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: isCurrentLevel ? 1.0 : 0.65,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: isCurrentLevel
                              ? Border.all(color: textColor, width: 0.5)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Level labels (optional)
          if (showLabels) ...[
            const SizedBox(height: 4),
            Row(
              children: RiskLevel.values.map((level) {
                final isCurrentLevel = level == currentLevel;
                final shortLabel = _getShortLabel(level);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: barSpacing / 2),
                    child: Text(
                      shortLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8,
                        height: 1.1,
                        fontWeight:
                            isCurrentLevel ? FontWeight.w600 : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

    // When onTap is provided, wrap in tappable widget with accessibility
    if (onTap != null) {
      return Semantics(
        label: 'Learn what the wildfire risk levels mean',
        hint: 'Opens help information',
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            // Ensure minimum 44dp tap target height
            constraints: const BoxConstraints(minHeight: 44),
            child: scaleContent,
          ),
        ),
      );
    }

    // Default: non-tappable with descriptive semantics
    return Semantics(
      label:
          'Risk scale showing ${_getLevelName(currentLevel)} highlighted among all six risk levels',
      child: scaleContent,
    );
  }
}
