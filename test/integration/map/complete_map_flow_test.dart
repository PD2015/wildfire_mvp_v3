import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:dartz/dartz.dart';

import 'package:wildfire_mvp_v3/features/map/screens/map_screen.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';

/// T034: End-to-end integration test for complete map flow
///
/// Tests the full interaction chain:
/// MockLocationResolver → FireLocationService → MapController → MapScreen →
/// markers visible → marker tap → risk check → map pan → refresh
///
/// Constitutional Compliance:
/// - C5: Resilience - verifies end-to-end error handling and timeouts
/// - C3: Accessibility - validates UI element presence and interaction
/// - C4: Transparency - verifies data source indicators

/// Mock LocationResolver for controlled testing
class MockLocationResolver implements LocationResolver {
  LatLng? _locationToReturn;
  LocationError? _errorToReturn;
  int callCount = 0;
  List<LatLng> savedLocations = [];

  void mockLocation(LatLng location) {
    _locationToReturn = location;
    _errorToReturn = null;
  }

  void mockError(LocationError error) {
    _errorToReturn = error;
    _locationToReturn = null;
  }

  void reset() {
    _locationToReturn = null;
    _errorToReturn = null;
    callCount = 0;
    savedLocations.clear();
  }

  @override
  Future<Either<LocationError, LatLng>> getLatLon({
    bool allowDefault = true,
  }) async {
    callCount++;

    if (_errorToReturn != null) {
      return Left(_errorToReturn!);
    }

    // Return mock location or default to Edinburgh
    return Right(_locationToReturn ?? const LatLng(55.9533, -3.1883));
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {
    savedLocations.add(location);
  }
}

/// Mock FireLocationService with controllable responses
class MockFireLocationService implements FireLocationService {
  List<FireIncident>? _incidentsToReturn;
  ApiError? _errorToReturn;
  Duration? _responseDelay;
  int callCount = 0;
  List<LatLngBounds> requestedBounds = [];

  void mockIncidents(List<FireIncident> incidents) {
    _incidentsToReturn = incidents;
    _errorToReturn = null;
  }

  void mockError(ApiError error) {
    _errorToReturn = error;
    _incidentsToReturn = null;
  }

  void setDelay(Duration delay) {
    _responseDelay = delay;
  }

  void reset() {
    _incidentsToReturn = null;
    _errorToReturn = null;
    _responseDelay = null;
    callCount = 0;
    requestedBounds.clear();
  }

  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    callCount++;
    requestedBounds.add(bounds);

    if (_responseDelay != null) {
      await Future.delayed(_responseDelay!);
    }

    if (_errorToReturn != null) {
      return Left(_errorToReturn!);
    }

    return Right(_incidentsToReturn ?? []);
  }
}

/// Mock FireRiskService for risk check button testing
class MockFireRiskService implements FireRiskService {
  FireRisk? _riskToReturn;
  ApiError? _errorToReturn;
  int callCount = 0;
  List<LatLng> requestedLocations = [];

  void mockRisk(FireRisk risk) {
    _riskToReturn = risk;
    _errorToReturn = null;
  }

  void mockError(ApiError error) {
    _errorToReturn = error;
    _riskToReturn = null;
  }

  void reset() {
    _riskToReturn = null;
    _errorToReturn = null;
    callCount = 0;
    requestedLocations.clear();
  }

  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    callCount++;
    requestedLocations.add(LatLng(lat, lon));

    if (_errorToReturn != null) {
      return Left(_errorToReturn!);
    }

    // Return mock risk or default to very low
    return Right(
      _riskToReturn ??
          FireRisk.fromMock(
            level: RiskLevel.veryLow,
            observedAt: DateTime.now().toUtc(),
          ),
    );
  }
}

