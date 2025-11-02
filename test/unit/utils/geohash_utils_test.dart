import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/utils/geohash_utils.dart';

void main() {
  group('GeohashUtils', () {
    group('encode', () {
      test('Edinburgh coordinates encode to reference geohash "gcvwr"', () {
        // Edinburgh coordinates (55.9533, -3.1883) at precision 5
        final result = GeohashUtils.encode(55.9533, -3.1883, precision: 5);
        expect(result, equals('gcvwr'));
      });

      test('encodes same coordinates consistently', () {
        const lat = 55.9533;
        const lon = -3.1883;
        final result1 = GeohashUtils.encode(lat, lon);
        final result2 = GeohashUtils.encode(lat, lon);
        expect(result1, equals(result2));
      });

      test('different precision produces different length results', () {
        const lat = 55.9533;
        const lon = -3.1883;
        final result3 = GeohashUtils.encode(lat, lon, precision: 3);
        final result5 = GeohashUtils.encode(lat, lon, precision: 5);
        final result7 = GeohashUtils.encode(lat, lon, precision: 7);

        expect(result3.length, equals(3));
        expect(result5.length, equals(5));
        expect(result7.length, equals(7));
      });

      test('handles edge cases correctly', () {
        // North Pole
        final northPole = GeohashUtils.encode(90.0, 0.0, precision: 5);
        expect(northPole.length, equals(5));

        // South Pole
        final southPole = GeohashUtils.encode(-90.0, 0.0, precision: 5);
        expect(southPole.length, equals(5));

        // Prime Meridian
        final primeMeridian = GeohashUtils.encode(51.4778, 0.0, precision: 5);
        expect(primeMeridian.length, equals(5));

        // International Date Line
        final dateLine = GeohashUtils.encode(0.0, 180.0, precision: 5);
        expect(dateLine.length, equals(5));
      });

      test('throws ArgumentError for invalid coordinates', () {
        expect(() => GeohashUtils.encode(91.0, 0.0), throwsArgumentError);
        expect(() => GeohashUtils.encode(-91.0, 0.0), throwsArgumentError);
        expect(() => GeohashUtils.encode(0.0, 181.0), throwsArgumentError);
        expect(() => GeohashUtils.encode(0.0, -181.0), throwsArgumentError);
      });

      test('throws ArgumentError for invalid precision', () {
        expect(
          () => GeohashUtils.encode(55.9533, -3.1883, precision: 0),
          throwsArgumentError,
        );
        expect(
          () => GeohashUtils.encode(55.9533, -3.1883, precision: -1),
          throwsArgumentError,
        );
      });
    });

    group('isValid', () {
      test('returns true for valid geohash strings', () {
        expect(GeohashUtils.isValid('gcvwr'), isTrue);
        expect(GeohashUtils.isValid('0123456789'), isTrue);
        expect(GeohashUtils.isValid('bcdefghjkmnpqrstuvwxyz'), isTrue);
        expect(GeohashUtils.isValid('u4pruydqqvj'), isTrue); // San Francisco
      });

      test('returns false for invalid characters', () {
        expect(GeohashUtils.isValid('gcvwr1a'), isFalse); // contains 'a'
        expect(GeohashUtils.isValid('gcvwri'), isFalse); // contains 'i'
        expect(GeohashUtils.isValid('gcvwrl'), isFalse); // contains 'l'
        expect(GeohashUtils.isValid('gcvwro'), isFalse); // contains 'o'
        expect(GeohashUtils.isValid('GCVWR'), isFalse); // uppercase
      });

      test('returns false for empty string', () {
        expect(GeohashUtils.isValid(''), isFalse);
      });

      test('returns false for strings with spaces or special characters', () {
        expect(GeohashUtils.isValid('gcv wr'), isFalse);
        expect(GeohashUtils.isValid('gcv-wr'), isFalse);
        expect(GeohashUtils.isValid('gcv_wr'), isFalse);
        expect(GeohashUtils.isValid('gcv.wr'), isFalse);
      });
    });
  });
}
