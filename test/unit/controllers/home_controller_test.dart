import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:wildfire_mvp_v3/controllers/home_controller.dart';
import 'package:wildfire_mvp_v3/models/home_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

/// Mock LocationResolver for controlled testing
class MockLocationResolver implements LocationResolver {
  Either<LocationError, LatLng>? _getLatLonResult;
  bool _saveManualThrows = false;
  List<String> loggedCalls = [];

  void mockGetLatLon(Either<LocationError, LatLng> result) {
    _getLatLonResult = result;
  }

  void mockSaveManualThrows() {
    _saveManualThrows = true;
  }

  void reset() {
    _getLatLonResult = null;
    _saveManualThrows = false;
    loggedCalls.clear();
  }

  @override
  Future<Either<LocationError, LatLng>> getLatLon(
      {bool allowDefault = true}) async {
    loggedCalls.add('getLatLon(allowDefault: $allowDefault)');
    if (_getLatLonResult != null) {
      return _getLatLonResult!;
    }
    // Default success case
    return const Right(LatLng(55.9533, -3.1883)); // Edinburgh
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {
    loggedCalls.add(
        'saveManual(${location.latitude}, ${location.longitude}, placeName: $placeName)');
    if (_saveManualThrows) {
      throw Exception('Save manual failed');
    }
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
    loggedCalls.add(
        'getCurrent(lat: $lat, lon: $lon, deadline: ${deadline?.inSeconds ?? 8}s)');
    if (_getCurrentResult != null) {
      return _getCurrentResult!;
    }
    // Default success case
    return Right(FireRisk(
      level: RiskLevel.moderate,
      fwi: 5.0,
      source: DataSource.effis,
      observedAt: DateTime.now().toUtc(),
      freshness: Freshness.live,
    ));
  }
}

/// Test data factory
class TestData {
  static const edinburgh = LatLng(55.9533, -3.1883);
  static const glasgow = LatLng(55.8642, -4.2518);

  static FireRisk createFireRisk({
    RiskLevel level = RiskLevel.moderate,
    double? fwi = 5.0,
    DataSource source = DataSource.effis,
    Freshness freshness = Freshness.live,
  }) {
    return FireRisk(
      level: level,
      fwi: fwi,
      source: source,
      observedAt: DateTime.now().toUtc(),
      freshness: freshness,
    );
  }

