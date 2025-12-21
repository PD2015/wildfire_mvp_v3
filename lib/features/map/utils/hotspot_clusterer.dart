import 'dart:math' as math;
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/hotspot_cluster.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Utility class for clustering hotspots based on geographic proximity
///
/// Uses a zoom-aware clustering algorithm similar to Mapbox Supercluster.
/// The clustering radius is specified in screen pixels and automatically
/// converts to meters based on the current zoom level.
///
/// Part of 021-live-fire-data feature implementation.
class HotspotClusterer {
  /// Default clustering radius in screen pixels (similar to Supercluster default of 40-50px)
  static const double defaultRadiusPixels = 60.0;

  /// Maximum zoom level at which clustering occurs (above this, show all individual points)
  static const double maxClusterZoom = 12.0;

  /// Minimum zoom level for clustering calculations
  static const double minZoom = 0.0;

  /// Approximate meters per pixel at zoom 0 at the equator
  /// At zoom 0, the world is 256 pixels wide = 40,075 km circumference
  /// So 1 pixel ≈ 156,543 meters at equator at zoom 0
  static const double _metersPerPixelAtZoom0 = 156543.03392;

  /// Convert pixel radius to meters based on zoom level and latitude
  ///
  /// The formula accounts for:
  /// - Zoom level: each zoom level halves the meters per pixel
  /// - Latitude: meters per pixel decreases towards the poles
  static double pixelsToMeters(
    double pixels,
    double zoom, {
    double latitude = 56.0,
  }) {
    // At higher zoom levels, each pixel represents fewer meters
    // Formula: metersPerPixel = baseMetersPerPixel / 2^zoom * cos(latitude)
    final double metersPerPixel =
        _metersPerPixelAtZoom0 *
        math.cos(latitude * math.pi / 180.0) /
        math.pow(2, zoom);
    return pixels * metersPerPixel;
  }

  /// Get the clustering radius in meters for a given zoom level
  ///
  /// Example values at latitude 56° (Scotland):
  /// - Zoom 3: ~60px ≈ 6.5 km radius
  /// - Zoom 5: ~60px ≈ 1.6 km radius
  /// - Zoom 7: ~60px ≈ 400m radius
  /// - Zoom 9: ~60px ≈ 100m radius
  static double getClusterRadiusMeters(
    double zoom, {
    double radiusPixels = defaultRadiusPixels,
  }) {
    return pixelsToMeters(radiusPixels, zoom);
  }

  /// Clusters hotspots using zoom-aware radius
  ///
  /// Returns a list of [HotspotCluster] objects. Single isolated hotspots
  /// are also returned as single-item clusters for consistent handling.
  ///
  /// [zoom] - Current map zoom level (affects clustering radius)
  /// [radiusPixels] - Clustering radius in screen pixels (default: 60)
  ///
  /// Algorithm:
  /// 1. Convert pixel radius to meters based on zoom
  /// 2. Start with unclustered hotspots
  /// 3. Pick first unclustered hotspot as cluster seed
  /// 4. Find all hotspots within radius and add to cluster
  /// 5. Repeat until all hotspots are clustered
  static List<HotspotCluster> cluster(
    List<Hotspot> hotspots, {
    double zoom = 6.0,
    double radiusPixels = defaultRadiusPixels,
  }) {
    if (hotspots.isEmpty) {
      return [];
    }

    // If above max cluster zoom, return each hotspot as its own "cluster"
    if (zoom >= maxClusterZoom) {
      return hotspots.asMap().entries.map((entry) {
        return HotspotCluster.fromHotspots(
          id: 'cluster_${entry.key}',
          hotspots: [entry.value],
        );
      }).toList();
    }

    // Calculate average latitude for more accurate radius conversion
    final avgLat =
        hotspots.fold<double>(0.0, (sum, h) => sum + h.location.latitude) /
        hotspots.length;

    // Convert pixel radius to meters based on current zoom
    final radiusMeters = pixelsToMeters(radiusPixels, zoom, latitude: avgLat);

    final List<HotspotCluster> clusters = [];
    final Set<int> clustered = {};

    for (int i = 0; i < hotspots.length; i++) {
      if (clustered.contains(i)) continue;

      // Start new cluster with this hotspot
      final clusterMembers = <Hotspot>[hotspots[i]];
      clustered.add(i);

      // Find all nearby hotspots
      for (int j = i + 1; j < hotspots.length; j++) {
        if (clustered.contains(j)) continue;

        final distance = _calculateDistanceMeters(
          hotspots[i].location,
          hotspots[j].location,
        );

        if (distance <= radiusMeters) {
          clusterMembers.add(hotspots[j]);
          clustered.add(j);
        }
      }

      clusters.add(
        HotspotCluster.fromHotspots(id: 'cluster_$i', hotspots: clusterMembers),
      );
    }

    return clusters;
  }

  /// Calculate the distance between two coordinates in meters using Haversine formula
  static double _calculateDistanceMeters(LatLng point1, LatLng point2) {
    const double earthRadiusMeters = 6371000.0;

    final double lat1Rad = point1.latitude * math.pi / 180.0;
    final double lat2Rad = point2.latitude * math.pi / 180.0;
    final double deltaLat =
        (point2.latitude - point1.latitude) * math.pi / 180.0;
    final double deltaLon =
        (point2.longitude - point1.longitude) * math.pi / 180.0;

    final double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }
}
