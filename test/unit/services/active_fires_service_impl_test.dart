import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service_impl.dart';
import 'package:wildfire_mvp_v3/services/effis_service.dart';

import 'active_fires_service_impl_test.mocks.dart';

@GenerateMocks([http.Client, EffisService])
void main() {
  late MockClient mockHttpClient;
  late MockEffisService mockEffisService;
  late ActiveFiresServiceImpl service;

  setUp(() {
    mockHttpClient = MockClient();
    mockEffisService = MockEffisService();
  });

  group('ActiveFiresServiceImpl Constructor', () {
    test('creates instance with HTTP client', () {
      final service = ActiveFiresServiceImpl(httpClient: mockHttpClient);
      expect(service, isNotNull);
      expect(service.metadata.sourceType, DataSourceType.live);
    });

    test('creates instance with injected EFFIS service', () {
      final service = ActiveFiresServiceImpl.withEffisService(mockEffisService);
      expect(service, isNotNull);
      expect(service.metadata.sourceType, DataSourceType.live);
    });
  });

  group('ActiveFiresServiceImpl Metadata', () {
    setUp(() {
      service = ActiveFiresServiceImpl(httpClient: mockHttpClient);
    });

    test('provides correct metadata', () {
      final metadata = service.metadata;
      
      expect(metadata.sourceType, DataSourceType.live);
      expect(metadata.description, contains('EFFIS'));
      expect(metadata.supportsRealTime, true);
      expect(metadata.maxIncidentsPerRequest, 1000);
    });

    test('has global coverage', () {
      final metadata = service.metadata;
      
      expect(metadata.coverage, isNotNull);
      expect(metadata.coverage!.southwest.latitude, -60.0);
      expect(metadata.coverage!.southwest.longitude, -180.0);
      expect(metadata.coverage!.northeast.latitude, 85.0);
      expect(metadata.coverage!.northeast.longitude, 180.0);
    });

    test('has recent lastUpdate timestamp', () {
      final before = DateTime.now();
      final metadata = service.metadata;
      final after = DateTime.now();
      
      expect(metadata.lastUpdate, isNotNull);
      expect(metadata.lastUpdate!.isAfter(before) || metadata.lastUpdate!.isAtSameMomentAs(before), true);
      expect(metadata.lastUpdate!.isBefore(after) || metadata.lastUpdate!.isAtSameMomentAs(after), true);
    });
  });

  group('ActiveFiresServiceImpl getIncidentsForViewport', () {
    const testBounds = LatLngBounds(
      southwest: LatLng(55.0, -4.0),
      northeast: LatLng(56.0, -3.0),
    );

    setUp(() {
      service = ActiveFiresServiceImpl.withEffisService(mockEffisService);
    });

    test('uses default timeout of 8 seconds', () async {
      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right([]));

      await service.getIncidentsForViewport(bounds: testBounds);

      final captured = verify(mockEffisService.getActiveFires(
        captureAny,
        timeout: captureAnyNamed('timeout'),
      )).captured;
      
      final capturedTimeout = captured[1] as Duration;
      expect(capturedTimeout, const Duration(seconds: 8));
    });

    test('accepts custom deadline parameter', () async {
      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right([]));

      const customDeadline = Duration(seconds: 5);
      await service.getIncidentsForViewport(
        bounds: testBounds,
        deadline: customDeadline,
      );

      final captured = verify(mockEffisService.getActiveFires(
        captureAny,
        timeout: captureAnyNamed('timeout'),
      )).captured;
      
      final capturedTimeout = captured[1] as Duration;
      expect(capturedTimeout, customDeadline);
    });

    test('passes bounds to EFFIS service', () async {
      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right([]));

      await service.getIncidentsForViewport(bounds: testBounds);

      final captured = verify(mockEffisService.getActiveFires(
        captureAny,
        timeout: anyNamed('timeout'),
      )).captured;
      
      final capturedBounds = captured[0] as LatLngBounds;
      expect(capturedBounds, testBounds);
    });

    test('applies confidence threshold filter', () async {
      // Create mock incidents with varying confidence
      final mockGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'id': 'fire1',
            'geometry': {'coordinates': [-3.5, 55.5]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z',
              'confidence': 80.0,
            },
          },
          {
            'id': 'fire2',
            'geometry': {'coordinates': [-3.6, 55.6]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z',
              'confidence': 40.0, // Below threshold
            },
          },
          {
            'id': 'fire3',
            'geometry': {'coordinates': [-3.7, 55.7]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z',
              'confidence': 90.0,
            },
          },
        ],
      };

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockGeoJson));

      final result = await service.getIncidentsForViewport(
        bounds: testBounds,
        confidenceThreshold: 50.0,
      );

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // Should filter out fire2 (confidence 40.0 < 50.0)
      expect(response.incidents.length, 2);
      expect(response.incidents.any((i) => i.id == 'fire1'), true);
      expect(response.incidents.any((i) => i.id == 'fire2'), false);
      expect(response.incidents.any((i) => i.id == 'fire3'), true);
    });

    test('applies minimum FRP filter', () async {
      final mockGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'id': 'fire1',
            'geometry': {'coordinates': [-3.5, 55.5]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z',
              'frp': 150.0,
            },
          },
          {
            'id': 'fire2',
            'geometry': {'coordinates': [-3.6, 55.6]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z',
              'frp': 50.0, // Below minimum
            },
          },
        ],
      };

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockGeoJson));

      final result = await service.getIncidentsForViewport(
        bounds: testBounds,
        minFrp: 100.0,
      );

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // Should filter out fire2 (frp 50.0 < 100.0)
      expect(response.incidents.length, 1);
      expect(response.incidents.first.id, 'fire1');
    });

    test('handles incidents without confidence (treats as 0)', () async {
      final mockGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'id': 'fire1',
            'geometry': {'coordinates': [-3.5, 55.5]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z',
              // No confidence field
            },
          },
        ],
      };

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockGeoJson));

      final result = await service.getIncidentsForViewport(
        bounds: testBounds,
        confidenceThreshold: 50.0,
      );

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // Should filter out fire1 (null confidence treated as 0 < 50)
      expect(response.incidents.length, 0);
    });

    test('handles incidents without FRP (treats as 0)', () async {
      final mockGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'id': 'fire1',
            'geometry': {'coordinates': [-3.5, 55.5]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z',
              // No frp field
            },
          },
        ],
      };

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockGeoJson));

      final result = await service.getIncidentsForViewport(
        bounds: testBounds,
        minFrp: 100.0,
      );

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      // Should filter out fire1 (null frp treated as 0 < 100)
      expect(response.incidents.length, 0);
    });

    test('sorts incidents by detection time (newest first)', () async {
      final mockGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'id': 'fire1',
            'geometry': {'coordinates': [-3.5, 55.5]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z', // Oldest
            },
          },
          {
            'id': 'fire2',
            'geometry': {'coordinates': [-3.6, 55.6]},
            'properties': {
              'detected_at': '2024-01-15T12:00:00Z', // Newest
            },
          },
          {
            'id': 'fire3',
            'geometry': {'coordinates': [-3.7, 55.7]},
            'properties': {
              'detected_at': '2024-01-15T11:00:00Z', // Middle
            },
          },
        ],
      };

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockGeoJson));

      final result = await service.getIncidentsForViewport(bounds: testBounds);

      expect(result.isRight(), true);
      final response = result.getOrElse(() => throw Exception('Expected Right'));
      
      expect(response.incidents.length, 3);
      expect(response.incidents[0].id, 'fire2'); // Newest first
      expect(response.incidents[1].id, 'fire3');
      expect(response.incidents[2].id, 'fire1');
    });

    test('returns ApiError when EFFIS service fails', () async {
      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Left(ApiError(
        message: 'Network error',
        statusCode: 500,
      )));

      final result = await service.getIncidentsForViewport(bounds: testBounds);

      expect(result.isLeft(), true);
      final error = result.swap().getOrElse(() => throw Exception('Expected Left'));
      expect(error.message, contains('Network error'));
    });
  });

  group('ActiveFiresServiceImpl checkHealth', () {
    setUp(() {
      service = ActiveFiresServiceImpl.withEffisService(mockEffisService);
    });

    test('returns true when EFFIS service is healthy', () async {
      when(mockEffisService.checkHealth()).thenAnswer((_) async => const Right(true));

      final result = await service.checkHealth();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => false), true);
    });

    test('returns ApiError when EFFIS service is unhealthy', () async {
      when(mockEffisService.checkHealth()).thenAnswer((_) async => Left(ApiError(
        message: 'Service unavailable',
        statusCode: 503,
      )));

      final result = await service.checkHealth();

      expect(result.isLeft(), true);
      final error = result.swap().getOrElse(() => throw Exception('Expected Left'));
      expect(error.message, contains('Service unavailable'));
    });
  });

  group('ActiveFiresServiceImpl getIncidentById', () {
    setUp(() {
      service = ActiveFiresServiceImpl.withEffisService(mockEffisService);
    });

    test('returns incident when found', () async {
      final mockGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'id': 'target-fire',
            'geometry': {'coordinates': [-3.5, 55.5]},
            'properties': {
              'detected_at': '2024-01-15T10:00:00Z',
              'confidence': 85.0,
            },
          },
        ],
      };

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockGeoJson));

      final result = await service.getIncidentById(incidentId: 'target-fire');

      expect(result.isRight(), true);
      final incident = result.getOrElse(() => throw Exception('Expected Right'));
      expect(incident.id, 'target-fire');
      expect(incident.confidence, 85.0);
    });

    test('returns ApiError when incident not found', () async {
      final mockGeoJson = {
        'type': 'FeatureCollection',
        'features': [],
      };

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockGeoJson));

      final result = await service.getIncidentById(incidentId: 'nonexistent');

      expect(result.isLeft(), true);
      final error = result.swap().getOrElse(() => throw Exception('Expected Left'));
      expect(error.message, contains('not found'));
      expect(error.statusCode, 404);
    });

    test('uses custom deadline parameter', () async {
      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right({'type': 'FeatureCollection', 'features': []}));

      const customDeadline = Duration(seconds: 3);
      await service.getIncidentById(
        incidentId: 'test',
        deadline: customDeadline,
      );

      final captured = verify(mockEffisService.getActiveFires(
        captureAny,
        timeout: captureAnyNamed('timeout'),
      )).captured;
      
      final capturedTimeout = captured[1] as Duration;
      expect(capturedTimeout, customDeadline);
    });

    test('uses default timeout of 5 seconds', () async {
      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right({'type': 'FeatureCollection', 'features': []}));

      await service.getIncidentById(incidentId: 'test');

      final captured = verify(mockEffisService.getActiveFires(
        captureAny,
        timeout: captureAnyNamed('timeout'),
      )).captured;
      
      final capturedTimeout = captured[1] as Duration;
      expect(capturedTimeout, const Duration(seconds: 5));
    });
  });
}
