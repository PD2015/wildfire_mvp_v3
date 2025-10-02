import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/services/utils/geo_utils.dart';

/// Comprehensive unit tests for geographic utilities
///
/// Tests geohash generation, coordinate validation, Scotland boundary detection,
/// and privacy-compliant coordinate redaction.
void main() {
  group('GeographicUtils', () {
    group('geohash', () {
      test('generates consistent 5-character alphanumeric hash for same coordinates', () {
        const lat = 55.9533;
        const lon = -3.1883;
        
        final hash1 = GeographicUtils.geohash(lat, lon);
        final hash2 = GeographicUtils.geohash(lat, lon);
        
        expect(hash1, equals(hash2));
        expect(hash1.length, equals(5)); // Default precision
        expect(RegExp(r'^[a-z0-9]+$').hasMatch(hash1), isTrue);
      });

      test('generates different hashes for different coordinates', () {
        final hash1 = GeographicUtils.geohash(55.9533, -3.1883); // Edinburgh
        final hash2 = GeographicUtils.geohash(57.1497, -2.0943); // Aberdeen
        final hash3 = GeographicUtils.geohash(40.7128, -74.0060); // New York
        
        expect(hash1, isNot(equals(hash2)));
        expect(hash1, isNot(equals(hash3)));
        expect(hash2, isNot(equals(hash3)));
      });

      test('produces similar hashes for nearby coordinates', () {
        const baseHash = 'gcvwr1'; // Expected for Edinburgh area
        final hash1 = GeographicUtils.geohash(55.9533, -3.1883);
        final hash2 = GeographicUtils.geohash(55.9534, -3.1884); // Very close
        
        // Both should start with same prefix (geohash property)
        expect(hash1.substring(0, 4), equals(hash2.substring(0, 4)));
      });

      test('handles edge cases: poles and prime meridian', () {
        final northPole = GeographicUtils.geohash(90.0, 0.0);
        final southPole = GeographicUtils.geohash(-90.0, 0.0);
        final primeMeridian = GeographicUtils.geohash(0.0, 0.0);
        final dateLine = GeographicUtils.geohash(0.0, 180.0);
        
        expect(northPole.length, equals(5)); // Default precision
        expect(southPole.length, equals(5));
        expect(primeMeridian.length, equals(5));
        expect(dateLine.length, equals(5));
        
        // All should be different
        final hashes = [northPole, southPole, primeMeridian, dateLine];
        expect(hashes.toSet().length, equals(4));
      });

      test('handles precision edge cases', () {
        // Test high precision coordinates
        final highPrecision = GeographicUtils.geohash(55.953252123, -3.188267456);
        final rounded = GeographicUtils.geohash(55.953252, -3.188267);
        
        // Should produce same hash for similar precision levels
        expect(highPrecision.substring(0, 5), equals(rounded.substring(0, 5)));
      });
    });

    group('isInScotland', () {
      test('returns true for major Scottish cities', () {
        // Major Scottish cities
        expect(GeographicUtils.isInScotland(55.9533, -3.1883), isTrue); // Edinburgh
        expect(GeographicUtils.isInScotland(55.8642, -4.2518), isTrue); // Glasgow
        expect(GeographicUtils.isInScotland(57.1497, -2.0943), isTrue); // Aberdeen
        expect(GeographicUtils.isInScotland(56.4620, -2.9707), isTrue); // Dundee
        expect(GeographicUtils.isInScotland(56.1165, -3.9369), isTrue); // Stirling
      });

      test('returns false for locations outside Scotland', () {
        // Other UK locations
        expect(GeographicUtils.isInScotland(53.4808, -2.2426), isFalse); // Manchester
        expect(GeographicUtils.isInScotland(51.5074, -0.1278), isFalse); // London
        expect(GeographicUtils.isInScotland(53.9600, -1.0873), isFalse); // York
        expect(GeographicUtils.isInScotland(52.2053, 0.1218), isFalse); // Cambridge
        
        // International locations
        expect(GeographicUtils.isInScotland(40.7128, -74.0060), isFalse); // New York
        expect(GeographicUtils.isInScotland(48.8566, 2.3522), isFalse); // Paris
        expect(GeographicUtils.isInScotland(35.6762, 139.6503), isFalse); // Tokyo
      });

      test('handles boundary cases correctly with documented bounds', () {
        // Scotland bounds: 54.6-60.9°N, -9.0-1.0°E
        
        // Test latitude boundaries
        expect(GeographicUtils.isInScotland(54.6, -4.0), isTrue);  // Minimum lat
        expect(GeographicUtils.isInScotland(60.9, -4.0), isTrue);  // Maximum lat
        expect(GeographicUtils.isInScotland(54.59, -4.0), isFalse); // Just below
        expect(GeographicUtils.isInScotland(60.91, -4.0), isFalse); // Just above
        
        // Test longitude boundaries
        expect(GeographicUtils.isInScotland(56.0, -9.0), isTrue);  // Minimum lon
        expect(GeographicUtils.isInScotland(56.0, 1.0), isTrue);   // Maximum lon
        expect(GeographicUtils.isInScotland(56.0, -9.01), isFalse); // Just west
        expect(GeographicUtils.isInScotland(56.0, 1.01), isFalse);  // Just east
      });

      test('includes St Kilda and outer Scottish islands', () {
        // St Kilda (westernmost Scotland)
        expect(GeographicUtils.isInScotland(57.8133, -8.5783), isTrue);
        
        // Orkney Islands
        expect(GeographicUtils.isInScotland(59.0000, -3.0000), isTrue);
        
        // Shetland Islands
        expect(GeographicUtils.isInScotland(60.1552, -1.1540), isTrue);
        
        // Outer Hebrides
        expect(GeographicUtils.isInScotland(57.7000, -7.3000), isTrue);
      });

      test('excludes areas clearly outside Scotland box', () {
        // Isle of Man (south of Scotland boundary)
        expect(GeographicUtils.isInScotland(54.1566, -4.4811), isFalse); // Douglas - below 54.6°N
        
        // Areas clearly east of Scotland
        expect(GeographicUtils.isInScotland(55.0, 2.0), isFalse); // East of 1.0°E
        
        // Areas clearly west of Scotland  
        expect(GeographicUtils.isInScotland(55.0, -10.0), isFalse); // West of -9.0°W
        
        // Note: Simple box boundaries will include some non-Scottish areas like parts of Northern Ireland
        // This is a known limitation of rectangular boundary detection
      });

      test('handles extreme coordinates gracefully', () {
        // These should all be false without throwing
        expect(GeographicUtils.isInScotland(90.0, 0.0), isFalse);    // North Pole
        expect(GeographicUtils.isInScotland(-90.0, 0.0), isFalse);   // South Pole
        expect(GeographicUtils.isInScotland(0.0, 180.0), isFalse);   // Pacific
        expect(GeographicUtils.isInScotland(0.0, -180.0), isFalse);  // Pacific
      });
    });

    group('logRedact', () {
      test('redacts coordinate pairs to 2 decimal places for privacy', () {
        expect(GeographicUtils.logRedact(55.953252, -3.188267), equals('55.95,-3.19'));
        expect(GeographicUtils.logRedact(0.123456, -74.006012), equals('0.12,-74.01'));
        expect(GeographicUtils.logRedact(-89.123, 179.456), equals('-89.12,179.46')); // Valid coords
      });

      test('handles edge cases: zeros and boundaries', () {
        expect(GeographicUtils.logRedact(0.0, 0.0), equals('0.00,0.00'));
        expect(GeographicUtils.logRedact(-0.0, -0.0), equals('0.00,0.00'));
        expect(GeographicUtils.logRedact(90.0, 180.0), equals('90.00,180.00'));
        expect(GeographicUtils.logRedact(-90.0, -180.0), equals('-90.00,-180.00'));
      });

      test('handles very small numbers correctly', () {
        expect(GeographicUtils.logRedact(0.001, -0.001), equals('0.00,0.00'));
        expect(GeographicUtils.logRedact(0.009, -0.009), equals('0.01,-0.01'));
        expect(GeographicUtils.logRedact(-0.005, 0.006), equals('-0.01,0.01'));
      });

      test('maintains negative signs correctly', () {
        expect(GeographicUtils.logRedact(-1.5, 2.7), equals('-1.50,2.70'));
        expect(GeographicUtils.logRedact(1.5, -2.7), equals('1.50,-2.70'));
        expect(GeographicUtils.logRedact(-89.999, -0.1), equals('-90.00,-0.10')); // Valid coords
      });

      test('consistent rounding behavior', () {
        // Test standard rounding (0.5 rounds up)
        expect(GeographicUtils.logRedact(1.234, 2.235), equals('1.23,2.24')); // 0.5 rounds up
        expect(GeographicUtils.logRedact(1.236, -1.235), equals('1.24,-1.24'));
      });

      test('returns INVALID_COORDS for invalid input', () {
        expect(GeographicUtils.logRedact(double.nan, 0.0), equals('INVALID_COORDS'));
        expect(GeographicUtils.logRedact(0.0, double.infinity), equals('INVALID_COORDS'));
        expect(GeographicUtils.logRedact(91.0, 0.0), equals('INVALID_COORDS')); // Out of range
        expect(GeographicUtils.logRedact(0.0, 181.0), equals('INVALID_COORDS')); // Out of range
      });

      test('privacy compliance: actual coordinate pairs should be unrecoverable', () {
        const originalLat = 55.953252123;
        const originalLon = -3.188267456;
        
        final redacted = GeographicUtils.logRedact(originalLat, originalLon);
        expect(redacted, equals('55.95,-3.19'));
        
        // Verify precision loss means exact location cannot be recovered
        final parts = redacted.split(',');
        final redactedLat = double.parse(parts[0]);
        final redactedLon = double.parse(parts[1]);
        
        final precisionLossLat = (originalLat - redactedLat).abs();
        final precisionLossLon = (originalLon - redactedLon).abs();
        
        expect(precisionLossLat, greaterThan(0.001));
        expect(precisionLossLon, greaterThan(0.001));
      });
    });

    group('Coordinate Validation', () {
      test('validates latitude range [-90, 90]', () {
        // Valid latitudes
        expect(() => GeographicUtils.geohash(0, 0), returnsNormally);
        expect(() => GeographicUtils.geohash(90, 0), returnsNormally);
        expect(() => GeographicUtils.geohash(-90, 0), returnsNormally);
        expect(() => GeographicUtils.geohash(45.5, 0), returnsNormally);
        
        // Invalid latitudes should throw
        expect(() => GeographicUtils.geohash(91, 0), throwsArgumentError);
        expect(() => GeographicUtils.geohash(-91, 0), throwsArgumentError);
      });

      test('validates longitude range [-180, 180]', () {
        // Valid longitudes
        expect(() => GeographicUtils.geohash(0, 0), returnsNormally);
        expect(() => GeographicUtils.geohash(0, 180), returnsNormally);
        expect(() => GeographicUtils.geohash(0, -180), returnsNormally);
        expect(() => GeographicUtils.geohash(0, 123.45), returnsNormally);
        
        // Invalid longitudes should throw
        expect(() => GeographicUtils.geohash(0, 181), throwsArgumentError);
        expect(() => GeographicUtils.geohash(0, -181), throwsArgumentError);
      });

      test('handles special floating point values', () {
        // NaN and infinity are handled by the service layer validation
        // Utility methods should not crash
        expect(() => GeographicUtils.logRedact(double.nan, 0.0), returnsNormally);
        expect(() => GeographicUtils.logRedact(0.0, double.infinity), returnsNormally);
        expect(() => GeographicUtils.logRedact(double.negativeInfinity, 0.0), returnsNormally);
      });
    });

    group('Geographic Precision and Accuracy', () {
      test('geohash provides appropriate spatial resolution', () {
        // Test that nearby coordinates produce similar hashes
        const baseLat = 55.9533;
        const baseLon = -3.1883;
        
        final baseHash = GeographicUtils.geohash(baseLat, baseLon);
        
        // Points within ~100m should share most of the hash
        final nearbyHash = GeographicUtils.geohash(baseLat + 0.001, baseLon + 0.001);
        expect(baseHash.substring(0, 3), equals(nearbyHash.substring(0, 3))); // Share 3-char prefix
        
        // Points much farther away should produce different hashes entirely
        final farHash = GeographicUtils.geohash(50.0, 0.0); // London area
        expect(baseHash, isNot(equals(farHash))); // Completely different locations
      });

      test('Scotland boundary detection has reasonable buffer', () {
        // The boundary should be inclusive enough to catch all of Scotland
        // but exclusive enough to not include other countries
        
        // Test some known Scottish locations near the boundary
        expect(GeographicUtils.isInScotland(54.65, -2.5), isTrue);  // Near Gretna
        expect(GeographicUtils.isInScotland(60.85, -1.2), isTrue);  // Shetland
        
        // Test just outside Scotland
        expect(GeographicUtils.isInScotland(54.55, -2.5), isFalse); // Just south of border
      });

      test('coordinate redaction maintains geographical regions', () {
        // Redacted coordinates should still clearly indicate general region
        
        // Scottish coordinates should still look Scottish after redaction
        final scottishRedacted = GeographicUtils.logRedact(55.953252, -3.188267);
        expect(scottishRedacted, startsWith('55.'));
        expect(scottishRedacted, contains('-3.'));
        
        // US coordinates should still look like US
        final usRedacted = GeographicUtils.logRedact(40.712800, -74.006012);
        expect(usRedacted, startsWith('40.'));
        expect(usRedacted, contains('-74.'));
      });
    });

    group('Performance and Consistency', () {
      test('geohash computation is fast and consistent', () {
        const iterations = 1000;
        const lat = 55.9533;
        const lon = -3.1883;
        
        final stopwatch = Stopwatch()..start();
        String? lastHash;
        
        for (int i = 0; i < iterations; i++) {
          final hash = GeographicUtils.geohash(lat, lon);
          lastHash ??= hash;
          expect(hash, equals(lastHash)); // Consistency check
        }
        
        stopwatch.stop();
        
        // Should complete quickly (< 100ms for 1000 iterations)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('Scotland detection is fast for batch operations', () {
        final testCoordinates = [
          [55.9533, -3.1883], // Edinburgh
          [55.8642, -4.2518], // Glasgow
          [51.5074, -0.1278], // London
          [40.7128, -74.0060], // New York
          [57.8133, -8.5783], // St Kilda
        ];
        
        final stopwatch = Stopwatch()..start();
        
        for (final coords in testCoordinates) {
          for (int i = 0; i < 200; i++) { // 1000 total checks
            GeographicUtils.isInScotland(coords[0], coords[1]);
          }
        }
        
        stopwatch.stop();
        
        // Should complete quickly (< 50ms for 1000 operations)
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('coordinate redaction is consistent across multiple calls', () {
        const testLat = 55.953252123456789;
        const testLon = -3.188267890123456;
        const iterations = 100;
        
        String? firstResult;
        
        for (int i = 0; i < iterations; i++) {
          final result = GeographicUtils.logRedact(testLat, testLon);
          firstResult ??= result;
          expect(result, equals(firstResult));
        }
        
        expect(firstResult, equals('55.95,-3.19'));
      });
    });
  });
}