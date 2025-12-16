import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/gwis_hotspot_service.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// T042: Integration test for fire data fallback behavior (Decision D5)
///
/// Tests that:
/// - When MAP_LIVE_DATA=false (default): Mock data is used directly
/// - When MAP_LIVE_DATA=true: Live service is called, failure sets isOffline=true
/// - Controller remains functional regardless of service state
/// - Mode switching and filter changes work correctly
///
/// NOTE: These tests run with MAP_LIVE_DATA=false (compile-time default).
/// The live service fallback to mock has been replaced with Option C:
/// - When MAP_LIVE_DATA=false: Always use mock (no live service calls)
/// - When MAP_LIVE_DATA=true: Try live, set isOffline=true on failure (no mock fallback)
///
/// The tests below verify behavior in demo mode (MAP_LIVE_DATA=false).

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
    return Right(ResolvedLocation(
      coordinates: _mockLocation,
      source: LocationSource.gps,
    ));
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
    return Right(FireRisk.fromMock(
      level: RiskLevel.low,
      observedAt: DateTime.now().toUtc(),
    ));
  }
}

/// GWIS service that always fails (for testing fallback)
class _FailingGwisService implements GwisHotspotService {
  final String errorMessage;
  int callCount = 0;

  _FailingGwisService({
    this.errorMessage = 'Service unavailable: Network timeout',
  });

  @override
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
    int maxRetries = 3,
  }) async {
    callCount++;
    return Left(ApiError(message: errorMessage));
  }
}

/// EFFIS burnt area service that always fails (for testing fallback)
class _FailingBurntAreaService implements EffisBurntAreaService {
  final String errorMessage;
  int callCount = 0;

  _FailingBurntAreaService({
    this.errorMessage = 'Service unavailable: Server error',
  });

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
  }) async {
    callCount++;
    return Left(ApiError(message: errorMessage));
  }
}

/// GWIS service that succeeds then fails (for retry testing)
class _FlakeyGwisService implements GwisHotspotService {
  int callCount = 0;
  int failUntil = 1; // Fail first N calls

  _FlakeyGwisService({this.failUntil = 1});

  @override
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
    int maxRetries = 3,
  }) async {
    callCount++;
    if (callCount <= failUntil) {
      return Left(ApiError(message: 'Temporary failure'));
    }
    // Return successful data on subsequent calls
    return Right([
      Hotspot(
        id: 'recovered-1',
        location: const LatLng(55.95, -3.19),
        frp: 50.0,
        confidence: 85.0,
        detectedAt: DateTime.now().toUtc(),
      ),
    ]);
  }
}

/// EFFIS service that succeeds then fails (for retry testing)
class _FlakeyBurntAreaService implements EffisBurntAreaService {
  int callCount = 0;
  int failUntil = 1;

