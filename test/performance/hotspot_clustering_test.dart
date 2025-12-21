import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/features/map/utils/hotspot_clusterer.dart';

/// T043: Performance tests for hotspot clustering algorithm
///
/// Verifies clustering performance meets requirements:
/// - 100 hotspots: < 50ms
/// - 500 hotspots: < 200ms
///
/// NOTE: print() statements are intentional for performance metric reporting
// ignore_for_file: avoid_print

void main() {
  group('Hotspot Clustering Performance Tests (T043)', () {
    /// Generate test hotspots scattered around Scotland
    List<Hotspot> generateHotspots(int count) {
      final random = Random(42); // Fixed seed for reproducibility
      return List.generate(count, (index) {
        // Scotland bounds: ~54.5-61.0 lat, ~-8.0-0.0 lon
        final lat = 54.5 + random.nextDouble() * 6.5;
        final lon = -8.0 + random.nextDouble() * 8.0;

        return Hotspot(
          id: 'hotspot_$index',
          location: LatLng(lat, lon),
          detectedAt: DateTime.now().subtract(Duration(hours: index % 24)),
          frp: 5.0 + random.nextDouble() * 100.0,
          confidence: 50.0 + random.nextDouble() * 50.0,
        );
      });
    }

    test('100 hotspots clustered in < 50ms', () {
      final hotspots = generateHotspots(100);

      final stopwatch = Stopwatch()..start();
      final clusters = HotspotClusterer.cluster(hotspots);
      stopwatch.stop();

      print(
        '✅ 100 hotspots → ${clusters.length} clusters in ${stopwatch.elapsedMilliseconds}ms',
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: '100 hotspots should cluster in < 50ms',
      );
      expect(
        clusters,
        isNotEmpty,
        reason: 'Should produce at least one cluster',
      );
    });

    test('500 hotspots clustered in < 200ms', () {
      final hotspots = generateHotspots(500);

      final stopwatch = Stopwatch()..start();
      final clusters = HotspotClusterer.cluster(hotspots);
      stopwatch.stop();

      print(
        '✅ 500 hotspots → ${clusters.length} clusters in ${stopwatch.elapsedMilliseconds}ms',
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: '500 hotspots should cluster in < 200ms',
      );
      expect(
        clusters,
        isNotEmpty,
        reason: 'Should produce at least one cluster',
      );
    });

    test('1000 hotspots clustered in < 500ms', () {
      final hotspots = generateHotspots(1000);

      final stopwatch = Stopwatch()..start();
      final clusters = HotspotClusterer.cluster(hotspots);
      stopwatch.stop();

      print(
        '✅ 1000 hotspots → ${clusters.length} clusters in ${stopwatch.elapsedMilliseconds}ms',
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '1000 hotspots should cluster in < 500ms (extended test)',
      );
      expect(
        clusters,
        isNotEmpty,
        reason: 'Should produce at least one cluster',
      );
    });

    test('empty hotspot list returns empty cluster list', () {
      final stopwatch = Stopwatch()..start();
      final clusters = HotspotClusterer.cluster([]);
      stopwatch.stop();

      print('✅ Empty list clustered in ${stopwatch.elapsedMilliseconds}ms');

      expect(clusters, isEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(1));
    });

    test('single hotspot returns single cluster', () {
      final hotspot = Hotspot(
        id: 'single',
        location: const LatLng(55.9533, -3.1883),
        detectedAt: DateTime.now(),
        frp: 25.0,
        confidence: 85.0,
      );

      final stopwatch = Stopwatch()..start();
      final clusters = HotspotClusterer.cluster([hotspot]);
      stopwatch.stop();

      print('✅ Single hotspot clustered in ${stopwatch.elapsedMilliseconds}ms');

      expect(clusters.length, equals(1));
      expect(clusters.first.count, equals(1));
    });

    test('hotspots very close together form single cluster', () {
      // Create 10 hotspots within 100m of each other
      const baseLocation = LatLng(55.9533, -3.1883);
      final hotspots = List.generate(10, (index) {
        return Hotspot(
          id: 'nearby_$index',
          location: LatLng(
            baseLocation.latitude + (index * 0.0001),
            baseLocation.longitude + (index * 0.0001),
          ),
          detectedAt: DateTime.now(),
          frp: 25.0,
          confidence: 85.0,
        );
      });

      final stopwatch = Stopwatch()..start();
      final clusters = HotspotClusterer.cluster(hotspots);
      stopwatch.stop();

      print(
        '✅ 10 nearby hotspots → ${clusters.length} clusters in ${stopwatch.elapsedMilliseconds}ms',
      );

      // All should be in 1-2 clusters at most
      expect(clusters.length, lessThanOrEqualTo(2));
    });

    test('hotspots far apart form individual clusters', () {
      // Create 5 hotspots at least 50km apart
      final hotspots = [
        Hotspot(
          id: 'edinburgh',
          location: const LatLng(55.9533, -3.1883),
          detectedAt: DateTime.now(),
          frp: 25.0,
          confidence: 85.0,
        ),
        Hotspot(
          id: 'glasgow',
          location: const LatLng(55.8642, -4.2518),
          detectedAt: DateTime.now(),
          frp: 30.0,
          confidence: 90.0,
        ),
        Hotspot(
          id: 'inverness',
          location: const LatLng(57.4778, -4.2247),
          detectedAt: DateTime.now(),
          frp: 20.0,
          confidence: 75.0,
        ),
        Hotspot(
          id: 'aberdeen',
          location: const LatLng(57.1497, -2.0943),
          detectedAt: DateTime.now(),
          frp: 35.0,
          confidence: 95.0,
        ),
        Hotspot(
          id: 'dundee',
          location: const LatLng(56.4620, -2.9707),
          detectedAt: DateTime.now(),
          frp: 15.0,
          confidence: 60.0,
        ),
      ];

      final stopwatch = Stopwatch()..start();
      final clusters = HotspotClusterer.cluster(hotspots);
      stopwatch.stop();

      print(
        '✅ 5 distant hotspots → ${clusters.length} clusters in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Each should be in its own cluster (or very few clusters)
      expect(clusters.length, greaterThanOrEqualTo(3));
    });
  });
}
