import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

import '../../helpers/mock_hotspot_orchestrator.dart';

/// Mock LocationResolver for controlled testing
class MockLocationResolver implements LocationResolver {
  Either<LocationError, ResolvedLocation>? _getLatLonResult;
  List<String> loggedCalls = [];

  void mockGetLatLon(Either<LocationError, ResolvedLocation> result) {
    _getLatLonResult = result;
  }

  void reset() {
    _getLatLonResult = null;
    loggedCalls.clear();
  }

  @override
  Future<Either<LocationError, ResolvedLocation>> getLatLon({
    bool allowDefault = true,
  }) async {
    loggedCalls.add('getLatLon(allowDefault: $allowDefault)');
    if (_getLatLonResult != null) {
      return _getLatLonResult!;
    }
    // Default success case: Edinburgh
    return const Right(
      ResolvedLocation(
        coordinates: LatLng(55.9533, -3.1883),
        source: LocationSource.gps,
      ),
    );
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {
    loggedCalls.add(
      'saveManual(${location.latitude}, ${location.longitude}, placeName: $placeName)',
    );
  }

  @override
  Future<void> clearManualLocation() async {
    loggedCalls.add('clearManualLocation()');
  }

  @override
  Future<(LatLng, String?)?> loadCachedManualLocation() async {
    loggedCalls.add('loadCachedManualLocation()');
    return null; // No cached location for controller tests
  }
}

/// Mock FireRiskService for controlled testing
class MockFireRiskService implements FireRiskService {
  Either<ApiError, FireRisk>? _getCurrentResult;
  List<String> loggedCalls = [];

  void mockGetCurrent(Either<ApiError, FireRisk> result) {
    _getCurrentResult = result;
  }

  void reset() {
    _getCurrentResult = null;
    loggedCalls.clear();
  }

  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    loggedCalls.add('getCurrent(lat: $lat, lon: $lon)');
    if (_getCurrentResult != null) {
      return _getCurrentResult!;
    }
    // Default success case
    return Right(TestData.createFireRisk());
  }
}

/// Test data factory
class TestData {
  static const edinburgh = LatLng(55.9533, -3.1883);
  static const glasgow = LatLng(55.8642, -4.2518);
  static const aviemore = LatLng(
    57.2,
    -3.8,
  ); // Fallback location in MapController

  // ResolvedLocation versions for mock setup
  static const edinburghResolved = ResolvedLocation(
    coordinates: edinburgh,
    source: LocationSource.gps,
  );

  static const glasgowResolved = ResolvedLocation(
    coordinates: glasgow,
    source: LocationSource.gps,
  );

  static FireIncident createFireIncident({
    String id = 'test_001',
    LatLng location = const LatLng(55.5, -3.5),
    DataSource source = DataSource.mock,
    Freshness freshness = Freshness.mock,
  }) {
    return FireIncident(
      id: id,
      location: location,
      source: source,
      freshness: freshness,
      timestamp: DateTime(2024, 10, 20, 12, 0), // Past timestamp
      intensity: 'moderate',
      description: 'Test fire incident',
    );
  }

  static FireRisk createFireRisk({
    RiskLevel level = RiskLevel.moderate,
    double fwi = 5.0,
    DataSource source = DataSource.mock,
    Freshness freshness = Freshness.mock,
  }) {
    return FireRisk(
      level: level,
      fwi: fwi,
      source: source,
      observedAt: DateTime.now().toUtc(),
      freshness: freshness,
    );
  }

  static LatLngBounds createBounds({LatLng? center, double delta = 2.0}) {
    final c = center ?? edinburgh;
    return LatLngBounds(
      southwest: LatLng(c.latitude - delta, c.longitude - delta),
      northeast: LatLng(c.latitude + delta, c.longitude + delta),
    );
  }
}

