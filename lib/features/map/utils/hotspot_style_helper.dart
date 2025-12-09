import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Helper utility for styling hotspot markers and squares on the map
///
/// Provides consistent styling for hotspot overlays based on FRP intensity.
/// Uses RiskPalette colors with higher opacity than burnt areas (more urgent).
///
/// Part of 021-live-fire-data feature implementation.
///
/// Usage:
/// ```dart
/// final fillColor = HotspotStyleHelper.getFillColor(hotspot);
/// final strokeColor = HotspotStyleHelper.getStrokeColor(hotspot);
/// ```
class HotspotStyleHelper {
  /// Default fill opacity for hotspot overlays (50% - more opaque than burnt areas)
  ///
  /// Higher opacity than burnt areas (35%) to emphasize active fire urgency.
  static const double fillOpacity = 0.5;

  /// Default stroke width in logical pixels
  static const int strokeWidth = 2;

  /// Minimum zoom level to display hotspot squares (too small at lower zooms)
  static const double minZoomForSquares = 8.0;

  /// Size of hotspot square marker in degrees (~370m at mid-latitudes)
  ///
  /// VIIRS nominal pixel size is 375m x 375m at nadir.
  static const double squareSizeDegrees = 0.00333; // ~370m

  /// Get the fill color for a given hotspot based on FRP
  ///
  /// Returns a semi-transparent color (50% opacity) for the hotspot fill.
  /// Uses FRP thresholds: <10 MW (low), 10-50 MW (moderate), >50 MW (high).
  static Color getFillColor(Hotspot hotspot) {
    final baseColor = _getBaseColorFromFrp(hotspot.frp);
    return baseColor.withValues(alpha: fillOpacity);
  }

  /// Get the fill color from intensity string
  ///
  /// Convenience method when only intensity string is available.
  static Color getFillColorFromIntensity(String intensity) {
    final baseColor = _getBaseColorFromIntensity(intensity);
    return baseColor.withValues(alpha: fillOpacity);
  }

  /// Get the stroke color for a given hotspot
  ///
  /// Returns a fully opaque color for the hotspot border.
  static Color getStrokeColor(Hotspot hotspot) {
    return _getBaseColorFromFrp(hotspot.frp);
  }

  /// Get the stroke color from intensity string
  static Color getStrokeColorFromIntensity(String intensity) {
    return _getBaseColorFromIntensity(intensity);
  }

  /// Get the base color from FRP value
  ///
  /// FRP thresholds match Hotspot.intensity getter:
  /// - < 10 MW: Low intensity (yellow/green)
  /// - 10-50 MW: Moderate intensity (orange)
  /// - >= 50 MW: High intensity (red)
  static Color _getBaseColorFromFrp(double frp) {
    if (frp < 10) {
      return RiskPalette.moderate; // Yellow/orange for low
    } else if (frp < 50) {
      return RiskPalette.high; // Orange for moderate
    } else {
      return RiskPalette.veryHigh; // Red for high
    }
  }

  /// Get the base color from intensity string
  static Color _getBaseColorFromIntensity(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'high':
        return RiskPalette.veryHigh; // Red
      case 'moderate':
        return RiskPalette.high; // Orange
      case 'low':
        return RiskPalette.moderate; // Yellow/orange
      default:
        return RiskPalette.midGray; // Gray for unknown
    }
  }

  /// Check if hotspot squares should be visible at the given zoom level
  ///
  /// Squares are hidden at low zoom levels where they would appear
  /// as tiny specks and clutter the map.
  static bool shouldShowSquaresAtZoom(double zoom) {
    return zoom >= minZoomForSquares;
  }

  /// Get cluster marker size category based on hotspot count
  ///
  /// Returns size tier for visual differentiation:
  /// - small: 1-5 hotspots
  /// - medium: 6-20 hotspots
  /// - large: 21+ hotspots
  static String getClusterSizeCategory(int count) {
    if (count <= 5) return 'small';
    if (count <= 20) return 'medium';
    return 'large';
  }

  /// Get cluster marker radius in logical pixels based on count
  static double getClusterRadius(int count) {
    switch (getClusterSizeCategory(count)) {
      case 'small':
        return 20.0;
      case 'medium':
        return 28.0;
      case 'large':
        return 36.0;
      default:
        return 20.0;
    }
  }

  /// Get cluster marker color based on max FRP in cluster
  ///
  /// Uses the hottest (highest FRP) spot to determine cluster severity.
  static Color getClusterColor(double maxFrp) {
    return _getBaseColorFromFrp(maxFrp);
  }
}
