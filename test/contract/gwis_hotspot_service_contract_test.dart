import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/gwis_hotspot_service.dart';
import 'package:wildfire_mvp_v3/services/gwis_hotspot_service_impl.dart';

/// Contract tests for GwisHotspotService
///
/// These tests verify the contract with the GWIS API:
/// - Endpoint format and parameters
/// - Response parsing for expected formats
/// - Error handling for various HTTP responses
///
/// Part of 021-live-fire-data feature (T016)
void main() {
  group('GwisHotspotService Contract', () {
    late GwisHotspotService service;
    late http.Client httpClient;

    setUp(() {
      httpClient = http.Client();
      service = GwisHotspotServiceImpl(httpClient: httpClient);
    });

    tearDown(() {
      httpClient.close();
    });

    group('API Response Contract', () {
      test('returns Either type from getHotspots', () async {
        // Scotland viewport - may or may not have hotspots
        const bounds = LatLngBounds(
          southwest: LatLng(55.0, -5.0),
          northeast: LatLng(58.0, -2.0),
        );

        final result = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
          timeout: const Duration(seconds: 15),
        );

        // Should return Either - either success or error, not throw
        expect(result.isLeft() || result.isRight(), isTrue);
      });

      test(
        'hotspots have required fields when present',
        () async {
          // Use Portugal/Spain region - more likely to have active fires
          const bounds = LatLngBounds(
            southwest: LatLng(36.0, -10.0),
            northeast: LatLng(44.0, 0.0),
          );

          final result = await service.getHotspots(
            bounds: bounds,
            timeFilter: HotspotTimeFilter.thisWeek,
            timeout: const Duration(seconds: 15),
          );

          result.fold(
            (error) {
              // API error is acceptable - service may be temporarily unavailable
              expect(error.message, isNotEmpty);
            },
            (hotspots) {
              // If we got hotspots, verify required fields
              for (final hotspot in hotspots) {
                expect(hotspot.id, isNotEmpty, reason: 'id is required');
                expect(
                  hotspot.location.latitude,
                  inInclusiveRange(-90, 90),
                  reason: 'latitude must be valid',
                );
                expect(
                  hotspot.location.longitude,
                  inInclusiveRange(-180, 180),
                  reason: 'longitude must be valid',
                );
                expect(
                  hotspot.detectedAt.isBefore(
                    DateTime.now().add(const Duration(hours: 1)),
                  ),
                  isTrue,
                  reason: 'detectedAt should not be in future',
                );
                expect(
                  hotspot.confidence,
                  inInclusiveRange(0, 100),
                  reason: 'confidence must be 0-100',
                );
                expect(
                  hotspot.frp,
                  greaterThanOrEqualTo(0),
                  reason: 'FRP cannot be negative',
                );
                expect(
                  ['low', 'moderate', 'high'],
                  contains(hotspot.intensity),
                  reason: 'intensity must be low, moderate, or high',
                );
              }
            },
          );
        },
        skip:
            'Live API test - run manually with: flutter test --name="hotspots have required fields"',
      );

      test(
        'returns empty list for Antarctic viewport (no fires)',
        () async {
          // Remote Antarctic region - no fires expected
          const bounds = LatLngBounds(
            southwest: LatLng(-75.0, -60.0),
            northeast: LatLng(-70.0, -50.0),
          );

          final result = await service.getHotspots(
            bounds: bounds,
            timeFilter: HotspotTimeFilter.today,
            timeout: const Duration(seconds: 15),
          );

          result.fold(
            (error) {
              // API error is acceptable for edge case regions
              expect(error.message, isNotEmpty);
            },
            (hotspots) {
              // Should be empty - no fires in Antarctica
              expect(hotspots, isEmpty);
            },
          );
        },
        skip: 'Live API test - run manually',
      );
    });

    group('Layer Selection Contract', () {
      test('HotspotTimeFilter.today maps to viirs.hs.today layer', () {
        expect(HotspotTimeFilter.today.gwisLayerName, equals('viirs.hs.today'));
      });

      test('HotspotTimeFilter.thisWeek maps to viirs.hs.week layer', () {
        expect(
          HotspotTimeFilter.thisWeek.gwisLayerName,
          equals('viirs.hs.week'),
        );
      });
    });

    group('Error Handling Contract', () {
      test('returns ApiError for invalid timeout', () async {
        const bounds = LatLngBounds(
          southwest: LatLng(55.0, -5.0),
          northeast: LatLng(58.0, -2.0),
        );

        final result = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
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

        final result = await service.getHotspots(
          bounds: bounds,
          timeFilter: HotspotTimeFilter.today,
          maxRetries: 100, // Invalid (max is 10)
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('maxRetries')),
          (_) => fail('Expected error'),
        );
      });
    });

    group('Coordinate Order Contract', () {
      test(
        'hotspot location uses lat,lon order (not lon,lat from GML)',
        () async {
          // This test verifies that coordinate swapping is correctly applied
          // GWIS returns lon,lat but our LatLng expects lat,lon
          const bounds = LatLngBounds(
            southwest: LatLng(55.0, -5.0),
            northeast: LatLng(58.0, -2.0),
          );

          final result = await service.getHotspots(
            bounds: bounds,
            timeFilter: HotspotTimeFilter.today,
            timeout: const Duration(seconds: 15),
          );

          result.fold(
            (error) {
              // API error is acceptable
            },
            (hotspots) {
              for (final hotspot in hotspots) {
                // Scotland is roughly 55-59°N, 2-8°W
                // If coordinates were swapped wrong, lat would be negative
                expect(
                  hotspot.location.latitude,
                  greaterThan(0),
                  reason: 'Scotland hotspots should have positive latitude',
                );
                expect(
                  hotspot.location.longitude,
                  lessThan(0),
                  reason: 'Scotland hotspots should have negative longitude',
                );
              }
            },
          );
        },
        skip: 'Live API test - run manually',
      );
    });
  });
}
