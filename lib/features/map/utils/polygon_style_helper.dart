import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Helper utility for styling burnt area polygons on the map
///
/// Provides consistent styling for polygon overlays.
/// All burnt areas are displayed in a single red color for clarity.
///
/// Usage:
/// ```dart
/// final fillColor = PolygonStyleHelper.burntAreaFillColor;
/// final strokeColor = PolygonStyleHelper.burntAreaStrokeColor;
/// ```
class PolygonStyleHelper {
  /// Default fill opacity for polygon overlays (35% for map visibility)
  static const double fillOpacity = 0.35;

  /// Default stroke width in logical pixels
  static const int strokeWidth = 2;

  /// Minimum zoom level to display polygons (too small at lower zooms)
  static const double minZoomForPolygons = 8.0;

  /// Single red color for all burnt area fills (semi-transparent)
  static Color get burntAreaFillColor =>
      RiskPalette.veryHigh.withValues(alpha: fillOpacity);

  /// Single red color for all burnt area strokes (opaque)
  static Color get burntAreaStrokeColor => RiskPalette.veryHigh;

  /// Get the fill color for a given intensity level
  ///
  /// @deprecated Use [burntAreaFillColor] instead - all burnt areas now use single red color
  /// Kept for backward compatibility during refactor.
  static Color getFillColor(String intensity) {
    // All burnt areas now use single red color (no intensity grading)
    return burntAreaFillColor;
  }

  /// Get the stroke color for a given intensity level
  ///
  /// @deprecated Use [burntAreaStrokeColor] instead - all burnt areas now use single red color
  /// Kept for backward compatibility during refactor.
  static Color getStrokeColor(String intensity) {
    // All burnt areas now use single red color (no intensity grading)
    return burntAreaStrokeColor;
  }

  /// Check if polygons should be visible at the given zoom level
  ///
  /// Polygons are hidden at low zoom levels where they would appear
  /// as tiny specks and clutter the map.
  static bool shouldShowPolygonsAtZoom(double zoom) {
    return zoom >= minZoomForPolygons;
  }
}
