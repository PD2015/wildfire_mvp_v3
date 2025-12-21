import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/effis_burnt_area_service.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/services/hotspot_service_orchestrator.dart';

import '../helpers/mock_hotspot_orchestrator.dart';

@GenerateMocks([
  LocationResolver,
  FireLocationService,
  FireRiskService,
  EffisBurntAreaService,
])
import 'map_controller_fallback_test.mocks.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Integration tests for MapController fallback to mock services
/// (021-live-fire-data Phase 2)
///
/// Tests that when live GWIS/EFFIS services fail, the controller
/// automatically falls back to mock services.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip all tests on web platform - mock services use rootBundle.loadString
  // which doesn't work in the Chrome test environment
  if (kIsWeb) {
    test('skipped on web platform', () {},
        skip: 'rootBundle.loadString hangs on web');
    return;
  }

  group('MapController Fallback Behavior', () {
    late MockLocationResolver mockLocationResolver;
    late MockFireLocationService mockFireLocationService;
    late MockFireRiskService mockFireRiskService;
    late MockHotspotOrchestrator mockHotspotOrchestrator;
    late MockEffisBurntAreaService mockBurntAreaService;
    MapController? controller;

    const testLocation = LatLng(55.9533, -3.1883); // Edinburgh
    const testBounds = LatLngBounds(
      southwest: LatLng(54.0, -8.0),
      northeast: LatLng(61.0, 0.0),
    );

    setUp(() {
      mockLocationResolver = MockLocationResolver();
      mockFireLocationService = MockFireLocationService();
      mockFireRiskService = MockFireRiskService();
      mockHotspotOrchestrator = MockHotspotOrchestrator();
      mockBurntAreaService = MockEffisBurntAreaService();

      // Default stubs for location resolver
      when(mockLocationResolver.loadCachedManualLocation())
          .thenAnswer((_) async => null);
      when(mockLocationResolver.getLatLon()).thenAnswer(
        (_) async => const Right(ResolvedLocation(
          coordinates: testLocation,
          source: LocationSource.gps,
        )),
      );

      // Default stub for fire location service
      when(mockFireLocationService.getActiveFires(any)).thenAnswer(
        (_) async => const Right(<FireIncident>[]),
      );
    });

    tearDown(() {
      controller?.dispose();
    });

    group('Hotspot fallback', () {
      test('uses live service when successful', () async {
        final liveHotspots = [
          Hotspot.test(
            id: 'live_1',
            location: const LatLng(57.2, -3.8),
            frp: 50.0,
          ),
        ];

        // Configure mock orchestrator to return live hotspots
        mockHotspotOrchestrator.hotspotsToReturn = liveHotspots;
        mockHotspotOrchestrator.sourceToReturn = HotspotDataSource.firms;

        controller = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
          burntAreaService: mockBurntAreaService,
        );

        await controller!.initialize();
        controller!.updateBounds(testBounds);

        // Wait for async fetch
        await Future.delayed(const Duration(milliseconds: 100));

        // When MAP_LIVE_DATA=false, mock data is used directly (orchestrator skipped)
        if (!FeatureFlags.mapLiveData) {
          expect(controller!.isUsingMockData, isTrue);
          expect(mockHotspotOrchestrator.callCount, equals(0));
        } else {
          expect(controller!.isUsingMockData, isFalse);
          expect(controller!.hotspots.length, equals(1));
          expect(controller!.hotspots.first.id, equals('live_1'));
        }
      },
          skip: FeatureFlags.mapLiveData
              ? null
              : 'Cannot test live service when MAP_LIVE_DATA=false');

      test('falls back to mock when live service fails', () async {
        // Configure mock orchestrator to simulate failure/mock fallback
        mockHotspotOrchestrator.hotspotsToReturn = [];
        mockHotspotOrchestrator.sourceToReturn = HotspotDataSource.mock;

        controller = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
          burntAreaService: mockBurntAreaService,
        );

        await controller!.initialize();
        controller!.updateBounds(testBounds);

        // Wait for async fetch + fallback
        await Future.delayed(const Duration(milliseconds: 200));

        // When MAP_LIVE_DATA=false, mock data is always used
        expect(controller!.isUsingMockData, isTrue);
      },
          skip: FeatureFlags.mapLiveData
              ? null
              : 'MAP_LIVE_DATA=false always uses mock - no fallback to test');

      test('uses mock data when orchestrator returns mock source', () async {
        // Configure mock orchestrator to return mock source
        mockHotspotOrchestrator.hotspotsToReturn = [];
        mockHotspotOrchestrator.sourceToReturn = HotspotDataSource.mock;

        controller = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
          burntAreaService: null,
        );

        await controller!.initialize();
        controller!.updateBounds(testBounds);

        // Wait for async fetch + fallback
        await Future.delayed(const Duration(milliseconds: 200));

        expect(controller!.isUsingMockData, isTrue);

        // Wait for all async operations to complete before tearDown disposes
        await Future.delayed(const Duration(milliseconds: 300));
      },
          skip: FeatureFlags.mapLiveData
              ? null
              : 'Orchestrator not called when MAP_LIVE_DATA=false');
    });

    group('Burnt area fallback', () {
      test('uses live service when successful', () async {
        // Skip test if MAP_LIVE_DATA=false (live service not called)
        if (!FeatureFlags.mapLiveData) {
          // This test requires live data mode to exercise the live service path
          // When MAP_LIVE_DATA=false, controller skips live service entirely
          // Set controller to null to avoid dispose() in tearDown affecting
          // the previous test's controller async operations
          controller = null;
          expect(FeatureFlags.mapLiveData, isFalse,
              reason:
                  'Test skipped: requires MAP_LIVE_DATA=true. Run with --dart-define=MAP_LIVE_DATA=true');
          return;
        }

        final liveBurntAreas = [
          BurntArea.test(
            id: 'live_ba_1',
            boundaryPoints: const [
              LatLng(57.0, -3.0),
              LatLng(57.1, -3.0),
              LatLng(57.1, -3.1),
              LatLng(57.0, -3.1),
            ],
            areaHectares: 50.0,
          ),
        ];

        when(mockBurntAreaService.getBurntAreas(
          bounds: anyNamed('bounds'),
          seasonFilter: anyNamed('seasonFilter'),
          timeout: anyNamed('timeout'),
          maxRetries: anyNamed('maxRetries'),
        )).thenAnswer((_) async => Right(liveBurntAreas));

        controller = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
          burntAreaService: mockBurntAreaService,
        );

        await controller!.initialize();

        // Switch to burnt areas mode
        controller!.setFireDataMode(FireDataMode.burntAreas);
        controller!.updateBounds(testBounds);

        // Wait for async fetch
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller!.isUsingMockData, isFalse);
        expect(controller!.burntAreas.length, equals(1));
        expect(controller!.burntAreas.first.id, equals('live_ba_1'));
      });

      test('falls back to mock when live service fails', () async {
        when(mockBurntAreaService.getBurntAreas(
          bounds: anyNamed('bounds'),
          seasonFilter: anyNamed('seasonFilter'),
          timeout: anyNamed('timeout'),
          maxRetries: anyNamed('maxRetries'),
        )).thenAnswer(
          (_) async => Left(ApiError(message: 'Service unavailable')),
        );

        controller = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
          burntAreaService: mockBurntAreaService,
        );

        await controller!.initialize();

        // Switch to burnt areas mode
        controller!.setFireDataMode(FireDataMode.burntAreas);
        controller!.updateBounds(testBounds);

        // Wait for async fetch + fallback
        await Future.delayed(const Duration(milliseconds: 200));

        expect(controller!.isUsingMockData, isTrue);
      });

      test('falls back to mock when burnt area service is null', () async {
        controller = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
          burntAreaService: null, // No live service
        );

        await controller!.initialize();

        // Switch to burnt areas mode
        controller!.setFireDataMode(FireDataMode.burntAreas);
        controller!.updateBounds(testBounds);

        // Wait for async fetch + fallback
        await Future.delayed(const Duration(milliseconds: 200));

        expect(controller!.isUsingMockData, isTrue);
      });
    });

    group('Mode switching', () {
      test('clears hotspots when switching to burnt areas mode', () async {
        final liveHotspots = [
          Hotspot.test(id: 'h1', location: const LatLng(57.2, -3.8)),
        ];

        // Configure mock orchestrator to return live hotspots
        mockHotspotOrchestrator.hotspotsToReturn = liveHotspots;
        mockHotspotOrchestrator.sourceToReturn = HotspotDataSource.firms;

        when(mockBurntAreaService.getBurntAreas(
          bounds: anyNamed('bounds'),
          seasonFilter: anyNamed('seasonFilter'),
          timeout: anyNamed('timeout'),
          maxRetries: anyNamed('maxRetries'),
        )).thenAnswer((_) async => const Right(<BurntArea>[]));

        controller = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
          burntAreaService: mockBurntAreaService,
        );

        await controller!.initialize();
        controller!.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller!.hotspots, isNotEmpty);

        // Switch to burnt areas
        controller!.setFireDataMode(FireDataMode.burntAreas);

        expect(controller!.hotspots, isEmpty);
        expect(controller!.clusters, isEmpty);
      });

      test('clears burnt areas when switching to hotspots mode', () async {
        final liveBurntAreas = [
          BurntArea.test(
            id: 'ba1',
            boundaryPoints: const [
              LatLng(57.0, -3.0),
              LatLng(57.1, -3.0),
              LatLng(57.1, -3.1),
            ],
          ),
        ];

        // Configure mock orchestrator to return empty hotspots
        mockHotspotOrchestrator.hotspotsToReturn = [];
        mockHotspotOrchestrator.sourceToReturn = HotspotDataSource.mock;

        when(mockBurntAreaService.getBurntAreas(
          bounds: anyNamed('bounds'),
          seasonFilter: anyNamed('seasonFilter'),
          timeout: anyNamed('timeout'),
          maxRetries: anyNamed('maxRetries'),
        )).thenAnswer((_) async => Right(liveBurntAreas));

        controller = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
          burntAreaService: mockBurntAreaService,
        );

        await controller!.initialize();

        // Start in burnt areas mode
        controller!.setFireDataMode(FireDataMode.burntAreas);
        controller!.updateBounds(testBounds);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller!.burntAreas, isNotEmpty);

        // Switch to hotspots
        controller!.setFireDataMode(FireDataMode.hotspots);

        expect(controller!.burntAreas, isEmpty);
      });
    });
  });
}
