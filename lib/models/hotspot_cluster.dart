import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Clustered group of hotspots for map visualization at low zoom levels
///
/// View model for displaying aggregated hotspot markers.
/// Part of 021-live-fire-data feature implementation.
///
/// Clusters are created when zoom < 10 and hotspots within 750m.
/// On tap, map zooms to fit all cluster points.
class HotspotCluster extends Equatable {
  /// Unique identifier for this cluster
  final String id;

  /// Geographic center of the cluster (centroid of all hotspots)
  final LatLng center;

  /// Number of hotspots in this cluster
  final int count;

  /// Bounding box containing all cluster hotspots
  ///
  /// Used for zoom-to-fit on cluster tap.
  final LatLngBounds bounds;

  /// Maximum FRP value among clustered hotspots
  ///
  /// Used to determine cluster marker intensity color.
  final double maxFrp;

  /// All hotspots in this cluster
  ///
  /// Available for drill-down when cluster is expanded.
  final List<Hotspot> hotspots;

  /// Intensity level based on max FRP in cluster
  ///
  /// Returns "low" | "moderate" | "high"
  String get intensity {
    if (maxFrp < 10) return 'low';
    if (maxFrp < 50) return 'moderate';
    return 'high';
  }

  const HotspotCluster({
    required this.id,
    required this.center,
    required this.count,
    required this.bounds,
    required this.maxFrp,
    required this.hotspots,
  });

  /// Create a cluster from a list of hotspots
  ///
  /// Calculates centroid, bounds, and max FRP automatically.
  factory HotspotCluster.fromHotspots({
    required String id,
    required List<Hotspot> hotspots,
  }) {
    if (hotspots.isEmpty) {
      throw ArgumentError('Cannot create cluster from empty hotspot list');
    }

    // Calculate centroid
    double sumLat = 0;
    double sumLon = 0;
    double maxFrp = 0;
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;

    for (final hotspot in hotspots) {
      sumLat += hotspot.location.latitude;
      sumLon += hotspot.location.longitude;

      if (hotspot.frp > maxFrp) maxFrp = hotspot.frp;

      if (hotspot.location.latitude < minLat) {
        minLat = hotspot.location.latitude;
      }
      if (hotspot.location.latitude > maxLat) {
        maxLat = hotspot.location.latitude;
      }
      if (hotspot.location.longitude < minLon) {
        minLon = hotspot.location.longitude;
      }
      if (hotspot.location.longitude > maxLon) {
        maxLon = hotspot.location.longitude;
      }
    }

    final center = LatLng(sumLat / hotspots.length, sumLon / hotspots.length);

    // Add small padding to bounds for better zoom-to-fit
    const padding = 0.005; // ~500m at mid-latitudes
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLon - padding),
      northeast: LatLng(maxLat + padding, maxLon + padding),
    );

    return HotspotCluster(
      id: id,
      center: center,
      count: hotspots.length,
      bounds: bounds,
      maxFrp: maxFrp,
      hotspots: hotspots,
    );
  }

  /// Factory for test data
  factory HotspotCluster.test({
    String? id,
    required LatLng center,
    required int count,
    LatLngBounds? bounds,
    double maxFrp = 25.0,
    List<Hotspot>? hotspots,
  }) {
    // Generate synthetic bounds if not provided
    final testBounds =
        bounds ??
        LatLngBounds(
          southwest: LatLng(center.latitude - 0.01, center.longitude - 0.01),
          northeast: LatLng(center.latitude + 0.01, center.longitude + 0.01),
        );

    // Generate synthetic hotspots if not provided
    final testHotspots =
        hotspots ??
        List.generate(
          count,
          (i) => Hotspot.test(
            id: 'test_hotspot_$i',
            location: LatLng(
              center.latitude + (i * 0.001),
              center.longitude + (i * 0.001),
            ),
            frp: maxFrp * (1 - i * 0.1).clamp(0.1, 1.0),
          ),
        );

    return HotspotCluster(
      id: id ?? 'test_cluster_${center.latitude}_${center.longitude}',
      center: center,
      count: count,
      bounds: testBounds,
      maxFrp: maxFrp,
      hotspots: testHotspots,
    );
  }

  @override
  List<Object?> get props => [id, center, count, bounds, maxFrp, hotspots];
}

/// Utility for clustering hotspots based on distance threshold
///
/// Uses simple distance-based clustering algorithm.
/// At zoom < 10, hotspots within 750m are grouped together.
class HotspotClusterBuilder {
  /// Distance threshold in kilometers for clustering
  ///
  /// Default 0.75km (750m) per action plan specification.
  final double distanceThresholdKm;

  const HotspotClusterBuilder({this.distanceThresholdKm = 0.75});

  /// Build clusters from a list of hotspots
  ///
  /// Uses simple greedy clustering algorithm:
  /// 1. Pick first unassigned hotspot as cluster seed
  /// 2. Find all hotspots within distance threshold
  /// 3. Repeat until all hotspots assigned
  List<HotspotCluster> buildClusters(List<Hotspot> hotspots) {
    if (hotspots.isEmpty) return [];
    if (hotspots.length == 1) {
      return [HotspotCluster.fromHotspots(id: 'cluster_0', hotspots: hotspots)];
    }

    final clusters = <HotspotCluster>[];
    final assigned = <String>{};

    for (int i = 0; i < hotspots.length; i++) {
      final seed = hotspots[i];
      if (assigned.contains(seed.id)) continue;

      // Find all hotspots within distance threshold
      final clusterHotspots = <Hotspot>[seed];
      assigned.add(seed.id);

      for (int j = i + 1; j < hotspots.length; j++) {
        final candidate = hotspots[j];
        if (assigned.contains(candidate.id)) continue;

        final distance = _calculateDistanceKm(
          seed.location,
          candidate.location,
        );

        if (distance <= distanceThresholdKm) {
          clusterHotspots.add(candidate);
          assigned.add(candidate.id);
        }
      }

      clusters.add(
        HotspotCluster.fromHotspots(
          id: 'cluster_${clusters.length}',
          hotspots: clusterHotspots,
        ),
      );
    }

    return clusters;
  }

  /// Calculate distance between two points using Haversine formula
  ///
  /// Returns distance in kilometers.
  double _calculateDistanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);

    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final sinDLat = _sin(dLat / 2);
    final sinDLon = _sin(dLon / 2);

    final h = sinDLat * sinDLat + _cos(lat1) * _cos(lat2) * sinDLon * sinDLon;
    final c = 2 * _atan2(_sqrt(h), _sqrt(1 - h));

    return earthRadiusKm * c;
  }

  // Math helpers to avoid importing dart:math in production code
  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) {
    // Taylor series approximation for sin
    x = x % (2 * 3.141592653589793);
    if (x > 3.141592653589793) x -= 2 * 3.141592653589793;
    if (x < -3.141592653589793) x += 2 * 3.141592653589793;

    double result = x;
    double term = x;
    for (int n = 1; n < 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  double _cos(double x) => _sin(x + 3.141592653589793 / 2);
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  double _atan(double x) {
    // Taylor series for atan, works best for |x| <= 1
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * (3.141592653589793 / 2 - _atan(1 / x));
    }
    double result = x;
    double term = x;
    for (int n = 1; n < 20; n++) {
      term *= -x * x;
      result += term / (2 * n + 1);
    }
    return result;
  }
}
