import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/hotspot_cluster.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Widget tests for HotspotClusterMarker
///
/// Tests for the cluster badge that shows count of hotspots.
/// Part of 021-live-fire-data feature (T026)
void main() {
  group('HotspotClusterMarker', () {
    // Create test hotspots for clustering
    List<Hotspot> createTestHotspots(int count, {double baseFrp = 25.0}) {
      return List.generate(
          count,
          (i) => Hotspot(
                id: 'hotspot_$i',
                location: LatLng(55.0 + i * 0.01, -3.0 + i * 0.01),
                detectedAt: DateTime.now(),
                frp: baseFrp + i,
                confidence: 75.0,
              ));
    }

    group('cluster model tests', () {
      test('HotspotCluster.fromHotspots calculates centroid correctly', () {
        final hotspots = [
          Hotspot(
            id: 'h1',
            location: const LatLng(55.0, -3.0),
            detectedAt: DateTime.now(),
            frp: 10.0,
            confidence: 80.0,
          ),
          Hotspot(
            id: 'h2',
            location: const LatLng(56.0, -4.0),
            detectedAt: DateTime.now(),
            frp: 20.0,
            confidence: 70.0,
          ),
        ];

        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_1',
          hotspots: hotspots,
        );

        // Centroid should be average of coordinates
        expect(cluster.center.latitude, closeTo(55.5, 0.01));
        expect(cluster.center.longitude, closeTo(-3.5, 0.01));
      });

      test('HotspotCluster count returns number of hotspots', () {
        final hotspots = createTestHotspots(5);
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_1',
          hotspots: hotspots,
        );

        expect(cluster.count, equals(5));
      });

      test('HotspotCluster calculates bounds for zoom-to-fit', () {
        final hotspots = [
          Hotspot(
            id: 'h1',
            location: const LatLng(55.0, -4.0),
            detectedAt: DateTime.now(),
            frp: 10.0,
            confidence: 80.0,
          ),
          Hotspot(
            id: 'h2',
            location: const LatLng(56.0, -3.0),
            detectedAt: DateTime.now(),
            frp: 20.0,
            confidence: 70.0,
          ),
        ];

        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_1',
          hotspots: hotspots,
        );
        final bounds = cluster.bounds;

        // Bounds should encompass all hotspots with ~500m padding (0.005 degrees)
        const padding = 0.005;
        expect(bounds.southwest.latitude, closeTo(55.0 - padding, 0.0001));
        expect(bounds.southwest.longitude, closeTo(-4.0 - padding, 0.0001));
        expect(bounds.northeast.latitude, closeTo(56.0 + padding, 0.0001));
        expect(bounds.northeast.longitude, closeTo(-3.0 + padding, 0.0001));
      });

      test('HotspotCluster calculates maxFrp from hotspots', () {
        final hotspots = [
          Hotspot(
            id: 'h1',
            location: const LatLng(55.0, -3.0),
            detectedAt: DateTime.now(),
            frp: 10.0,
            confidence: 80.0,
          ),
          Hotspot(
            id: 'h2',
            location: const LatLng(56.0, -4.0),
            detectedAt: DateTime.now(),
            frp: 75.0, // High FRP
            confidence: 70.0,
          ),
        ];

        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_1',
          hotspots: hotspots,
        );

        expect(cluster.maxFrp, equals(75.0));
      });
    });

    group('cluster intensity from maxFrp', () {
      test('low intensity when maxFrp < 10', () {
        final hotspots = createTestHotspots(3, baseFrp: 5.0);
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_1',
          hotspots: hotspots,
        );
        expect(cluster.intensity, equals('low'));
      });

      test('moderate intensity when maxFrp 10-50', () {
        final hotspots = createTestHotspots(3, baseFrp: 30.0);
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_1',
          hotspots: hotspots,
        );
        expect(cluster.intensity, equals('moderate'));
      });

      test('high intensity when maxFrp >= 50', () {
        final hotspots = createTestHotspots(3, baseFrp: 60.0);
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_1',
          hotspots: hotspots,
        );
        expect(cluster.intensity, equals('high'));
      });
    });

    group('cluster validation', () {
      test('throws ArgumentError for empty hotspot list', () {
        expect(
          () => HotspotCluster.fromHotspots(id: 'cluster_1', hotspots: []),
          throwsArgumentError,
        );
      });

      test('single hotspot creates valid cluster', () {
        final hotspots = createTestHotspots(1);
        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_1',
          hotspots: hotspots,
        );

        expect(cluster.count, equals(1));
        expect(cluster.center, equals(hotspots.first.location));
      });
    });

    group('cluster equatable', () {
      test('clusters with same id are equal', () {
        final hotspots = createTestHotspots(3);
        final cluster1 = HotspotCluster.fromHotspots(
          id: 'same_id',
          hotspots: hotspots,
        );
        final cluster2 = HotspotCluster.fromHotspots(
          id: 'same_id',
          hotspots: hotspots,
        );

        expect(cluster1, equals(cluster2));
      });

      test('clusters with different ids are not equal', () {
        final hotspots = createTestHotspots(3);
        final cluster1 = HotspotCluster.fromHotspots(
          id: 'cluster_a',
          hotspots: hotspots,
        );
        final cluster2 = HotspotCluster.fromHotspots(
          id: 'cluster_b',
          hotspots: hotspots,
        );

        expect(cluster1, isNot(equals(cluster2)));
      });
    });
  });
}