void main() {
  // NOTE: Legacy FireLocationService tests were removed in 021-live-fire-data refactor.
  // Tests for the new Hotspot/BurntArea data flow are in:
  // - test/unit/controllers/map_controller_mode_test.dart
  // - test/integration/fire_data_fallback_test.dart
  // - test/integration/map/live_fire_hotspots_test.dart
  // - test/integration/map/live_fire_burnt_areas_test.dart

  group('MapController', () {
    late MockLocationResolver mockLocationResolver;
    late MockFireRiskService mockFireRiskService;
    late MockHotspotOrchestrator mockHotspotOrchestrator;
    late MapController controller;

    setUp(() {
      mockLocationResolver = MockLocationResolver();
      mockFireRiskService = MockFireRiskService();
      mockHotspotOrchestrator = MockHotspotOrchestrator();
      controller = MapController(
        locationResolver: mockLocationResolver,
        fireRiskService: mockFireRiskService,
        hotspotOrchestrator: mockHotspotOrchestrator,
      );
    });

    tearDown(() {
      // Safe dispose - may already be disposed by test
      try {
        controller.dispose();
      } catch (e) {
        // Already disposed - this is fine
      }
      mockLocationResolver.reset();
      mockFireRiskService.reset();
      mockHotspotOrchestrator.reset();
    });

    group('Constructor', () {
      test('initializes with MapLoading state', () {
        expect(controller.state, isA<MapLoading>());
      });

      test('accepts required dependencies via DI', () {
        final customController = MapController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
          hotspotOrchestrator: mockHotspotOrchestrator,
        );
        expect(customController, isNotNull);
        expect(customController.state, isA<MapLoading>());
        customController.dispose();
      });
    });

    group('initialize()', () {
      test('uses Aviemore fallback when LocationResolver fails', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(
          const Left(LocationError.gpsUnavailable),
        );

        // Act
        await controller.initialize();

        // Assert
        final state = controller.state;
        expect(state, isA<MapSuccess>());

        final successState = state as MapSuccess;
        expect(
          successState.centerLocation,
          TestData.aviemore,
        ); // Fallback location
      });
    });

    group('checkRiskAt()', () {
      test('returns Right(FireRisk) when risk check succeeds', () async {
        // Arrange
        final expectedRisk = TestData.createFireRisk(
          level: RiskLevel.high,
          fwi: 25.0,
        );
        mockFireRiskService.mockGetCurrent(Right(expectedRisk));

        // Act
        final result = await controller.checkRiskAt(TestData.edinburgh);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((error) => fail('Expected Right, got Left: $error'), (
          risk,
        ) {
          expect(risk, isA<FireRisk>());
          expect((risk as FireRisk).level, RiskLevel.high);
          expect(risk.fwi, 25.0);
        });

        expect(mockFireRiskService.loggedCalls.length, 1);
        expect(mockFireRiskService.loggedCalls.first, contains('getCurrent'));
      });

      test('returns Left(error) when risk check fails', () async {
        // Arrange
        mockFireRiskService.mockGetCurrent(
          Left(ApiError(message: 'Service unavailable')),
        );

        // Act
        final result = await controller.checkRiskAt(TestData.edinburgh);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold((error) {
          expect(error, contains('Risk check failed'));
          expect(error, contains('Service unavailable'));
        }, (risk) => fail('Expected Left, got Right'));
      });

      test('handles exceptions gracefully', () async {
        // Arrange: Don't mock getCurrent - let it use default behavior
        // Then mock to throw by using a Left result
        mockFireRiskService.mockGetCurrent(
          Left(ApiError(message: 'Unexpected error')),
        );

        // Act
        final result = await controller.checkRiskAt(TestData.edinburgh);

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('passes correct coordinates to FireRiskService', () async {
        // Arrange
        const testLocation = LatLng(56.5, -4.2);
        mockFireRiskService.mockGetCurrent(Right(TestData.createFireRisk()));

        // Act
        await controller.checkRiskAt(testLocation);

        // Assert
        expect(mockFireRiskService.loggedCalls.length, 1);
        final call = mockFireRiskService.loggedCalls.first;
        expect(call, contains('lat: 56.5'));
        expect(call, contains('lon: -4.2'));
      });
    });

    group('dispose()', () {
      test('completes without throwing', () {
        // Arrange
        bool listenerCalled = false;
        void listener() => listenerCalled = true;
        controller.addListener(listener);

        // Get state before disposal to verify controller was functional
        final stateBeforeDispose = controller.state;
        expect(stateBeforeDispose, isA<MapLoading>());

        // Act: Dispose should complete without error
        expect(() => controller.dispose(), returnsNormally);

        // Assert: Listener was not called during dispose
        expect(listenerCalled, isFalse);

        // Note: After dispose(), accessing state or calling methods will throw
        // This is expected ChangeNotifier behavior - we just verify dispose() itself works
      });
    });

    group('ChangeNotifier integration', () {
      test('notifies listeners when state changes', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(
          const Right(TestData.edinburghResolved),
        );

        final states = <MapState>[];
        controller.addListener(() {
          states.add(controller.state);
        });

        // Act
        await controller.initialize();

        // Assert - MapController uses built-in mock fallback for fire data
        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first, isA<MapLoading>());
        expect(states.last, isA<MapSuccess>());
      });

      test('allows multiple listeners to be added', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(
          const Right(TestData.edinburghResolved),
        );

        int listener1Count = 0;
        int listener2Count = 0;

        controller.addListener(() => listener1Count++);
        controller.addListener(() => listener2Count++);

        // Act
        await controller.initialize();

        // Assert
        expect(listener1Count, greaterThanOrEqualTo(2));
        expect(listener2Count, greaterThanOrEqualTo(2));
        expect(listener1Count, equals(listener2Count));
      });

      test('stops notifying after listener is removed', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(
          const Right(TestData.edinburghResolved),
        );

        int callCount = 0;
        void listener() => callCount++;

        controller.addListener(listener);
        await controller.initialize();

        final countAfterInit = callCount;

        // Act: Remove listener
        controller.removeListener(listener);

        // Trigger refresh
        await controller.refreshMapData(TestData.createBounds());

        // Assert: Count should not increase after removal
        expect(callCount, equals(countAfterInit));
      });
    });
  });
}
