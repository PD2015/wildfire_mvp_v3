import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/hotspot_cluster.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

void main() {
  group('HotspotCluster', () {
    const testCenter = LatLng(55.9533, -3.1883);

    group('construction', () {
      test('creates instance with all required fields', () {
        final hotspots = [
          Hotspot.test(location: const LatLng(55.95, -3.18), frp: 30.0),
          Hotspot.test(location: const LatLng(55.96, -3.19), frp: 45.0),
        ];

        final cluster = HotspotCluster.fromHotspots(
          id: 'cluster_001',
          hotspots: hotspots,
        );

        expect(cluster.id, equals('cluster_001'));
        expect(cluster.count, equals(2));
        expect(cluster.maxFrp, equals(45.0));
        expect(cluster.hotspots.length, equals(2));
      });

      test('test factory creates valid instance', () {
        final cluster = HotspotCluster.test(
          center: testCenter,
          count: 5,
          maxFrp: 50.0,
        );

        expect(cluster.center, equals(testCenter));
        expect(cluster.count, equals(5));
        expect(cluster.maxFrp, equals(50.0));
      });
    });

    group('fromHotspots factory', () {
      test('throws for empty hotspot list', () {
        expect(
          () => HotspotCluster.fromHotspots(
            id: 'empty',
            hotspots: const [],
          ),
          throwsArgumentError,
        );
      });

      test('calculates centroid correctly', () {
        final hotspots = [
          Hotspot.test(location: const LatLng(55.0, -3.0)),
          Hotspot.test(location: const LatLng(56.0, -4.0)),
        ];

        final cluster = HotspotCluster.fromHotspots(
          id: 'test',
          hotspots: hotspots,
        );

        expect(cluster.center.latitude, closeTo(55.5, 0.001));
        expect(cluster.center.longitude, closeTo(-3.5, 0.001));
      });

      test('calculates bounds correctly', () {
        final hotspots = [
          Hotspot.test(location: const LatLng(55.0, -3.0)),
          Hotspot.test(location: const LatLng(56.0, -4.0)),
        ];

        final cluster = HotspotCluster.fromHotspots(
          id: 'test',
          hotspots: hotspots,
        );

        // Bounds include 0.005 padding
        // Southwest: min lat, min lon (more negative = more west)
        expect(cluster.bounds.southwest.latitude, closeTo(54.995, 0.001));
        expect(cluster.bounds.southwest.longitude, closeTo(-4.005, 0.001));
        // Northeast: max lat, max lon (less negative = more east)
        expect(cluster.bounds.northeast.latitude, closeTo(56.005, 0.001));
        expect(cluster.bounds.northeast.longitude, closeTo(-2.995, 0.001));
      });

      test('finds maximum FRP', () {
        final hotspots = [
          Hotspot.test(location: const LatLng(55.0, -3.0), frp: 10.0),
          Hotspot.test(location: const LatLng(55.1, -3.1), frp: 75.0),
          Hotspot.test(location: const LatLng(55.2, -3.2), frp: 25.0),
        ];

        final cluster = HotspotCluster.fromHotspots(
          id: 'test',
          hotspots: hotspots,
        );

        expect(cluster.maxFrp, equals(75.0));
      });
    });

    group('intensity from maxFrp', () {
      test('maxFrp < 10 returns low intensity', () {
        final cluster = HotspotCluster.test(
          center: testCenter,
          count: 3,
          maxFrp: 5.0,
        );
        expect(cluster.intensity, equals('low'));
      });

      test('maxFrp 10-49 returns moderate intensity', () {
        final cluster = HotspotCluster.test(
          center: testCenter,
          count: 3,
          maxFrp: 35.0,
        );
        expect(cluster.intensity, equals('moderate'));
      });

      test('maxFrp >= 50 returns high intensity', () {
        final cluster = HotspotCluster.test(
          center: testCenter,
          count: 3,
          maxFrp: 80.0,
        );
        expect(cluster.intensity, equals('high'));
      });
    });

    group('Equatable', () {
      test('two clusters with same props are equal', () {
        final hotspots = [
          Hotspot.test(id: 'h1', location: testCenter),
        ];

        final c1 = HotspotCluster.fromHotspots(id: 'same', hotspots: hotspots);
        final c2 = HotspotCluster.fromHotspots(id: 'same', hotspots: hotspots);

        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
      });
    });
  });

  group('HotspotClusterBuilder', () {
    const builder = HotspotClusterBuilder();

    test('returns empty list for empty input', () {
      final clusters = builder.buildClusters([]);
      expect(clusters, isEmpty);
    });

    test('single hotspot becomes single cluster', () {
      final hotspots = [
        Hotspot.test(location: const LatLng(55.0, -3.0)),
      ];

      final clusters = builder.buildClusters(hotspots);

      expect(clusters.length, equals(1));
      expect(clusters.first.count, equals(1));
    });

    test('hotspots within 750m are clustered together', () {
      // Two hotspots ~500m apart (should cluster)
      final hotspots = [
        Hotspot.test(id: 'a', location: const LatLng(55.9533, -3.1883)),
        Hotspot.test(
            id: 'b', location: const LatLng(55.9573, -3.1883)), // ~440m north
      ];

      final clusters = builder.buildClusters(hotspots);

      expect(clusters.length, equals(1));
      expect(clusters.first.count, equals(2));
    });

    test('hotspots beyond 750m are separate clusters', () {
      // Two hotspots ~10km apart (should not cluster)
      final hotspots = [
        Hotspot.test(
            id: 'a', location: const LatLng(55.9533, -3.1883)), // Edinburgh
        Hotspot.test(
            id: 'b', location: const LatLng(55.8642, -4.2518)), // Glasgow
      ];

      final clusters = builder.buildClusters(hotspots);

      expect(clusters.length, equals(2));
    });

    test('custom distance threshold is applied', () {
      const customBuilder =
          HotspotClusterBuilder(distanceThresholdKm: 0.1); // 100m

      // Two hotspots ~440m apart (should NOT cluster with 100m threshold)
      final hotspots = [
        Hotspot.test(id: 'a', location: const LatLng(55.9533, -3.1883)),
        Hotspot.test(
            id: 'b', location: const LatLng(55.9573, -3.1883)), // ~440m north
      ];

      final clusters = customBuilder.buildClusters(hotspots);

      expect(clusters.length, equals(2));
    });

    test('assigns unique cluster IDs', () {
      final hotspots = [
        Hotspot.test(id: 'a', location: const LatLng(55.0, -3.0)),
        Hotspot.test(id: 'b', location: const LatLng(56.0, -4.0)), // Far away
        Hotspot.test(id: 'c', location: const LatLng(57.0, -5.0)), // Far away
      ];

      final clusters = builder.buildClusters(hotspots);

      final ids = clusters.map((c) => c.id).toSet();
      expect(ids.length, equals(3)); // All unique
    });

    group('performance', () {
      test('clusters 100 hotspots within 50ms', () {
        final hotspots = List.generate(
          100,
          (i) => Hotspot.test(
            id: 'hotspot_$i',
            location: LatLng(55.0 + (i * 0.01), -3.0 + (i * 0.01)),
          ),
        );

        final stopwatch = Stopwatch()..start();
        builder.buildClusters(hotspots);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
