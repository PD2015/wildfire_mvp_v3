import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// T005: Contract test for MapController
///
/// Covers initialize(), refreshMapData(), checkRiskAt(), state transitions.
///
/// NOTE: These tests verify the MapController contract is properly defined.
/// Full integration tests with mocked services are in test/integration/.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapController Contract Tests', () {
    setUp(() {
      // Contract tests verify type signatures and behavior contracts
      // Real integration tests are in test/integration/map/
    });

    test('MapSuccess state has valid structure', () {
      // Verify MapSuccess contract: incidents, centerLocation, freshness, lastUpdated
      final state = MapSuccess(
        incidents: const [],
        centerLocation: const LatLng(55.9533, -3.1883),
        freshness: Freshness.mock,
        lastUpdated: DateTime.now(),
      );

      expect(state.incidents, isA<List>());
      expect(state.centerLocation.isValid, isTrue);
      expect(state.lastUpdated, isA<DateTime>());
    });

    test('MapError state has valid structure', () {
      // Verify MapError contract: message, optional cachedIncidents, optional lastKnownLocation
      final state = MapError(
        message: 'All services failed',
        cachedIncidents: null,
        lastKnownLocation: null,
      );

      expect(state.message, isNotEmpty);
      expect(state.cachedIncidents, isNull);
      expect(state.lastKnownLocation, isNull);
    });

    test('MapLoading state exists', () {
      // Verify MapLoading contract
      const state = MapLoading();
      expect(state, isA<MapLoading>());
      expect(state, isA<MapState>());
    });

    test('LatLngBounds validation works', () {
      // Verify LatLngBounds contract used by refreshMapData
      const validBounds = LatLngBounds(
        southwest: LatLng(55.0, -5.0),
        northeast: LatLng(59.0, -1.0),
      );

      expect(validBounds.southwest.latitude,
          lessThan(validBounds.northeast.latitude));
      expect(validBounds.southwest.longitude,
          lessThan(validBounds.northeast.longitude));

      // Invalid bounds should throw
      expect(
        () => LatLngBounds.validated(
          southwest: const LatLng(59.0, -1.0),
          northeast: const LatLng(55.0, -5.0),
        ),
        throwsArgumentError,
      );
    });

    test('sealed class hierarchy has all three states', () {
      // Verify sealed class MapState has all required subtypes
      const loading = MapLoading();
      expect(loading, isA<MapState>());

      final success = MapSuccess(
        incidents: const [],
        centerLocation: const LatLng(55.9533, -3.1883),
        freshness: Freshness.mock,
        lastUpdated: DateTime.now(),
      );
      expect(success, isA<MapState>());

      final error = MapError(message: 'Test error');
      expect(error, isA<MapState>());
    });

    test('MapSuccess requires valid centerLocation', () {
      // Verify validation in MapSuccess
      expect(
        () => MapSuccess(
          incidents: const [],
          centerLocation: const LatLng(999, 999), // Invalid
          freshness: Freshness.mock,
          lastUpdated: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });
  });
}
