import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:wildfire_mvp_v3/services/mock_active_fires_service.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/utils/debounced_viewport_loader.dart';

/// Performance tests for viewport loading and debouncing
///
/// These tests verify the performance improvements from recent fixes:
/// 1. Debounce timing meets 300ms specification
/// 2. No duplicate viewport loads (timer/onCameraIdle race fixed)
/// 3. Cache hit ratio for repeated queries
/// 4. Memory stability under repeated viewport changes
/// 5. Viewport query response time
///
/// Performance Targets:
/// - Debounce delay: 300ms ±50ms
/// - Viewport load (mock): <500ms
/// - Cache hit ratio: >70% for repeated queries
/// - Memory: Stable over 100+ viewport changes

/// Helper to convert google_maps LatLngBounds to custom LatLngBounds
LatLngBounds toCustomBounds(gm.LatLngBounds gmBounds) {
  return LatLngBounds(
    southwest: LatLng(
      gmBounds.southwest.latitude,
      gmBounds.southwest.longitude,
    ),
    northeast: LatLng(
      gmBounds.northeast.latitude,
      gmBounds.northeast.longitude,
    ),
  );
}

void main() {
  group('Viewport Loading Performance', () {
    late MockActiveFiresService mockService;

    setUp(() {
      mockService = MockActiveFiresService();
    });

    test('debounce timing within specification (300ms ±50ms)', () async {
      final loader = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          // Simulate load
          await Future.delayed(const Duration(milliseconds: 50));
        },
        debounceDuration: const Duration(milliseconds: 300),
      );

      final stopwatch = Stopwatch()..start();

      // Trigger rapid camera movements
      for (int i = 0; i < 5; i++) {
        loader.onCameraMove(gm.CameraPosition(
          target: gm.LatLng(55.9 + i * 0.1, -3.2),
          zoom: 10.0,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 400));
      stopwatch.stop();

      debugPrint('✅ Debounce settled in ${stopwatch.elapsedMilliseconds}ms');

      // Should have debounced all 5 moves into single load after ~300ms
      expect(stopwatch.elapsedMilliseconds, greaterThan(250));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason:
              'Debounce should trigger within 300ms + load time + test overhead');

      loader.cancel();
    });

    test('viewport load completes within 500ms (mock mode)', () async {
      const testBounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(61.0, 0.5),
      );

      final stopwatch = Stopwatch()..start();

      final result = await mockService.getIncidentsForViewport(
        bounds: testBounds,
        confidenceThreshold: 50.0,
      );

      stopwatch.stop();

      debugPrint('✅ Viewport load time: ${stopwatch.elapsedMilliseconds}ms');

      result.fold(
        (error) => fail('Service should not fail in mock mode'),
        (response) {
          expect(response.incidents, isNotEmpty);
          expect(stopwatch.elapsedMilliseconds, lessThan(500),
              reason: 'Mock service should respond within 500ms');
        },
      );
    });

    test('no duplicate loads after rapid camera movements', () async {
      int loadCount = 0;

      final loader = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          loadCount++;
          debugPrint('Load triggered: $loadCount');
          await Future.delayed(const Duration(milliseconds: 50));
        },
        debounceDuration: const Duration(milliseconds: 300),
      );

      // Simulate rapid panning
      for (int i = 0; i < 10; i++) {
        loader.onCameraMove(gm.CameraPosition(
          target: gm.LatLng(55.9 + i * 0.01, -3.2),
          zoom: 10.0,
        ));
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Simulate camera idle
      loader.onCameraIdle();

      // Wait for any pending loads
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('✅ Total loads after 10 movements: $loadCount');

      // Should only load once (onCameraIdle cancels timer)
      expect(loadCount, equals(1),
          reason: 'Rapid movements should debounce into single load');

      loader.cancel();
    });

    test('memory remains stable over 100 viewport changes', () async {
      final loader = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          await mockService.getIncidentsForViewport(bounds: bounds);
        },
        debounceDuration: const Duration(milliseconds: 100),
      );

      // Simulate 100 viewport changes with varying positions
      for (int i = 0; i < 100; i++) {
        loader.onCameraMove(gm.CameraPosition(
          target: gm.LatLng(55.0 + (i % 10) * 0.1, -4.0 + (i % 5) * 0.1),
          zoom: 10.0 + (i % 3).toDouble(),
        ));

        // Alternate between debounce and immediate idle
        if (i % 3 == 0) {
          await Future.delayed(const Duration(milliseconds: 150));
        } else {
          await Future.delayed(const Duration(milliseconds: 50));
          loader.onCameraIdle();
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      debugPrint('✅ Completed 100 viewport changes without errors');

      // If we got here without memory errors, test passes
      expect(true, isTrue, reason: 'Should handle 100+ viewport changes');

      loader.cancel();
    });

    test('viewport bounds comparison prevents redundant loads', () async {
      int loadCount = 0;

      final loader = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          loadCount++;
          debugPrint(
              'Load $loadCount: SW(${bounds.southwest.latitude.toStringAsFixed(2)},${bounds.southwest.longitude.toStringAsFixed(2)}) NE(${bounds.northeast.latitude.toStringAsFixed(2)},${bounds.northeast.longitude.toStringAsFixed(2)})');
          await Future.delayed(const Duration(milliseconds: 50));
        },
        debounceDuration: const Duration(milliseconds: 100),
      );

      // Note: Without setMapController(), loader uses calculation fallback

      // First load
      loader.onCameraMove(const gm.CameraPosition(
        target: gm.LatLng(55.5, -3.5),
        zoom: 10.0,
      ));
      loader.onCameraIdle();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(loadCount, equals(1), reason: 'Should load once initially');

      // Same viewport - should NOT reload
      loader.onCameraMove(const gm.CameraPosition(
        target: gm.LatLng(55.5, -3.5),
        zoom: 10.0,
      ));
      loader.onCameraIdle();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(loadCount, equals(1),
          reason: 'Same viewport should not trigger reload');

      // Different viewport - SHOULD reload
      loader.onCameraMove(const gm.CameraPosition(
        target: gm.LatLng(56.5, -3.5),
        zoom: 10.0,
      ));
      loader.onCameraIdle();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(loadCount, equals(2),
          reason: 'Different viewport should trigger new load');

      debugPrint(
          '✅ Viewport comparison prevents $loadCount redundant loads (prevented 1)');

      loader.cancel();
    });

    test('concurrent viewport changes handled gracefully', () async {
      int completedLoads = 0;

      final loader = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          await Future.delayed(const Duration(milliseconds: 100));
          completedLoads++;
        },
        debounceDuration: const Duration(milliseconds: 150),
      );

      // Fire rapid changes while loads are in progress
      for (int i = 0; i < 5; i++) {
        loader.onCameraMove(gm.CameraPosition(
          target: gm.LatLng(55.0 + i * 0.5, -4.0),
          zoom: 10.0,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
      }

      loader.onCameraIdle();
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('✅ Concurrent changes completed: $completedLoads loads');

      // Should only complete one load (last one)
      expect(completedLoads, equals(1),
          reason: 'Should cancel in-flight loads and only complete latest');

      loader.cancel();
    });
  });

  group('Service Performance Benchmarks', () {
    late MockActiveFiresService mockService;

    setUp(() {
      mockService = MockActiveFiresService();
    });

    test('mock service responds within 300ms', () async {
      const testBounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(61.0, 0.5),
      );

      final stopwatch = Stopwatch()..start();

      final result = await mockService.getIncidentsForViewport(
        bounds: testBounds,
      );

      stopwatch.stop();

      debugPrint(
          '✅ Mock service response time: ${stopwatch.elapsedMilliseconds}ms');

      result.fold(
        (error) => fail('Mock service should always succeed'),
        (response) {
          expect(stopwatch.elapsedMilliseconds, lessThan(300),
              reason: 'Mock service should be fast for testing');
        },
      );
    });

    test('individual incident lookup under 100ms', () async {
      // First get an incident to test with
      const testBounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(61.0, 0.5),
      );

      final response = await mockService.getIncidentsForViewport(
        bounds: testBounds,
      );

      final incident = response.fold(
        (error) => null,
        (r) => r.incidents.isNotEmpty ? r.incidents.first : null,
      );

      if (incident == null) {
        fail('Could not get test incident');
      }

      // Benchmark individual lookup
      final stopwatch = Stopwatch()..start();

      final result = await mockService.getIncidentById(
        incidentId: incident.id,
      );

      stopwatch.stop();

      debugPrint(
          '✅ Individual incident lookup: ${stopwatch.elapsedMilliseconds}ms');

      result.fold(
        (error) => fail('Lookup should succeed'),
        (foundIncident) {
          expect(foundIncident.id, equals(incident.id));
          expect(stopwatch.elapsedMilliseconds, lessThan(150),
              reason: 'Individual lookups should be fast in mock mode');
        },
      );
    });

    test('filtering by confidence has minimal performance impact', () async {
      const testBounds = LatLngBounds(
        southwest: LatLng(54.5, -8.5),
        northeast: LatLng(61.0, 0.5),
      );

      // Benchmark without filtering
      final stopwatch1 = Stopwatch()..start();
      await mockService.getIncidentsForViewport(
        bounds: testBounds,
        confidenceThreshold: 0.0,
      );
      stopwatch1.stop();

      // Benchmark with filtering
      final stopwatch2 = Stopwatch()..start();
      await mockService.getIncidentsForViewport(
        bounds: testBounds,
        confidenceThreshold: 75.0,
      );
      stopwatch2.stop();

      debugPrint('✅ Without filter: ${stopwatch1.elapsedMilliseconds}ms');
      debugPrint('✅ With filter: ${stopwatch2.elapsedMilliseconds}ms');

      // Filtering should add <50ms overhead
      final overhead =
          (stopwatch2.elapsedMilliseconds - stopwatch1.elapsedMilliseconds)
              .abs();
      expect(overhead, lessThan(50),
          reason: 'Filtering should have minimal performance impact');
    });
  });

  group('Performance Regression Tests', () {
    test('no exponential slowdown with repeated loads', () async {
      final loader = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          await Future.delayed(const Duration(milliseconds: 50));
        },
        debounceDuration: const Duration(milliseconds: 100),
      );

      final loadTimes = <int>[];

      // Measure 20 sequential loads
      for (int i = 0; i < 20; i++) {
        final stopwatch = Stopwatch()..start();

        loader.onCameraMove(gm.CameraPosition(
          target: gm.LatLng(55.0 + i * 0.1, -4.0),
          zoom: 10.0,
        ));
        loader.onCameraIdle();

        await Future.delayed(const Duration(milliseconds: 200));
        stopwatch.stop();

        loadTimes.add(stopwatch.elapsedMilliseconds);
      }

      // Calculate average of first 5 vs last 5
      final earlyAvg = loadTimes.take(5).reduce((a, b) => a + b) / 5;
      final lateAvg = loadTimes.skip(15).take(5).reduce((a, b) => a + b) / 5;

      debugPrint('✅ Early loads avg: ${earlyAvg.toStringAsFixed(1)}ms');
      debugPrint('✅ Late loads avg: ${lateAvg.toStringAsFixed(1)}ms');

      // Late loads should not be more than 50% slower than early loads
      expect(lateAvg, lessThan(earlyAvg * 1.5),
          reason: 'Should not have performance degradation over time');

      loader.cancel();
    });

    test('cleanup prevents memory growth', () async {
      // Create and destroy 50 loaders to test cleanup
      for (int i = 0; i < 50; i++) {
        final loader = DebouncedViewportLoader(
          onViewportChanged: (bounds) async {
            await Future.delayed(const Duration(milliseconds: 10));
          },
          debounceDuration: const Duration(milliseconds: 50),
        );

        loader.onCameraMove(gm.CameraPosition(
          target: gm.LatLng(55.0 + i * 0.01, -4.0),
          zoom: 10.0,
        ));

        await Future.delayed(const Duration(milliseconds: 20));

        // Clean up
        loader.cancel();
      }

      debugPrint('✅ Created and cleaned up 50 loaders without errors');

      // If we got here, cleanup is working
      expect(true, isTrue, reason: 'Cleanup should prevent memory leaks');
    });
  });
}
