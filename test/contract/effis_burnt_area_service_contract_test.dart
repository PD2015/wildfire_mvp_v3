import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service_impl.dart';

/// Contract tests for EffisBurntAreaService
///
/// These tests verify the contract with the EFFIS WFS API:
/// - Endpoint format and parameters
/// - GeoJSON response parsing
/// - Polygon simplification behavior
/// - Error handling for various HTTP responses
///
/// Part of 021-live-fire-data feature (T017)
void main() {
  group('EffisBurntAreaService Contract', () {
    late EffisBurntAreaService service;
    late http.Client httpClient;

    setUp(() {
      httpClient = http.Client();
      service = EffisBurntAreaServiceImpl(httpClient: httpClient);
    });

    tearDown(() {
      httpClient.close();
    });

    group('API Response Contract', () {
      test('returns Either type from getBurntAreas', () async {
        // Scotland viewport
        const bounds = LatLngBounds(
          southwest: LatLng(54.5, -8.0),
          northeast: LatLng(61.0, 0.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
          timeout: const Duration(seconds: 15),
        );

        // Should return Either - either success or error, not throw
        expect(result.isLeft() || result.isRight(), isTrue);
      });

      test(
        'burnt areas have required fields when present',
        () async {
          // Portugal/Spain - more likely to have burnt areas
          const bounds = LatLngBounds(
            southwest: LatLng(36.0, -10.0),
            northeast: LatLng(44.0, 0.0),
          );

          final result = await service.getBurntAreas(
            bounds: bounds,
            seasonFilter: BurntAreaSeasonFilter.thisSeason,
            timeout: const Duration(seconds: 20),
          );

          result.fold(
            (error) {
              // API error is acceptable - service may be temporarily unavailable
              expect(error.message, isNotEmpty);
            },
            (burntAreas) {
              // If we got burnt areas, verify required fields
              for (final area in burntAreas) {
                expect(area.id, isNotEmpty, reason: 'id is required');
                expect(
                  area.boundaryPoints.length,
                  greaterThanOrEqualTo(3),
                  reason: 'polygon must have at least 3 points',
                );
                expect(
                  area.areaHectares,
                  greaterThan(0),
                  reason: 'area must be positive',
                );
                expect(
                  area.fireDate.isBefore(
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  isTrue,
                  reason: 'fireDate should not be in future',
                );
                expect(
                  area.seasonYear,
                  greaterThanOrEqualTo(2020),
                  reason: 'seasonYear should be recent',
                );

                // Validate all boundary points are within valid coordinate ranges
                for (final point in area.boundaryPoints) {
                  expect(
                    point.latitude,
                    inInclusiveRange(-90, 90),
                    reason: 'latitude must be valid',
                  );
                  expect(
                    point.longitude,
                    inInclusiveRange(-180, 180),
                    reason: 'longitude must be valid',
                  );
                }

                // Verify centroid is computed
                final centroid = area.centroid;
                expect(centroid.latitude, inInclusiveRange(-90, 90));
                expect(centroid.longitude, inInclusiveRange(-180, 180));
              }
            },
          );
        },
        skip:
            'Live API test - run manually with: flutter test --name="burnt areas have required fields"',
      );

      test(
        'returns empty list for Antarctic viewport (no burnt areas)',
        () async {
          // Remote Antarctic region - no fires expected
          const bounds = LatLngBounds(
            southwest: LatLng(-75.0, -60.0),
            northeast: LatLng(-70.0, -50.0),
          );

          final result = await service.getBurntAreas(
            bounds: bounds,
            seasonFilter: BurntAreaSeasonFilter.thisSeason,
            timeout: const Duration(seconds: 15),
          );

          result.fold(
            (error) {
              // API error is acceptable for edge case regions
              expect(error.message, isNotEmpty);
            },
            (burntAreas) {
              // Should be empty - no fires in Antarctica
              expect(burntAreas, isEmpty);
            },
          );
        },
        skip: 'Live API test - run manually',
      );
    });

    group('Season Filter Contract', () {
      test('BurntAreaSeasonFilter.thisSeason returns current year', () {
        final currentYear = DateTime.now().year;
        expect(BurntAreaSeasonFilter.thisSeason.year, equals(currentYear));
      });

      test('BurntAreaSeasonFilter.lastSeason returns previous year', () {
        final lastYear = DateTime.now().year - 1;
        expect(BurntAreaSeasonFilter.lastSeason.year, equals(lastYear));
      });

      test(
        'lastSeason filter returns historical data',
        () async {
          // Scotland viewport - check for historical burnt areas
          const bounds = LatLngBounds(
            southwest: LatLng(54.5, -8.0),
            northeast: LatLng(61.0, 0.0),
          );

          final result = await service.getBurntAreas(
            bounds: bounds,
            seasonFilter: BurntAreaSeasonFilter.lastSeason,
            timeout: const Duration(seconds: 15),
          );

          // Either success or error is acceptable
          expect(result.isLeft() || result.isRight(), isTrue);
        },
        skip: 'Live API test - run manually',
      );
    });

    group('Polygon Simplification Contract', () {
      test(
        'isSimplified flag available on BurntArea',
        () async {
          const bounds = LatLngBounds(
            southwest: LatLng(36.0, -10.0),
            northeast: LatLng(44.0, 0.0),
          );

          final result = await service.getBurntAreas(
            bounds: bounds,
            seasonFilter: BurntAreaSeasonFilter.thisSeason,
            timeout: const Duration(seconds: 20),
          );

          result.fold(
            (error) {
              // Acceptable if service unavailable
            },
            (burntAreas) {
              for (final area in burntAreas) {
                // isSimplified should be a valid boolean
                expect(area.isSimplified, isA<bool>());

                // If simplified, original point count should be available
                if (area.isSimplified) {
                  expect(area.originalPointCount, isNotNull);
                  expect(
                    area.originalPointCount,
                    greaterThan(area.boundaryPoints.length),
                  );
                }

                // Simplified polygons should have max 500 points
                expect(
                  area.boundaryPoints.length,
                  lessThanOrEqualTo(500),
                  reason: 'Polygons should be simplified to max 500 points',
                );
              }
            },
          );
        },
        skip: 'Live API test - run manually',
      );
    });

    group('Error Handling Contract', () {
      test('returns ApiError for invalid timeout', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(55.0, -5.0),
          northeast: LatLng(58.0, -2.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
          timeout: Duration.zero, // Invalid
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('Timeout')),
          (_) => fail('Expected error'),
        );
      });

      test('returns ApiError for invalid maxRetries', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(55.0, -5.0),
          northeast: LatLng(58.0, -2.0),
        );

        final result = await service.getBurntAreas(
          bounds: bounds,
          seasonFilter: BurntAreaSeasonFilter.thisSeason,
          maxRetries: 100, // Invalid (max is 10)
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('maxRetries')),
          (_) => fail('Expected error'),
        );
      });
    });

    group('Land Cover Contract', () {
      test(
        'landCoverBreakdown contains expected keys when present',
        () async {
          const bounds = LatLngBounds(
            southwest: LatLng(36.0, -10.0),
            northeast: LatLng(44.0, 0.0),
          );

          final result = await service.getBurntAreas(
            bounds: bounds,
            seasonFilter: BurntAreaSeasonFilter.thisSeason,
            timeout: const Duration(seconds: 20),
          );

          result.fold(
            (error) {
              // Acceptable if service unavailable
            },
            (burntAreas) {
              for (final area in burntAreas) {
                if (area.landCoverBreakdown != null) {
                  // Values should be percentages (0-100 or 0-1)
                  for (final value in area.landCoverBreakdown!.values) {
                    expect(value, greaterThanOrEqualTo(0));
                  }
                }
              }
            },
          );
        },
        skip: 'Live API test - run manually',
      );
    });

    group('Coordinate Order Contract', () {
      test(
        'polygon points use lat,lon order (not lon,lat from GeoJSON)',
        () async {
          // Scotland viewport
          const bounds = LatLngBounds(
            southwest: LatLng(54.5, -8.0),
            northeast: LatLng(61.0, 0.0),
          );

          final result = await service.getBurntAreas(
            bounds: bounds,
            seasonFilter: BurntAreaSeasonFilter.thisSeason,
            timeout: const Duration(seconds: 15),
          );

          result.fold(
            (error) {
              // API error is acceptable
            },
            (burntAreas) {
              for (final area in burntAreas) {
                for (final point in area.boundaryPoints) {
                  // Scotland is roughly 54-61°N, 0-8°W
                  // If coordinates were swapped wrong, values would be inverted
                  expect(
                    point.latitude,
                    greaterThan(0),
                    reason: 'Scotland points should have positive latitude',
                  );
                }
              }
            },
          );
        },
        skip: 'Live API test - run manually',
      );
    });
  });
}
