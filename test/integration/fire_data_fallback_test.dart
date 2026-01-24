import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

import '../helpers/mock_hotspot_orchestrator.dart';

/// T042: Integration test for fire data fallback behavior (Decision D5)
///
/// Tests that:
/// - When MAP_LIVE_DATA=false (default): Mock data is used via orchestrator
/// - Controller remains functional regardless of service state
/// - Mode switching and filter changes work correctly
///
/// NOTE: These tests run with MAP_LIVE_DATA=false (compile-time default).
/// The orchestrator handles the FIRMS → GWIS WMS → Mock fallback chain.

// =============================================================================
// Mock Services
// =============================================================================

/// Mock location resolver for testing
class _MockLocationResolver implements LocationResolver {
  final LatLng _mockLocation;

  _MockLocationResolver({LatLng? location})
      : _mockLocation = location ?? const LatLng(55.9533, -3.1883);

  @override
  Future<Either<LocationError, ResolvedLocation>> getLatLon({
    bool allowDefault = true,
  }) async {
    return Right(
      ResolvedLocation(coordinates: _mockLocation, source: LocationSource.gps),
    );
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {}

  @override
  Future<void> clearManualLocation() async {}

  @override
  Future<(LatLng, String?)?> loadCachedManualLocation() async => null;
}

/// Mock fire risk service
class _MockFireRiskService implements FireRiskService {
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    return Right(
      FireRisk.fromMock(
        level: RiskLevel.low,
        observedAt: DateTime.now().toUtc(),
      ),
    );
  }
}

/// EFFIS burnt area service that always fails (for testing fallback)
class _FailingBurntAreaService implements EffisBurntAreaService {
  int callCount = 0;

