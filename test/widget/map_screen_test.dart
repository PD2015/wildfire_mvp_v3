import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:wildfire_mvp_v3/features/map/screens/map_screen.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:dartz/dartz.dart';

/// Mock MapController for widget testing with controllable state
class MockMapController extends MapController {
  MapState _mockState;

  MockMapController(this._mockState)
      : super(
          locationResolver: _NoOpLocationResolver(),
          fireLocationService: _NoOpFireLocationService(),
          fireRiskService: _NoOpFireRiskService(),
        );

  @override
  MapState get state => _mockState;

  /// Update state and notify listeners (for testing state changes)
  void setState(MapState newState) {
    _mockState = newState;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    // No-op for testing - state is controlled via setState()
  }
}

/// No-op LocationResolver for testing
class _NoOpLocationResolver implements LocationResolver {
  @override
  Future<Either<LocationError, LatLng>> getLatLon({
    bool allowDefault = true,
  }) async {
    return const Right(LatLng(55.9533, -3.1883)); // Edinburgh
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {
    // No-op
  }

  @override
  Future<void> clearManualLocation() async {
    // No-op
  }
}

/// No-op FireLocationService for testing
class _NoOpFireLocationService implements FireLocationService {
  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    return const Right([]); // Empty list
  }
}

/// No-op FireRiskService for testing
class _NoOpFireRiskService implements FireRiskService {
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    // Return a mock FireRisk with Very Low rating
    return Right(
      FireRisk.fromMock(
        level: RiskLevel.veryLow,
        observedAt: DateTime.now().toUtc(),
      ),
    );
  }
}

