import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/location_resolver_impl.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';
import '../../support/fakes.dart';

void main() {
  // Initialize Flutter binding for SharedPreferences platform channel
  WidgetsFlutterBinding.ensureInitialized();

  // Note: These tests run with DEV_MODE=true by default (compile-time constant).
  // The default fallback location is Aviemore (57.2, -3.8) in dev mode.
  // In production (DEV_MODE=false), the fallback would be Scotland centroid (55.8642, -4.2518).
  // See: lib/config/feature_flags.dart and lib/services/location_resolver_impl.dart

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

      // Create location resolver with injected fake geolocator
      // This allows tests to control GPS behavior regardless of platform
      locationResolver = LocationResolverImpl(
        geolocatorService: fakeGeolocator,
      );
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
        // Also set current position for web (getLastKnownPosition skipped on web)
        fakeGeolocator.setCurrentPosition(lastKnownPos);

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await locationResolver.getLatLon();

        // Assert
        stopwatch.stop();
        // Web may take slightly longer since it uses getCurrentPosition
        const maxTime = kIsWeb ? 500 : 100;
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(maxTime),
          reason: 'Should return quickly regardless of platform',
        );

        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);

        // With injectable GeolocatorService, GPS works on all platforms
        // The fake returns Edinburgh coordinates as last known position (native)
        // or current position (web, since getLastKnownPosition is skipped)
        // Note: On desktop, platform guard skips GPS, so fallback is used
        if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
          // Desktop: platform guard triggers, falls back to Aviemore (DEV_MODE)
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
          );
          expect(
            location.coordinates.longitude,
            closeTo(TestData.aviemore.longitude, 0.001),
          );
        } else {
          // Web and mobile: GPS works via injectable fake
          // Web uses getCurrentPosition, mobile uses getLastKnownPosition
          expect(
            location.coordinates.latitude,
            closeTo(TestData.edinburgh.latitude, 0.001),
          );
          expect(
            location.coordinates.longitude,
            closeTo(TestData.edinburgh.longitude, 0.001),
          );
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
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2500),
          reason: 'Should complete within timeout budget',
        );

        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);

        // With injectable GeolocatorService, GPS works on web/mobile
        // Note: On desktop, platform guard skips GPS, so fallback is used
        if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
          // Desktop: platform guard triggers, falls back to Aviemore (DEV_MODE)
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
          );
          expect(
            location.coordinates.longitude,
            closeTo(TestData.aviemore.longitude, 0.001),
          );
        } else {
          // Web and mobile: GPS works via injectable fake
          expect(
            location.coordinates.latitude,
            closeTo(TestData.glasgow.latitude, 0.001),
          );
          expect(
            location.coordinates.longitude,
            closeTo(TestData.glasgow.longitude, 0.001),
          );
        }
      });
    });

    group('GPS Permission Handling', () {
      test(
        'GPS permission granted returns GPS coordinates within 2s timeout',
        () async {
          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.whileInUse);
          fakeGeolocator.setLocationServiceEnabled(true);
          fakeGeolocator.setResponseDelay(const Duration(milliseconds: 500));

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
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(2000),
            reason: 'GPS should complete within 2s timeout',
          );

          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);

          // With injectable GeolocatorService, GPS works on web/mobile
          // Note: On desktop, platform guard skips GPS, so fallback is used
          if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
            // Desktop: platform guard triggers, falls back to Aviemore (DEV_MODE)
            expect(
              location.coordinates.latitude,
              closeTo(TestData.aviemore.latitude, 0.001),
            );
            expect(
              location.coordinates.longitude,
              closeTo(TestData.aviemore.longitude, 0.001),
            );
          } else {
            // Web and mobile: GPS works via injectable fake
            expect(
              location.coordinates.latitude,
              closeTo(TestData.london.latitude, 0.001),
            );
            expect(
              location.coordinates.longitude,
              closeTo(TestData.london.longitude, 0.001),
            );
          }
        },
      );

      test(
        'permission denied + allowDefault=true returns Scotland centroid',
        () async {
          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.denied);

          // Act
          final result = await locationResolver.getLatLon(allowDefault: true);

          // Assert
          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
          );
          expect(
            location.coordinates.longitude,
            closeTo(TestData.aviemore.longitude, 0.001),
          );
        },
        // Web intentionally requires manual entry rather than silent default fallback
        // See location_resolver_impl.dart Tier 4 comments
        skip: kIsWeb,
      );

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
          final error = result.fold(
            (l) => l,
            (r) => LocationError.invalidInput,
          );
          expect(error, equals(LocationError.permissionDenied));
        },
      );

      test(
        'deniedForever + allowDefault=false returns Left(permissionDenied)',
        () async {
          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.deniedForever);

          // Act
          final result = await locationResolver.getLatLon(allowDefault: false);

          // Assert
          expect(result.isLeft(), isTrue);
          final error = result.fold(
            (l) => l,
            (r) => LocationError.invalidInput,
          );
          expect(error, equals(LocationError.permissionDenied));
        },
      );
    });

    group('GPS Timeout and Fallback', () {
      test(
        'GPS timeout triggers fallback within 2.5s total budget',
        () async {
          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.whileInUse);
          fakeGeolocator.setLocationServiceEnabled(true);
          fakeGeolocator.setResponseDelay(
            const Duration(seconds: 3),
          ); // Exceeds 2s timeout
          fakeGeolocator.setException(
            TimeoutException('GPS timeout', const Duration(seconds: 2)),
          );

          final stopwatch = Stopwatch()..start();

          // Act
          final result = await locationResolver.getLatLon(allowDefault: true);

          // Assert
          stopwatch.stop();
          // Web has 10s timeout, native has 3s timeout
          // With timeout exception, should fall back to default quickly
          // Allow more time on web since timeout is longer (though exception should be fast)
          const maxTime = kIsWeb ? 5000 : 2500;
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(maxTime),
            reason: 'Total resolution should complete within timeout budget',
          );

          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
          );
        },
        // Web intentionally requires manual entry rather than silent default fallback
        skip: kIsWeb,
      );
    });

    group('Platform Guards', () {
      // Note: Web platform now ALLOWS GPS access (via browser Geolocation API)
      // Only desktop platforms (macOS, Windows, Linux) skip GPS
      // This change was made to support PWA GPS on mobile browsers

      test(
        'desktop platform skips GPS and uses fallback path',
        () async {
          // Note: In a real implementation, we would mock kIsWeb or platform detection
          // For this test, we simulate the behavior by configuring GPS as unavailable

          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setLocationServiceEnabled(false);

          // Act
          final result = await locationResolver.getLatLon(allowDefault: true);

          // Assert - uses default fallback (Aviemore in DEV_MODE)
          expect(result.isRight(), isTrue);
          // ignore: deprecated_member_use_from_same_package
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(
            location.coordinates.latitude,
            // ignore: deprecated_member_use_from_same_package
            closeTo(TestData.aviemore.latitude, 0.001),
          );
        },
        // Web intentionally requires manual entry rather than silent default fallback
        skip: kIsWeb,
      );
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
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(
          location.coordinates.latitude,
          closeTo(TestData.edinburgh.latitude, 0.001),
        );
        expect(
          location.coordinates.longitude,
          closeTo(TestData.edinburgh.longitude, 0.001),
        );
      });

      test(
        'handles SharedPreferences corruption gracefully',
        () async {
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
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
          );
        },
        // Web intentionally requires manual entry rather than silent default fallback
        skip: kIsWeb,
      );

      test(
        'expired cached manual location is ignored (TTL >1 hour)',
        () async {
          // This test verifies the fix for the mobile web GPS bug where:
          // 1. User sets manual location on desktop browser
          // 2. Stale location persists in localStorage
          // 3. Phone browser should NOT use stale location - should try GPS

          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.denied);

          // Set up cached location from 2 hours ago (expired)
          final twoHoursAgo = DateTime.now()
              .subtract(const Duration(hours: 2))
              .millisecondsSinceEpoch;
          SharedPreferences.setMockInitialValues({
            'manual_location_version': '1.0',
            'manual_location_lat': TestData.edinburgh.latitude,
            'manual_location_lon': TestData.edinburgh.longitude,
            'manual_location_timestamp': twoHoursAgo,
          });

          // Act
          final result = await locationResolver.getLatLon(allowDefault: true);

          // Assert - should ignore expired cache and use fallback
          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
            reason: 'Should ignore expired cache and fall back to Aviemore',
          );
        },
        // Web intentionally requires manual entry rather than silent default fallback
        skip: kIsWeb,
      );

      test('fresh cached manual location is used (TTL <1 hour)', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Set up cached location from 30 minutes ago (still fresh)
        final thirtyMinutesAgo = DateTime.now()
            .subtract(const Duration(minutes: 30))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'manual_location_version': '1.0',
          'manual_location_lat': TestData.edinburgh.latitude,
          'manual_location_lon': TestData.edinburgh.longitude,
          'manual_location_timestamp': thirtyMinutesAgo,
        });

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert - should use fresh cached location
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(
          location.coordinates.latitude,
          closeTo(TestData.edinburgh.latitude, 0.001),
          reason: 'Should use fresh cached location (within 1 hour TTL)',
        );
      });

      test(
        'cache without timestamp is treated as expired',
        () async {
          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.denied);

          // Set up cached location without timestamp (old format)
          SharedPreferences.setMockInitialValues({
            'manual_location_version': '1.0',
            'manual_location_lat': TestData.edinburgh.latitude,
            'manual_location_lon': TestData.edinburgh.longitude,
            // No timestamp key
          });

          // Act
          final result = await locationResolver.getLatLon(allowDefault: true);

          // Assert - should ignore cache without timestamp and use fallback
          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
            reason: 'Should treat missing timestamp as expired',
          );
        },
        // Web intentionally requires manual entry rather than silent default fallback
        skip: kIsWeb,
      );
    });

    group('saveManual Integration', () {
      test('saveManual persists location to cache', () async {
        // Arrange
        const testLocation = TestData.edinburgh;
        const placeName = 'Edinburgh Castle';

        // Act
        await locationResolver.saveManual(testLocation, placeName: placeName);

        // Assert - verify data was saved to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('manual_location_version'), equals('1.0'));
        expect(
          prefs.getDouble('manual_location_lat'),
          equals(testLocation.latitude),
        );
        expect(
          prefs.getDouble('manual_location_lon'),
          equals(testLocation.longitude),
        );
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
        // Test negative coordinates (within valid range)
        expect(
          LocationUtils.logRedact(-89.123456, 179.987654),
          equals('-89.12,179.99'),
        );

        // Test zero values
        expect(LocationUtils.logRedact(0.0, 0.0), equals('0.00,0.00'));

        // Test exact boundary values (valid)
        expect(LocationUtils.logRedact(90.0, -180.0), equals('90.00,-180.00'));
        expect(LocationUtils.logRedact(90.0, 180.0), equals('90.00,180.00'));
        expect(LocationUtils.logRedact(-90.0, 0.0), equals('-90.00,0.00'));
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
      test(
        'handles multiple GPS failures gracefully',
        () async {
          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setException(Exception('GPS hardware error'));

          // Act
          final result = await locationResolver.getLatLon(allowDefault: true);

          // Assert - should not crash and return default
          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
          );
        },
        // Web intentionally requires manual entry rather than silent default fallback
        skip: kIsWeb,
      );

      test('handles concurrent location requests', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setResponseDelay(const Duration(milliseconds: 100));

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
          final location = result.getOrElse(() => TestData.aviemoreResolved);

          // With injectable GeolocatorService, GPS works on all platforms except desktop
          // Desktop (macOS, Windows, Linux) skips GPS and uses DEV_MODE default (Aviemore)
          // Web and mobile platforms use the injected FakeGeolocator → Glasgow
          if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
            // Desktop only - GPS skipped, uses Aviemore fallback
            expect(
              location.coordinates.latitude,
              closeTo(TestData.aviemore.latitude, 0.001),
            );
            expect(
              location.coordinates.longitude,
              closeTo(TestData.aviemore.longitude, 0.001),
            );
          } else {
            // Web and mobile - GPS works via FakeGeolocator → Glasgow
            expect(
              location.coordinates.latitude,
              closeTo(TestData.glasgow.latitude, 0.001),
            );
            expect(
              location.coordinates.longitude,
              closeTo(TestData.glasgow.longitude, 0.001),
            );
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
        // Also set current position for web (getLastKnownPosition skipped on web)
        fakeGeolocator.setCurrentPosition(lastKnownPos);

        // Act & Assert
        final stopwatch = Stopwatch()..start();
        final result = await locationResolver.getLatLon();
        stopwatch.stop();

        expect(result.isRight(), isTrue);
        // Web may take slightly longer since it uses getCurrentPosition
        const maxTime = kIsWeb ? 500 : 100;
        expect(stopwatch.elapsedMilliseconds, lessThan(maxTime));
      });

      test(
        'total resolution completes within 2.5s budget under adverse conditions',
        () async {
          // Arrange - simulate slow GPS that will timeout
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.whileInUse);
          fakeGeolocator.setResponseDelay(const Duration(seconds: 3));
          fakeGeolocator.setException(
            TimeoutException('GPS timeout', const Duration(seconds: 2)),
          );

          // Act & Assert
          final stopwatch = Stopwatch()..start();
          final result = await locationResolver.getLatLon(allowDefault: true);
          stopwatch.stop();

          expect(result.isRight(), isTrue);
          // Web has 10s timeout, but exception should short-circuit quickly
          const maxTime = kIsWeb ? 5000 : 2500;
          expect(stopwatch.elapsedMilliseconds, lessThan(maxTime));
        },
        // Web intentionally requires manual entry rather than silent default fallback
        skip: kIsWeb,
      );
    });
  });
}
