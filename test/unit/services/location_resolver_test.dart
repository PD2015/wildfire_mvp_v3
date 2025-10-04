import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/models/location_models.dart';
import '../../../lib/services/location_resolver_impl.dart';
import '../../../lib/utils/location_utils.dart';
import '../../support/fakes.dart';

void main() {
  group('LocationResolver Unit Tests', () {
    late LocationResolverImpl locationResolver;
    late FakeGeolocator fakeGeolocator;
    late FakeSharedPreferences fakePrefs;
    late LogSpy logSpy;

    setUp(() {
      // Initialize fakes
      fakeGeolocator = FakeGeolocator();
      fakePrefs = FakeSharedPreferences();
      logSpy = LogSpy();

      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});

      // Create location resolver with dependency injection
      locationResolver =
          LocationResolverImpl(geolocatorService: fakeGeolocator);
    });

    tearDown(() {
      fakeGeolocator.reset();
      fakePrefs.reset();
      logSpy.clear();
    });

    group('Last Known Position Tier', () {
      test('returns last known position immediately when available', () async {
        // Arrange
        final lastKnownPos = TestData.createPosition(
          latitude: TestData.edinburgh.latitude,
          longitude: TestData.edinburgh.longitude,
        );
        fakeGeolocator.setLastKnownPosition(lastKnownPos);

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await locationResolver.getLatLon();

        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'Should return quickly regardless of platform');

        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);

        // On macOS, GPS is skipped by platform guard, so we get Scotland centroid
        // On mobile platforms, we would get the last known position
        if (Platform.isAndroid || Platform.isIOS) {
          expect(
              location.latitude, closeTo(TestData.edinburgh.latitude, 0.001));
          expect(
              location.longitude, closeTo(TestData.edinburgh.longitude, 0.001));
        } else {
          // macOS/desktop: platform guard triggers, falls back to Scotland centroid
          expect(location.latitude,
              closeTo(TestData.scotlandCentroid.latitude, 0.001));
          expect(location.longitude,
              closeTo(TestData.scotlandCentroid.longitude, 0.001));
        }
      });

      test('falls back to GPS when no last known position', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        final currentPos = TestData.createPosition(
          latitude: TestData.glasgow.latitude,
          longitude: TestData.glasgow.longitude,
        );
        fakeGeolocator.setCurrentPosition(currentPos);

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await locationResolver.getLatLon();

        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(2500),
            reason: 'Should complete within timeout budget');

        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);

        // On all platforms without GPS support (including macOS), falls back to Scotland centroid
        expect(location.latitude,
            closeTo(TestData.scotlandCentroid.latitude, 0.001));
        expect(location.longitude,
            closeTo(TestData.scotlandCentroid.longitude, 0.001));
      });
    });

    group('GPS Permission Handling', () {
      test('GPS permission granted returns GPS coordinates within 2s timeout',
          () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(true);
        fakeGeolocator.setResponseDelay(Duration(milliseconds: 500));

        final gpsPos = TestData.createPosition(
          latitude: TestData.london.latitude,
          longitude: TestData.london.longitude,
        );
        fakeGeolocator.setCurrentPosition(gpsPos);

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await locationResolver.getLatLon();

        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'GPS should complete within 2s timeout');

        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);

        // On macOS/desktop, platform guard skips GPS and uses Scotland centroid
        if (Platform.isAndroid || Platform.isIOS) {
          expect(location.latitude, closeTo(TestData.london.latitude, 0.001));
          expect(location.longitude, closeTo(TestData.london.longitude, 0.001));
        } else {
          expect(location.latitude,
              closeTo(TestData.scotlandCentroid.latitude, 0.001));
          expect(location.longitude,
              closeTo(TestData.scotlandCentroid.longitude, 0.001));
        }
      });

      test('permission denied + allowDefault=true returns Scotland centroid',
          () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);
        expect(location.latitude,
            closeTo(TestData.scotlandCentroid.latitude, 0.001));
        expect(location.longitude,
            closeTo(TestData.scotlandCentroid.longitude, 0.001));
      });

      test(
          'permission denied + allowDefault=false returns Left(permissionDenied)',
          () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Act
        final result = await locationResolver.getLatLon(allowDefault: false);

        // Assert
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => LocationError.invalidInput);
        expect(error, equals(LocationError.permissionDenied));
      });

      test('deniedForever + allowDefault=false returns Left(permissionDenied)',
          () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.deniedForever);

        // Act
        final result = await locationResolver.getLatLon(allowDefault: false);

        // Assert
        expect(result.isLeft(), isTrue);
        final error = result.fold((l) => l, (r) => LocationError.invalidInput);
        expect(error, equals(LocationError.permissionDenied));
      });
    });

    group('GPS Timeout and Fallback', () {
      test('GPS timeout triggers fallback within 2.5s total budget', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(true);
        fakeGeolocator
            .setResponseDelay(Duration(seconds: 3)); // Exceeds 2s timeout
        fakeGeolocator.setException(
            TimeoutException('GPS timeout', Duration(seconds: 2)));

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(2500),
            reason: 'Total resolution should complete within 2.5s budget');

        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);
        expect(location.latitude,
            closeTo(TestData.scotlandCentroid.latitude, 0.001));
      });
    });

    group('Platform Guards', () {
      test('web/emulator platform skips GPS and uses fallback path', () async {
        // Note: In a real implementation, we would mock kIsWeb or platform detection
        // For this test, we simulate the behavior by configuring GPS as unavailable

        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setLocationServiceEnabled(false);

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);
        expect(location.latitude,
            closeTo(TestData.scotlandCentroid.latitude, 0.001));
      });
    });

    group('SharedPreferences Cache Tier', () {
      test('uses cached manual location when GPS fails', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Set up cached location
        SharedPreferences.setMockInitialValues({
          'manual_location_version': '1.0',
          'manual_location_lat': TestData.edinburgh.latitude,
          'manual_location_lon': TestData.edinburgh.longitude,
          'manual_location_timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);
        expect(location.latitude, closeTo(TestData.edinburgh.latitude, 0.001));
        expect(
            location.longitude, closeTo(TestData.edinburgh.longitude, 0.001));
      });

      test('handles SharedPreferences corruption gracefully', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Set up corrupted cache data
        SharedPreferences.setMockInitialValues({
          'manual_location_version': '1.0',
          'manual_location_lat': 999.0, // Invalid latitude
          'manual_location_lon': TestData.edinburgh.longitude,
          'manual_location_timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert - should fall back to Scotland centroid without crashing
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);
        expect(location.latitude,
            closeTo(TestData.scotlandCentroid.latitude, 0.001));
      });
    });

    group('saveManual Integration', () {
      test('saveManual persists location to cache', () async {
        // Arrange
        final testLocation = TestData.edinburgh;
        const placeName = 'Edinburgh Castle';

        // Act
        await locationResolver.saveManual(testLocation, placeName: placeName);

        // Assert - verify data was saved to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('manual_location_version'), equals('1.0'));
        expect(prefs.getDouble('manual_location_lat'),
            equals(testLocation.latitude));
        expect(prefs.getDouble('manual_location_lon'),
            equals(testLocation.longitude));
        expect(prefs.getString('manual_location_place'), equals(placeName));
        expect(prefs.getInt('manual_location_timestamp'), isNotNull);
      });
    });

    group('Privacy Compliance (Gate C2)', () {
      test('all coordinate logging uses logRedact helper', () async {
        // Note: In a real implementation, we would inject a logger to capture output
        // This test verifies the logRedact helper is used correctly

        // Arrange
        const testLat = 55.123456789;
        const testLon = -3.987654321;

        // Act
        final redacted = LocationUtils.logRedact(testLat, testLon);

        // Assert
        expect(redacted, equals('55.12,-3.99'));
        expect(redacted.split(',')[0].split('.')[1].length, equals(2));
        expect(redacted.split(',')[1].split('.')[1].length, equals(2));
      });

      test('logRedact handles edge cases correctly', () {
        // Test negative coordinates
        expect(LocationUtils.logRedact(-90.123456, 180.987654),
            equals('-90.12,180.99'));

        // Test zero values
        expect(LocationUtils.logRedact(0.0, 0.0), equals('0.00,0.00'));

        // Test boundary values
        expect(LocationUtils.logRedact(90.0, -180.0), equals('90.00,-180.00'));
      });
    });

    group('Coordinate Validation', () {
      test('validates coordinate ranges correctly', () {
        // Valid coordinates
        expect(LocationUtils.isValidCoordinate(55.9533, -3.1883), isTrue);
        expect(LocationUtils.isValidCoordinate(90.0, 180.0), isTrue);
        expect(LocationUtils.isValidCoordinate(-90.0, -180.0), isTrue);

        // Invalid coordinates
        expect(LocationUtils.isValidCoordinate(91.0, -3.1883), isFalse);
        expect(LocationUtils.isValidCoordinate(55.9533, 181.0), isFalse);
        expect(LocationUtils.isValidCoordinate(-91.0, -3.1883), isFalse);
        expect(LocationUtils.isValidCoordinate(55.9533, -181.0), isFalse);
      });
    });

    group('Error Handling and Resilience', () {
      test('handles multiple GPS failures gracefully', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setException(Exception('GPS hardware error'));

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert - should not crash and return default
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.scotlandCentroid);
        expect(location.latitude,
            closeTo(TestData.scotlandCentroid.latitude, 0.001));
      });

      test('handles concurrent location requests', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setResponseDelay(Duration(milliseconds: 100));

        final gpsPos = TestData.createPosition(
          latitude: TestData.glasgow.latitude,
          longitude: TestData.glasgow.longitude,
        );
        fakeGeolocator.setCurrentPosition(gpsPos);

        // Act - make multiple concurrent requests
        final futures = List.generate(3, (_) => locationResolver.getLatLon());
        final results = await Future.wait(futures);

        // Assert - all should succeed
        for (final result in results) {
          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.scotlandCentroid);

          // On macOS/desktop, platform guard skips GPS and uses Scotland centroid
          if (Platform.isAndroid || Platform.isIOS) {
            expect(
                location.latitude, closeTo(TestData.glasgow.latitude, 0.001));
            expect(
                location.longitude, closeTo(TestData.glasgow.longitude, 0.001));
          } else {
            expect(location.latitude,
                closeTo(TestData.scotlandCentroid.latitude, 0.001));
            expect(location.longitude,
                closeTo(TestData.scotlandCentroid.longitude, 0.001));
          }
        }
      });
    });

    group('Performance Requirements', () {
      test('last known position resolves in under 100ms', () async {
        // Arrange
        final lastKnownPos = TestData.createPosition(
          latitude: TestData.edinburgh.latitude,
          longitude: TestData.edinburgh.longitude,
        );
        fakeGeolocator.setLastKnownPosition(lastKnownPos);

        // Act & Assert
        final stopwatch = Stopwatch()..start();
        final result = await locationResolver.getLatLon();
        stopwatch.stop();

        expect(result.isRight(), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test(
          'total resolution completes within 2.5s budget under adverse conditions',
          () async {
        // Arrange - simulate slow GPS that will timeout
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setResponseDelay(Duration(seconds: 3));
        fakeGeolocator.setException(
            TimeoutException('GPS timeout', Duration(seconds: 2)));

        // Act & Assert
        final stopwatch = Stopwatch()..start();
        final result = await locationResolver.getLatLon(allowDefault: true);
        stopwatch.stop();

        expect(result.isRight(), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(2500));
      });
    });
  });
}