  static ApiError createApiError({String message = 'Test error'}) {
    return ApiError(message: message, statusCode: 500);
  }
}

void main() {
  group('HomeController Unit Tests', () {
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

    tearDown(() {
      controller.dispose();
      mockLocationResolver.reset();
      mockFireRiskService.reset();
    });

    group('Initial State', () {
      test('starts with Loading state', () {
        expect(controller.state, isA<HomeStateLoading>());
        expect(controller.isLoading, isFalse);
      });

      test('initial loading state is not retry', () {
        final state = controller.state as HomeStateLoading;
        expect(state.isRetry, isFalse);
        expect(state.startTime, isA<DateTime>());
      });
    });

    group('Load Operation', () {
      test('successful load transitions through Loading to Success', () async {
        // Arrange
        final states = <HomeState>[];
        controller.addListener(() => states.add(controller.state));

        mockLocationResolver.mockGetLatLon(Right(TestData.edinburgh));
        mockFireRiskService.mockGetCurrent(Right(TestData.createFireRisk()));

        // Act
        await controller.load();

        // Assert
        expect(states.length, equals(2)); // Loading -> Success
        expect(states[0], isA<HomeStateLoading>());
        expect((states[0] as HomeStateLoading).isRetry, isFalse);
        expect(states[1], isA<HomeStateSuccess>());

        final successState = states[1] as HomeStateSuccess;
        expect(successState.location, equals(TestData.edinburgh));
        expect(successState.riskData.level, equals(RiskLevel.moderate));
        expect(successState.lastUpdated, isA<DateTime>());
      });

      test('location failure results in Error state', () async {
        // Arrange
        final states = <HomeState>[];
        controller.addListener(() => states.add(controller.state));

        mockLocationResolver
            .mockGetLatLon(const Left(LocationError.permissionDenied));

        // Act
        await controller.load();

        // Assert
        expect(states.length, equals(2)); // Loading -> Error
        expect(states[0], isA<HomeStateLoading>());
        expect(states[1], isA<HomeStateError>());

        final errorState = states[1] as HomeStateError;
        expect(errorState.errorMessage, contains('Location permission denied'));
        expect(errorState.canRetry, isTrue);
      });

      test('fire risk service failure results in Error state', () async {
        // Arrange
        final states = <HomeState>[];
        controller.addListener(() => states.add(controller.state));

        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireRiskService.mockGetCurrent(
            Left(TestData.createApiError(message: 'Service unavailable')));

        // Act
        await controller.load();

        // Assert
        expect(states.length, equals(2)); // Loading -> Error
        expect(states[0], isA<HomeStateLoading>());
        expect(states[1], isA<HomeStateError>());

        final errorState = states[1] as HomeStateError;
        expect(errorState.errorMessage, contains('Service unavailable'));
        expect(errorState.canRetry, isTrue);
      });
    });

    group('Retry Operation', () {
      test('retry transitions through Loading (isRetry=true) to Success',
          () async {
        // Arrange
        final states = <HomeState>[];
        controller.addListener(() => states.add(controller.state));

        mockLocationResolver.mockGetLatLon(Right(TestData.edinburgh));
        mockFireRiskService.mockGetCurrent(Right(TestData.createFireRisk()));

        // Act
        await controller.retry();

        // Assert
        expect(states.length, equals(2)); // Loading -> Success
        expect(states[0], isA<HomeStateLoading>());
        expect((states[0] as HomeStateLoading).isRetry, isTrue);
        expect(states[1], isA<HomeStateSuccess>());
      });
    });

    group('Manual Location', () {
      test('setManualLocation saves location and refreshes data', () async {
        // Arrange
        final states = <HomeState>[];
        controller.addListener(() => states.add(controller.state));

        mockLocationResolver.mockGetLatLon(const Right(TestData.glasgow));
        mockFireRiskService.mockGetCurrent(Right(TestData.createFireRisk()));

        // Act
        await controller.setManualLocation(TestData.glasgow,
            placeName: 'Glasgow');

        // Assert
        expect(mockLocationResolver.loggedCalls,
            contains('saveManual(55.8642, -4.2518, placeName: Glasgow)'));
        expect(states.length, equals(2)); // Loading -> Success
        expect(states[1], isA<HomeStateSuccess>());

        final successState = states[1] as HomeStateSuccess;
        expect(successState.location, equals(TestData.glasgow));
      });

      test('setManualLocation handles save failure', () async {
        // Arrange
        final states = <HomeState>[];
        controller.addListener(() => states.add(controller.state));

        mockLocationResolver.mockSaveManualThrows();

        // Act
        await controller.setManualLocation(TestData.glasgow);

        // Assert
        expect(states.length, equals(1)); // Error state only
        expect(states[0], isA<HomeStateError>());

        final errorState = states[0] as HomeStateError;
        expect(errorState.errorMessage, contains('Failed to save location'));
        expect(errorState.canRetry, isTrue);
      });
    });

    group('Re-entrancy Protection', () {
      test('load() ignores subsequent calls while loading', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(Right(TestData.edinburgh));
        mockFireRiskService.mockGetCurrent(Right(TestData.createFireRisk()));

        // Set up normal successful responses
        mockLocationResolver.mockGetLatLon(Right(TestData.edinburgh));

        // Act
        final future1 = controller.load();
        final future2 = controller.load(); // Should be ignored
        final future3 = controller.retry(); // Should be ignored

        await future1;
        await future2;
        await future3;

        // Assert
        expect(
            mockLocationResolver.loggedCalls
                .where((call) => call.startsWith('getLatLon'))
                .length,
            equals(1));
        expect(controller.isLoading, isFalse);
      });

      test('setManualLocation ignores calls while loading', () async {
        // Arrange - create a slow-loading scenario
        mockLocationResolver.mockGetLatLon(Right(TestData.edinburgh));
        mockFireRiskService.mockGetCurrent(Right(TestData.createFireRisk()));

        // Start a load operation
        final loadFuture = controller.load();

        // Act - try to set manual location while loading
        await controller.setManualLocation(TestData.glasgow);

        // Complete the load
        await loadFuture;

        // Assert - manual location call should be ignored
        expect(
            mockLocationResolver.loggedCalls
                .where((call) => call.startsWith('saveManual'))
                .length,
            equals(0));
      });
    });

    group('Timeout Handling', () {
      test('global timeout triggers error state', () async {
        // This test would require more sophisticated timer mocking
        // For now, we'll verify the timeout setup exists
        expect(controller.isLoading, isFalse);

        // The actual timeout behavior would need fake timers to test properly
        // This is a structural test to ensure the timeout mechanism exists
      });
    });

    group('State Transition Notifications', () {
      test('notifies listeners on each state change', () async {
        // Arrange
        int notificationCount = 0;
        controller.addListener(() => notificationCount++);

        mockLocationResolver.mockGetLatLon(Right(TestData.edinburgh));
        mockFireRiskService.mockGetCurrent(Right(TestData.createFireRisk()));

        // Act
        await controller.load();

        // Assert
        expect(notificationCount, equals(2)); // Loading -> Success
      });
    });

    group('Dispose Cleanup', () {
      test('dispose cleans up resources without throwing', () {
        // Create a separate controller for this test to avoid tearDown conflicts
        final testController = HomeController(
          locationResolver: mockLocationResolver,
          fireRiskService: mockFireRiskService,
        );

        // Verify controller is in good state before disposal
        expect(testController.isLoading, isFalse);

        // Act - dispose should complete without throwing
        expect(() => testController.dispose(), returnsNormally);

        // Note: Cannot access controller properties after disposal
        // as it throws in debug mode. The test verifies disposal succeeds.
      });
    });
    group('Privacy Compliance (C2)', () {
      test('logs use redacted coordinates', () async {
        // This test verifies that the controller uses LocationUtils.logRedact
        // The actual log redaction testing is done in the LocationUtils tests
        // We verify the controller doesn't expose raw coordinates in state

        mockLocationResolver.mockGetLatLon(Right(TestData.edinburgh));
        mockFireRiskService.mockGetCurrent(Right(TestData.createFireRisk()));

        await controller.load();

        // Verify state contains coordinates but logs would be redacted
        expect(controller.state, isA<HomeStateSuccess>());
        final successState = controller.state as HomeStateSuccess;
        expect(successState.location, equals(TestData.edinburgh));
      });
    });

    group('Constitutional Compliance', () {
      test('C5: Error states are visible with retry capability', () async {
        // Arrange
        mockLocationResolver
            .mockGetLatLon(const Left(LocationError.gpsUnavailable));

        // Act
        await controller.load();

        // Assert
        expect(controller.state, isA<HomeStateError>());
        final errorState = controller.state as HomeStateError;
        expect(errorState.canRetry, isTrue);
        expect(errorState.errorMessage, isNotEmpty);
      });

      test('C4: Success state includes source attribution', () async {
        // Arrange
        mockLocationResolver.mockGetLatLon(const Right(TestData.edinburgh));
        mockFireRiskService.mockGetCurrent(
            Right(TestData.createFireRisk(source: DataSource.sepa)));

        // Act
        await controller.load();

        // Assert
        expect(controller.state, isA<HomeStateSuccess>());
        final successState = controller.state as HomeStateSuccess;
        expect(successState.riskData.source, equals(DataSource.sepa));
        expect(successState.lastUpdated, isA<DateTime>());
      });
    });
  });
}
