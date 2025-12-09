import 'dart:math' as math;
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/hotspot_cluster.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Utility class for clustering hotspots based on geographic proximity
///
/// Uses a simple distance-based clustering algorithm where hotspots within
/// a specified radius are grouped together.
///
/// Part of 021-live-fire-data feature implementation.
class HotspotClusterer {
  /// Default clustering radius in meters
  static const double defaultRadiusMeters = 750.0;

  /// Clusters hotspots that are within [radiusMeters] of each other
  ///
  /// Returns a list of [HotspotCluster] objects. Single isolated hotspots
  /// are also returned as single-item clusters for consistent handling.
  ///
  /// Algorithm:
  /// 1. Start with unclustered hotspots
  /// 2. Pick first unclustered hotspot as cluster seed
  /// 3. Find all hotspots within radius and add to cluster
  /// 4. Repeat until all hotspots are clustered
  static List<HotspotCluster> cluster(
    List<Hotspot> hotspots, {
    double radiusMeters = defaultRadiusMeters,
  }) {
    if (hotspots.isEmpty) {
      return [];
    }

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

      clusters.add(HotspotCluster.fromHotspots(
        id: 'cluster_$i',
        hotspots: clusterMembers,
      ));
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

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }
}
