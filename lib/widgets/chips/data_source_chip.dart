import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Chip widget displaying the data source type with color-coded styling
/// 
/// Shows badges for Live/Cached/Mock data sources with appropriate colors
/// from the Scottish color palette. Provides accessibility labels for
/// screen readers.
/// 
/// Example usage:
/// ```dart
/// DataSourceChip(sourceType: DataSourceType.live)
/// DataSourceChip(sourceType: DataSourceType.cached)
/// DataSourceChip(sourceType: DataSourceType.mock)
/// ```
/// 
/// Constitutional compliance:
/// - C3: Accessibility - Semantic labels for screen readers
/// - C4: Transparency - Clear visual distinction between data sources
class DataSourceChip extends StatelessWidget {
  /// Type of data source to display
  final DataSourceType sourceType;
  
  /// Optional custom label text (defaults to source type description)
  final String? label;
  
  const DataSourceChip({
    super.key,
    required this.sourceType,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final chipData = _getChipData();
    
    return Semantics(
      label: chipData.semanticLabel,
      button: false,
      child: Chip(
        avatar: Icon(
          chipData.icon,
          color: chipData.iconColor,
          size: 16,
          semanticLabel: '', // Icon meaning conveyed by chip semantic label
        ),
        label: Text(
          label ?? chipData.displayLabel,
          style: TextStyle(
            color: chipData.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: chipData.backgroundColor,
        side: BorderSide(
          color: chipData.borderColor,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
  
  /// Get styling data for the current source type
  _ChipData _getChipData() {
    switch (sourceType) {
      case DataSourceType.live:
        return const _ChipData(
          displayLabel: 'LIVE',
          semanticLabel: 'Live data from EFFIS API',
          icon: Icons.cloud_outlined,
          iconColor: RiskPalette.white,
          textColor: RiskPalette.white,
          backgroundColor: RiskPalette.low, // Green for live/fresh data
          borderColor: RiskPalette.low,
        );
        
      case DataSourceType.cached:
        return const _ChipData(
          displayLabel: 'CACHED',
          semanticLabel: 'Cached data from recent request',
          icon: Icons.storage_outlined,
          iconColor: RiskPalette.darkGray,
          textColor: RiskPalette.darkGray,
          backgroundColor: RiskPalette.lightGray,
          borderColor: RiskPalette.midGray,
        );
        
      case DataSourceType.mock:
        return const _ChipData(
          displayLabel: 'MOCK',
          semanticLabel: 'Mock test data for development',
          icon: Icons.science_outlined,
          iconColor: RiskPalette.white,
          textColor: RiskPalette.white,
          backgroundColor: RiskPalette.blueAccent, // Blue for test/demo
          borderColor: RiskPalette.blueAccent,
        );
    }
  }
}

/// Internal data class for chip styling
class _ChipData {
  final String displayLabel;
  final String semanticLabel;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  
  const _ChipData({
    required this.displayLabel,
    required this.semanticLabel,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
