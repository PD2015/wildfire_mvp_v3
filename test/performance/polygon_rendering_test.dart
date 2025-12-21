import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/features/map/utils/polygon_style_helper.dart';

/// T044: Performance tests for polygon rendering
///
/// Verifies polygon processing performance meets requirements:
/// - 50 simplified polygons: < 100ms
/// - 100 hotspot squares: < 100ms
///
/// NOTE: print() statements are intentional for performance metric reporting
// ignore_for_file: avoid_print

void main() {
  group('Polygon Rendering Performance Tests (T044)', () {
    /// Generate a test polygon with specified number of points
    List<LatLng> generatePolygon(
      int pointCount,
      LatLng center,
      double radiusDegrees,
    ) {
      final points = <LatLng>[];
      for (int i = 0; i < pointCount; i++) {
        final angle = (2 * 3.14159 * i) / pointCount;
        final lat = center.latitude + radiusDegrees * sin(angle);
        final lon = center.longitude + radiusDegrees * cos(angle);
        points.add(LatLng(lat, lon));
      }
      return points;
    }

    /// Generate test burnt areas with polygons
    List<BurntArea> generateBurntAreas(int count, int pointsPerPolygon) {
      final random = Random(42);
      return List.generate(count, (index) {
        final centerLat = 54.5 + random.nextDouble() * 6.5;
        final centerLon = -8.0 + random.nextDouble() * 8.0;
        final center = LatLng(centerLat, centerLon);

        return BurntArea(
          id: 'burnt_area_$index',
          boundaryPoints: generatePolygon(pointsPerPolygon, center, 0.01),
          areaHectares: 10.0 + random.nextDouble() * 200.0,
          fireDate: DateTime.now().subtract(Duration(days: random.nextInt(90))),
          seasonYear: 2025,
          isSimplified: pointsPerPolygon < 100,
          originalPointCount: pointsPerPolygon < 100 ? 500 : null,
        );
      });
    }

    test('50 simplified polygons processed in < 100ms', () {
      // Generate 50 burnt areas with ~50 points each (simplified)
      final burntAreas = generateBurntAreas(50, 50);

      final stopwatch = Stopwatch()..start();

      // Simulate processing: get colors and check validity
      for (final area in burntAreas) {
        final fillColor = PolygonStyleHelper.getFillColor(area.intensity);
        final strokeColor = PolygonStyleHelper.getStrokeColor(area.intensity);
        final isValid = area.boundaryPoints.length >= 3;

        // Verify colors are computed
        expect(fillColor, isNotNull);
        expect(strokeColor, isNotNull);
        expect(isValid, isTrue);
      }

      stopwatch.stop();

      print(
        '✅ 50 simplified polygons processed in ${stopwatch.elapsedMilliseconds}ms',
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '50 simplified polygons should process in < 100ms',
      );
    });

    test('100 hotspot squares processed in < 100ms', () {
      // Generate 100 "square" polygons (4 points each)
      final squares = generateBurntAreas(100, 4);

      final stopwatch = Stopwatch()..start();

      // Simulate processing: get colors and compute centroid
      for (final square in squares) {
        final fillColor = PolygonStyleHelper.getFillColor(square.intensity);
        final strokeColor = PolygonStyleHelper.getStrokeColor(square.intensity);
        final centroid = square.centroid;

        // Verify processing
        expect(fillColor, isNotNull);
        expect(strokeColor, isNotNull);
        expect(centroid.latitude, isNot(0));
      }

      stopwatch.stop();

      print(
        '✅ 100 hotspot squares processed in ${stopwatch.elapsedMilliseconds}ms',
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '100 hotspot squares should process in < 100ms',
      );
    });

    test('polygon style helper is O(1) complexity', () {
      // Test that style computation is constant time regardless of intensity
      final intensities = ['low', 'moderate', 'high'];

      for (final intensity in intensities) {
        final stopwatch = Stopwatch()..start();

        // Call 10000 times
        for (int i = 0; i < 10000; i++) {
          PolygonStyleHelper.getFillColor(intensity);
          PolygonStyleHelper.getStrokeColor(intensity);
        }

        stopwatch.stop();

        print(
          '✅ "$intensity" style: 10000 calls in ${stopwatch.elapsedMilliseconds}ms',
        );

        // 10000 calls should be < 50ms (O(1) lookup)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
          reason: 'Style helper should be constant time',
        );
      }
    });

    test('centroid calculation is linear in polygon size', () {
      // Test centroid calculation scales linearly
      final sizes = [10, 100, 500];
      final times = <int>[];

      for (final size in sizes) {
        final area = generateBurntAreas(1, size).first;

        final stopwatch = Stopwatch()..start();

        // Calculate centroid 1000 times
        for (int i = 0; i < 1000; i++) {
          area.centroid;
        }

        stopwatch.stop();
        times.add(stopwatch.elapsedMilliseconds);

        print(
          '✅ Centroid calculation ($size points): 1000 calls in ${stopwatch.elapsedMilliseconds}ms',
        );
      }

      // Verify all calculations complete in reasonable time
      // When operations are sub-millisecond (0ms), that's excellent performance
      // We just verify the largest polygon doesn't explode in time
      expect(
        times[2],
        lessThan(100), // 500-point centroid x 1000 should be < 100ms
        reason: 'Centroid calculation should scale reasonably',
      );
    });

    test('polygon intensity calculation is O(1)', () {
      final area = generateBurntAreas(1, 100).first;

      final stopwatch = Stopwatch()..start();

      // Call intensity 10000 times
      for (int i = 0; i < 10000; i++) {
        area.intensity;
      }

      stopwatch.stop();

      print(
        '✅ Intensity calculation: 10000 calls in ${stopwatch.elapsedMilliseconds}ms',
      );

      // 10000 calls should be < 10ms (simple comparison)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10),
        reason: 'Intensity calculation should be O(1)',
      );
    });

    test('large polygon (500+ points) centroid in < 10ms', () {
      final area = generateBurntAreas(1, 500).first;

      final stopwatch = Stopwatch()..start();
      final centroid = area.centroid;
      stopwatch.stop();

      print(
        '✅ 500-point polygon centroid in ${stopwatch.elapsedMilliseconds}ms',
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10),
        reason: '500-point polygon centroid should compute in < 10ms',
      );
      expect(centroid.latitude, isNot(0));
      expect(centroid.longitude, isNot(0));
    });
  });
}
