import 'dart:math' show cos;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:wildfire_mvp_v3/features/map/utils/hotspot_style_helper.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Builds square polygon overlays for hotspot markers on Google Maps
///
/// Converts VIIRS hotspot detections into visible square polygons that
/// represent the ~375m x 375m VIIRS pixel footprint.
///
/// Part of 021-live-fire-data feature implementation.
///
/// Usage:
/// ```dart
/// final polygons = HotspotSquareBuilder.buildPolygons(
///   hotspots: hotspotList,
///   onTap: (hotspot) => showDetails(hotspot),
/// );
/// ```
class HotspotSquareBuilder {
  /// Build a set of square polygons for all hotspots
  ///
  /// Returns polygons styled by FRP intensity with tap handlers.
  /// Filters out hotspots outside visible bounds if provided.
  static Set<gmap.Polygon> buildPolygons({
    required List<Hotspot> hotspots,
    required void Function(Hotspot) onTap,
    gmap.LatLngBounds? visibleBounds,
  }) {
    final polygons = <gmap.Polygon>{};

    for (final hotspot in hotspots) {
      // Skip if outside visible bounds (performance optimization)
      if (visibleBounds != null &&
          !_isInBounds(hotspot.location, visibleBounds)) {
        continue;
      }

      polygons.add(_buildSquare(hotspot, onTap));
    }

    return polygons;
  }

  /// Build a single square polygon for a hotspot
  static gmap.Polygon _buildSquare(
    Hotspot hotspot,
    void Function(Hotspot) onTap,
  ) {
    final vertices = _calculateSquareVertices(hotspot.location);

    return gmap.Polygon(
      polygonId: gmap.PolygonId('hotspot_${hotspot.id}'),
      points: vertices,
      fillColor: HotspotStyleHelper.getFillColor(hotspot),
      strokeColor: HotspotStyleHelper.getStrokeColor(hotspot),
      strokeWidth: HotspotStyleHelper.strokeWidth,
      consumeTapEvents: true,
      onTap: () => onTap(hotspot),
    );
  }

  /// Calculate the 4 corner vertices for a square centered on location
  ///
  /// Creates a square approximately matching the VIIRS pixel size (~375m).
  /// Applies latitude correction so squares appear square on the map
  /// (longitude degrees are smaller at higher latitudes).
  static List<gmap.LatLng> _calculateSquareVertices(LatLng center) {
    const halfSizeLat = HotspotStyleHelper.squareSizeDegrees / 2;

    // Apply latitude correction: longitude degrees are smaller at higher latitudes
    // cos(lat) gives the ratio of longitude distance to latitude distance
    // At 57°N (Scotland), cos(57°) ≈ 0.545, so we need ~1.8x more longitude degrees
    final latRadians = center.latitude * 3.14159265359 / 180.0;
    final cosLat = cos(latRadians);
    final lonCorrection = cosLat.abs() > 0.01 ? 1.0 / cosLat : 1.0;
    final halfSizeLon = halfSizeLat * lonCorrection;

    // Calculate corners (clockwise from southwest)
    return [
      gmap.LatLng(
        center.latitude - halfSizeLat,
        center.longitude - halfSizeLon,
      ), // SW
      gmap.LatLng(
        center.latitude + halfSizeLat,
        center.longitude - halfSizeLon,
      ), // NW
      gmap.LatLng(
        center.latitude + halfSizeLat,
        center.longitude + halfSizeLon,
      ), // NE
      gmap.LatLng(
        center.latitude - halfSizeLat,
        center.longitude + halfSizeLon,
      ), // SE
    ];
  }

  /// Check if a location is within the visible bounds
  static bool _isInBounds(LatLng location, gmap.LatLngBounds bounds) {
    return location.latitude >= bounds.southwest.latitude &&
        location.latitude <= bounds.northeast.latitude &&
        location.longitude >= bounds.southwest.longitude &&
        location.longitude <= bounds.northeast.longitude;
  }

  /// Build a single polygon from a hotspot (exposed for testing)
  @visibleForTesting
  static gmap.Polygon buildSinglePolygon({
    required Hotspot hotspot,
    required void Function(Hotspot) onTap,
  }) {
    return _buildSquare(hotspot, onTap);
  }
}
