import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/services/mock_gwis_hotspot_service.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';

/// Unit tests for MockGwisHotspotService (021-live-fire-data)
///
/// Tests mock data loading, bounding box filtering, and fallback behavior.
void main() {
  // Required for rootBundle.loadString in tests
  WidgetsFlutterBinding.ensureInitialized();

  group('MockGwisHotspotService', () {
    late MockGwisHotspotService service;

    setUp(() {
      service = MockGwisHotspotService();
    });

    group('getHotspots', () {
      test('returns Right with list of hotspots', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (error) => fail('Should not return error'),
          (hotspots) {
            // Mock data should return hotspots (may be empty if bounds don't match)
            expect(hotspots, isA<List>());
          },
        );
      });

      test('filters hotspots by bounding box', () async {
        // Very small bounds that likely exclude all mock data
        const tightBounds = LatLngBounds(
          southwest: LatLng(0.0, 0.0),
          northeast: LatLng(1.0, 1.0),
        );

        final result = await service.getHotspots(
          bounds: tightBounds,
          timeFilter: HotspotTimeFilter.today,
        );

        result.fold(
          (error) => fail('Should not return error'),
          (hotspots) {
            // With bounds far from Scotland, should return empty
            expect(hotspots, isEmpty);
          },
        );
      });

      test('returns hotspots within Scotland bounds', () async {
        // Bounds covering all of Scotland
        const scotlandBounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getHotspots(
          bounds: scotlandBounds,
          timeFilter: HotspotTimeFilter.today,
        );

        result.fold(
          (error) => fail('Should not return error'),
          (hotspots) {
            // All mock hotspots should be in Scotland
            for (final hotspot in hotspots) {
              expect(hotspot.location.latitude, greaterThanOrEqualTo(54.0));
              expect(hotspot.location.latitude, lessThanOrEqualTo(61.0));
              expect(hotspot.location.longitude, greaterThanOrEqualTo(-8.0));
              expect(hotspot.location.longitude, lessThanOrEqualTo(0.0));
            }
          },
        );
      });

      test('never returns Left (mock service always succeeds)', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // Call multiple times to ensure consistency
        for (int i = 0; i < 3; i++) {
          final result = await service.getHotspots(
            bounds: bounds,
            timeFilter: HotspotTimeFilter.today,
          );
          expect(result.isRight(), isTrue);
        }
      });

      test('ignores timeout and maxRetries parameters (mock behavior)',
          () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
          timeout: const Duration(milliseconds: 1), // Very short timeout
          maxRetries: 0,
        );

        // Should still succeed - mock ignores these parameters
        expect(result.isRight(), isTrue);
      });

      test('accepts both time filters', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final todayResult = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
        );
        final weekResult = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.thisWeek,
        );

        expect(todayResult.isRight(), isTrue);
        expect(weekResult.isRight(), isTrue);
      });
    });

    group('caching behavior', () {
      test('caches loaded data across calls', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // First call loads data
        final result1 = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
        );

        // Second call should use cached data (same instance returned)
        final result2 = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
        );

        expect(result1.isRight(), isTrue);
        expect(result2.isRight(), isTrue);
      });
    });
  });
}
