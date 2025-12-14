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

      test('clusters nearby hotspots at low zoom', () {
        // Two hotspots ~200m apart (should cluster at low zoom)
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

        // At low zoom (6), radius is large enough to cluster these
        final result = HotspotClusterer.cluster(hotspots, zoom: 6.0);

        expect(result.length, 1);
        expect(result.first.count, 2);
      });

      test('keeps distant hotspots in separate clusters at low zoom', () {
        // Two hotspots ~150km apart (should not cluster even at zoom 5)
        // At zoom 5, radius is ~164km, so 150km is borderline
        // At zoom 6, radius is ~82km, so 150km apart should be separate
        final hotspots = [
          Hotspot(
            id: 'hs1',
            location: const LatLng(55.0, -3.0),
            frp: 15.0,
            confidence: 85.0,
            detectedAt: DateTime.now(),
          ),
          Hotspot(
            id: 'hs2',
            location: const LatLng(56.3, -3.0), // ~150km away (1.3° latitude)
            frp: 25.0,
            confidence: 60.0,
            detectedAt: DateTime.now(),
          ),
        ];

        final result = HotspotClusterer.cluster(hotspots, zoom: 6.0);

        expect(result.length, 2);
        expect(result[0].count, 1);
        expect(result[1].count, 1);
      });

      test('zoom level affects clustering radius', () {
        // Two hotspots ~50km apart
        // At zoom 5 (~164km radius): should cluster
        // At zoom 7 (~41km radius): should NOT cluster
        final hotspots = [
          Hotspot(
            id: 'hs1',
            location: const LatLng(55.0, -3.0),
            frp: 15.0,
            confidence: 85.0,
            detectedAt: DateTime.now(),
          ),
          Hotspot(
            id: 'hs2',
            location: const LatLng(55.45, -3.0), // ~50km away (0.45° latitude)
            frp: 25.0,
            confidence: 60.0,
            detectedAt: DateTime.now(),
          ),
        ];

        // At zoom 5 (very zoomed out), radius is ~164km - should cluster
        final lowZoomResult = HotspotClusterer.cluster(hotspots, zoom: 5.0);
        expect(lowZoomResult.length, 1);
        expect(lowZoomResult.first.count, 2);

        // At zoom 7, radius is ~41km - 50km apart should be separate
        final highZoomResult = HotspotClusterer.cluster(hotspots, zoom: 7.0);
        expect(highZoomResult.length, 2);
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

        final result = HotspotClusterer.cluster(hotspots, zoom: 6.0);

        expect(result.length, 1);
        final cluster = result.first;
        expect(cluster.count, 2);
        expect(cluster.maxFrp, 50.0);
        expect(cluster.intensity, 'high');
      });

      test('returns individual clusters at maxClusterZoom', () {
        // At or above maxClusterZoom (12), every hotspot is its own cluster
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
            location: const LatLng(55.9535, -3.1885), // Very close
            frp: 25.0,
            confidence: 60.0,
            detectedAt: DateTime.now(),
          ),
        ];

        final result = HotspotClusterer.cluster(hotspots,
            zoom: HotspotClusterer.maxClusterZoom);

        // Even though they're close, at max zoom they're separate
        expect(result.length, 2);
        expect(result[0].count, 1);
        expect(result[1].count, 1);
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
        final result = HotspotClusterer.cluster(hotspots, zoom: 6.0);
        stopwatch.stop();

        // Should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(result, isNotEmpty);
      });
    });

    group('pixelsToMeters', () {
      test('returns larger radius at lower zoom', () {
        final lowZoomRadius = HotspotClusterer.pixelsToMeters(60.0, 5.0);
        final highZoomRadius = HotspotClusterer.pixelsToMeters(60.0, 10.0);

        expect(lowZoomRadius, greaterThan(highZoomRadius));
      });

      test('returns expected values for known inputs', () {
        // At zoom 0, 60 pixels at latitude 56 (Scotland):
        // metersPerPixel = 156543.03392 * cos(56°) = ~87,538 m/px
        // 60 pixels = ~5,252 km
        final radiusAtZoom0 =
            HotspotClusterer.pixelsToMeters(60.0, 0.0, latitude: 56.0);
        expect(radiusAtZoom0, closeTo(5252000, 10000)); // ~5252 km

        // Each zoom level halves the radius
        final radiusAtZoom1 =
            HotspotClusterer.pixelsToMeters(60.0, 1.0, latitude: 56.0);
        expect(radiusAtZoom1, closeTo(radiusAtZoom0 / 2, 5000));
      });

      test('accounts for latitude', () {
        // At higher latitudes, radius should be smaller (cos factor)
        final radiusAtEquator =
            HotspotClusterer.pixelsToMeters(60.0, 6.0, latitude: 0.0);
        final radiusAtScotland =
            HotspotClusterer.pixelsToMeters(60.0, 6.0, latitude: 56.0);

        expect(radiusAtScotland, lessThan(radiusAtEquator));
      });
    });

    group('getClusterRadiusMeters', () {
      test('uses default pixel radius', () {
        final radius = HotspotClusterer.getClusterRadiusMeters(6.0);
        final expectedRadius = HotspotClusterer.pixelsToMeters(
          HotspotClusterer.defaultRadiusPixels,
          6.0,
        );

        expect(radius, equals(expectedRadius));
      });

      test('accepts custom pixel radius', () {
        final smallRadius =
            HotspotClusterer.getClusterRadiusMeters(6.0, radiusPixels: 30.0);
        final largeRadius =
            HotspotClusterer.getClusterRadiusMeters(6.0, radiusPixels: 120.0);

        expect(largeRadius, greaterThan(smallRadius));
        expect(largeRadius, closeTo(smallRadius * 4, 100));
      });
    });

    group('constants', () {
      test('defaultRadiusPixels is reasonable', () {
        expect(HotspotClusterer.defaultRadiusPixels, equals(60.0));
      });

      test('maxClusterZoom is appropriate for fire visualization', () {
        // At zoom 12, we want to see individual hotspots
        expect(HotspotClusterer.maxClusterZoom, equals(12.0));
      });
    });
  });
}