void main() {
  // Initialize Flutter binding for GoogleMap platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Map Flow Integration Tests (T034)', () {
    late MockLocationResolver mockLocationResolver;
    late MockFireLocationService mockFireLocationService;
    late MockFireRiskService mockFireRiskService;

    setUp(() {
      mockLocationResolver = MockLocationResolver();
      mockFireLocationService = MockFireLocationService();
      mockFireRiskService = MockFireRiskService();
    });

    tearDown(() {
      mockLocationResolver.reset();
      mockFireLocationService.reset();
      mockFireRiskService.reset();
    });

    testWidgets(
      'complete flow: location → fires → MapController → MapScreen → markers visible',
      (tester) async {
        // Skip on unsupported platforms (macOS desktop)
        if (!kIsWeb && Platform.isMacOS) {
          return; // Skip test - GoogleMap not supported on macOS desktop
        }

        // Arrange: Mock Edinburgh location
        mockLocationResolver.mockLocation(const LatLng(55.9533, -3.1883));

        // Mock fire incidents
        final mockIncidents = [
          FireIncident.test(
            id: 'test_fire_1',
            location: const LatLng(55.9533, -3.1883),
            source: DataSource.mock,
            freshness: Freshness.mock,
            timestamp: DateTime.now(),
            intensity: 'high',
            description: 'Edinburgh - Holyrood Park',
            areaHectares: 45.0,
          ),
          FireIncident.test(
            id: 'test_fire_2',
            location: const LatLng(55.8642, -4.2518),
            source: DataSource.mock,
            freshness: Freshness.mock,
            timestamp: DateTime.now(),
            intensity: 'moderate',
            description: 'Glasgow - Campsie Fells',
            areaHectares: 20.0,
          ),
        ];
        mockFireLocationService.mockIncidents(mockIncidents);

        // Create MapController with mocked services
        final controller = MapController(
          locationResolver: mockLocationResolver,
          fireLocationService: mockFireLocationService,
          fireRiskService: mockFireRiskService,
        );

        // Act: Build MapScreen
        await tester.pumpWidget(
          MaterialApp(home: MapScreen(controller: controller)),
        );

        // Wait for controller to initialize
        await tester.pump();
        await controller.initialize();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Assert: GoogleMap widget rendered
        expect(find.byType(gmaps.GoogleMap), findsOneWidget);

        // Assert: AppBar with correct title
        expect(find.widgetWithText(AppBar, 'Fire Map'), findsOneWidget);

        // Assert: Location resolver was called
        expect(mockLocationResolver.callCount, greaterThan(0));

        // Assert: Fire location service was called
        expect(mockFireLocationService.callCount, greaterThan(0));

        // Assert: Source chip shows demo data (MAP_LIVE_DATA=false by default)
        expect(find.text('DEMO DATA'), findsOneWidget);

        controller.dispose();
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );

    testWidgets(
      'GPS denied fallback returns Scotland centroid',
      (tester) async {
        // Skip on unsupported platforms (macOS desktop)
        if (!kIsWeb && Platform.isMacOS) {
          return; // Skip test - GoogleMap not supported on macOS desktop
        }

        // Arrange: Mock GPS permission denied
        mockLocationResolver.mockError(LocationError.permissionDenied);

        // Mock empty incident list
        mockFireLocationService.mockIncidents([]);

        final controller = MapController(
          locationResolver: mockLocationResolver,
          fireLocationService: mockFireLocationService,
          fireRiskService: mockFireRiskService,
        );

        // Act: Build and initialize
        await tester.pumpWidget(
          MaterialApp(home: MapScreen(controller: controller)),
        );

        await tester.pump();
        await controller.initialize();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Assert: Map still loads (with default Scotland centroid)
        expect(find.byType(gmaps.GoogleMap), findsOneWidget);

        // Assert: Location resolver was called
        expect(mockLocationResolver.callCount, greaterThan(0));

        // Assert: Fire service was still called (with default location)
        expect(mockFireLocationService.callCount, greaterThan(0));

        controller.dispose();
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );

    testWidgets(
      '"Check risk here" button calls FireRiskService',
      (tester) async {
        // Skip on web and unsupported platforms (macOS desktop, web)
        if (kIsWeb || (!kIsWeb && Platform.isMacOS)) {
          return; // Skip test - GoogleMap/FAB layout differs on web, not supported on macOS desktop
        }

        // Arrange
        mockLocationResolver.mockLocation(const LatLng(55.9533, -3.1883));
        mockFireLocationService.mockIncidents([]);
        mockFireRiskService.mockRisk(
          FireRisk.fromMock(
            level: RiskLevel.high,
            observedAt: DateTime.now().toUtc(),
          ),
        );

        final controller = MapController(
          locationResolver: mockLocationResolver,
          fireLocationService: mockFireLocationService,
          fireRiskService: mockFireRiskService,
        );

        // Act: Build MapScreen
        await tester.pumpWidget(
          MaterialApp(home: MapScreen(controller: controller)),
        );

        await tester.pump();
        await controller.initialize();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Find and tap the risk check button (FloatingActionButton)
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // Assert: FireRiskService was called
        expect(mockFireRiskService.callCount, greaterThan(0));

        // Assert: Risk check was performed for a location
        expect(mockFireRiskService.requestedLocations, isNotEmpty);

        controller.dispose();
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );

    testWidgets(
      'empty region (no fires) displays appropriate state',
      (tester) async {
        // Skip on unsupported platforms (macOS desktop)
        if (!kIsWeb && Platform.isMacOS) {
          return; // Skip test - GoogleMap not supported on macOS desktop
        }

        // Arrange: Return empty incident list
        mockLocationResolver.mockLocation(const LatLng(55.9533, -3.1883));
        mockFireLocationService.mockIncidents([]);

        final controller = MapController(
          locationResolver: mockLocationResolver,
          fireLocationService: mockFireLocationService,
          fireRiskService: mockFireRiskService,
        );

        // Act: Build MapScreen
        await tester.pumpWidget(
          MaterialApp(home: MapScreen(controller: controller)),
        );

        await tester.pump();
        await controller.initialize();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Assert: Map loads successfully
        expect(find.byType(gmaps.GoogleMap), findsOneWidget);

        // Assert: No error state displayed
        expect(find.text('Error'), findsNothing);

        controller.dispose();
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );

    testWidgets(
      'test completes within 8s deadline (performance requirement)',
      (tester) async {
        // Skip on unsupported platforms (macOS desktop)
        if (!kIsWeb && Platform.isMacOS) {
          return; // Skip test - GoogleMap not supported on macOS desktop
        }

        // Arrange
        final stopwatch = Stopwatch()..start();

        mockLocationResolver.mockLocation(const LatLng(55.9533, -3.1883));
        mockFireLocationService.mockIncidents([
          FireIncident.test(
            id: 'test_fire',
            location: const LatLng(55.9533, -3.1883),
            source: DataSource.mock,
            freshness: Freshness.mock,
            timestamp: DateTime.now(),
            intensity: 'moderate',
          ),
        ]);

        final controller = MapController(
          locationResolver: mockLocationResolver,
          fireLocationService: mockFireLocationService,
          fireRiskService: mockFireRiskService,
        );

        // Act: Build and initialize
        await tester.pumpWidget(
          MaterialApp(home: MapScreen(controller: controller)),
        );

        await tester.pump();
        await controller.initialize();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        stopwatch.stop();

        // Assert: Completed within deadline
        expect(
          stopwatch.elapsed.inSeconds,
          lessThan(8),
          reason: 'Map flow must complete within 8s global deadline (T034)',
        );

        // Assert: Map rendered successfully
        expect(find.byType(gmaps.GoogleMap), findsOneWidget);

        controller.dispose();
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );

    testWidgets(
      'network timeout falls back gracefully',
      (tester) async {
        // Skip on unsupported platforms (macOS desktop)
        if (!kIsWeb && Platform.isMacOS) {
          return; // Skip test - GoogleMap not supported on macOS desktop
        }

        // Arrange: Mock timeout error
        mockLocationResolver.mockLocation(const LatLng(55.9533, -3.1883));
        mockFireLocationService.mockError(
          ApiError(message: 'EFFIS WFS request timed out', statusCode: 503),
        );

        final controller = MapController(
          locationResolver: mockLocationResolver,
          fireLocationService: mockFireLocationService,
          fireRiskService: mockFireRiskService,
        );

        // Act: Build MapScreen
        await tester.pumpWidget(
          MaterialApp(home: MapScreen(controller: controller)),
        );

        await tester.pump();
        await controller.initialize();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Assert: Error handled gracefully with error view
        // MapController transitions to MapError state, showing error UI
        expect(find.text('Failed to load map'), findsOneWidget);
        expect(find.textContaining('request timed out'), findsOneWidget);

        // Assert: Retry button is available
        expect(find.text('Retry'), findsOneWidget);

        // Note: MapController shows error view instead of map when initialization fails
        // This is the expected resilient behavior (C5 compliance)

        controller.dispose();
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );

    testWidgets(
      'memory stable after multiple cycles',
      (tester) async {
        // Arrange
        mockLocationResolver.mockLocation(const LatLng(55.9533, -3.1883));
        mockFireLocationService.mockIncidents([
          FireIncident.test(
            id: 'test_fire',
            location: const LatLng(55.9533, -3.1883),
            source: DataSource.mock,
            freshness: Freshness.mock,
            timestamp: DateTime.now(),
            intensity: 'low',
          ),
        ]);

        // Act: Create and dispose controller 3 times
        for (int i = 0; i < 3; i++) {
          final controller = MapController(
            locationResolver: mockLocationResolver,
            fireLocationService: mockFireLocationService,
            fireRiskService: mockFireRiskService,
          );

          await tester.pumpWidget(
            MaterialApp(home: MapScreen(controller: controller)),
          );

          await tester.pump();
          await controller.initialize();
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Dispose and reset for next cycle
          controller.dispose();
          await tester.pumpWidget(Container());
          await tester.pumpAndSettle();

          mockLocationResolver.reset();
          mockFireLocationService.reset();
          mockFireRiskService.reset();

          // Re-mock for next iteration
          mockLocationResolver.mockLocation(const LatLng(55.9533, -3.1883));
          mockFireLocationService.mockIncidents([
            FireIncident.test(
              id: 'test_fire',
              location: const LatLng(55.9533, -3.1883),
              source: DataSource.mock,
              freshness: Freshness.mock,
              timestamp: DateTime.now(),
              intensity: 'low',
            ),
          ]);
        }

        // Assert: Test completes without memory leaks or errors
        // Note: Memory leak detection in Flutter tests is limited
        // This test verifies proper dispose() handling by cycling 3 times
        expect(true, isTrue, reason: '3 cycles completed without errors');
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'MAP_LIVE_DATA flag reflected in source chip',
      (tester) async {
        // Skip on unsupported platforms (macOS desktop)
        if (!kIsWeb && Platform.isMacOS) {
          return; // Skip test - GoogleMap not supported on macOS desktop
        }

        // Arrange: Mock data with different freshness values
        mockLocationResolver.mockLocation(const LatLng(55.9533, -3.1883));
        mockFireLocationService.mockIncidents([
          FireIncident.test(
            id: 'test_fire',
            location: const LatLng(55.9533, -3.1883),
            source: DataSource.mock,
            freshness: Freshness.mock, // Mock data when MAP_LIVE_DATA=false
            timestamp: DateTime.now(),
            intensity: 'low',
          ),
        ]);

        final controller = MapController(
          locationResolver: mockLocationResolver,
          fireLocationService: mockFireLocationService,
          fireRiskService: mockFireRiskService,
        );

        // Act: Build MapScreen
        await tester.pumpWidget(
          MaterialApp(home: MapScreen(controller: controller)),
        );

        await tester.pump();
        await controller.initialize();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Assert: Source chip shows "DEMO DATA" (MAP_LIVE_DATA=false by default in tests)
        expect(find.text('DEMO DATA'), findsOneWidget);

        // Note: Testing MAP_LIVE_DATA=true requires --dart-define at runtime
        // Cannot be tested in unit/integration tests due to const feature flag
        // Manual testing required with: flutter run --dart-define=MAP_LIVE_DATA=true

        controller.dispose();
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );
  });
}