  _FailingBurntAreaService();

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
    int? maxFeatures,
    bool skipLiveApi = false,
  }) async {
    callCount++;
    return Left(ApiError(message: 'Service unavailable: Server error'));
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip all tests on web platform - mock services use rootBundle.loadString
  // which doesn't work in the Chrome test environment
  if (kIsWeb) {
    test(
      'skipped on web platform',
      () {},
      skip: 'rootBundle.loadString hangs on web',
    );
    return;
  }

  const testBounds = LatLngBounds(
    southwest: LatLng(55.0, -4.0),
    northeast: LatLng(56.0, -3.0),
  );

  group('Fire Data Fallback Behavior (T042, D5)', () {
    group('Hotspot Service via Orchestrator', () {
      late MapController controller;
      late MockHotspotOrchestrator mockOrchestrator;

      setUp(() {
        mockOrchestrator = MockHotspotOrchestrator();
        controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotOrchestrator: mockOrchestrator,
          burntAreaService: null,
        );
      });

      tearDown(() {
        controller.dispose();
      });

      test(
        'uses mock data directly when MAP_LIVE_DATA=false (default)',
        () async {
          await controller.initialize();
          expect(controller.state, isA<MapSuccess>());

          // Set mode to hotspots and update bounds to trigger fetch
          controller.setFireDataMode(FireDataMode.hotspots);
          controller.updateBounds(testBounds);

          // Allow async fetch to complete
          await Future.delayed(const Duration(milliseconds: 100));

          // With MAP_LIVE_DATA=false, mock data is used directly (skipping orchestrator)
          expect(controller.isUsingMockData, isTrue);
          // Orchestrator is NOT called when MAP_LIVE_DATA=false
          expect(mockOrchestrator.callCount, equals(0));
        },
      );

      test('controller remains functional after hotspot fetch', () async {
        await controller.initialize();
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // Controller should still be in success state
        expect(controller.state, isA<MapSuccess>());

        // Can still change modes
        controller.setFireDataMode(FireDataMode.burntAreas);
        expect(controller.fireDataMode, equals(FireDataMode.burntAreas));

        // Wait for burnt area fetch to complete before changing modes again
        await Future.delayed(const Duration(milliseconds: 200));

        // Can still change filters
        controller.setFireDataMode(FireDataMode.hotspots);
        await Future.delayed(const Duration(milliseconds: 100));
        controller.setHotspotTimeFilter(HotspotTimeFilter.thisWeek);
        expect(
          controller.hotspotTimeFilter,
          equals(HotspotTimeFilter.thisWeek),
        );

        // Wait for all async operations to complete before tearDown disposes
        await Future.delayed(const Duration(milliseconds: 200));
      });

      test(
        'orchestrator returns hotspots correctly',
        () async {
          // NOTE: When MAP_LIVE_DATA=false, the orchestrator is NOT called.
          // This test verifies that mock hotspots are loaded directly.
          await controller.initialize();
          controller.setFireDataMode(FireDataMode.hotspots);
          controller.updateBounds(testBounds);

          await Future.delayed(const Duration(milliseconds: 100));

          // Controller received hotspots from mock service (not orchestrator)
          expect(controller.hotspots.length, greaterThan(0));
          // Orchestrator was not called
          expect(mockOrchestrator.callCount, equals(0));
        },
        skip:
            'Orchestrator not called when MAP_LIVE_DATA=false - testing mock path instead',
      );

      test(
        'tracks data source from orchestrator',
        () async {
          // NOTE: When MAP_LIVE_DATA=false, the orchestrator is NOT called.
          // Data source tracking from orchestrator cannot be tested in this environment.
          // Skip this test.
        },
        skip:
            'Cannot test orchestrator data source when MAP_LIVE_DATA=false (feature flag is const)',
      );
    });

    group('EFFIS Burnt Area Service Failure', () {
      late MapController controller;
      late _FailingBurntAreaService failingService;

      setUp(() {
        failingService = _FailingBurntAreaService();
        controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotOrchestrator: MockHotspotOrchestrator(),
          burntAreaService: failingService,
        );
      });

      tearDown(() {
        controller.dispose();
      });

      test('uses mock data for burnt areas when service fails', () async {
        await controller.initialize();
        expect(controller.state, isA<MapSuccess>());

        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // Mock data used when live service fails
        expect(controller.isUsingMockData, isTrue);
        expect(controller.state, isA<MapSuccess>());
      });

      test('controller remains functional after EFFIS failure', () async {
        await controller.initialize();
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // Controller should still be in success state
        expect(controller.state, isA<MapSuccess>());

        // Can still change modes
        controller.setFireDataMode(FireDataMode.hotspots);
        expect(controller.fireDataMode, equals(FireDataMode.hotspots));

        // Can still change filters
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.setBurntAreaSeasonFilter(BurntAreaSeasonFilter.lastSeason);
        expect(
          controller.burntAreaSeasonFilter,
          equals(BurntAreaSeasonFilter.lastSeason),
        );
      });
    });

    group('Mode Switching with Orchestrator', () {
      late MapController controller;
      late MockHotspotOrchestrator mockOrchestrator;

      setUp(() {
        mockOrchestrator = MockHotspotOrchestrator();
        controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotOrchestrator: mockOrchestrator,
          burntAreaService: _FailingBurntAreaService(),
        );
      });

      tearDown(() {
        controller.dispose();
      });

      test('switching between modes works correctly', () async {
        await controller.initialize();

        // Start in hotspots mode
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.fireDataMode, equals(FireDataMode.hotspots));
        // When MAP_LIVE_DATA=false, orchestrator is NOT called
        expect(mockOrchestrator.callCount, equals(0));

        // Switch to burnt areas mode
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.fireDataMode, equals(FireDataMode.burntAreas));

        // Switch back to hotspots
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.fireDataMode, equals(FireDataMode.hotspots));
      });

      test('hotspots cleared when switching to burnt areas mode', () async {
        // When MAP_LIVE_DATA=false, mock data is loaded directly (not from orchestrator)
        await controller.initialize();
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        // Mock hotspots loaded directly (not from orchestrator)
        expect(controller.hotspots.length, greaterThan(0));

        // Switch to burnt areas - hotspots should be cleared
        controller.setFireDataMode(FireDataMode.burntAreas);
        expect(controller.hotspots, isEmpty);
      });
    });

    group('Filter Changes with Orchestrator', () {
      late MapController controller;
      late MockHotspotOrchestrator mockOrchestrator;

      setUp(() {
        mockOrchestrator = MockHotspotOrchestrator();
        controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotOrchestrator: mockOrchestrator,
          burntAreaService: null,
        );
      });

      tearDown(() {
        controller.dispose();
      });

      test(
        'filter changes trigger refetch via orchestrator',
        () async {
          // When MAP_LIVE_DATA=false, orchestrator is skipped, but filter changes
          // should still update state
          await controller.initialize();
          controller.setFireDataMode(FireDataMode.hotspots);
          controller.updateBounds(testBounds);
          await Future.delayed(const Duration(milliseconds: 100));

          // Orchestrator not called when MAP_LIVE_DATA=false
          expect(mockOrchestrator.callCount, equals(0));

          // Change filter - should still work (updates internal state)
          controller.setHotspotTimeFilter(HotspotTimeFilter.thisWeek);
          expect(
            controller.hotspotTimeFilter,
            equals(HotspotTimeFilter.thisWeek),
          );
        },
        skip:
            'Cannot test orchestrator filter changes when MAP_LIVE_DATA=false',
      );

      test(
        'orchestrator receives correct bounds on update',
        () async {
          // When MAP_LIVE_DATA=false, orchestrator is not called
          await controller.initialize();
          controller.setFireDataMode(FireDataMode.hotspots);
          controller.updateBounds(testBounds);
          await Future.delayed(const Duration(milliseconds: 100));

          // Orchestrator not called when MAP_LIVE_DATA=false
          expect(mockOrchestrator.callCount, equals(0));
          expect(mockOrchestrator.lastRequestedBounds, isNull);
        },
        skip: 'Cannot test orchestrator bounds when MAP_LIVE_DATA=false',
      );
    });
  });
}
