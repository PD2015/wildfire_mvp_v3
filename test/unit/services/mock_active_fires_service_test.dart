import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/mock_active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

void main() {
  late MockActiveFiresService service;

  setUp(() {
    service = MockActiveFiresService();
  });

  group('MockActiveFiresService Metadata', () {
    test('provides correct metadata', () {
      final metadata = service.metadata;
      
      expect(metadata.sourceType, DataSourceType.mock);
      expect(metadata.description, contains('Mock'));
      expect(metadata.description, contains('testing'));
      expect(metadata.supportsRealTime, false);
      expect(metadata.maxIncidentsPerRequest, 500);
    });

    test('has Scotland coverage bounds', () {
      final metadata = service.metadata;
      
      expect(metadata.coverage, isNotNull);
      expect(metadata.coverage!.southwest.latitude, 54.5);
      expect(metadata.coverage!.southwest.longitude, -8.5);
      expect(metadata.coverage!.northeast.latitude, 60.9);
      expect(metadata.coverage!.northeast.longitude, 0.5);
    });

    test('has recent lastUpdate timestamp', () {
      final before = DateTime.now().subtract(const Duration(minutes: 20));
      final metadata = service.metadata;
      final after = DateTime.now();
      
      expect(metadata.lastUpdate, isNotNull);
      expect(metadata.lastUpdate!.isAfter(before), true);
      expect(metadata.lastUpdate!.isBefore(after), true);
    });
  });

  group('MockActiveFiresService getIncidentsForViewport', () {
    test('returns deterministic mock data for Scotland bounds', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(60.9, 0.5),
      );

      final result = await service.getIncidentsForViewport(bounds: bounds);

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // Mock service should return consistent number of incidents
      expect(response.incidents, isNotEmpty);
      expect(response.dataSource, DataSource.mock);
      expect(response.totalCount, response.incidents.length);
    });

    test('filters incidents by geographic bounds', () async {
      // Very small bounds in Edinburgh area
      const smallBounds = LatLngBounds(
        southwest: LatLng(55.9, -3.3),
        northeast: LatLng(56.0, -3.1),
      );

      final result = await service.getIncidentsForViewport(bounds: smallBounds);

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // All incidents should be within bounds
      for (final incident in response.incidents) {
        expect(smallBounds.contains(incident.location), true);
      }
    });

    test('filters by confidence threshold', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(60.9, 0.5),
      );

      final result = await service.getIncidentsForViewport(
        bounds: bounds,
        confidenceThreshold: 80.0,
      );

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // All incidents should meet confidence threshold
      for (final incident in response.incidents) {
        expect(incident.confidence ?? 0, greaterThanOrEqualTo(80.0));
      }
    });

    test('filters by minimum FRP', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(60.9, 0.5),
      );

      final result = await service.getIncidentsForViewport(
        bounds: bounds,
        minFrp: 1000.0,
      );

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // All incidents should meet minimum FRP
      for (final incident in response.incidents) {
        expect(incident.frp ?? 0, greaterThanOrEqualTo(1000.0));
      }
    });

    test('combines confidence and FRP filters', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(60.9, 0.5),
      );

      final result = await service.getIncidentsForViewport(
        bounds: bounds,
        confidenceThreshold: 75.0,
        minFrp: 500.0,
      );

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // All incidents should meet both thresholds
      for (final incident in response.incidents) {
        expect(incident.confidence ?? 0, greaterThanOrEqualTo(75.0));
        expect(incident.frp ?? 0, greaterThanOrEqualTo(500.0));
      }
    });

    test('returns empty list for bounds outside Scotland', () async {
      // Bounds in London
      const londonBounds = LatLngBounds(
        southwest: LatLng(51.4, -0.2),
        northeast: LatLng(51.6, 0.0),
      );

      final result = await service.getIncidentsForViewport(bounds: londonBounds);

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // No mock incidents in London
      expect(response.incidents, isEmpty);
    });

    test('returns ApiError for invalid bounds', () async {
      // Invalid bounds (southwest > northeast)
      const invalidBounds = LatLngBounds(
        southwest: LatLng(100.0, 0.0), // Invalid latitude
        northeast: LatLng(56.0, -3.0),
      );

      final result = await service.getIncidentsForViewport(bounds: invalidBounds);

      expect(result.isLeft(), true);
      final error = result.swap().getOrElse(() => throw Exception('Expected Left'));
      expect(error.message, contains('Invalid'));
      expect(error.statusCode, 400);
    });

    test('simulates realistic network delay (~250ms)', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(55.0, -4.0),
        northeast: LatLng(56.0, -3.0),
      );

      final stopwatch = Stopwatch()..start();
      await service.getIncidentsForViewport(bounds: bounds);
      stopwatch.stop();

      // Should take at least 200ms (150ms + 100ms simulated delay)
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(200));
      // Should complete in reasonable time (<500ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('returns metadata in response', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(55.0, -4.0),
        northeast: LatLng(56.0, -3.0),
      );

      final result = await service.getIncidentsForViewport(bounds: bounds);

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      expect(response.queriedBounds, isNotNull);
      expect(response.responseTimeMs, 250); // Simulated response time
      expect(response.dataSource, DataSource.mock);
      expect(response.timestamp, isNotNull);
      expect(response.totalCount, response.incidents.length);
    });

    test('incidents have realistic fire data', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(60.9, 0.5),
      );

      final result = await service.getIncidentsForViewport(bounds: bounds);

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // Check first incident has realistic data
      if (response.incidents.isNotEmpty) {
        final incident = response.incidents.first;
        
        expect(incident.id, startsWith('mock_fire_'));
        expect(incident.source, DataSource.mock);
        expect(incident.freshness, Freshness.mock);
        expect(incident.sensorSource, 'MODIS');
        expect(incident.confidence, isNotNull);
        expect(incident.confidence! >= 0 && incident.confidence! <= 100, true);
        expect(incident.frp, isNotNull);
        expect(incident.frp! > 0, true);
        expect(incident.detectedAt.isBefore(DateTime.now()), true);
      }
    });

    test('incidents are sorted by detection time (newest first)', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(60.9, 0.5),
      );

      final result = await service.getIncidentsForViewport(bounds: bounds);

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // Verify incidents are sorted newest first
      for (int i = 0; i < response.incidents.length - 1; i++) {
        final current = response.incidents[i];
        final next = response.incidents[i + 1];
        expect(
          current.detectedAt.isAfter(next.detectedAt) ||
          current.detectedAt.isAtSameMomentAs(next.detectedAt),
          true,
        );
      }
    });
  });

  group('MockActiveFiresService getIncidentById', () {
    test('returns incident when found', () async {
      // First get all incidents to find valid ID
      const bounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(60.9, 0.5),
      );
      final listResult = await service.getIncidentsForViewport(bounds: bounds);
      final incidents = listResult.getOrElse(() => throw Exception('Setup failed')).incidents;
      
      if (incidents.isEmpty) {
        fail('No incidents to test with');
      }

      final targetId = incidents.first.id;
      final result = await service.getIncidentById(incidentId: targetId);

      expect(result.isRight(), true);
      final incident = result.getOrElse(() => throw Exception('Expected Right'));
      expect(incident.id, targetId);
    });

    test('returns ApiError when incident not found', () async {
      final result = await service.getIncidentById(incidentId: 'nonexistent_fire_id');

      expect(result.isLeft(), true);
      final error = result.swap().getOrElse(() => throw Exception('Expected Left'));
      expect(error.message, contains('not found'));
      expect(error.statusCode, 404);
    });

    test('simulates realistic network delay (~100ms)', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(60.9, 0.5),
      );
      final listResult = await service.getIncidentsForViewport(bounds: bounds);
      final incidents = listResult.getOrElse(() => throw Exception('Setup failed')).incidents;
      
      if (incidents.isEmpty) {
        return; // Skip test if no incidents
      }

      final targetId = incidents.first.id;
      
      final stopwatch = Stopwatch()..start();
      await service.getIncidentById(incidentId: targetId);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });

  group('MockActiveFiresService checkHealth', () {
    test('returns true (mock service is always healthy)', () async {
      final result = await service.checkHealth();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => false), true);
    });

    test('simulates health check delay (~50ms)', () async {
      final stopwatch = Stopwatch()..start();
      await service.checkHealth();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
      expect(stopwatch.elapsedMilliseconds, lessThan(150));
    });
  });

  group('MockActiveFiresService Determinism', () {
    test('returns same incidents across multiple calls', () async {
      const bounds = LatLngBounds(
        southwest: LatLng(55.0, -4.0),
        northeast: LatLng(56.0, -3.0),
      );

      final result1 = await service.getIncidentsForViewport(bounds: bounds);
      final result2 = await service.getIncidentsForViewport(bounds: bounds);

      expect(result1.isRight(), true);
      expect(result2.isRight(), true);

      final response1 = result1.getOrElse(() => throw Exception('Failed'));
      final response2 = result2.getOrElse(() => throw Exception('Failed'));

      expect(response1.incidents.length, response2.incidents.length);
      
      // Check that incident IDs match (deterministic generation)
      for (int i = 0; i < response1.incidents.length; i++) {
        expect(response1.incidents[i].id, response2.incidents[i].id);
      }
    });

    test('different service instances return same data', () async {
      final service1 = MockActiveFiresService();
      final service2 = MockActiveFiresService();

      const bounds = LatLngBounds(
        southwest: LatLng(55.0, -4.0),
        northeast: LatLng(56.0, -3.0),
      );

      final result1 = await service1.getIncidentsForViewport(bounds: bounds);
      final result2 = await service2.getIncidentsForViewport(bounds: bounds);

      final response1 = result1.getOrElse(() => throw Exception('Failed'));
      final response2 = result2.getOrElse(() => throw Exception('Failed'));

      expect(response1.incidents.length, response2.incidents.length);
      expect(response1.incidents.first.id, response2.incidents.first.id);
    });
  });
}
