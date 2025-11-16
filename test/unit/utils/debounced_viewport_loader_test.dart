import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart' as bounds;
import 'package:wildfire_mvp_v3/utils/debounced_viewport_loader.dart';

void main() {
  group('DebouncedViewportLoader Tests', () {
    late DebouncedViewportLoader loader;
    late List<bounds.LatLngBounds> capturedBounds;

    setUp(() {
      capturedBounds = [];
      loader = DebouncedViewportLoader(
        onViewportChanged: (viewportBounds) async {
          capturedBounds.add(viewportBounds);
        },
      );
    });

    tearDown(() {
      loader.dispose();
    });

    test('debounces rapid camera movements', () async {
      const position1 = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);
      const position2 = CameraPosition(target: LatLng(56.0, -3.2), zoom: 10);
      const position3 = CameraPosition(target: LatLng(56.1, -3.3), zoom: 10);

      // Trigger multiple rapid movements
      loader.onCameraMove(position1);
      loader.onCameraMove(position2);
      loader.onCameraMove(position3);

      // Should not trigger immediately
      expect(capturedBounds, isEmpty);

      // Wait for debounce to complete
      await Future.delayed(const Duration(milliseconds: 350));

      // Should only trigger once with last position
      expect(capturedBounds.length, equals(1));
      expect(capturedBounds.first.center.latitude, closeTo(56.1, 0.1));
    });

    test('cancels previous timer when new movement occurs', () async {
      const position1 = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);
      const position2 = CameraPosition(target: LatLng(56.0, -3.2), zoom: 10);

      // First movement
      loader.onCameraMove(position1);

      // Wait 200ms (less than 300ms debounce)
      await Future.delayed(const Duration(milliseconds: 200));

      // Second movement cancels first timer
      loader.onCameraMove(position2);

      // Wait 150ms (still less than 300ms from second movement)
      await Future.delayed(const Duration(milliseconds: 150));

      // Should still be empty (first timer was cancelled)
      expect(capturedBounds, isEmpty);

      // Wait for second debounce to complete
      await Future.delayed(const Duration(milliseconds: 200));

      // Should trigger once with second position
      expect(capturedBounds.length, equals(1));
      expect(capturedBounds.first.center.latitude, closeTo(56.0, 0.1));
    });

    test('onCameraIdle triggers immediate load', () async {
      const position = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);

      loader.onCameraMove(position);
      loader.onCameraIdle();

      // Should trigger immediately (not wait for debounce)
      await Future.delayed(const Duration(milliseconds: 50));

      expect(capturedBounds.length, equals(1));
    });

    test('calculates bounds correctly for different zoom levels', () async {
      // Zoom 0: whole world
      const zoom0 = CameraPosition(target: LatLng(0, 0), zoom: 0);
      loader.onCameraMove(zoom0);
      await Future.delayed(const Duration(milliseconds: 350));

      final bounds0 = capturedBounds.last;
      final height0 = bounds0.northeast.latitude - bounds0.southwest.latitude;
      final width0 = bounds0.northeast.longitude - bounds0.southwest.longitude;

      capturedBounds.clear();

      // Zoom 10: much smaller area
      const zoom10 = CameraPosition(target: LatLng(0, 0), zoom: 10);
      loader.onCameraMove(zoom10);
      await Future.delayed(const Duration(milliseconds: 350));

      final bounds10 = capturedBounds.last;
      final height10 =
          bounds10.northeast.latitude - bounds10.southwest.latitude;
      final width10 =
          bounds10.northeast.longitude - bounds10.southwest.longitude;

      // Higher zoom should show smaller area
      expect(height10, lessThan(height0));
      expect(width10, lessThan(width0));
    });

    test('includes 10% padding in calculated bounds', () async {
      const position = CameraPosition(target: LatLng(55.0, -3.0), zoom: 8);
      loader.onCameraMove(position);
      await Future.delayed(const Duration(milliseconds: 350));

      final calculatedBounds = capturedBounds.first;

      // Bounds should extend beyond visible area due to 10% padding
      // This ensures all visible markers are loaded
      expect(calculatedBounds.southwest.latitude, lessThan(55.0));
      expect(calculatedBounds.southwest.longitude, lessThan(-3.0));
      expect(calculatedBounds.northeast.latitude, greaterThan(55.0));
      expect(calculatedBounds.northeast.longitude, greaterThan(-3.0));
    });

    test('clamps bounds to valid lat/lon ranges', () async {
      // Position near north pole
      const northPole = CameraPosition(target: LatLng(89.0, 0), zoom: 1);
      loader.onCameraMove(northPole);
      await Future.delayed(const Duration(milliseconds: 350));

      final bounds = capturedBounds.last;

      // Latitude should be clamped to -90/90
      expect(bounds.southwest.latitude, greaterThanOrEqualTo(-90.0));
      expect(bounds.northeast.latitude, lessThanOrEqualTo(90.0));

      // Longitude should be clamped to -180/180
      expect(bounds.southwest.longitude, greaterThanOrEqualTo(-180.0));
      expect(bounds.northeast.longitude, lessThanOrEqualTo(180.0));
    });

    test('isLoading reflects current state', () async {
      var loadingCompleter = Completer<void>();
      final loaderWithDelay = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          await loadingCompleter.future;
        },
      );

      expect(loaderWithDelay.isLoading, isFalse);

      const position = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);
      loaderWithDelay.onCameraMove(position);
      await Future.delayed(const Duration(milliseconds: 350));

      // Should be loading now
      expect(loaderWithDelay.isLoading, isTrue);

      // Complete the load
      loadingCompleter.complete();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(loaderWithDelay.isLoading, isFalse);

      loaderWithDelay.dispose();
    });

    test('lastPosition tracks most recent camera position', () {
      expect(loader.lastPosition, isNull);

      const position1 = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);
      loader.onCameraMove(position1);

      expect(loader.lastPosition, equals(position1));

      const position2 = CameraPosition(target: LatLng(56.0, -3.2), zoom: 10);
      loader.onCameraMove(position2);

      expect(loader.lastPosition, equals(position2));
    });

    test('cancel clears state', () async {
      const position = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);
      loader.onCameraMove(position);

      expect(loader.lastPosition, isNotNull);

      loader.cancel();

      expect(loader.lastPosition, isNull);
      expect(loader.isLoading, isFalse);

      // Wait for debounce - should not trigger after cancel
      await Future.delayed(const Duration(milliseconds: 350));
      expect(capturedBounds, isEmpty);
    });

    test('dispose cancels pending timers', () async {
      const position = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);
      loader.onCameraMove(position);

      loader.dispose();

      // Wait for what would be debounce completion
      await Future.delayed(const Duration(milliseconds: 350));

      // Should not trigger after dispose
      expect(capturedBounds, isEmpty);
    });

    test('custom debounce duration is respected', () async {
      final customLoader = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          capturedBounds.add(bounds);
        },
        debounceDuration: const Duration(milliseconds: 100),
      );

      const position = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);
      customLoader.onCameraMove(position);

      // Should not trigger immediately
      expect(capturedBounds, isEmpty);

      // Wait for custom debounce
      await Future.delayed(const Duration(milliseconds: 150));

      // Should have triggered
      expect(capturedBounds.length, equals(1));

      customLoader.dispose();
    });

    test('does not load while previous load in progress', () async {
      var loadingCompleter = Completer<void>();
      var loadCount = 0;

      final loaderWithDelay = DebouncedViewportLoader(
        onViewportChanged: (bounds) async {
          loadCount++;
          await loadingCompleter.future;
        },
      );

      const position1 = CameraPosition(target: LatLng(55.9, -3.1), zoom: 10);
      const position2 = CameraPosition(target: LatLng(56.0, -3.2), zoom: 10);

      // First load
      loaderWithDelay.onCameraMove(position1);
      await Future.delayed(const Duration(milliseconds: 350));

      expect(loadCount, equals(1));
      expect(loaderWithDelay.isLoading, isTrue);

      // Try to trigger second load while first is in progress
      loaderWithDelay.onCameraMove(position2);
      await Future.delayed(const Duration(milliseconds: 350));

      // Should still be only 1 load
      expect(loadCount, equals(1));

      // Complete first load
      loadingCompleter.complete();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(loaderWithDelay.isLoading, isFalse);

      loaderWithDelay.dispose();
    });
  });
}
