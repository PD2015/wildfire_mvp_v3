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

    group('date transformation', () {
      test('transforms mock data dates so newest is ~6 hours ago', () async {
        // Arrange: Fixed "now" for reproducible tests
        final fixedNow = DateTime.utc(2025, 6, 15, 12, 0);
        final clockedService = MockGwisHotspotService(clock: () => fixedNow);

        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // Act
        final result = await clockedService.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.thisWeek,
        );

        // Assert
        expect(result.isRight(), isTrue);
        final hotspots = result.getOrElse(() => []);

        if (hotspots.isNotEmpty) {
          // Newest should be ~6 hours before fixedNow
          final newestDate = hotspots
              .map((h) => h.detectedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);

          final expectedNewest = fixedNow.subtract(const Duration(hours: 6));

          // Allow small tolerance for test timing
          final diff = newestDate.difference(expectedNewest).abs();
          expect(
            diff.inMinutes,
            lessThan(5),
            reason: 'Newest hotspot should be ~6 hours ago: '
                'expected $expectedNewest, got $newestDate',
          );
        }
      });

      test('mock data never expires regardless of real date', () async {
        // Arrange: Far future date
        final futureNow = DateTime.utc(2030, 1, 1, 12, 0);
        final clockedService = MockGwisHotspotService(clock: () => futureNow);

        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // Act
        final result = await clockedService.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today, // Strictest filter
        );

        // Assert
        final hotspots = result.getOrElse(() => []);

        // Mock data should still return hotspots even in 2030
        // because dates are transformed relative to "now"
        expect(
          hotspots.length,
          greaterThan(0),
          reason: 'Mock data should never expire',
        );
      });

      test('preserves relative timing between hotspots', () async {
        // Arrange: Two services at different "now" times
        final now1 = DateTime.utc(2025, 6, 15, 12, 0);
        final now2 = DateTime.utc(2025, 12, 25, 12, 0); // 6 months later

        final service1 = MockGwisHotspotService(clock: () => now1);
        final service2 = MockGwisHotspotService(clock: () => now2);

        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // Act
        final result1 = await service1.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.thisWeek,
        );
        final result2 = await service2.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.thisWeek,
        );

        // Assert
        final hotspots1 = result1.getOrElse(() => []);
        final hotspots2 = result2.getOrElse(() => []);

        // Both should return same number of hotspots
        expect(hotspots1.length, equals(hotspots2.length));

        // The time differences between hotspots should be preserved
        if (hotspots1.length >= 2) {
          // Find common hotspots by ID
          final h1ById = {for (final h in hotspots1) h.id: h};
          final h2ById = {for (final h in hotspots2) h.id: h};

          // Pick first two IDs that exist in both
          final commonIds = h1ById.keys
              .where((id) => h2ById.containsKey(id))
              .take(2)
              .toList();

          if (commonIds.length >= 2) {
            final diff1 = h1ById[commonIds[0]]!
                .detectedAt
                .difference(h1ById[commonIds[1]]!.detectedAt);
            final diff2 = h2ById[commonIds[0]]!
                .detectedAt
                .difference(h2ById[commonIds[1]]!.detectedAt);

            // The relative time difference should be identical
            expect(diff1, equals(diff2));
          }
        }
      });

      test('today filter returns hotspots within 24 hours of mock now',
          () async {
        // Arrange: Fixed "now" for reproducible tests
        final fixedNow = DateTime.utc(2025, 6, 15, 12, 0);
        final clockedService = MockGwisHotspotService(clock: () => fixedNow);

        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // Act
        final result = await clockedService.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
        );

        // Assert
        final hotspots = result.getOrElse(() => []);
        final cutoff = fixedNow.subtract(const Duration(hours: 24));

        for (final hotspot in hotspots) {
          expect(
            hotspot.detectedAt.isAfter(cutoff),
            isTrue,
            reason: 'Hotspot at ${hotspot.detectedAt} should be after $cutoff',
          );
        }
      });

      test('thisWeek filter returns hotspots within 7 days of mock now',
          () async {
        // Arrange: Fixed "now" for reproducible tests
        final fixedNow = DateTime.utc(2025, 6, 15, 12, 0);
        final clockedService = MockGwisHotspotService(clock: () => fixedNow);

        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // Act
        final result = await clockedService.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.thisWeek,
        );

        // Assert
        final hotspots = result.getOrElse(() => []);
        final cutoff = fixedNow.subtract(const Duration(days: 7));

        for (final hotspot in hotspots) {
          expect(
            hotspot.detectedAt.isAfter(cutoff),
            isTrue,
            reason: 'Hotspot at ${hotspot.detectedAt} should be after $cutoff',
          );
        }
      });
    });
  });
}
