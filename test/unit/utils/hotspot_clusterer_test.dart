import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/utils/hotspot_clusterer.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

void main() {
  group('HotspotClusterer', () {
    group('cluster', () {
      test('returns empty list for empty input', () {
        final result = HotspotClusterer.cluster([]);
        expect(result, isEmpty);
      });

      test('returns single cluster for single hotspot', () {
        final hotspots = [
          Hotspot(
            id: 'hs1',
            location: const LatLng(55.9533, -3.1883),
            frp: 15.0,
            confidence: 85.0,
            detectedAt: DateTime.now(),
          ),
        ];

        final result = HotspotClusterer.cluster(hotspots);

        expect(result.length, 1);
        expect(result.first.count, 1);
        expect(result.first.hotspots.first.id, 'hs1');
      });

      test('clusters nearby hotspots within default radius', () {
        // Two hotspots ~100m apart (should cluster)
        final hotspots = [
          Hotspot(
            id: 'hs1',
            location: const LatLng(55.9533, -3.1883),
            frp: 15.0,
            confidence: 85.0,
            detectedAt: DateTime.now(),
          ),
          Hotspot(
            id: 'hs2',
            location: const LatLng(55.9535, -3.1885), // ~200m away
            frp: 25.0,
            confidence: 60.0,

            detectedAt: DateTime.now(),
          ),
        ];

        final result = HotspotClusterer.cluster(hotspots);

        expect(result.length, 1);
        expect(result.first.count, 2);
      });

      test('keeps distant hotspots in separate clusters', () {
        // Two hotspots ~10km apart (should not cluster)
        final hotspots = [
          Hotspot(
            id: 'hs1',
            location: const LatLng(55.9533, -3.1883),
            frp: 15.0,
            confidence: 85.0,
            detectedAt: DateTime.now(),
          ),
          Hotspot(
            id: 'hs2',
            location: const LatLng(56.0533, -3.1883), // ~10km away
            frp: 25.0,
            confidence: 60.0,

            detectedAt: DateTime.now(),
          ),
        ];

        final result = HotspotClusterer.cluster(hotspots);

        expect(result.length, 2);
        expect(result[0].count, 1);
        expect(result[1].count, 1);
      });

      test('respects custom radius parameter', () {
        // Two hotspots ~500m apart
        final hotspots = [
          Hotspot(
            id: 'hs1',
            location: const LatLng(55.9533, -3.1883),
            frp: 15.0,
            confidence: 85.0,
            detectedAt: DateTime.now(),
          ),
          Hotspot(
            id: 'hs2',
            location: const LatLng(55.9573, -3.1883), // ~450m away
            frp: 25.0,
            confidence: 60.0,

            detectedAt: DateTime.now(),
          ),
        ];

        // With small radius - should be separate clusters
        final smallRadiusResult =
            HotspotClusterer.cluster(hotspots, radiusMeters: 100);
        expect(smallRadiusResult.length, 2);

        // With large radius - should be one cluster
        final largeRadiusResult =
            HotspotClusterer.cluster(hotspots, radiusMeters: 1000);
        expect(largeRadiusResult.length, 1);
      });

      test('cluster has correct metadata', () {
        final detectedAt = DateTime.now();
        final hotspots = [
          Hotspot(
            id: 'hs1',
            location: const LatLng(55.9533, -3.1883),
            frp: 15.0,
            confidence: 85.0,
            detectedAt: detectedAt,
          ),
          Hotspot(
            id: 'hs2',
            location: const LatLng(55.9535, -3.1885),
            frp: 50.0,
            confidence: 60.0,
            detectedAt: detectedAt,
          ),
        ];

        final result = HotspotClusterer.cluster(hotspots);

        expect(result.length, 1);
        final cluster = result.first;
        expect(cluster.count, 2);
        expect(cluster.maxFrp, 50.0);
        expect(cluster.intensity, 'high');
      });

      test('handles many hotspots efficiently', () {
        // Create 100 hotspots spread across Scotland
        final hotspots = List.generate(100, (index) {
          return Hotspot(
            id: 'hs$index',
            location: LatLng(
              55.0 + (index ~/ 10) * 0.5, // Spread across latitude
              -3.0 - (index % 10) * 0.1, // Spread across longitude
            ),
            frp: 10.0 + index % 50,
            confidence: 60.0,
            detectedAt: DateTime.now(),
          );
        });

        final stopwatch = Stopwatch()..start();
        final result = HotspotClusterer.cluster(hotspots);
        stopwatch.stop();

        // Should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(result, isNotEmpty);
      });
    });
  });
}
