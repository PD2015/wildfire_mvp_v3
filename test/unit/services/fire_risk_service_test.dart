import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/effis_fwi_result.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/services/contracts/service_contracts.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service_impl.dart';
import 'package:wildfire_mvp_v3/services/mock_service.dart';
import 'package:wildfire_mvp_v3/services/telemetry/orchestrator_telemetry.dart';

// Generate mocks for all service dependencies
@GenerateMocks([EffisService, SepaService, CacheService])
import 'fire_risk_service_test.mocks.dart';

/// Contract tests for FireRiskService orchestrator
///
/// These tests define the expected behavior of the FireRiskService
/// implementation using mocked dependencies. Tests are designed to FAIL
/// until T003 implementation is complete.
///
/// Test Coverage:
/// - Input validation (NaN, ±Infinity, out-of-range coordinates)
/// - Never-fail guarantee (mock fallback always succeeds)
/// - Source attribution and freshness correctness
/// - Scotland routing logic (SEPA only for Scotland coordinates)
/// - Deadline behavior and timing budget enforcement
void main() {
  group('FireRiskService Contract Tests', () {
    late MockEffisService mockEffisService;
    late MockSepaService mockSepaService;
    late MockCacheService mockCacheService;
    // TODO: FireRiskService implementation will be created in T003
    late FireRiskService fireRiskService;

    final testDateTime = DateTime.utc(2025, 10, 2, 14, 30);
    const edinburghLat = 55.9533; // Scotland coordinates
    const edinburghLon = -3.1883;
    const newYorkLat = 40.7128; // Non-Scotland coordinates
    const newYorkLon = -74.0060;

    setUp(() {
      mockEffisService = MockEffisService();
      mockSepaService = MockSepaService();
      mockCacheService = MockCacheService();

      // T003 implementation now available
      fireRiskService = FireRiskServiceImpl(
        effisService: mockEffisService,
        sepaService: mockSepaService,
        cacheService: mockCacheService,
        mockService: MockService.defaultStrategy(),
        telemetry: SpyTelemetry(),
      );
    });

    group('Input Validation', () {
      test('rejects NaN latitude', () async {
        final result = await fireRiskService.getCurrent(
          lat: double.nan,
          lon: edinburghLon,
        );

        expect(result.isLeft(), isTrue);
        expect(
          result.fold((error) => error.message, (fireRisk) => ''),
          contains('finite'),
        );
      });

      test('rejects NaN longitude', () async {
        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: double.nan,
        );

        expect(result.isLeft(), isTrue,
            reason: 'NaN longitude should return validation error');
        expect(
          result.fold((error) => error.message, (fireRisk) => ''),
          contains('finite'),
        );
      });

      test('rejects positive infinity latitude', () async {
        final result = await fireRiskService.getCurrent(
          lat: double.infinity,
          lon: edinburghLon,
        );

        expect(result.isLeft(), isTrue);
      });

      test('rejects negative infinity longitude', () async {
        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: double.negativeInfinity,
        );

        expect(result.isLeft(), isTrue);
      });

      test('rejects latitude out of range (> 90)', () async {
        final result = await fireRiskService.getCurrent(
          lat: 91.0,
          lon: edinburghLon,
        );

        expect(result.isLeft(), isTrue);
        expect(
          result.fold((error) => error.message, (fireRisk) => ''),
          contains('Latitude'),
        );
      });

      test('rejects latitude out of range (< -90)', () async {
        final result = await fireRiskService.getCurrent(
          lat: -91.0,
          lon: edinburghLon,
        );

        expect(result.isLeft(), isTrue);
      });

      test('rejects longitude out of range (> 180)', () async {
        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: 181.0,
        );

        expect(result.isLeft(), isTrue);
      });

      test('rejects longitude out of range (< -180)', () async {
        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: -181.0,
        );

        expect(result.isLeft(), isTrue);
      });

      test('accepts valid coordinate boundaries', () async {
        // Test boundary conditions
        final validCoords = [
          [-90.0, -180.0], // Min bounds
          [90.0, 180.0], // Max bounds
          [0.0, 0.0], // Origin
        ];

        for (final coords in validCoords) {
          final result = await fireRiskService.getCurrent(
            lat: coords[0],
            lon: coords[1],
          );
          expect(result.isRight(), isTrue,
              reason: 'Valid coordinates should not return validation error');
        }
      });
    });

    group('Never-Fail Guarantee', () {
      test('returns mock data when all upstream services fail', () async {
        // Given: All services fail
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'EFFIS unavailable')));
        when(mockSepaService.getCurrent(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'SEPA unavailable')));
        when(mockCacheService.get(key: anyNamed('key')))
            .thenAnswer((_) async => none());

        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: edinburghLon,
        );

        // Then: Should still succeed with mock data (never-fail guarantee)
        expect(result.isRight(), isTrue,
            reason:
                'Service must never fail completely - mock should provide fallback');
        final fireRisk =
            result.getOrElse(() => throw Exception('Expected Right'));
        expect(fireRisk.source, DataSource.mock);
        expect(fireRisk.freshness, Freshness.mock);
      });

      test('never throws exceptions, only returns Left for validation errors',
          () async {
        // Given: Various failure scenarios
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenThrow(Exception('Network failure'));
        when(mockSepaService.getCurrent(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenThrow(Exception('SEPA service crashed'));
        when(mockCacheService.get(key: anyNamed('key')))
            .thenThrow(Exception('Cache service error'));

        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: edinburghLon,
        );

        // Then: Should handle exceptions gracefully and return mock data
        expect(result.isRight(), isTrue,
            reason:
                'Service should handle all exceptions and return mock fallback');
        final fireRisk =
            result.getOrElse(() => throw Exception('Expected Right'));
        expect(fireRisk.source, DataSource.mock);
      });
    });

    group('Source Attribution and Freshness', () {
      test('returns EFFIS data with live freshness when EFFIS succeeds',
          () async {
        // Given: EFFIS service returns successful data
        final effisFwiResult = EffisFwiResult(
          fwi: 18.5,
          dc: 150.0,
          dmc: 50.0,
          ffmc: 85.0,
          isi: 8.0,
          bui: 120.0,
          datetime: testDateTime,
          longitude: newYorkLon,
          latitude: newYorkLat,
        );
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer((_) async => Right(effisFwiResult));

        final result = await fireRiskService.getCurrent(
          lat: newYorkLat, // Non-Scotland to skip SEPA
          lon: newYorkLon,
        );

        // Then: Should return EFFIS data with correct attribution
        expect(result.isRight(), isTrue);
        final fireRisk = result.getOrElse(() => throw Exception('Expected Right'));
        expect(fireRisk.source, DataSource.effis);
        expect(fireRisk.freshness, Freshness.live);
        expect(fireRisk.fwi, 18.5);
        expect(fireRisk.level, RiskLevel.moderate);
      });

      test(
          'returns SEPA data with live freshness when EFFIS fails and coordinates in Scotland',
          () async {
        // Given: EFFIS fails, SEPA succeeds for Scotland coordinates
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'EFFIS unavailable')));

        final sepaFireRisk = FireRisk.fromSepa(
          level: RiskLevel.high,
          fwi: 25.0,
          observedAt: testDateTime,
        );
        when(mockSepaService.getCurrent(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer((_) async => Right(sepaFireRisk));

        final result = await fireRiskService.getCurrent(
          lat: edinburghLat, // Scotland coordinates
          lon: edinburghLon,
        );

        // Then: Should return SEPA data with correct attribution
        expect(result.isRight(), isTrue);
        final fireRisk = result.getOrElse(() => throw Exception('Expected Right'));
        expect(fireRisk.source, DataSource.sepa);
        expect(fireRisk.freshness, Freshness.live);
      });

      test(
          'returns cached data with cached freshness when services fail but cache available',
          () async {
        // Given: Services fail but cache has fresh data
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'EFFIS unavailable')));
        when(mockSepaService.getCurrent(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'SEPA unavailable')));

        final cachedFireRisk = FireRisk.fromCache(
          level: RiskLevel.veryHigh,
          fwi: 42.0,
          originalSource: DataSource.effis,
          observedAt: testDateTime,
        );
        when(mockCacheService.get(key: anyNamed('key')))
            .thenAnswer((_) async => Some(cachedFireRisk));

        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: edinburghLon,
        );

        // Then: Should return cached data with correct attribution
        expect(result.isRight(), isTrue);
        final fireRisk = result.getOrElse(() => throw Exception('Expected Right'));
        expect(fireRisk.source, DataSource.effis); // Original source preserved
        expect(fireRisk.freshness, Freshness.cached);
      });

      test('returns mock data with mock freshness as final fallback', () async {
        // Given: All services fail and no cache
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'EFFIS unavailable')));
        when(mockSepaService.getCurrent(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'SEPA unavailable')));
        when(mockCacheService.get(key: anyNamed('key')))
            .thenAnswer((_) async => none());

        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: edinburghLon,
        );

        // Then: Should return mock data as final fallback
        expect(result.isRight(), isTrue);
        final fireRisk = result.getOrElse(() => throw Exception('Expected Right'));
        expect(fireRisk.source, DataSource.mock);
        expect(fireRisk.freshness, Freshness.mock);
        expect(fireRisk.fwi, isNull, reason: 'Mock service should not provide FWI');
      });
    });

    group('Scotland Routing Logic', () {
      test('uses SEPA service only for Scotland coordinates when EFFIS fails',
          () async {
        // Given: EFFIS fails
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'EFFIS unavailable')));

        when(mockCacheService.get(key: anyNamed('key')))
            .thenAnswer((_) async => none());

        // Test with Scotland coordinates that should trigger SEPA fallback
        final scotlandCoords = [
          [55.9533, -3.1883], // Edinburgh
          [57.4778, -4.2247], // Inverness
          [60.3933, -1.1664], // Lerwick, Shetland
        ];

        for (final coords in scotlandCoords) {
          reset(mockSepaService);
          when(mockSepaService.getCurrent(lat: anyNamed('lat'), lon: anyNamed('lon')))
              .thenAnswer((_) async => Right(FireRisk.fromSepa(
                level: RiskLevel.moderate,
                observedAt: testDateTime,
              )));

          final result = await fireRiskService.getCurrent(
            lat: coords[0],
            lon: coords[1],
          );

          // Should attempt SEPA service for Scotland coordinates
          verify(mockSepaService.getCurrent(lat: coords[0], lon: coords[1])).called(1);
          expect(result.isRight(), isTrue);
          final fireRisk = result.getOrElse(() => throw Exception('Should not reach here'));
          expect(fireRisk.source, DataSource.sepa);
        }
      });

      test('skips SEPA service for non-Scotland coordinates', () async {
        // Given: EFFIS fails, coordinates outside Scotland
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer(
                (_) async => Left(ApiError(message: 'EFFIS unavailable')));
        when(mockCacheService.get(key: anyNamed('key')))
            .thenAnswer((_) async => none());

        // Test with non-Scotland coordinates that should skip SEPA
        final nonScotlandCoords = [
          [40.7128, -74.0060], // New York
          [51.5074, -0.1278],  // London
          [48.8566, 2.3522],   // Paris
        ];

        for (final coords in nonScotlandCoords) {
          reset(mockSepaService);

          final result = await fireRiskService.getCurrent(
            lat: coords[0],
            lon: coords[1],
          );

          // Should NOT attempt SEPA service for non-Scotland coordinates
          verifyNever(mockSepaService.getCurrent(lat: anyNamed('lat'), lon: anyNamed('lon')));
          expect(result.isRight(), isTrue, reason: 'Should fallback to mock');
          final fireRisk = result.getOrElse(() => throw Exception('Should not reach here'));
          expect(fireRisk.source, DataSource.mock, reason: 'Should use mock for non-Scotland coords');
        }
      });
    });

    group('Deadline and Timing Budget', () {
      test('respects default 8-second deadline', () async {
        // Given: Services that respond within budget
        when(mockEffisService.getFwi(lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer((_) async {
              await Future.delayed(Duration(milliseconds: 100));
              return Right(EffisFwiResult(
                fwi: 15.0,
                dc: 200.0,
                dmc: 50.0,
                ffmc: 80.0,
                isi: 5.0,
                bui: 25.0,
                datetime: testDateTime,
                longitude: newYorkLon,
                latitude: newYorkLat,
              ));
            });

        final stopwatch = Stopwatch()..start();
        final result = await fireRiskService.getCurrent(
          lat: newYorkLat,
          lon: newYorkLon,
        );
        stopwatch.stop();

        expect(result.isRight(), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(8000),
            reason: 'Should complete within default 8-second deadline');
      });

      test('accepts custom deadline parameter', () async {
        final customDeadline = Duration(seconds: 5);
        
        // Fast-responding EFFIS service
        when(mockEffisService.getFwi(lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return Right(EffisFwiResult(
            fwi: 12.0,
            dc: 180.0,
            dmc: 40.0,
            ffmc: 75.0,
            isi: 4.0,
            bui: 20.0,
            datetime: testDateTime,
            longitude: edinburghLon,
            latitude: edinburghLat,
          ));
        });

        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: edinburghLon,
          deadline: customDeadline,
        );

        expect(result.isRight(), isTrue,
            reason: 'Should accept custom deadline parameter');
      });

      test('enforces per-service timeout budgets (EFFIS 3s, SEPA 2s, Cache 1s)',
          () async {
        // Given: EFFIS takes longer than 3s budget
        when(mockEffisService.getFwi(lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer((_) async {
              await Future.delayed(Duration(seconds: 4)); // Exceeds 3s budget
              return Right(EffisFwiResult(
                fwi: 15.0,
                dc: 210.0,
                dmc: 55.0,
                ffmc: 82.0,
                isi: 6.0,
                bui: 28.0,
                datetime: testDateTime,
                longitude: edinburghLon,
                latitude: edinburghLat,
              ));
            });

        // Mock SEPA for Scotland fallback
        when(mockSepaService.getCurrent(lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer((_) async => Right(FireRisk.fromSepa(
              level: RiskLevel.high,
              observedAt: testDateTime,
            )));

        when(mockCacheService.get(key: anyNamed('key')))
            .thenAnswer((_) async => none());

        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: edinburghLon,
        );

        // Should timeout EFFIS and proceed to SEPA (for Scotland coords)
        expect(result.isRight(), isTrue);
        final fireRisk = result.getOrElse(() => throw Exception('Should not reach here'));
        expect(fireRisk.source, DataSource.sepa, reason: 'Should fallback to SEPA after EFFIS timeout');
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles service exceptions gracefully', () async {
        // Given: Services throw exceptions
        when(mockEffisService.getFwi(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenThrow(Exception('Network error'));
        when(mockSepaService.getCurrent(
                lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenThrow(Exception('Service crashed'));
        when(mockCacheService.get(key: anyNamed('key')))
            .thenThrow(Exception('Cache corrupted'));

        final result = await fireRiskService.getCurrent(
          lat: edinburghLat,
          lon: edinburghLon,
        );

        // Then: Should handle exceptions and return mock fallback
        expect(result.isRight(), isTrue,
            reason: 'Should handle all exceptions gracefully with mock fallback');
      });

      test('maintains fallback order: EFFIS → SEPA → Cache → Mock', () async {
        // Create service with SpyTelemetry to verify fallback order
        final spyTelemetry = SpyTelemetry();
        final serviceWithTelemetry = FireRiskServiceImpl(
          effisService: mockEffisService,
          sepaService: mockSepaService,
          cacheService: mockCacheService,
          mockService: MockService.defaultStrategy(),
          telemetry: spyTelemetry,
        );

        // Given: All services fail in sequence
        when(mockEffisService.getFwi(lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer((_) async => Left(ApiError(message: 'EFFIS failed')));
        when(mockSepaService.getCurrent(lat: anyNamed('lat'), lon: anyNamed('lon')))
            .thenAnswer((_) async => Left(ApiError(message: 'SEPA failed')));
        when(mockCacheService.get(key: anyNamed('key')))
            .thenAnswer((_) async => none());

        final result = await serviceWithTelemetry.getCurrent(
          lat: edinburghLat, // Scotland coords to test full chain
          lon: edinburghLon,
        );

        // Then: Should attempt services in correct order
        verifyInOrder([
          mockEffisService.getFwi(lat: edinburghLat, lon: edinburghLon),
          mockSepaService.getCurrent(lat: edinburghLat, lon: edinburghLon),
          mockCacheService.get(key: anyNamed('key')),
        ]);

        expect(result.isRight(), isTrue);
        final fireRisk = result.getOrElse(() => throw Exception('Should not reach here'));
        expect(fireRisk.source, DataSource.mock);

        // Verify telemetry recorded attempts in correct order
        final attemptEvents = spyTelemetry.eventsOfType<AttemptStartEvent>();
        expect(attemptEvents.length, greaterThanOrEqualTo(3));
        expect(attemptEvents[0].source, TelemetrySource.effis);
        expect(attemptEvents[1].source, TelemetrySource.sepa);
        expect(attemptEvents[2].source, TelemetrySource.cache);
      });
    });
  });
}
