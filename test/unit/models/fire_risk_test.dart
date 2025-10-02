import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

void main() {
  group('FireRisk', () {
    final testDateTime = DateTime.utc(2025, 10, 2, 14, 30);

    group('constructor validation', () {
      test('accepts valid UTC timestamp', () {
        final fireRisk = FireRisk(
          level: RiskLevel.moderate,
          fwi: 15.5,
          source: DataSource.effis,
          observedAt: testDateTime,
          freshness: Freshness.live,
        );

        expect(fireRisk.level, RiskLevel.moderate);
        expect(fireRisk.fwi, 15.5);
        expect(fireRisk.source, DataSource.effis);
        expect(fireRisk.observedAt, testDateTime);
        expect(fireRisk.freshness, Freshness.live);
      });

      test('throws on non-UTC timestamp', () {
        final nonUtcDateTime = DateTime(2025, 10, 2, 14, 30); // Local timezone

        expect(
          () => FireRisk(
            level: RiskLevel.moderate,
            source: DataSource.effis,
            observedAt: nonUtcDateTime,
            freshness: Freshness.live,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('factory constructors', () {
      test('fromEffis sets source and freshness correctly', () {
        final fireRisk = FireRisk.fromEffis(
          level: RiskLevel.high,
          fwi: 25.0,
          observedAt: testDateTime,
        );

        expect(fireRisk.level, RiskLevel.high);
        expect(fireRisk.fwi, 25.0);
        expect(fireRisk.source, DataSource.effis);
        expect(fireRisk.freshness, Freshness.live);
        expect(fireRisk.observedAt, testDateTime);
      });

      test('fromSepa sets source and freshness correctly', () {
        final fireRisk = FireRisk.fromSepa(
          level: RiskLevel.low,
          fwi: 8.5,
          observedAt: testDateTime,
        );

        expect(fireRisk.level, RiskLevel.low);
        expect(fireRisk.fwi, 8.5);
        expect(fireRisk.source, DataSource.sepa);
        expect(fireRisk.freshness, Freshness.live);
        expect(fireRisk.observedAt, testDateTime);
      });

      test('fromSepa allows null FWI', () {
        final fireRisk = FireRisk.fromSepa(
          level: RiskLevel.moderate,
          fwi: null,
          observedAt: testDateTime,
        );

        expect(fireRisk.level, RiskLevel.moderate);
        expect(fireRisk.fwi, isNull);
        expect(fireRisk.source, DataSource.sepa);
        expect(fireRisk.freshness, Freshness.live);
      });

      test('fromCache preserves original source and sets cached freshness', () {
        final fireRisk = FireRisk.fromCache(
          level: RiskLevel.veryHigh,
          fwi: 42.0,
          originalSource: DataSource.effis,
          observedAt: testDateTime,
        );

        expect(fireRisk.level, RiskLevel.veryHigh);
        expect(fireRisk.fwi, 42.0);
        expect(fireRisk.source, DataSource.effis); // Original source preserved
        expect(fireRisk.freshness, Freshness.cached);
        expect(fireRisk.observedAt, testDateTime);
      });

      test('fromMock sets source and freshness correctly with null FWI', () {
        final fireRisk = FireRisk.fromMock(
          level: RiskLevel.moderate,
          observedAt: testDateTime,
        );

        expect(fireRisk.level, RiskLevel.moderate);
        expect(fireRisk.fwi, isNull); // Mock service doesn't provide FWI
        expect(fireRisk.source, DataSource.mock);
        expect(fireRisk.freshness, Freshness.mock);
        expect(fireRisk.observedAt, testDateTime);
      });

      test('factory constructors validate UTC timestamp', () {
        final nonUtcDateTime = DateTime(2025, 10, 2, 14, 30); // Local timezone

        expect(
          () => FireRisk.fromEffis(
            level: RiskLevel.moderate,
            fwi: 15.0,
            observedAt: nonUtcDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => FireRisk.fromSepa(
            level: RiskLevel.moderate,
            observedAt: nonUtcDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => FireRisk.fromCache(
            level: RiskLevel.moderate,
            originalSource: DataSource.effis,
            observedAt: nonUtcDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => FireRisk.fromMock(
            level: RiskLevel.moderate,
            observedAt: nonUtcDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('equality and toString', () {
      test('supports value equality', () {
        final fireRisk1 = FireRisk.fromEffis(
          level: RiskLevel.moderate,
          fwi: 15.5,
          observedAt: testDateTime,
        );

        final fireRisk2 = FireRisk.fromEffis(
          level: RiskLevel.moderate,
          fwi: 15.5,
          observedAt: testDateTime,
        );

        final fireRisk3 = FireRisk.fromEffis(
          level: RiskLevel.high, // Different level
          fwi: 15.5,
          observedAt: testDateTime,
        );

        expect(fireRisk1, equals(fireRisk2));
        expect(fireRisk1, isNot(equals(fireRisk3)));
      });

      test('provides meaningful toString', () {
        final fireRisk = FireRisk.fromEffis(
          level: RiskLevel.moderate,
          fwi: 15.5,
          observedAt: testDateTime,
        );

        final string = fireRisk.toString();
        expect(string, contains('FireRisk'));
        expect(string, contains('moderate'));
        expect(string, contains('15.5'));
        expect(string, contains('effis'));
        expect(string, contains('live'));
      });
    });

    group('enum validation', () {
      test('DataSource enum has expected values', () {
        expect(DataSource.values, [
          DataSource.effis,
          DataSource.sepa,
          DataSource.cache,
          DataSource.mock,
        ]);
      });

      test('Freshness enum has expected values', () {
        expect(Freshness.values, [
          Freshness.live,
          Freshness.cached,
          Freshness.mock,
        ]);
      });
    });
  });

  // TODO: Add coordinate validation tests when service implementation is ready
  // These tests should verify that invalid coordinates (NaN, ±Infinity, out-of-range)
  // are handled by the FireRiskService implementation, not the model itself.
  group('coordinate validation (TODO for service layer)', () {
    test('TODO: NaN coordinates should be handled by service', () {
      // Will be implemented when FireRiskService implementation is ready
      // Should test: service.getCurrent(lat: double.nan, lon: 0.0)
      // Expected: Left(ApiError.invalidCoordinates)
    });

    test('TODO: ±Infinity coordinates should be handled by service', () {
      // Will be implemented when FireRiskService implementation is ready
      // Should test: service.getCurrent(lat: double.infinity, lon: 0.0)
      // Expected: Left(ApiError.invalidCoordinates)
    });

    test('TODO: out-of-range coordinates should be handled by service', () {
      // Will be implemented when FireRiskService implementation is ready
      // Should test: service.getCurrent(lat: 91.0, lon: 181.0)
      // Expected: Left(ApiError.invalidCoordinates)
    });
  });
}
