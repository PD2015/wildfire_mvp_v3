import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/effis_fire.dart';
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

  /// Helper to create test EffisFire instances
  /// Note: EffisFire.toFireIncident() sets confidence=null and frp=null
  /// since EFFIS API doesn't provide these fields (they're set to null in the model)
  EffisFire createTestFire({
    required String id,
    required double lat,
    required double lon,
    DateTime? fireDate,
    double areaHectares = 10.0,
    String? country,
  }) {
    return EffisFire(
      id: id,
      location: LatLng(lat, lon),
      fireDate: fireDate ?? DateTime.parse('2024-01-15T10:00:00Z'),
      areaHectares: areaHectares,
      country: country,
    );
  }

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
      expect(
          metadata.lastUpdate!.isAfter(before) ||
              metadata.lastUpdate!.isAtSameMomentAs(before),
          true);
      expect(
          metadata.lastUpdate!.isBefore(after) ||
              metadata.lastUpdate!.isAtSameMomentAs(after),
          true);
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
      )).thenAnswer((_) async => const Right([]));

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
      )).thenAnswer((_) async => const Right([]));

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
      )).thenAnswer((_) async => const Right([]));

      await service.getIncidentsForViewport(bounds: testBounds);

      final captured = verify(mockEffisService.getActiveFires(
        captureAny,
        timeout: anyNamed('timeout'),
      )).captured;

      final capturedBounds = captured[0] as LatLngBounds;
      expect(capturedBounds, testBounds);
    });

    test('returns all incidents when confidence is null (EFFIS data)',
        () async {
      // EFFIS data doesn't include confidence, so all fires pass through
      // This tests that null confidence values don't cause filtering issues
      final mockFires = [
        createTestFire(id: 'fire1', lat: 55.5, lon: -3.5),
        createTestFire(id: 'fire2', lat: 55.6, lon: -3.6),
        createTestFire(id: 'fire3', lat: 55.7, lon: -3.7),
      ];

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockFires));

      final result = await service.getIncidentsForViewport(
        bounds: testBounds,
        confidenceThreshold: 50.0,
      );

      expect(result.isRight(), true);
      final response =
          result.getOrElse(() => throw Exception('Expected Right'));

      // All fires should pass through since confidence is null (not filtered)
      expect(response.incidents.length, 3);
      expect(response.incidents.any((i) => i.id == 'fire1'), true);
      expect(response.incidents.any((i) => i.id == 'fire2'), true);
      expect(response.incidents.any((i) => i.id == 'fire3'), true);
    });

    test('returns all incidents when FRP is null (EFFIS data)', () async {
      // EFFIS data doesn't include FRP, so all fires pass through
      // This tests that null FRP values don't cause filtering issues
      final mockFires = [
        createTestFire(id: 'fire1', lat: 55.5, lon: -3.5),
        createTestFire(id: 'fire2', lat: 55.6, lon: -3.6),
      ];

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockFires));

      final result = await service.getIncidentsForViewport(
        bounds: testBounds,
        minFrp: 100.0,
      );

      expect(result.isRight(), true);
      final response =
          result.getOrElse(() => throw Exception('Expected Right'));

      // All fires should pass through since FRP is null (not filtered)
      expect(response.incidents.length, 2);
      expect(response.incidents.first.id, 'fire1');
    });

    test('handles null confidence gracefully (EFFIS default)', () async {
      // EFFIS EffisFire.toFireIncident() always sets confidence: null
      // This should NOT filter out incidents (null != < threshold)
      final mockFires = [
        createTestFire(id: 'fire1', lat: 55.5, lon: -3.5),
      ];

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockFires));

      final result = await service.getIncidentsForViewport(
        bounds: testBounds,
        confidenceThreshold: 50.0,
      );

      expect(result.isRight(), true);
      final response =
          result.getOrElse(() => throw Exception('Expected Right'));

      // Fire should NOT be filtered out (null confidence passes through)
      expect(response.incidents.length, 1);
      expect(response.incidents.first.confidence, isNull);
    });

    test('handles null FRP gracefully (EFFIS default)', () async {
      // EFFIS EffisFire.toFireIncident() always sets frp: null
      // This should NOT filter out incidents (null != < minimum)
      final mockFires = [
        createTestFire(id: 'fire1', lat: 55.5, lon: -3.5),
      ];

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockFires));

      final result = await service.getIncidentsForViewport(
        bounds: testBounds,
        minFrp: 100.0,
      );

      expect(result.isRight(), true);
      final response =
          result.getOrElse(() => throw Exception('Expected Right'));

      // Fire should NOT be filtered out (null FRP passes through)
      expect(response.incidents.length, 1);
      expect(response.incidents.first.frp, isNull);
    });

    test('sorts incidents by detection time (newest first)', () async {
      final mockFires = [
        createTestFire(
            id: 'fire1',
            lat: 55.5,
            lon: -3.5,
            fireDate: DateTime.parse('2024-01-15T10:00:00Z')), // Oldest
        createTestFire(
            id: 'fire2',
            lat: 55.6,
            lon: -3.6,
            fireDate: DateTime.parse('2024-01-15T12:00:00Z')), // Newest
        createTestFire(
            id: 'fire3',
            lat: 55.7,
            lon: -3.7,
            fireDate: DateTime.parse('2024-01-15T11:00:00Z')), // Middle
      ];

      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Right(mockFires));

      final result = await service.getIncidentsForViewport(bounds: testBounds);

      expect(result.isRight(), true);
      final response =
          result.getOrElse(() => throw Exception('Expected Right'));

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
      final error =
          result.swap().getOrElse(() => throw Exception('Expected Left'));
      expect(error.message, contains('Network error'));
    });
  });

  group('ActiveFiresServiceImpl checkHealth', () {
    setUp(() {
      service = ActiveFiresServiceImpl.withEffisService(mockEffisService);
    });

    test('returns true when EFFIS service responds successfully', () async {
      // checkHealth calls _effisService.getActiveFires internally
      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => const Right([]));

      final result = await service.checkHealth();

      expect(result.isRight(), true);
      expect(result.getOrElse(() => false), true);
    });

    test('returns false when EFFIS service fails', () async {
      // checkHealth returns Right(false) when getActiveFires fails
      when(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => Left(ApiError(
            message: 'Service unavailable',
            statusCode: 503,
          )));

      final result = await service.checkHealth();

      expect(result.isRight(), true); // Returns Right, not Left
      expect(result.getOrElse(() => true), false); // But value is false
    });
  });

  group('ActiveFiresServiceImpl getIncidentById', () {
    setUp(() {
      service = ActiveFiresServiceImpl.withEffisService(mockEffisService);
    });

    test('returns not implemented error', () async {
      // EFFIS WFS doesn't support direct ID lookups
      final result = await service.getIncidentById(incidentId: 'any-id');

      expect(result.isLeft(), true);
      final error =
          result.swap().getOrElse(() => throw Exception('Expected Left'));
      expect(error.message, contains('not supported'));
    });

    test('does not call EFFIS service (not implemented)', () async {
      // Method should return error without making API calls
      await service.getIncidentById(incidentId: 'test');

      verifyNever(mockEffisService.getActiveFires(
        any,
        timeout: anyNamed('timeout'),
      ));
    });
  });
}
