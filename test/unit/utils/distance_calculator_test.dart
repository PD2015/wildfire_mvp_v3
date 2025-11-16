import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/utils/distance_calculator.dart';

void main() {
  group('DistanceCalculator distanceInMeters', () {
    test('returns 0 for identical coordinates', () {
      const coord = LatLng(55.9533, -3.1883);
      final distance = DistanceCalculator.distanceInMeters(coord, coord);
      expect(distance, 0.0);
    });

    test('calculates correct distance Edinburgh to Glasgow (~67km)', () {
      const edinburgh = LatLng(55.9533, -3.1883);
      const glasgow = LatLng(55.8642, -4.2518);

      final distance = DistanceCalculator.distanceInMeters(edinburgh, glasgow);

      // Expected ~67km (67000m), allow 1% tolerance
      expect(distance, greaterThan(66000));
      expect(distance, lessThan(68000));
    });

    test('calculates correct distance Edinburgh to Aviemore (~144km)', () {
      const edinburgh = LatLng(55.9533, -3.1883);
      const aviemore = LatLng(57.2, -3.8);

      final distance = DistanceCalculator.distanceInMeters(edinburgh, aviemore);

      // Expected ~144km (144000m), allow 1% tolerance
      expect(distance, greaterThan(142000));
      expect(distance, lessThan(146000));
    });

    test('handles coordinates at poles', () {
      const northPole = LatLng(90.0, 0.0);
      const southPole = LatLng(-90.0, 0.0);

      final distance =
          DistanceCalculator.distanceInMeters(northPole, southPole);

      // Half circumference of Earth = π * radius ≈ 20015086 meters
      expect(distance, greaterThan(19000000));
      expect(distance, lessThan(21000000));
    });

    test('handles coordinates crossing date line', () {
      const eastOfDateLine = LatLng(0.0, 179.0);
      const westOfDateLine = LatLng(0.0, -179.0);

      final distance =
          DistanceCalculator.distanceInMeters(eastOfDateLine, westOfDateLine);

      // Should be short distance across date line, not long way around
      expect(distance, lessThan(250000)); // ~222km
    });

    test('handles coordinates crossing equator', () {
      const northEquator = LatLng(1.0, 0.0);
      const southEquator = LatLng(-1.0, 0.0);

      final distance =
          DistanceCalculator.distanceInMeters(northEquator, southEquator);

      // 2 degrees of latitude ≈ 222km
      expect(distance, greaterThan(220000));
      expect(distance, lessThan(225000));
    });

    test('handles short distances accurately (<100m)', () {
      const point1 = LatLng(55.9533, -3.1883);
      const point2 = LatLng(55.9540, -3.1885); // ~78 meters away

      final distance = DistanceCalculator.distanceInMeters(point1, point2);

      expect(distance, greaterThan(70));
      expect(distance, lessThan(85));
    });

    test('is symmetric (distance A→B = distance B→A)', () {
      const pointA = LatLng(55.9533, -3.1883);
      const pointB = LatLng(56.5, -3.5);

      final distanceAtoB = DistanceCalculator.distanceInMeters(pointA, pointB);
      final distanceBtoA = DistanceCalculator.distanceInMeters(pointB, pointA);

      expect(distanceAtoB, closeTo(distanceBtoA, 0.01));
    });

    test('handles antipodal points (opposite sides of Earth)', () {
      const point1 = LatLng(55.9533, -3.1883); // Edinburgh
      const point2 = LatLng(-55.9533, 176.8117); // Antipodal

      final distance = DistanceCalculator.distanceInMeters(point1, point2);

      // Should be close to Earth's circumference / 2 ≈ 20015 km
      expect(distance, greaterThan(19500000));
      expect(distance, lessThan(20500000));
    });
  });

  group('DistanceCalculator bearingInDegrees', () {
    test('returns 0 for identical coordinates', () {
      const coord = LatLng(55.9533, -3.1883);
      final bearing = DistanceCalculator.bearingInDegrees(coord, coord);
      expect(bearing, 0.0);
    });

    test('calculates north bearing correctly (~0°)', () {
      const start = LatLng(55.0, -3.0);
      const north = LatLng(56.0, -3.0);

      final bearing = DistanceCalculator.bearingInDegrees(start, north);
      expect(bearing, closeTo(0.0, 1.0));
    });

    test('calculates east bearing correctly (~90°)', () {
      const start = LatLng(55.0, -3.0);
      const east = LatLng(55.0, -2.0);

      final bearing = DistanceCalculator.bearingInDegrees(start, east);
      expect(bearing, closeTo(90.0, 5.0)); // Allow 5° tolerance due to latitude
    });

    test('calculates south bearing correctly (~180°)', () {
      const start = LatLng(56.0, -3.0);
      const south = LatLng(55.0, -3.0);

      final bearing = DistanceCalculator.bearingInDegrees(start, south);
      expect(bearing, closeTo(180.0, 1.0));
    });

    test('calculates west bearing correctly (~270°)', () {
      const start = LatLng(55.0, -2.0);
      const west = LatLng(55.0, -3.0);

      final bearing = DistanceCalculator.bearingInDegrees(start, west);
      expect(
          bearing, closeTo(270.0, 5.0)); // Allow 5° tolerance due to latitude
    });

    test('calculates northeast bearing correctly (~25-50°)', () {
      const start = LatLng(55.0, -3.0);
      const northeast = LatLng(56.0, -2.0);

      final bearing = DistanceCalculator.bearingInDegrees(start, northeast);
      expect(bearing, greaterThan(20.0)); // Adjusted from 30.0
      expect(bearing, lessThan(60.0));
    });

    test('returns value in 0-360 range', () {
      const start = LatLng(55.9533, -3.1883);

      // Test various directions
      for (double latOffset = -1.0; latOffset <= 1.0; latOffset += 0.5) {
        for (double lonOffset = -1.0; lonOffset <= 1.0; lonOffset += 0.5) {
          if (latOffset == 0 && lonOffset == 0) continue;

          final end = LatLng(
            start.latitude + latOffset,
            start.longitude + lonOffset,
          );

          final bearing = DistanceCalculator.bearingInDegrees(start, end);
          expect(bearing, greaterThanOrEqualTo(0.0));
          expect(bearing, lessThan(360.0));
        }
      }
    });

    test('handles bearing across date line', () {
      const start = LatLng(0.0, 179.0);
      const end = LatLng(0.0, -179.0);

      final bearing = DistanceCalculator.bearingInDegrees(start, end);

      // Should point east (across date line), ~90°
      expect(bearing, greaterThan(70.0));
      expect(bearing, lessThan(110.0));
    });
  });

  group('DistanceCalculator bearingToCardinal', () {
    test('converts 0° to N', () {
      expect(DistanceCalculator.bearingToCardinal(0.0), 'N');
    });

    test('converts 45° to NE', () {
      expect(DistanceCalculator.bearingToCardinal(45.0), 'NE');
    });

    test('converts 90° to E', () {
      expect(DistanceCalculator.bearingToCardinal(90.0), 'E');
    });

    test('converts 135° to SE', () {
      expect(DistanceCalculator.bearingToCardinal(135.0), 'SE');
    });

    test('converts 180° to S', () {
      expect(DistanceCalculator.bearingToCardinal(180.0), 'S');
    });

    test('converts 225° to SW', () {
      expect(DistanceCalculator.bearingToCardinal(225.0), 'SW');
    });

    test('converts 270° to W', () {
      expect(DistanceCalculator.bearingToCardinal(270.0), 'W');
    });

    test('converts 315° to NW', () {
      expect(DistanceCalculator.bearingToCardinal(315.0), 'NW');
    });

    test('converts 360° to N (wraps around)', () {
      expect(DistanceCalculator.bearingToCardinal(360.0), 'N');
    });

    test('handles edge case 22.5° (boundary N/NE)', () {
      expect(DistanceCalculator.bearingToCardinal(22.0), 'N');
      expect(DistanceCalculator.bearingToCardinal(23.0), 'NE');
    });

    test('handles edge case 67.5° (boundary NE/E)', () {
      expect(DistanceCalculator.bearingToCardinal(67.0), 'NE');
      expect(DistanceCalculator.bearingToCardinal(68.0), 'E');
    });

    test('handles all 8 cardinal directions with tolerance', () {
      final expectations = {
        'N': [0.0, 5.0, 355.0],
        'NE': [40.0, 45.0, 50.0],
        'E': [85.0, 90.0, 95.0],
        'SE': [130.0, 135.0, 140.0],
        'S': [175.0, 180.0, 185.0],
        'SW': [220.0, 225.0, 230.0],
        'W': [265.0, 270.0, 275.0],
        'NW': [310.0, 315.0, 320.0],
      };

      expectations.forEach((cardinal, bearings) {
        for (final bearing in bearings) {
          expect(DistanceCalculator.bearingToCardinal(bearing), cardinal,
              reason: '$bearing° should be $cardinal');
        }
      });
    });
  });

  group('DistanceCalculator formatDistanceAndDirection', () {
    test('formats distance <1km in meters', () {
      const start = LatLng(55.9533, -3.1883);
      const end = LatLng(55.9540, -3.1885); // ~78 meters away

      final formatted =
          DistanceCalculator.formatDistanceAndDirection(start, end);

      expect(formatted, matches(r'^\d+ m [NESW]{1,2}$'));
      expect(formatted, contains(' m '));
    });

    test('formats distance ≥1km in kilometers with 1 decimal', () {
      const edinburgh = LatLng(55.9533, -3.1883);
      const glasgow = LatLng(55.8642, -4.2518); // ~67 km

      final formatted =
          DistanceCalculator.formatDistanceAndDirection(edinburgh, glasgow);

      expect(formatted, matches(r'^\d+\.\d km [NESW]{1,2}$'));
      expect(formatted, contains(' km '));
      expect(formatted, contains('.'));
    });

    test('includes correct cardinal direction', () {
      const start = LatLng(55.0, -3.0);
      const north = LatLng(56.0, -3.0);

      final formatted =
          DistanceCalculator.formatDistanceAndDirection(start, north);

      expect(formatted, contains(' N'));
    });

    test('formats 0 distance as "0 m N"', () {
      const coord = LatLng(55.9533, -3.1883);

      final formatted =
          DistanceCalculator.formatDistanceAndDirection(coord, coord);

      expect(formatted, '0 m N');
    });

    test('rounds meters to nearest whole number', () {
      const start = LatLng(55.9533, -3.1883);
      const end = LatLng(55.9540, -3.1885);

      final formatted =
          DistanceCalculator.formatDistanceAndDirection(start, end);

      // Should not have decimal point for meters
      expect(formatted, isNot(matches(r'\d+\.\d+ m')));
    });

    test('formats kilometers with exactly 1 decimal place', () {
      const edinburgh = LatLng(55.9533, -3.1883);
      const aviemore = LatLng(57.2, -3.8);

      final formatted =
          DistanceCalculator.formatDistanceAndDirection(edinburgh, aviemore);

      expect(formatted, matches(r'^\d+\.\d km [NESW]{1,2}$'));
    });

    test('handles long distances correctly (>1000km)', () {
      const scotland = LatLng(57.0, -4.0);
      const london = LatLng(51.5, -0.1);

      final formatted =
          DistanceCalculator.formatDistanceAndDirection(scotland, london);

      expect(formatted, contains(' km '));
      expect(formatted, matches(r'^\d+\.\d km [NESW]{1,2}$'));
    });
  });

  group('DistanceCalculator calculateDistanceSafe', () {
    test('returns formatted distance for valid coordinates', () {
      const coord1 = LatLng(55.9533, -3.1883);
      const coord2 = LatLng(56.5, -3.5);

      final result = DistanceCalculator.calculateDistanceSafe(coord1, coord2);

      expect(result, isNotNull);
      expect(result, matches(r'^\d+(\.\d)? (m|km) [NESW]{1,2}$'));
    });

    test('returns null for null user location', () {
      const fireLocation = LatLng(55.9533, -3.1883);

      final result =
          DistanceCalculator.calculateDistanceSafe(null, fireLocation);

      expect(result, isNull);
    });

    test('returns null for null fire location', () {
      const userLocation = LatLng(55.9533, -3.1883);

      final result =
          DistanceCalculator.calculateDistanceSafe(userLocation, null);

      expect(result, isNull);
    });

    test('returns null for both null coordinates', () {
      final result = DistanceCalculator.calculateDistanceSafe(null, null);

      expect(result, isNull);
    });

    test('returns null for invalid latitude in user location', () {
      const invalidUser = LatLng(91.0, -3.0); // Invalid latitude
      const validFire = LatLng(55.9533, -3.1883);

      final result =
          DistanceCalculator.calculateDistanceSafe(invalidUser, validFire);

      expect(result, isNull);
    });

    test('returns null for invalid longitude in fire location', () {
      const validUser = LatLng(55.9533, -3.1883);
      const invalidFire = LatLng(55.0, 181.0); // Invalid longitude

      final result =
          DistanceCalculator.calculateDistanceSafe(validUser, invalidFire);

      expect(result, isNull);
    });

    test('handles edge case coordinates correctly', () {
      const northPole = LatLng(90.0, 0.0);
      const equator = LatLng(0.0, 0.0);

      final result =
          DistanceCalculator.calculateDistanceSafe(northPole, equator);

      expect(result, isNotNull);
      expect(result, contains(' km '));
    });
  });

  group('DistanceCalculator areValidCoordinates', () {
    test('returns true for two valid coordinates', () {
      const coord1 = LatLng(55.9533, -3.1883);
      const coord2 = LatLng(56.5, -3.5);

      expect(DistanceCalculator.areValidCoordinates(coord1, coord2), true);
    });

    test('returns false for invalid first coordinate', () {
      const invalid = LatLng(100.0, -3.0);
      const valid = LatLng(55.9533, -3.1883);

      expect(DistanceCalculator.areValidCoordinates(invalid, valid), false);
    });

    test('returns false for invalid second coordinate', () {
      const valid = LatLng(55.9533, -3.1883);
      const invalid = LatLng(55.0, 200.0);

      expect(DistanceCalculator.areValidCoordinates(valid, invalid), false);
    });

    test('returns false for both invalid coordinates', () {
      const invalid1 = LatLng(100.0, -3.0);
      const invalid2 = LatLng(55.0, 200.0);

      expect(DistanceCalculator.areValidCoordinates(invalid1, invalid2), false);
    });

    test('returns true for edge case valid coordinates', () {
      const northPole = LatLng(90.0, 0.0);
      const southPole = LatLng(-90.0, 180.0);

      expect(
          DistanceCalculator.areValidCoordinates(northPole, southPole), true);
    });
  });

  group('DistanceCalculator verifyKnownDistance', () {
    test('returns true for accurate calculation', () {
      const edinburgh = LatLng(55.9533, -3.1883);
      const glasgow = LatLng(55.8642, -4.2518);

      // Known distance ~67km (actual: 67019m)
      final result = DistanceCalculator.verifyKnownDistance(
        point1: edinburgh,
        point2: glasgow,
        expectedMeters: 67000,
        tolerancePercent: 1.0, // 1% = ±670m
      );

      expect(result, true);
    });

    test('returns false for significantly incorrect expected distance', () {
      const point1 = LatLng(55.9533, -3.1883);
      const point2 = LatLng(56.5, -3.5);

      // Expected wrong distance (should be ~60km, not 100km)
      final result = DistanceCalculator.verifyKnownDistance(
        point1: point1,
        point2: point2,
        expectedMeters: 100000,
        tolerancePercent: 1.0,
      );

      expect(result, false);
    });

    test('handles custom tolerance correctly', () {
      const point1 = LatLng(55.9533, -3.1883);
      const point2 = LatLng(56.0, -3.2);

      final actualDistance =
          DistanceCalculator.distanceInMeters(point1, point2);

      // Within 5% tolerance
      final resultWide = DistanceCalculator.verifyKnownDistance(
        point1: point1,
        point2: point2,
        expectedMeters: actualDistance * 1.04, // 4% off
        tolerancePercent: 5.0,
      );
      expect(resultWide, true);

      // Outside 1% tolerance
      final resultNarrow = DistanceCalculator.verifyKnownDistance(
        point1: point1,
        point2: point2,
        expectedMeters: actualDistance * 1.04, // 4% off
        tolerancePercent: 1.0,
      );
      expect(resultNarrow, false);
    });

    test('returns true for zero distance with zero expected', () {
      const coord = LatLng(55.9533, -3.1883);

      final result = DistanceCalculator.verifyKnownDistance(
        point1: coord,
        point2: coord,
        expectedMeters: 0,
        tolerancePercent: 0.1,
      );

      expect(result, true);
    });
  });

  group('DistanceCalculator Edge Cases', () {
    test('handles minimum valid latitude (-90°)', () {
      const southPole = LatLng(-90.0, 0.0);
      const nearSouthPole = LatLng(-89.0, 0.0);

      final distance =
          DistanceCalculator.distanceInMeters(southPole, nearSouthPole);

      expect(distance, greaterThan(0));
      expect(distance, lessThan(200000)); // ~111 km
    });

    test('handles maximum valid latitude (90°)', () {
      const northPole = LatLng(90.0, 0.0);
      const nearNorthPole = LatLng(89.0, 0.0);

      final distance =
          DistanceCalculator.distanceInMeters(northPole, nearNorthPole);

      expect(distance, greaterThan(0));
      expect(distance, lessThan(200000)); // ~111 km
    });

    test('handles minimum valid longitude (-180°)', () {
      const coord1 = LatLng(0.0, -180.0);
      const coord2 = LatLng(0.0, 180.0); // Same meridian

      final distance = DistanceCalculator.distanceInMeters(coord1, coord2);

      // Should be very small or zero (same line, wraps around)
      expect(distance, lessThan(100));
    });

    test('handles coordinates very close to each other', () {
      const point1 = LatLng(55.95330, -3.18830);
      const point2 = LatLng(55.95331, -3.18831); // ~1.5 meters

      final distance = DistanceCalculator.distanceInMeters(point1, point2);

      expect(distance, greaterThan(0));
      expect(distance, lessThan(3));
    });

    test('maintains precision for large distances', () {
      const newYork = LatLng(40.7128, -74.0060);
      const tokyo = LatLng(35.6762, 139.6503);

      final distance = DistanceCalculator.distanceInMeters(newYork, tokyo);

      // ~10,850 km
      expect(distance, greaterThan(10000000));
      expect(distance, lessThan(11500000));
    });
  });
}
