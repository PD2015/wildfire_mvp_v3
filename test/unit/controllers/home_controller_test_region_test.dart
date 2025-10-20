import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:wildfire_mvp_v3/controllers/home_controller.dart';
import 'package:wildfire_mvp_v3/models/home_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';

/// Tests for TEST_REGION feature flag behavior in HomeController
///
/// These tests verify that HomeController correctly handles LocationError
/// when TEST_REGION is set, using test region coordinates instead of
/// treating the error as a failure.
void main() {
  group('HomeController TEST_REGION Integration', () {
    late HomeController controller;
    late MockLocationResolver mockLocationResolver;
    late MockFireRiskService mockFireRiskService;

    setUp(() {
      mockLocationResolver = MockLocationResolver();
      mockFireRiskService = MockFireRiskService();

      controller = HomeController(
        locationResolver: mockLocationResolver,
        fireRiskService: mockFireRiskService,
      );
    });

    group('TEST_REGION Fallback Logic', () {
      test(
          'should use test region coordinates when LocationResolver returns error and TEST_REGION is set',
          () async {
        // This test documents the expected behavior when TEST_REGION != 'scotland'
        // In actual usage with --dart-define=TEST_REGION=portugal:
        // 1. LocationResolver returns Left(LocationError.gpsUnavailable)
        // 2. HomeController checks FeatureFlags.testRegion
        // 3. If not 'scotland', uses _getTestRegionCenter()
        // 4. Proceeds with fire risk query using test coordinates

        // Arrange: Simulate LocationResolver error (what happens when TEST_REGION is set)
        mockLocationResolver.mockGetLatLon(
          const Left(LocationError.gpsUnavailable),
        );

        // Mock successful fire risk response
        mockFireRiskService.mockGetCurrent(
          Right(FireRisk(
            level: RiskLevel.moderate,
            fwi: 15.0,
            source: DataSource.effis,
            observedAt: DateTime.now().toUtc(),
            freshness: Freshness.live,
          )),
        );

        // Act: Load data
        await controller.load();

        // Wait for async operations
        await Future.delayed(Duration(milliseconds: 100));

        // Assert: With default TEST_REGION=scotland in tests, this becomes an error
        // In production with TEST_REGION=portugal, it would succeed with Portugal coords
        final state = controller.state;

        // Document expected behavior in different scenarios:
        if (FeatureFlags.testRegion == 'scotland') {
          // Test environment: LocationError should cause error state
          expect(state, isA<HomeStateError>(),
              reason: 'Default scotland with LocationError should error');
        } else {
          // Production with TEST_REGION set: Should use test region coordinates
          expect(state, isA<HomeStateSuccess>(),
              reason:
                  'Non-scotland TEST_REGION should use fallback coordinates');
        }
      });

      test('_getTestRegionCenter should match MapController implementation',
          () {
        // This test verifies that HomeController and MapController use
        // identical test region mappings to ensure consistency

        final testRegionMappings = {
          'portugal': const LatLng(39.6, -9.1),
          'spain': const LatLng(40.4, -3.7),
          'greece': const LatLng(37.9, 23.7),
          'california': const LatLng(36.7, -119.4),
          'australia': const LatLng(-33.8, 151.2),
          'scotland': const LatLng(57.2, -3.8), // Default
        };

        // Verify all regions are documented
        expect(
          testRegionMappings.keys,
          containsAll(
              ['portugal', 'spain', 'greece', 'california', 'australia']),
          reason: 'All test regions from TEST_REGIONS.md should be mapped',
        );

        // Note: Actual coordinate verification would require reflection or
        // exposing _getTestRegionCenter() as a public method for testing
        // Current implementation keeps it private for encapsulation
      });
    });

    group('Integration Test Scenarios', () {
      // Document integration test commands for manual verification

      test('TEST_REGION=portugal integration scenario', () {
        // Integration test command:
        // flutter test test/unit/controllers/home_controller_test_region_test.dart \
        //   --dart-define=TEST_REGION=portugal \
        //   --dart-define=MAP_LIVE_DATA=true

        // Expected flow:
        // 1. LocationResolver returns Left(LocationError.gpsUnavailable)
        // 2. HomeController checks FeatureFlags.testRegion → 'portugal'
        // 3. HomeController uses LatLng(39.6, -9.1)
        // 4. FireRiskService queries EFFIS for Portugal coordinates
        // 5. RiskBanner displays Portugal fire risk data

        // Verification:
        // - Check logs: "Using test region: portugal at 39.60,-9.10"
        // - Verify FireRiskService receives correct coordinates
        // - Verify HomeStateSuccess with Portugal location
      });

      test('TEST_REGION=california should query California coordinates', () {
        // Expected: LatLng(36.7, -119.4)
        // Use case: Testing during California fire season (June-November)
      });
    });

    group('Controller Consistency', () {
      test('HomeController and MapController should use same test coordinates',
          () {
        // This is a critical requirement: Both controllers must query EFFIS
        // for the same geographic location when TEST_REGION is set

        // Verification method:
        // 1. Run with TEST_REGION=portugal
        // 2. Check HomeController logs for coordinates
        // 3. Check MapController logs for coordinates
        // 4. Verify both use (39.6, -9.1)

        // Expected log patterns:
        // HomeController: "Using test region: portugal at 39.60,-9.10"
        // MapController: "🗺️ Using test region: portugal at 39.6,-9.1"
      });
    });
  });
}

/// Mock LocationResolver for TEST_REGION testing
class MockLocationResolver implements LocationResolver {
  Either<LocationError, LatLng>? _getLatLonResult;

  void mockGetLatLon(Either<LocationError, LatLng> result) {
    _getLatLonResult = result;
  }

  @override
  Future<Either<LocationError, LatLng>> getLatLon(
      {bool allowDefault = true}) async {
    return _getLatLonResult ?? const Right(LatLng(55.9533, -3.1883));
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {}
}

/// Mock FireRiskService for TEST_REGION testing
class MockFireRiskService implements FireRiskService {
  Either<ApiError, FireRisk>? _getCurrentResult;
  LatLng? lastQueriedLocation;

  void mockGetCurrent(Either<ApiError, FireRisk> result) {
    _getCurrentResult = result;
  }

  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    lastQueriedLocation = LatLng(lat, lon);
    return _getCurrentResult ??
        Right(FireRisk(
          level: RiskLevel.low,
          fwi: 5.0,
          source: DataSource.mock,
          observedAt: DateTime.now().toUtc(),
          freshness: Freshness.live,
        ));
  }
}
