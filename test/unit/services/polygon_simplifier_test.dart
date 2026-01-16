import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/utils/polygon_simplifier.dart';

void main() {
  group('PolygonSimplifier', () {
    group('simplify', () {
      test('returns original when points <= maxPoints', () {
        final points = [
          const LatLng(55.0, -3.0),
          const LatLng(55.1, -3.1),
          const LatLng(55.0, -3.2),
        ];

        final result = PolygonSimplifier.simplify(points, maxPoints: 500);

        expect(result, equals(points));
      });

      test('simplifies when points > maxPoints', () {
        // Create a polygon with 600 points
        final points = List.generate(
          600,
          (i) => LatLng(55.0 + (i * 0.001), -3.0 + (i % 2) * 0.001),
        );

        final result = PolygonSimplifier.simplify(points, maxPoints: 500);

        expect(result.length, lessThanOrEqualTo(500));
      });

      test('preserves minimum 3 points for valid polygon', () {
        final points = [
          const LatLng(55.0, -3.0),
          const LatLng(55.001, -3.001),
          const LatLng(55.002, -3.002),
          const LatLng(55.003, -3.003),
          const LatLng(55.0, -3.0),
        ];

        final result = PolygonSimplifier.simplify(
          points,
          tolerance: 1.0, // Very high tolerance
          maxPoints: 2,
        );

        expect(result.length, greaterThanOrEqualTo(3));
      });

      test('tolerance affects output point count', () {
        // Create a zigzag pattern
        final points = List.generate(
          100,
          (i) => LatLng(55.0 + (i * 0.01), -3.0 + (i % 2) * 0.01),
        );

        final lowTolerance = PolygonSimplifier.simplify(
          points,
          tolerance: 0.0001,
          maxPoints: 1000,
        );

        final highTolerance = PolygonSimplifier.simplify(
          points,
          tolerance: 0.01,
          maxPoints: 1000,
        );

        // Higher tolerance should result in fewer or equal points
        expect(highTolerance.length, lessThanOrEqualTo(lowTolerance.length));
      });

      test('returns original for small polygons', () {
        final smallPolygon = [
          const LatLng(55.0, -3.0),
          const LatLng(55.1, -3.0),
          const LatLng(55.05, -3.1),
        ];

        final result = PolygonSimplifier.simplify(smallPolygon);

        expect(result, equals(smallPolygon));
      });
    });

    group('wouldSimplify', () {
      test('returns false when points <= maxPoints', () {
        final points = List.generate(100, (i) => LatLng(55.0 + i * 0.01, -3.0));

        expect(
          PolygonSimplifier.wouldSimplify(points, maxPoints: 500),
          isFalse,
        );
      });

      test('returns true when points > maxPoints', () {
        final points = List.generate(
          600,
          (i) => LatLng(55.0 + i * 0.001, -3.0),
        );

        expect(PolygonSimplifier.wouldSimplify(points, maxPoints: 500), isTrue);
      });
    });

    group('getStats', () {
      test('calculates correct reduction statistics', () {
        final original = List.generate(
          1000,
          (i) => LatLng(55.0 + i * 0.001, -3.0),
        );
        final simplified = List.generate(
          500,
          (i) => LatLng(55.0 + i * 0.002, -3.0),
        );

        final stats = PolygonSimplifier.getStats(original, simplified);

        expect(stats.originalCount, equals(1000));
        expect(stats.simplifiedCount, equals(500));
        expect(stats.reductionPercent, closeTo(50.0, 0.1));
      });
    });

    group('performance', () {
      test('simplifies 22000 points within 100ms', () {
        // Create large polygon simulating complex burnt area
        final points = List.generate(22000, (i) {
          final angle = i * 0.0003;
          return LatLng(55.0 + 0.1 * _sin(angle), -3.0 + 0.1 * _cos(angle));
        });

        final stopwatch = Stopwatch()..start();
        final result = PolygonSimplifier.simplify(points, maxPoints: 500);
        stopwatch.stop();

        expect(result.length, lessThanOrEqualTo(500));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        // Print for visibility in verbose mode
        // ignore: avoid_print
        print(
          'Simplified ${points.length} points to ${result.length} in ${stopwatch.elapsedMilliseconds}ms',
        );
      });
    });

    group('edge cases', () {
      test('handles empty list', () {
        final result = PolygonSimplifier.simplify([]);
        expect(result, isEmpty);
      });

      test('handles single point', () {
        final result = PolygonSimplifier.simplify([const LatLng(55.0, -3.0)]);
        expect(result.length, equals(1));
      });

      test('handles two points', () {
        final result = PolygonSimplifier.simplify([
          const LatLng(55.0, -3.0),
          const LatLng(55.1, -3.1),
        ]);
        expect(result.length, equals(2));
      });

      test('handles collinear points', () {
        // All points on a straight line
        final points = List.generate(100, (i) => LatLng(55.0 + i * 0.01, -3.0));

        // Algorithm doesn't trigger without maxPoints exceeded
        // Original list returned as-is when below maxPoints threshold
        final result = PolygonSimplifier.simplify(
          points,
          tolerance: 0.001,
          maxPoints: 1000,
        );

        // Points are not simplified when under maxPoints
        expect(result, equals(points));
      });
    });
  });
}

// Simple sin/cos for test data generation
double _sin(double x) {
  x = x % (2 * 3.141592653589793);
  if (x > 3.141592653589793) x -= 2 * 3.141592653589793;
  if (x < -3.141592653589793) x += 2 * 3.141592653589793;

  double result = x;
  double term = x;
  for (int n = 1; n < 10; n++) {
    term *= -x * x / ((2 * n) * (2 * n + 1));
    result += term;
  }
  return result;
}

double _cos(double x) => _sin(x + 3.141592653589793 / 2);
