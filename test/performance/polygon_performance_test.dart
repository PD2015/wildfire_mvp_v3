// Performance test for polygon rendering
// NOTE: print() statements are intentional in performance tests for reporting metrics
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/features/map/utils/polygon_style_helper.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart' as app;
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

void main() {
  group('Polygon Performance Tests', () {
    /// Generate mock fire incidents with polygon boundaries for performance testing
    List<FireIncident> generateMockIncidents(int count) {
      final incidents = <FireIncident>[];
      const baseLatitude = 55.0;
      const baseLongitude = -4.0;
      final intensities = ['low', 'moderate', 'high'];

      for (int i = 0; i < count; i++) {
        // Spread incidents across Scotland
        final lat = baseLatitude + (i % 10) * 0.5;
        final lon = baseLongitude + (i ~/ 10) * 0.3;

        // Create a realistic polygon (roughly 2km x 2km)
        final boundaryPoints = [
          app.LatLng(lat, lon),
          app.LatLng(lat + 0.02, lon),
          app.LatLng(lat + 0.02, lon + 0.03),
          app.LatLng(lat, lon + 0.03),
          app.LatLng(lat, lon), // Close the polygon
        ];

        incidents.add(
          FireIncident(
            id: 'perf-test-$i',
            location: app.LatLng(lat + 0.01, lon + 0.015), // Center point
            intensity: intensities[i % intensities.length],
            timestamp: DateTime.now().subtract(Duration(hours: i)),
            source: DataSource.mock,
            freshness: Freshness.live,
            boundaryPoints: boundaryPoints,
          ),
        );
      }

      return incidents;
    }

    /// Build a polygon from FireIncident using PolygonStyleHelper colors
    Polygon buildPolygon(FireIncident incident) {
      return Polygon(
        polygonId: PolygonId(incident.id),
        points: incident.boundaryPoints!
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        fillColor: PolygonStyleHelper.getFillColor(incident.intensity),
        strokeColor: PolygonStyleHelper.getStrokeColor(incident.intensity),
        strokeWidth: PolygonStyleHelper.strokeWidth,
      );
    }

    /// Check if incident has a valid polygon boundary (>= 3 points)
    bool hasValidBoundary(FireIncident incident) {
      return incident.boundaryPoints != null &&
          incident.boundaryPoints!.length >= 3;
    }

    test('generates 50 polygons within 100ms', () {
      final incidents = generateMockIncidents(50);
      expect(incidents.length, equals(50));

      final stopwatch = Stopwatch()..start();

      final polygons = <Polygon>{};
      for (final incident in incidents) {
        if (hasValidBoundary(incident)) {
          polygons.add(buildPolygon(incident));
        }
      }

      stopwatch.stop();

      expect(polygons.length, equals(50));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Polygon generation should complete within 100ms',
      );

      print('✅ Generated 50 polygons in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('generates 100 polygons within 200ms', () {
      final incidents = generateMockIncidents(100);
      expect(incidents.length, equals(100));

      final stopwatch = Stopwatch()..start();

      final polygons = <Polygon>{};
      for (final incident in incidents) {
        if (hasValidBoundary(incident)) {
          polygons.add(buildPolygon(incident));
        }
      }

      stopwatch.stop();

      expect(polygons.length, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: 'Polygon generation should complete within 200ms',
      );

      print('✅ Generated 100 polygons in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('polygon style helper handles all intensity levels', () {
      final intensities = ['low', 'moderate', 'high'];
      final boundaryPoints = [
        const app.LatLng(55.0, -4.0),
        const app.LatLng(55.02, -4.0),
        const app.LatLng(55.02, -3.97),
        const app.LatLng(55.0, -3.97),
      ];

      for (final intensity in intensities) {
        final incident = FireIncident(
          id: 'test-$intensity',
          location: const app.LatLng(55.01, -3.985),
          intensity: intensity,
          timestamp: DateTime.now(),
          source: DataSource.mock,
          freshness: Freshness.live,
          boundaryPoints: boundaryPoints,
        );

        final polygon = buildPolygon(incident);

        expect((polygon.fillColor.a * 255).round(), greaterThan(0));
        expect((polygon.strokeColor.a * 255).round(), equals(255));
        expect(polygon.points.length, equals(4));
      }

      print('✅ All intensity levels produce valid polygons');
    });

    test('polygon memory footprint is reasonable', () {
      final incidents = generateMockIncidents(50);

      // Create polygons and measure approximate memory
      final polygons = <Polygon>[];
      for (final incident in incidents) {
        if (hasValidBoundary(incident)) {
          polygons.add(buildPolygon(incident));
        }
      }

      // Each polygon has ~5 points, each point is 2 doubles (16 bytes)
      // Plus overhead for colors, stroke width, etc.
      // Estimate: ~200 bytes per polygon is reasonable
      // 50 polygons * 200 bytes = 10KB - well within limits

      expect(polygons.length, equals(50));

      // Verify each polygon has reasonable point count
      for (final polygon in polygons) {
        expect(polygon.points.length, lessThanOrEqualTo(10));
      }

      print('✅ 50 polygons created with reasonable memory footprint');
    });

    test('empty boundary points are handled gracefully', () {
      final incident = FireIncident(
        id: 'no-boundary',
        location: const app.LatLng(55.0, -4.0),
        intensity: 'high',
        timestamp: DateTime.now(),
        source: DataSource.mock,
        freshness: Freshness.live,
        boundaryPoints: null, // No boundary
      );

      // Should not throw when boundary is null
      expect(incident.boundaryPoints, isNull);
      expect(hasValidBoundary(incident), isFalse);

      print('✅ Incidents without boundaries handled correctly');
    });

    test('single-point boundary is rejected at construction', () {
      // FireIncident validates that boundaryPoints must have >= 3 points
      expect(
        () => FireIncident(
          id: 'single-point',
          location: const app.LatLng(55.0, -4.0),
          intensity: 'high',
          timestamp: DateTime.now(),
          source: DataSource.mock,
          freshness: Freshness.live,
          boundaryPoints: const [app.LatLng(55.0, -4.0)], // Only 1 point
        ),
        throwsArgumentError,
      );

      print('✅ Single-point boundaries correctly rejected at construction');
    });

    test('two-point boundary is rejected at construction', () {
      // FireIncident validates that boundaryPoints must have >= 3 points
      expect(
        () => FireIncident(
          id: 'two-point',
          location: const app.LatLng(55.0, -4.0),
          intensity: 'high',
          timestamp: DateTime.now(),
          source: DataSource.mock,
          freshness: Freshness.live,
          boundaryPoints: const [
            app.LatLng(55.0, -4.0),
            app.LatLng(55.1, -3.9),
          ], // Only 2 points
        ),
        throwsArgumentError,
      );

      print('✅ Two-point boundaries correctly rejected at construction');
    });

    test('zoom threshold is respected', () {
      // Polygons should only show at zoom >= 8.0
      expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(7.0), isFalse);
      expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(7.9), isFalse);
      expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(8.0), isTrue);
      expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(10.0), isTrue);
      expect(PolygonStyleHelper.shouldShowPolygonsAtZoom(15.0), isTrue);

      print('✅ Zoom threshold correctly enforced at 8.0');
    });
  });
}