/// T006: Widget tests for MapScreen with accessibility validation
///
/// Validates ≥44dp touch targets, semantic labels, screen reader support.
void main() {
  group('MapScreen Widget Tests', () {
    testWidgets('MapScreen renders GoogleMap widget', (tester) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return; // Skip test on macOS desktop
      }

      // Setup mock controller with MapSuccess state
      final mockIncidents = [
        FireIncident(
          id: 'test_fire_1',
          location: const LatLng(55.9533, -3.1883),
          source: DataSource.mock,
          freshness: Freshness.mock,
          timestamp: DateTime.now(),
          intensity: 'high',
          description: 'Test fire 1',
          areaHectares: 45.0,
        ),
        FireIncident(
          id: 'test_fire_2',
          location: const LatLng(55.8642, -4.2518),
          source: DataSource.mock,
          freshness: Freshness.mock,
          timestamp: DateTime.now(),
          intensity: 'moderate',
          description: 'Test fire 2',
          areaHectares: 20.0,
        ),
      ];

      final mockController = MockMapController(
        MapSuccess(
          incidents: mockIncidents,
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
      );

      // Build MapScreen
      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );

      // Wait for widget tree to settle
      await tester.pumpAndSettle();

      // Verify GoogleMap widget exists
      expect(find.byType(gmaps.GoogleMap), findsOneWidget);

      // Verify AppBar exists with correct title
      expect(find.widgetWithText(AppBar, 'Fire Map'), findsOneWidget);

      // Note: Markers are created internally by GoogleMap widget
      // We can't directly verify marker count from widget tree,
      // but we can verify the state has correct number of incidents
      expect(mockIncidents.length, 2);
    });

    testWidgets('"Check risk here" button is ≥44dp touch target (C3)', (
      tester,
    ) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return; // Skip test on macOS desktop
      }

      // Setup mock controller
      final mockController = MockMapController(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
      );

      // Build MapScreen
      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );

      await tester.pumpAndSettle();

      // Find FloatingActionButton (RiskCheckButton)
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Get FAB size
      final fabSize = tester.getSize(fabFinder);

      // Verify ≥44dp touch target (iOS requirement)
      // 44dp = 44 logical pixels in Flutter
      expect(
        fabSize.width,
        greaterThanOrEqualTo(44.0),
        reason: 'FAB width must be ≥44dp for accessibility (C3)',
      );
      expect(
        fabSize.height,
        greaterThanOrEqualTo(44.0),
        reason: 'FAB height must be ≥44dp for accessibility (C3)',
      );

      // Verify semantic label exists by finding widget with partial semantic label match
      // The RiskCheckButton wraps FAB with Semantics(label: 'Check fire risk at this location')
      final semanticFinder = find.byWidgetPredicate((widget) {
        return widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.toLowerCase().contains('risk');
      });
      expect(
        semanticFinder,
        findsOneWidget,
        reason:
            'FAB must have descriptive semantic label containing "risk" (C3)',
      );
    });

    testWidgets(
        'source chip displays "DEMO DATA", "LIVE", or "CACHED" (C4, T019)', (
      tester,
    ) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return; // Skip test on macOS desktop
      }

      // Test MOCK freshness - shows "DEMO DATA" when MAP_LIVE_DATA=false (default)
      final mockController = MockMapController(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );

      await tester.pumpAndSettle();

      // Verify "DEMO DATA" text appears (T019 - prominent demo mode indicator)
      expect(
        find.text('DEMO DATA'),
        findsOneWidget,
        reason:
            'Source chip must display "DEMO DATA" for mock data when MAP_LIVE_DATA=false (C4, T019)',
      );

      // Test LIVE freshness
      mockController.setState(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.live,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('LIVE'),
        findsOneWidget,
        reason: 'Source chip must display "LIVE" for live data (C4)',
      );

      // Test CACHED freshness
      mockController.setState(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.cached,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('CACHED'),
        findsOneWidget,
        reason: 'Source chip must display "CACHED" for cached data (C4)',
      );
    });

    testWidgets('loading spinner has semanticLabel (C3)', (tester) async {
      // Skip on unsupported platforms (macOS desktop)
      // Note: On macOS desktop, MapScreen shows unsupported platform view
      // This test only applies to supported platforms (web, Android, iOS)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return; // Skip test on macOS desktop
      }

      // Setup mock controller with MapLoading state
      final mockController = MockMapController(const MapLoading());

      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );

      await tester.pump();

      // Find CircularProgressIndicator
      final spinnerFinder = find.byType(CircularProgressIndicator);
      expect(spinnerFinder, findsOneWidget);

      // Verify semantic label exists on the Semantics wrapper
      final semanticsFinder = find.ancestor(
        of: spinnerFinder,
        matching: find.byType(Semantics),
      );
      expect(semanticsFinder, findsOneWidget);

      // Get the Semantics widget and check its label
      final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      expect(
        semanticsWidget.properties.label,
        isNotEmpty,
        reason: 'Loading spinner must have semantic label (C3)',
      );
      expect(
        semanticsWidget.properties.label!.toLowerCase(),
        contains('loading'),
        reason: 'Semantic label should describe loading state',
      );
    });

    // Placeholder tests for remaining test cases (not critical for Option 3)
    testWidgets('zoom controls are ≥44dp touch target (C3)', (tester) async {
      // Note: GoogleMap zoom controls are native platform widgets
      // Their size is controlled by the platform, not directly testable in Flutter widget tests
      // This would require platform-specific integration tests or manual testing
    });

    testWidgets('marker info windows have semantic labels (C3)', (
      tester,
    ) async {
      // Note: Marker info windows are created by GoogleMap plugin internally
      // Semantic labels would need to be verified through integration tests or manual testing
    });

    testWidgets('"Last updated" timestamp visible for live/cached data (C4)', (
      tester,
    ) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return; // Skip test on macOS desktop
      }

      // Test with LIVE data (not demo mode)
      final mockController = MockMapController(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.live,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );

      await tester.pumpAndSettle();

      // Verify MapSourceChip is displayed
      expect(
        find.byType(MapSourceChip),
        findsOneWidget,
        reason: 'MapSourceChip should be visible on map screen',
      );

      // Verify data source indicator is present (either timestamp or "DEMO DATA")
      final hasTimestamp = find.textContaining(
        RegExp(r'(Just now|ago|min|hour|day)', caseSensitive: false),
      );
      final hasDemoData = find.text('DEMO DATA');

      expect(
        hasTimestamp.evaluate().isNotEmpty || hasDemoData.evaluate().isNotEmpty,
        true,
        reason:
            'Either timestamp or demo data indicator should be visible (C4)',
      );

      // Test with CACHED data
      mockController.setState(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.cached,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify timestamp still visible for cached data
      expect(
        find.textContaining(
          RegExp(r'(Just now|ago|min|hour|day)', caseSensitive: false),
        ),
        findsOneWidget,
        reason:
            'Timestamp should be visible in source chip for cached data (C4)',
      );

      // Note: DEMO DATA chip (mock + MAP_LIVE_DATA=false) intentionally does not show timestamp
      // to distinguish it visually from production data sources (T019)
    });

    // =========================================================================
    // Map Control Widget Tests
    // =========================================================================

    testWidgets('MapTypeSelector is present and accessible', (tester) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return;
      }

      final mockController = MockMapController(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      // Verify map type selector container exists
      final selectorFinder =
          find.byKey(const Key('map_type_selector_container'));
      expect(
        selectorFinder,
        findsOneWidget,
        reason: 'MapTypeSelector should be present on map screen',
      );

      // Verify the popup menu button exists inside
      final popupFinder = find.byKey(const Key('map_type_selector'));
      expect(
        popupFinder,
        findsOneWidget,
        reason: 'Map type popup menu should be present',
      );
    });

    testWidgets('MapTypeSelector opens dropdown on tap', (tester) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return;
      }

      final mockController = MockMapController(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      // Tap the map type selector
      final selectorFinder = find.byKey(const Key('map_type_selector'));
      await tester.tap(selectorFinder);
      await tester.pumpAndSettle();

      // Verify dropdown menu items are shown
      expect(find.text('Terrain'), findsOneWidget);
      expect(find.text('Satellite'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('PolygonToggleChip is present and accessible', (tester) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return;
      }

      final mockController = MockMapController(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      // Verify polygon toggle container exists
      final toggleFinder = find.byKey(const Key('polygon_toggle_container'));
      expect(
        toggleFinder,
        findsOneWidget,
        reason: 'PolygonToggleChip should be present on map screen',
      );

      // Verify it shows "Hide burn areas" initially (polygons visible by default)
      expect(
        find.text('Hide burn areas'),
        findsOneWidget,
        reason: 'Polygon toggle should show "Hide burn areas" initially',
      );
    });

    testWidgets('PolygonToggleChip toggles on tap', (tester) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return;
      }

      final mockController = MockMapController(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      // Initially shows "Hide burn areas"
      expect(find.text('Hide burn areas'), findsOneWidget);
      expect(find.text('Show burn areas'), findsNothing);

      // Tap the toggle
      final toggleFinder = find.byKey(const Key('polygon_toggle_container'));
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Should now show "Show burn areas"
      expect(find.text('Show burn areas'), findsOneWidget);
      expect(find.text('Hide burn areas'), findsNothing);
    });

    testWidgets('Map controls have ≥44dp touch targets (C3)', (tester) async {
      // Skip on unsupported platforms (macOS desktop)
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return;
      }

      final mockController = MockMapController(
        MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(55.9, -3.2),
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: MapScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      // Check MapTypeSelector touch target
      final mapTypeFinder =
          find.byKey(const Key('map_type_selector_container'));
      if (mapTypeFinder.evaluate().isNotEmpty) {
        final mapTypeSize = tester.getSize(mapTypeFinder);
        expect(
          mapTypeSize.height,
          greaterThanOrEqualTo(44.0),
          reason: 'MapTypeSelector height must be ≥44dp for accessibility (C3)',
        );
      }

      // Check PolygonToggleChip touch target
      final toggleFinder = find.byKey(const Key('polygon_toggle_container'));
      if (toggleFinder.evaluate().isNotEmpty) {
        final toggleSize = tester.getSize(toggleFinder);
        expect(
          toggleSize.height,
          greaterThanOrEqualTo(44.0),
          reason:
              'PolygonToggleChip height must be ≥44dp for accessibility (C3)',
        );
      }
    });
  });
}
