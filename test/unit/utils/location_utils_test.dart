import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';

void main() {
  group('LocationUtils', () {
    group('logRedact', () {
      test('formats positive coordinates to exactly 2 decimal places', () {
        expect(
          LocationUtils.logRedact(55.9533, -3.1883),
          equals('55.95,-3.19'),
        );
        expect(LocationUtils.logRedact(0.0, 0.0), equals('0.00,0.00'));
        expect(LocationUtils.logRedact(12.3, 45.6), equals('12.30,45.60'));
      });

      test('formats negative coordinates correctly', () {
        expect(
          LocationUtils.logRedact(-89.123456, -179.987654),
          equals('-89.12,-179.99'),
        );
        expect(LocationUtils.logRedact(-55.9, 3.1), equals('-55.90,3.10'));
        expect(LocationUtils.logRedact(55.9, -3.1), equals('55.90,-3.10'));
      });

      test('handles extreme coordinate values', () {
        expect(LocationUtils.logRedact(90.0, 180.0), equals('90.00,180.00'));
        expect(
          LocationUtils.logRedact(-90.0, -180.0),
          equals('-90.00,-180.00'),
        );
        expect(
          LocationUtils.logRedact(89.999999, 179.999999),
          equals('90.00,180.00'),
        );
      });

      test('rounds coordinates appropriately', () {
        // Test rounding up
        expect(LocationUtils.logRedact(55.996, -3.186), equals('56.00,-3.19'));

        // Test rounding down
        expect(LocationUtils.logRedact(55.994, -3.184), equals('55.99,-3.18'));

        // Test banker's rounding (round half to even)
        expect(LocationUtils.logRedact(55.995, -3.185), equals('55.99,-3.19'));
      });
      test('handles very small and very large numbers', () {
        expect(LocationUtils.logRedact(0.001, -0.001), equals('0.00,-0.00'));
        expect(LocationUtils.logRedact(0.009, -0.009), equals('0.01,-0.01'));
        expect(LocationUtils.logRedact(90.0, 180.0), equals('90.00,180.00'));
      });

      test('prevents PII exposure by limiting precision', () {
        // High precision input should be reduced to 2 decimals
        const highPrecisionLat = 55.953312345678901234567890;
        const highPrecisionLon = -3.188312345678901234567890;

        final result = LocationUtils.logRedact(
          highPrecisionLat,
          highPrecisionLon,
        );

        // Should only contain 2 decimal places
        expect(result, equals('55.95,-3.19'));

        // Verify no high precision data leaked
        expect(result, isNot(contains('953312')));
        expect(result, isNot(contains('188312')));
      });
    });

    group('isValidCoordinate', () {
      test('returns true for valid coordinates', () {
        expect(LocationUtils.isValidCoordinate(55.9533, -3.1883), isTrue);
        expect(LocationUtils.isValidCoordinate(0.0, 0.0), isTrue);
        expect(LocationUtils.isValidCoordinate(45.0, 90.0), isTrue);
        expect(LocationUtils.isValidCoordinate(-45.0, -90.0), isTrue);
      });

      test('returns true for boundary coordinates', () {
        // Exact boundaries should be valid
        expect(LocationUtils.isValidCoordinate(90.0, 180.0), isTrue);
        expect(LocationUtils.isValidCoordinate(-90.0, -180.0), isTrue);
        expect(LocationUtils.isValidCoordinate(90.0, -180.0), isTrue);
        expect(LocationUtils.isValidCoordinate(-90.0, 180.0), isTrue);
      });

      test('returns false for invalid latitude', () {
        // Latitude out of range [-90, 90]
        expect(LocationUtils.isValidCoordinate(90.1, 0.0), isFalse);
        expect(LocationUtils.isValidCoordinate(-90.1, 0.0), isFalse);
        expect(LocationUtils.isValidCoordinate(91.0, 0.0), isFalse);
        expect(LocationUtils.isValidCoordinate(-91.0, 0.0), isFalse);
        expect(LocationUtils.isValidCoordinate(999.0, 0.0), isFalse);
      });

      test('returns false for invalid longitude', () {
        // Longitude out of range [-180, 180]
        expect(LocationUtils.isValidCoordinate(0.0, 180.1), isFalse);
        expect(LocationUtils.isValidCoordinate(0.0, -180.1), isFalse);
        expect(LocationUtils.isValidCoordinate(0.0, 181.0), isFalse);
        expect(LocationUtils.isValidCoordinate(0.0, -181.0), isFalse);
        expect(LocationUtils.isValidCoordinate(0.0, 999.0), isFalse);
      });

      test('returns false for both coordinates invalid', () {
        expect(LocationUtils.isValidCoordinate(999.0, 999.0), isFalse);
        expect(LocationUtils.isValidCoordinate(-999.0, -999.0), isFalse);
        expect(LocationUtils.isValidCoordinate(91.0, 181.0), isFalse);
        expect(LocationUtils.isValidCoordinate(-91.0, -181.0), isFalse);
      });

      test('handles edge cases near boundaries', () {
        // Just inside boundaries
        expect(LocationUtils.isValidCoordinate(89.999999, 179.999999), isTrue);
        expect(
          LocationUtils.isValidCoordinate(-89.999999, -179.999999),
          isTrue,
        );

        // Just outside boundaries
        expect(LocationUtils.isValidCoordinate(90.000001, 0.0), isFalse);
        expect(LocationUtils.isValidCoordinate(0.0, 180.000001), isFalse);
      });

      test('handles special float values', () {
        // Test with very small numbers
        expect(LocationUtils.isValidCoordinate(0.0000001, 0.0000001), isTrue);
        expect(LocationUtils.isValidCoordinate(-0.0000001, -0.0000001), isTrue);
      });

      test('returns false for NaN coordinates', () {
        expect(LocationUtils.isValidCoordinate(double.nan, 0.0), isFalse);
        expect(LocationUtils.isValidCoordinate(0.0, double.nan), isFalse);
        expect(
            LocationUtils.isValidCoordinate(double.nan, double.nan), isFalse);
      });

      test('returns false for Infinity coordinates', () {
        expect(LocationUtils.isValidCoordinate(double.infinity, 0.0), isFalse);
        expect(LocationUtils.isValidCoordinate(double.negativeInfinity, 0.0),
            isFalse);
        expect(LocationUtils.isValidCoordinate(0.0, double.infinity), isFalse);
        expect(LocationUtils.isValidCoordinate(0.0, double.negativeInfinity),
            isFalse);
        expect(
            LocationUtils.isValidCoordinate(double.infinity, double.infinity),
            isFalse);
      });
    });

    group('logRedact error handling', () {
      test('handles NaN latitude gracefully', () {
        final result = LocationUtils.logRedact(double.nan, -3.1883);
        expect(result, equals('Invalid location'));
      });

      test('handles NaN longitude gracefully', () {
        final result = LocationUtils.logRedact(55.9533, double.nan);
        expect(result, equals('Invalid location'));
      });

      test('handles both NaN coordinates gracefully', () {
        final result = LocationUtils.logRedact(double.nan, double.nan);
        expect(result, equals('Invalid location'));
      });

      test('handles Infinity latitude gracefully', () {
        final result = LocationUtils.logRedact(double.infinity, -3.1883);
        expect(result, equals('Invalid location'));
      });

      test('handles negative Infinity latitude gracefully', () {
        final result =
            LocationUtils.logRedact(double.negativeInfinity, -3.1883);
        expect(result, equals('Invalid location'));
      });

      test('handles Infinity longitude gracefully', () {
        final result = LocationUtils.logRedact(55.9533, double.infinity);
        expect(result, equals('Invalid location'));
      });

      test('handles negative Infinity longitude gracefully', () {
        final result =
            LocationUtils.logRedact(55.9533, double.negativeInfinity);
        expect(result, equals('Invalid location'));
      });

      test('handles both Infinity coordinates gracefully', () {
        final result =
            LocationUtils.logRedact(double.infinity, double.infinity);
        expect(result, equals('Invalid location'));
      });

      test('handles out-of-range latitude (>90)', () {
        final result = LocationUtils.logRedact(91.0, -3.1883);
        expect(result, equals('Invalid location'));
      });

      test('handles out-of-range latitude (<-90)', () {
        final result = LocationUtils.logRedact(-91.0, -3.1883);
        expect(result, equals('Invalid location'));
      });

      test('handles out-of-range longitude (>180)', () {
        final result = LocationUtils.logRedact(55.9533, 181.0);
        expect(result, equals('Invalid location'));
      });

      test('handles out-of-range longitude (<-180)', () {
        final result = LocationUtils.logRedact(55.9533, -181.0);
        expect(result, equals('Invalid location'));
      });

      test('handles extreme out-of-range coordinates', () {
        final result = LocationUtils.logRedact(999.0, 999.0);
        expect(result, equals('Invalid location'));
      });
    });

    group('Gate C2 compliance verification', () {
      test('logRedact never exposes more than 2 decimal places', () {
        // Test a variety of high-precision inputs (all within valid ranges)
        final testCases = [
          [55.953312345678, -3.188312345678],
          [89.123456789012, 179.987654321098],
          [-89.111111111111, -179.222222222222],
          [0.999999999999, 0.111111111111],
        ];

        for (final testCase in testCases) {
          final result = LocationUtils.logRedact(testCase[0], testCase[1]);

          // Result should not be an error
          expect(result, isNot(equals('Invalid location')),
              reason:
                  'Coordinate ${testCase[0]}, ${testCase[1]} should be valid');

          // Split by comma to check each coordinate
          final parts = result.split(',');
          expect(parts.length, equals(2));

          // Check each part has exactly 2 decimal places
          for (final part in parts) {
            // Remove negative sign for decimal checking
            final absValue = part.replaceFirst(RegExp(r'^-'), '');

            if (absValue.contains('.')) {
              final decimalPart = absValue.split('.')[1];
              expect(
                decimalPart.length,
                equals(2),
                reason: 'Coordinate $part should have exactly 2 decimal places',
              );
            } else {
              fail(
                'Coordinate $part should always contain decimal point with 2 places',
              );
            }
          }
        }
      });

      test('logRedact output format is consistent', () {
        final result = LocationUtils.logRedact(55.9, -3.1);

        // Should always follow the pattern: number.dd,number.dd
        expect(result, matches(RegExp(r'^-?\d+\.\d{2},-?\d+\.\d{2}$')));
      });
    });
  });
}
