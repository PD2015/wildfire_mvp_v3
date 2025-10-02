import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

/// Unit tests for RiskLevel FWI mapping boundaries
///
/// Tests verify correct FWI value to risk level mapping per docs/DATA-SOURCES.md:
/// - < 5 → Very Low
/// - 5–11 → Low
/// - 12–20 → Moderate
/// - 21–37 → High
/// - 38–49 → Very High
/// - ≥ 50 → Extreme
void main() {
  group('RiskLevel', () {
    group('fromFwi() mapping boundaries', () {
      test('FWI < 5 should map to veryLow', () {
        // Test boundary values for veryLow category
        expect(RiskLevel.fromFwi(0.0), equals(RiskLevel.veryLow));
        expect(RiskLevel.fromFwi(4.0), equals(RiskLevel.veryLow));
        expect(RiskLevel.fromFwi(4.99), equals(RiskLevel.veryLow));
      });

      test('FWI 5-11.99 should map to low', () {
        // Test boundary values for low category
        expect(RiskLevel.fromFwi(5.0), equals(RiskLevel.low));
        expect(RiskLevel.fromFwi(8.0), equals(RiskLevel.low));
        expect(RiskLevel.fromFwi(11.99), equals(RiskLevel.low));
      });

      test('FWI 12-20.99 should map to moderate', () {
        // Test boundary values for moderate category (includes our test fixture FWI=12.0)
        expect(RiskLevel.fromFwi(12.0), equals(RiskLevel.moderate));
        expect(RiskLevel.fromFwi(16.0), equals(RiskLevel.moderate));
        expect(RiskLevel.fromFwi(20.99), equals(RiskLevel.moderate));
      });

      test('FWI 21-37.99 should map to high', () {
        // Test boundary values for high category
        expect(RiskLevel.fromFwi(21.0), equals(RiskLevel.high));
        expect(RiskLevel.fromFwi(29.0), equals(RiskLevel.high));
        expect(RiskLevel.fromFwi(37.99), equals(RiskLevel.high));
      });

      test('FWI 38-49.99 should map to veryHigh', () {
        // Test boundary values for veryHigh category
        expect(RiskLevel.fromFwi(38.0), equals(RiskLevel.veryHigh));
        expect(RiskLevel.fromFwi(43.0), equals(RiskLevel.veryHigh));
        expect(RiskLevel.fromFwi(49.99), equals(RiskLevel.veryHigh));
      });

      test('FWI >= 50 should map to extreme', () {
        // Test boundary values for extreme category
        expect(RiskLevel.fromFwi(50.0), equals(RiskLevel.extreme));
        expect(RiskLevel.fromFwi(75.0), equals(RiskLevel.extreme));
        expect(RiskLevel.fromFwi(100.0), equals(RiskLevel.extreme));
      });
    });

    group('specific boundary test values per specification', () {
      test('test fixture values from docs/DATA-SOURCES.md', () {
        // These are the exact boundary values specified in DATA-SOURCES.md
        expect(RiskLevel.fromFwi(4), equals(RiskLevel.veryLow)); // < 5
        expect(RiskLevel.fromFwi(5), equals(RiskLevel.low)); // 5–11
        expect(RiskLevel.fromFwi(12), equals(RiskLevel.moderate)); // 12–20
        expect(RiskLevel.fromFwi(21), equals(RiskLevel.high)); // 21–37
        expect(RiskLevel.fromFwi(38), equals(RiskLevel.veryHigh)); // 38–49
        expect(RiskLevel.fromFwi(50), equals(RiskLevel.extreme)); // ≥ 50
      });
    });

    group('edge cases and validation', () {
      test('should handle negative FWI values', () {
        // Negative FWI values are invalid per data-model.md but should not crash
        expect(() => RiskLevel.fromFwi(-1.0), throwsArgumentError);
      });

      test('should handle very high FWI values', () {
        // Test extreme values beyond typical ranges
        expect(RiskLevel.fromFwi(200.0), equals(RiskLevel.extreme));
        expect(RiskLevel.fromFwi(1000.0), equals(RiskLevel.extreme));
      });
    });

    group('enum values and string representation', () {
      test('should have correct enum values', () {
        // Verify all expected risk levels exist
        expect(RiskLevel.values.length, equals(6));
        expect(RiskLevel.values, contains(RiskLevel.veryLow));
        expect(RiskLevel.values, contains(RiskLevel.low));
        expect(RiskLevel.values, contains(RiskLevel.moderate));
        expect(RiskLevel.values, contains(RiskLevel.high));
        expect(RiskLevel.values, contains(RiskLevel.veryHigh));
        expect(RiskLevel.values, contains(RiskLevel.extreme));
      });
    });
  });
}
