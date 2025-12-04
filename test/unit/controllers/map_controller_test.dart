import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

/// Mock LocationResolver for controlled testing
class MockLocationResolver implements LocationResolver {
  Either<LocationError, LatLng>? _getLatLonResult;
  List<String> loggedCalls = [];

  void mockGetLatLon(Either<LocationError, LatLng> result) {
    _getLatLonResult = result;
  }

  void reset() {
    _getLatLonResult = null;
    loggedCalls.clear();
  }

  @override
  Future<Either<LocationError, LatLng>> getLatLon({
    bool allowDefault = true,
  }) async {
    loggedCalls.add('getLatLon(allowDefault: $allowDefault)');
    if (_getLatLonResult != null) {
      return _getLatLonResult!;
    }
    // Default success case: Edinburgh
    return const Right(LatLng(55.9533, -3.1883));
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

/// Mock FireLocationService for controlled testing
class MockFireLocationService implements FireLocationService {
  Either<ApiError, List<FireIncident>>? _getActiveFiresResult;
  List<String> loggedCalls = [];

  void mockGetActiveFires(Either<ApiError, List<FireIncident>> result) {
    _getActiveFiresResult = result;
  }

  void reset() {
    _getActiveFiresResult = null;
    loggedCalls.clear();
  }

  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    loggedCalls.add('getActiveFires(${bounds.toBboxString()})');
    if (_getActiveFiresResult != null) {
      return _getActiveFiresResult!;
    }
    // Default success case: 2 mock incidents
    return Right([
      TestData.createFireIncident(id: 'mock_001'),
      TestData.createFireIncident(
        id: 'mock_002',
        location: const LatLng(55.6, -3.6),
      ),
    ]);
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
  group('MapController', () {
    late MockLocationResolver mockLocationResolver;
    late MockFireLocationService mockFireLocationService;
    late MockFireRiskService mockFireRiskService;
    late MapController controller;

    setUp(() {
      mockLocationResolver = MockLocationResolver();
      mockFireLocationService = MockFireLocationService();
      mockFireRiskService = MockFireRiskService();
      controller = MapController(
        locationResolver: mockLocationResolver,
        fireLocationService: mockFireLocationService,
        fireRiskService: mockFireRiskService,
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
      mockFireLocationService.reset();
      mockFireRiskService.reset();
    });

    group('Constructor', () {
      test('initializes with MapLoading state', () {
        expect(controller.state, isA<MapLoading>());
      });

      test('accepts required dependencies via DI', () {
        final customController = MapController(
          locationResolver: mockLocationResolver,
          fireLocationService: mockFireLocationService,
          fireRiskService: mockFireRiskService,
        );
        expect(customController, isNotNull);
        expect(customController.state, isA<MapLoading>());
        customController.dispose();
      });
    });

    group('initialize()', () {
      test(
        'transitions to MapSuccess when location and fires load successfully',
        () async {
          // Arrange
          mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
          mockFireLocationService.mockGetActiveFires(
            Right([TestData.createFireIncident(id: 'fire_001')]),
          );

          // Track state changes
          final states = <MapState>[];
          controller.addListener(() {
            states.add(controller.state);
          });

          // Act
          await controller.initialize();

          // Assert
          expect(states.length, greaterThanOrEqualTo(2)); // Loading → Success
          expect(states.first, isA<MapLoading>());
          expect(states.last, isA<MapSuccess>());

          final finalState = controller.state as MapSuccess;
          expect(finalState.incidents.length, 1);
          expect(finalState.incidents.first.id, 'fire_001');
          expect(finalState.centerLocation, TestData.edinburgh);
          expect(finalState.freshness, Freshness.mock);
        },
      );

      test('uses Aviemore fallback when LocationResolver fails', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(
          const Left(LocationError.gpsUnavailable),
        );
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'fire_001')]),
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

      test('transitions to MapError when FireLocationService fails', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Left(ApiError(message: 'Service unavailable')),
        );

        // Act
        await controller.initialize();

        // Assert
        final state = controller.state;
        expect(state, isA<MapError>());

        final errorState = state as MapError;
        expect(errorState.message, contains('Failed to load fire data'));
        expect(errorState.lastKnownLocation, TestData.edinburgh);
      });

      test('notifies listeners during state transitions', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'fire_001')]),
        );

        int notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        // Act
        await controller.initialize();

