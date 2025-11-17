import 'package:flutter/material.dart';

/// WildFire Risk Color Palette
/// Source of truth for all wildfire risk levels and brand colors.
/// Do not hardcode hex values elsewhere. Gate C4 checks against these constants.
class RiskPalette {
  // Risk levels (Very Low → Extreme)
  static const veryLow = Color(0xFF4CAF50); // Very Low
  static const low = Color(0xFF8BC34A); // Low
  static const moderate = Color(0xFFFFEB3B); // Moderate
  static const high = Color(0xFFFF9800); // High
  static const veryHigh = Color(0xFFF44336); // Very High
  static const extreme = Color(0xFFB71C1C); // Extreme

  // Brand accent
  static const brandForest = Color(0xFF0B3D2E);

  // Neutrals
  static const black = Color(0xFF000000);
  static const darkGray = Color(0xFF222222);
  static const midGray = Color(0xFF666666);
  static const lightGray = Color(0xFFCCCCCC);
  static const white = Color(0xFFFFFFFF);

  // Accent / Focus (optional)
  static const blueAccent = Color(0xFF1E90FF);
  static const pinkAccent = Color(0xFFFF4081);

  /// Map risk level string → Color
  static Color fromLevel(String level) {
    switch (level.toLowerCase()) {
      case 'verylow':
        return veryLow;
      case 'low':
        return low;
      case 'moderate':
        return moderate;
      case 'high':
        return high;
      case 'veryhigh':
        return veryHigh;
      case 'extreme':
        return extreme;
      default:
        return lightGray; // fallback
    }
  }
}
