import '../../models/location_models.dart';

/// Douglas-Peucker polygon simplification algorithm
///
/// Reduces the number of points in a polygon while preserving its shape.
/// Used to optimize burnt area polygon rendering on maps.
///
/// Part of 021-live-fire-data feature implementation.
class PolygonSimplifier {
  /// Default tolerance in degrees (~100m at 56°N latitude)
  ///
  /// At 56°N (Scotland):
  /// - 1 degree latitude ≈ 111km
  /// - 1 degree longitude ≈ 62km (cos(56°) × 111km)
  /// - 0.0009 degrees ≈ 100m latitude, 56m longitude
  static const double defaultTolerance = 0.0009;

  /// Maximum points after simplification
  static const int defaultMaxPoints = 500;

  /// Simplifies a polygon using Douglas-Peucker algorithm
  ///
  /// Parameters:
  /// - [points]: Original polygon points (must have >= 3 points)
  /// - [tolerance]: Perpendicular distance tolerance in degrees (default: ~100m)
  /// - [maxPoints]: Maximum points in simplified polygon (default: 500)
  ///
  /// Returns:
  /// - Simplified polygon with <= maxPoints points
  /// - Original polygon if already <= maxPoints
  /// - Minimum 3 points for valid polygon
  ///
  /// Algorithm:
  /// 1. If points <= maxPoints, return original
  /// 2. Apply Douglas-Peucker with given tolerance
  /// 3. If result still > maxPoints, increase tolerance and retry
  static List<LatLng> simplify(
    List<LatLng> points, {
    double tolerance = defaultTolerance,
    int maxPoints = defaultMaxPoints,
  }) {
    if (points.length <= maxPoints) {
      return points;
    }

    // Apply Douglas-Peucker
    var simplified = _douglasPeucker(points, tolerance);

    // If still too many points, increase tolerance iteratively
    var currentTolerance = tolerance;
    var iterations = 0;
    while (simplified.length > maxPoints && iterations < 10) {
      currentTolerance *= 1.5;
      simplified = _douglasPeucker(points, currentTolerance);
      iterations++;
    }

    // Ensure minimum 3 points for valid polygon
    if (simplified.length < 3) {
      // Return first, middle, and last points
      return [points.first, points[points.length ~/ 2], points.last];
    }

    return simplified;
  }

  /// Douglas-Peucker recursive simplification
  static List<LatLng> _douglasPeucker(List<LatLng> points, double epsilon) {
    if (points.length < 3) {
      return points;
    }

    // Find the point with maximum distance from line between first and last
    double maxDistance = 0;
    int maxIndex = 0;

    final first = points.first;
    final last = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than epsilon, recursively simplify
    if (maxDistance > epsilon) {
      final leftResult = _douglasPeucker(
        points.sublist(0, maxIndex + 1),
        epsilon,
      );
      final rightResult = _douglasPeucker(points.sublist(maxIndex), epsilon);

      // Combine results, removing duplicate middle point
      return [...leftResult.sublist(0, leftResult.length - 1), ...rightResult];
    } else {
      // All points between first and last can be removed
      return [first, last];
    }
  }

  /// Calculate perpendicular distance from point to line
  ///
  /// Uses formula for distance from point (x0, y0) to line through
  /// (x1, y1) and (x2, y2).
  static double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final x0 = point.longitude;
    final y0 = point.latitude;
    final x1 = lineStart.longitude;
    final y1 = lineStart.latitude;
    final x2 = lineEnd.longitude;
    final y2 = lineEnd.latitude;

    // Handle case where line is a point
    final dx = x2 - x1;
    final dy = y2 - y1;
    if (dx == 0 && dy == 0) {
      return _sqrt((x0 - x1) * (x0 - x1) + (y0 - y1) * (y0 - y1));
    }

    // Calculate perpendicular distance
    final numerator = ((dy * x0 - dx * y0 + x2 * y1 - y2 * x1).abs());
    final denominator = _sqrt(dy * dy + dx * dx);

    return numerator / denominator;
  }

  /// Square root without dart:math import
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Check if simplification would be applied
  static bool wouldSimplify(
    List<LatLng> points, {
    int maxPoints = defaultMaxPoints,
  }) {
    return points.length > maxPoints;
  }

  /// Get reduction statistics for a polygon
  static SimplificationStats getStats(
    List<LatLng> original,
    List<LatLng> simplified,
  ) {
    return SimplificationStats(
      originalCount: original.length,
      simplifiedCount: simplified.length,
      reductionPercent:
          ((original.length - simplified.length) / original.length * 100)
              .roundToDouble(),
    );
  }
}

/// Statistics about polygon simplification
class SimplificationStats {
  final int originalCount;
  final int simplifiedCount;
  final double reductionPercent;

  const SimplificationStats({
    required this.originalCount,
    required this.simplifiedCount,
    required this.reductionPercent,
  });

  @override
  String toString() =>
      'SimplificationStats(original: $originalCount, simplified: $simplifiedCount, reduction: ${reductionPercent.toStringAsFixed(1)}%)';
}