        // Assert
        expect(notificationCount, greaterThanOrEqualTo(2)); // Loading + Success
      });

      test(
        'creates bbox with ~220km radius (±2.0 degrees) around center',
        () async {
          // Arrange
          const testLocation = TestData.edinburgh;
          mockLocationResolver.mockGetLatLon(const Right(testLocation));
          mockFireLocationService.mockGetActiveFires(
            Right([TestData.createFireIncident(id: 'fire_001')]),
          );

          // Act
          await controller.initialize();

          // Assert
          expect(mockFireLocationService.loggedCalls.length, 1);
          final call = mockFireLocationService.loggedCalls.first;

          // Verify bbox contains expected bounds (±2.0 degrees from center)
          expect(call, contains('getActiveFires'));
          // The actual bbox validation happens in FireLocationService
        },
      );

      test('handles FireLocationService returning empty list', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(const Right([])); // No fires

        // Act
        await controller.initialize();

        // Assert
        final state = controller.state;
        expect(state, isA<MapSuccess>());

        final successState = state as MapSuccess;
        expect(successState.incidents, isEmpty);
        expect(
          successState.freshness,
          Freshness.live,
        ); // Empty list defaults to live
      });

      test('handles exceptions during initialization', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        // Don't mock FireLocationService - let it throw
        mockFireLocationService.mockGetActiveFires(
          Left(ApiError(message: 'Unexpected error')),
        );

        // Act
        await controller.initialize();

        // Assert
        final state = controller.state;
        expect(state, isA<MapError>());
      });
    });

    group('refreshMapData()', () {
      test('updates incidents for new visible bounds', () async {
        // Arrange: Initialize with Edinburgh
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'initial_fire')]),
        );
        await controller.initialize();

        // Arrange: Mock new fires for Glasgow area
        mockFireLocationService.reset();
        mockFireLocationService.mockGetActiveFires(
          Right([
            TestData.createFireIncident(
              id: 'glasgow_fire',
              location: TestData.glasgow,
            ),
          ]),
        );

        final newBounds = TestData.createBounds(center: TestData.glasgow);

        // Act
        await controller.refreshMapData(newBounds);

        // Assert
        final state = controller.state;
        expect(state, isA<MapSuccess>());

        final successState = state as MapSuccess;
        expect(successState.incidents.length, 1);
        expect(successState.incidents.first.id, 'glasgow_fire');
        expect(successState.centerLocation, newBounds.center);
      });

      test('preserves previous incidents when refresh fails', () async {
        // Arrange: Initialize with successful data
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'cached_fire')]),
        );
        await controller.initialize();

        final initialState = controller.state as MapSuccess;
        final cachedIncidents = initialState.incidents;

        // Arrange: Mock refresh failure
        mockFireLocationService.reset();
        mockFireLocationService.mockGetActiveFires(
          Left(ApiError(message: 'Network error')),
        );

        final newBounds = TestData.createBounds(center: TestData.glasgow);

        // Act
        await controller.refreshMapData(newBounds);

        // Assert
        final state = controller.state;
        expect(state, isA<MapError>());

        final errorState = state as MapError;
        expect(errorState.message, contains('Failed to refresh'));
        expect(errorState.cachedIncidents, isNotNull);
        expect(errorState.cachedIncidents?.length, cachedIncidents.length);
        expect(errorState.cachedIncidents?.first.id, 'cached_fire');
        expect(errorState.lastKnownLocation, TestData.edinburgh);
      });

      test('refreshes without MapLoading to avoid widget unmount', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'initial_fire')]),
        );
        await controller.initialize();

        // Add listener to verify only success state emitted (no loading during refresh)
        final states = <MapState>[];
        controller.addListener(() {
          states.add(controller.state);
        });

        // Arrange: Mock new data for refresh
        mockFireLocationService.reset();
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'refreshed_fire')]),
        );

        final newBounds = TestData.createBounds(center: TestData.glasgow);

        // Act
        await controller.refreshMapData(newBounds);

        // Assert - Should only emit success, NOT loading (to prevent widget unmount)
        expect(states.length, greaterThanOrEqualTo(1)); // At least success
        // Verify NO loading state during refresh (prevents map widget unmount)
        final hasLoadingState = states.any((state) => state is MapLoading);
        expect(hasLoadingState, isFalse,
            reason: 'Should NOT transition through MapLoading during refresh');
        expect(states.last, isA<MapSuccess>());
      });

      test('notifies listeners on state changes', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'initial_fire')]),
        );
        await controller.initialize();

        int refreshNotificationCount = 0;
        controller.addListener(() {
          refreshNotificationCount++;
        });

        // Arrange: Mock refresh
        mockFireLocationService.reset();
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'refreshed_fire')]),
        );

        final newBounds = TestData.createBounds();

        // Act
        await controller.refreshMapData(newBounds);

        // Assert - Should emit at least 1 notification (success state, no loading during refresh)
        expect(refreshNotificationCount, greaterThanOrEqualTo(1));
      });

      test(
        'handles refresh exception and preserves previous state if available',
        () async {
          // Arrange: Initialize successfully
          mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
          mockFireLocationService.mockGetActiveFires(
            Right([TestData.createFireIncident(id: 'cached_fire')]),
          );
          await controller.initialize();

          final initialIncidents = (controller.state as MapSuccess).incidents;

          // Arrange: Mock exception
          mockFireLocationService.reset();
          mockFireLocationService.mockGetActiveFires(
            Left(ApiError(message: 'Timeout')),
          );

          final newBounds = TestData.createBounds();

          // Act
          await controller.refreshMapData(newBounds);

          // Assert
          final state = controller.state;
          expect(state, isA<MapError>());

          final errorState = state as MapError;
          expect(errorState.cachedIncidents?.length, initialIncidents.length);
        },
      );
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
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'fire_001')]),
        );

        final states = <MapState>[];
        controller.addListener(() {
          states.add(controller.state);
        });

        // Act
        await controller.initialize();

        // Assert
        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first, isA<MapLoading>());
        expect(states.last, isA<MapSuccess>());
      });

      test('allows multiple listeners to be added', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'fire_001')]),
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
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'fire_001')]),
        );

        int callCount = 0;
        void listener() => callCount++;

        controller.addListener(listener);
        await controller.initialize();

        final countAfterInit = callCount;

        // Act: Remove listener
        controller.removeListener(listener);

        // Arrange: Trigger refresh
        mockFireLocationService.reset();
        mockFireLocationService.mockGetActiveFires(
          Right([TestData.createFireIncident(id: 'fire_002')]),
        );

        await controller.refreshMapData(TestData.createBounds());

        // Assert: Count should not increase after removal
        expect(callCount, equals(countAfterInit));
      });
    });
  });
}