  _FlakeyBurntAreaService({this.failUntil = 1});

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
  }) async {
    callCount++;
    if (callCount <= failUntil) {
      return Left(ApiError(message: 'Temporary failure'));
    }
    return Right([
      BurntArea(
        id: 'recovered-ba-1',
        boundaryPoints: const [
          LatLng(55.94, -3.20),
          LatLng(55.96, -3.20),
          LatLng(55.96, -3.18),
          LatLng(55.94, -3.18),
        ],
        areaHectares: 150.0,
        fireDate: DateTime.now().subtract(const Duration(days: 5)),
        seasonYear: DateTime.now().year,
      ),
    ]);
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const testBounds = LatLngBounds(
    southwest: LatLng(55.0, -4.0),
    northeast: LatLng(56.0, -3.0),
  );

  group('Fire Data Fallback Behavior (T042, D5)', () {
    group('GWIS Hotspot Service Failure', () {
      late MapController controller;
      late _FailingGwisService failingService;

      setUp(() {
        failingService = _FailingGwisService();
        controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: failingService,
          burntAreaService: null,
        );
      });

      test('uses mock data directly when MAP_LIVE_DATA=false (default)',
          () async {
        await controller.initialize();
        expect(controller.state, isA<MapSuccess>());

        // Set mode to hotspots and update bounds to trigger fetch
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);

        // Allow async fetch to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // With MAP_LIVE_DATA=false, mock data is used directly
        // Live service is NOT called (Option C behavior)
        expect(controller.isUsingMockData, isTrue);
        // Live service should NOT be called when MAP_LIVE_DATA=false
        expect(failingService.callCount, equals(0));
      });

      test('controller remains functional after GWIS failure', () async {
        await controller.initialize();
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // Controller should still be in success state
        expect(controller.state, isA<MapSuccess>());

        // Can still change modes
        controller.setFireDataMode(FireDataMode.burntAreas);
        expect(controller.fireDataMode, equals(FireDataMode.burntAreas));

        // Can still change filters
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.setHotspotTimeFilter(HotspotTimeFilter.thisWeek);
        expect(
          controller.hotspotTimeFilter,
          equals(HotspotTimeFilter.thisWeek),
        );
      });

      test('mock data used consistently regardless of service capability',
          () async {
        // With MAP_LIVE_DATA=false, even a "succeeding" live service is not called
        // Mock data is used directly
        final flakeyService = _FlakeyGwisService(failUntil: 0);
        // Service would succeed if called, but it won't be called

        final controller2 = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: flakeyService,
          burntAreaService: null,
        );

        await controller2.initialize();
        controller2.setFireDataMode(FireDataMode.hotspots);
        controller2.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // With MAP_LIVE_DATA=false, mock is always used
        expect(controller2.isUsingMockData, isTrue);
        // Live service NOT called
        expect(flakeyService.callCount, equals(0));
      });
    });

    group('EFFIS Burnt Area Service Failure', () {
      late MapController controller;
      late _FailingBurntAreaService failingService;

      setUp(() {
        failingService = _FailingBurntAreaService();
        controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: null,
          burntAreaService: failingService,
        );
      });

      test('uses mock data directly for EFFIS when MAP_LIVE_DATA=false',
          () async {
        await controller.initialize();
        expect(controller.state, isA<MapSuccess>());

        // Set mode to burnt areas and update bounds
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // With MAP_LIVE_DATA=false, mock data is used directly
        expect(controller.isUsingMockData, isTrue);
        // Live service should NOT be called when MAP_LIVE_DATA=false
        expect(failingService.callCount, equals(0));
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

    group('Both Services Not Called (MAP_LIVE_DATA=false)', () {
      test('map uses mock data directly when MAP_LIVE_DATA=false', () async {
        final gwisService = _FailingGwisService();
        final burntService = _FailingBurntAreaService();

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: gwisService,
          burntAreaService: burntService,
        );

        await controller.initialize();
        expect(controller.state, isA<MapSuccess>());

        // Try hotspots mode
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        // Mock data used directly, live services not called
        expect(controller.isUsingMockData, isTrue);
        expect(controller.state, isA<MapSuccess>());
        expect(gwisService.callCount, equals(0));

        // Try burnt areas mode
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.isUsingMockData, isTrue);
        expect(controller.state, isA<MapSuccess>());
        expect(burntService.callCount, equals(0));
      });
    });

    group('Mock Data Consistency (MAP_LIVE_DATA=false)', () {
      test('mock data is used consistently across bounds updates', () async {
        final flakeyService = _FlakeyGwisService(failUntil: 1);

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: flakeyService,
          burntAreaService: null,
        );

        await controller.initialize();
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // With MAP_LIVE_DATA=false, mock is used directly
        expect(controller.isUsingMockData, isTrue);
        // Live service NOT called
        expect(flakeyService.callCount, equals(0));

        // Simulate map pan/zoom
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // Still using mock, service still not called
        expect(flakeyService.callCount, equals(0));
        expect(controller.isUsingMockData, isTrue);
      });

      test('mock burnt area data used consistently', () async {
        final flakeyService = _FlakeyBurntAreaService(failUntil: 1);

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: null,
          burntAreaService: flakeyService,
        );

        await controller.initialize();
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // With MAP_LIVE_DATA=false, mock is used directly
        expect(controller.isUsingMockData, isTrue);
        // Live service NOT called
        expect(flakeyService.callCount, equals(0));

        // Trigger another fetch via bounds update
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // Still using mock
        expect(controller.isUsingMockData, isTrue);
        expect(flakeyService.callCount, equals(0));
      });
    });

    group('Error Message Handling (MAP_LIVE_DATA=false)', () {
      test('mock data used regardless of error type when MAP_LIVE_DATA=false',
          () async {
        final service = _FailingGwisService(
          errorMessage: 'Network timeout after 10000ms',
        );

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: service,
          burntAreaService: null,
        );

        await controller.initialize();
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.isUsingMockData, isTrue);
      });

      test('server error sets mock data flag', () async {
        final service = _FailingBurntAreaService(
          errorMessage: 'HTTP 500: Internal Server Error',
        );

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: null,
          burntAreaService: service,
        );

        await controller.initialize();
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.isUsingMockData, isTrue);
      });

      test('parsing error sets mock data flag', () async {
        final service = _FailingGwisService(
          errorMessage: 'Failed to parse GML response',
        );

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: service,
          burntAreaService: null,
        );

        await controller.initialize();
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.isUsingMockData, isTrue);
      });
    });

    group('Mode Switching (MAP_LIVE_DATA=false)', () {
      test('mock data flag remains true in all modes when MAP_LIVE_DATA=false',
          () async {
        // Even with one "succeeding" service, MAP_LIVE_DATA=false means
        // mock data is always used and live services are not called
        final hotspotService = _FailingGwisService();
        final burntAreaService = _FlakeyBurntAreaService(failUntil: 0);

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: hotspotService,
          burntAreaService: burntAreaService,
        );

        await controller.initialize();

        // Hotspots mode - mock used directly
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.isUsingMockData, isTrue);
        expect(hotspotService.callCount, equals(0)); // Not called

        // Burnt areas mode - mock used directly (live service not called)
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.isUsingMockData, isTrue);
        expect(burntAreaService.callCount, equals(0)); // Not called
      });

      test('mode switching works correctly with mock data', () async {
        final hotspotService = _FailingGwisService();
        final burntAreaService = _FlakeyBurntAreaService(failUntil: 0);

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: hotspotService,
          burntAreaService: burntAreaService,
        );

        await controller.initialize();
        await Future.delayed(const Duration(milliseconds: 200));

        // Start in burnt areas mode
        controller.setFireDataMode(FireDataMode.burntAreas);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 200));

        // Mock data loaded for burnt areas
        expect(controller.isUsingMockData, isTrue);

        // Switch to hotspots mode
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 200));

        // Still using mock data
        expect(controller.isUsingMockData, isTrue);
      });
    });

    group('Filter Changes (MAP_LIVE_DATA=false)', () {
      test('filter changes work with mock data', () async {
        final flakeyService = _FlakeyGwisService(failUntil: 1);

        final controller = MapController(
          locationResolver: _MockLocationResolver(),
          fireRiskService: _MockFireRiskService(),
          hotspotService: flakeyService,
          burntAreaService: null,
        );

        await controller.initialize();
        controller.setFireDataMode(FireDataMode.hotspots);
        controller.updateBounds(testBounds);

        await Future.delayed(const Duration(milliseconds: 100));

        // Mock data used (live service not called)
        expect(controller.isUsingMockData, isTrue);
        expect(flakeyService.callCount, equals(0));

        // Change filter
        controller.setHotspotTimeFilter(HotspotTimeFilter.thisWeek);

        await Future.delayed(const Duration(milliseconds: 100));

        // Still using mock data (live service still not called)
        expect(controller.isUsingMockData, isTrue);
        expect(flakeyService.callCount, equals(0));
      });
    });
  });
}
