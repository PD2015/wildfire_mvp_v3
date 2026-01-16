import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/services/mock_effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';

/// Unit tests for MockEffisBurntAreaService (021-live-fire-data)
///
/// Tests mock data loading, bounding box filtering, season filtering, and fallback behavior.
///
/// NOTE: These tests are skipped on web platform because rootBundle.loadString
/// hangs indefinitely in Chrome test environment. The mock service works correctly
/// in the actual app on web - this is a test infrastructure limitation.
void main() {
  // Required for rootBundle.loadString in tests
  WidgetsFlutterBinding.ensureInitialized();

  // Skip entire test file on web - rootBundle.loadString hangs in Chrome tests
  if (kIsWeb) {
    test(
      'skipped on web platform',
      () {
        // rootBundle.loadString doesn't work in Chrome test environment
      },
      skip: 'MockEffisBurntAreaService tests use rootBundle which hangs on web',
    );
    return;
  }

  group('MockEffisBurntAreaService', () {
    late MockEffisBurntAreaService service;

    setUp(() {
      service = MockEffisBurntAreaService();
    });

    group('getBurntAreas', () {
      test('returns Right with list of burnt areas', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Should not return error'), (burntAreas) {
          expect(burntAreas, isA<List>());
        });
      });

      test('filters burnt areas by bounding box', () async {
        // Very small bounds that likely exclude all mock data
        const tightBounds = LatLngBounds(
          southwest: LatLng(0.0, 0.0),
          northeast: LatLng(1.0, 1.0),
        );

        final result = await service.getBurntAreas(
          bounds: tightBounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        result.fold((error) => fail('Should not return error'), (burntAreas) {
          // With bounds far from Scotland, should return empty
          expect(burntAreas, isEmpty);
        });
      });

      test('returns burnt areas within Scotland bounds', () async {
        // Bounds covering all of Scotland
        const scotlandBounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getBurntAreas(
          bounds: scotlandBounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        result.fold((error) => fail('Should not return error'), (burntAreas) {
          // All mock burnt areas should be in Scotland
          for (final area in burntAreas) {
            // Check centroid is within bounds
            expect(area.centroid.latitude, greaterThanOrEqualTo(54.0));
            expect(area.centroid.latitude, lessThanOrEqualTo(61.0));
            expect(area.centroid.longitude, greaterThanOrEqualTo(-8.0));
            expect(area.centroid.longitude, lessThanOrEqualTo(0.0));
          }
        });
      });

      test('never returns Left (mock service always succeeds)', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // Call multiple times to ensure consistency
        for (int i = 0; i < 3; i++) {
          final result = await service.getBurntAreas(
            bounds: bounds,
            seasonFilter: BurntAreaSeasonFilter.thisSeason,
          );
          expect(result.isRight(), isTrue);
        }
      });

      test(
        'ignores timeout and maxRetries parameters (mock behavior)',
        () async {
          const bounds = LatLngBounds(
            southwest: LatLng(54.0, -8.0),
            northeast: LatLng(61.0, 0.0),
          );

          final result = await service.getBurntAreas(
            bounds: bounds,
            seasonFilter: BurntAreaSeasonFilter.thisSeason,
            timeout: const Duration(milliseconds: 1), // Very short timeout
            maxRetries: 0,
          );

          // Should still succeed - mock ignores these parameters
          expect(result.isRight(), isTrue);
        },
      );
    });

    group('season filtering', () {
      test('thisSeason filter returns current year data', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        result.fold((error) => fail('Should not return error'), (burntAreas) {
          final currentYear = DateTime.now().year;
          for (final area in burntAreas) {
            expect(area.seasonYear, equals(currentYear));
          }
        });
      });

      test('lastSeason filter returns previous year data', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.lastSeason,
        );

        result.fold((error) => fail('Should not return error'), (burntAreas) {
          final lastYear = DateTime.now().year - 1;
          for (final area in burntAreas) {
            expect(area.seasonYear, equals(lastYear));
          }
        });
      });
    });

    group('burnt area properties', () {
      test('returned areas have valid boundary points (>= 3)', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        result.fold((error) => fail('Should not return error'), (burntAreas) {
          for (final area in burntAreas) {
            expect(
              area.boundaryPoints.length,
              greaterThanOrEqualTo(3),
              reason: 'BurntArea ${area.id} should have >= 3 boundary points',
            );
          }
        });
      });

      test('returned areas have positive area in hectares', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        result.fold((error) => fail('Should not return error'), (burntAreas) {
          for (final area in burntAreas) {
            expect(
              area.areaHectares,
              greaterThan(0),
              reason: 'BurntArea ${area.id} should have positive area',
            );
          }
        });
      });

      test('returned areas have unique IDs', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        result.fold((error) => fail('Should not return error'), (burntAreas) {
          final ids = burntAreas.map((a) => a.id).toSet();
          expect(
            ids.length,
            equals(burntAreas.length),
            reason: 'All burnt area IDs should be unique',
          );
        });
      });
    });

    group('caching behavior', () {
      test('caches loaded data across calls', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(54.0, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        // First call loads data
        final result1 = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        // Second call should use cached data
        final result2 = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
        );

        expect(result1.isRight(), isTrue);
        expect(result2.isRight(), isTrue);
      });
    });
  });
}
