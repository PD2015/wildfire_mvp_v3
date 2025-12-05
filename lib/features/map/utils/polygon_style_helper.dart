import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Helper utility for styling burnt area polygons on the map
///
/// Provides consistent styling for polygon overlays based on fire intensity.
/// Uses RiskPalette colors with opacity adjustments for fill vs stroke.
///
/// Usage:
/// ```dart
/// final fillColor = PolygonStyleHelper.getFillColor('high');
/// final strokeColor = PolygonStyleHelper.getStrokeColor('high');
/// ```
class PolygonStyleHelper {
  /// Default fill opacity for polygon overlays (35% for map visibility)
  static const double fillOpacity = 0.35;

  /// Default stroke width in logical pixels
  static const int strokeWidth = 2;

  /// Minimum zoom level to display polygons (too small at lower zooms)
  static const double minZoomForPolygons = 8.0;

  /// Get the fill color for a given intensity level
  ///
  /// Returns a semi-transparent color (35% opacity) for the polygon fill.
  /// Falls back to gray for unknown intensities.
  static Color getFillColor(String intensity) {
    final baseColor = _getBaseColor(intensity);
    return baseColor.withValues(alpha: fillOpacity);
  }

  /// Get the stroke color for a given intensity level
  ///
  /// Returns a fully opaque color for the polygon border.
  /// Falls back to gray for unknown intensities.
  static Color getStrokeColor(String intensity) {
    return _getBaseColor(intensity);
  }

  /// Get the base color for intensity level using RiskPalette
  static Color _getBaseColor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'high':
        return RiskPalette.veryHigh; // Red
      case 'moderate':
        return RiskPalette.high; // Orange
      case 'low':
        return RiskPalette.low; // Green
      default:
        return RiskPalette.midGray; // Gray for unknown
    }
  }

  /// Check if polygons should be visible at the given zoom level
  ///
  /// Polygons are hidden at low zoom levels where they would appear
  /// as tiny specks and clutter the map.
  static bool shouldShowPolygonsAtZoom(double zoom) {
    return zoom >= minZoomForPolygons;
  }
}
