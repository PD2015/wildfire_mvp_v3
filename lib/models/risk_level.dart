import 'package:flutter/material.dart';
import '../theme/risk_palette.dart';

/// Risk level classification based on Fire Weather Index (FWI) values
///
/// Maps FWI numerical values to categorical risk levels per docs/DATA-SOURCES.md:
/// - < 5 → Very Low
/// - 5–11 → Low
/// - 12–20 → Moderate
/// - 21–37 → High
/// - 38–49 → Very High
/// - ≥ 50 → Extreme
enum RiskLevel {
  veryLow,
  low,
  moderate,
  high,
  veryHigh,
  extreme;

  /// Creates a RiskLevel from a Fire Weather Index (FWI) value
  ///
  /// [fwiValue] must be non-negative. Throws [ArgumentError] if negative.
  ///
  /// FWI boundary mapping per docs/DATA-SOURCES.md:
  /// - FWI < 5.0 → veryLow
  /// - FWI 5.0-11.99 → low
  /// - FWI 12.0-20.99 → moderate
  /// - FWI 21.0-37.99 → high
  /// - FWI 38.0-49.99 → veryHigh
  /// - FWI ≥ 50.0 → extreme
  static RiskLevel fromFwi(double fwiValue) {
    if (fwiValue < 0.0) {
      throw ArgumentError('FWI value cannot be negative: $fwiValue');
    }

    if (fwiValue < 5.0) {
      return RiskLevel.veryLow;
    } else if (fwiValue < 12.0) {
      return RiskLevel.low;
    } else if (fwiValue < 21.0) {
      return RiskLevel.moderate;
    } else if (fwiValue < 38.0) {
      return RiskLevel.high;
    } else if (fwiValue < 50.0) {
      return RiskLevel.veryHigh;
    } else {
      return RiskLevel.extreme;
    }
  }
}

/// Extension providing RiskPalette color mapping for RiskLevel enum
///
/// Eliminates duplicate color mapping code across widgets by providing
/// a single source of truth for RiskLevel → Color conversion.
///
/// Usage: `riskLevel.color` instead of switch statements or helper methods.
///
/// Constitutional compliance:
/// - C4: Single source of truth for risk level colors
extension RiskLevelColor on RiskLevel {
  /// Gets the corresponding RiskPalette color for this risk level
  Color get color {
    switch (this) {
      case RiskLevel.veryLow:
        return RiskPalette.veryLow;
      case RiskLevel.low:
        return RiskPalette.low;
      case RiskLevel.moderate:
        return RiskPalette.moderate;
      case RiskLevel.high:
        return RiskPalette.high;
      case RiskLevel.veryHigh:
        return RiskPalette.veryHigh;
      case RiskLevel.extreme:
        return RiskPalette.extreme;
    }
  }
}
