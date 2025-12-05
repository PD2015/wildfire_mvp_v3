import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/location_resolver_impl.dart';
import 'package:wildfire_mvp_v3/services/location_cache.dart';
import '../support/fakes.dart';

void main() {
  // Initialize Flutter binding for SharedPreferences platform channel
  WidgetsFlutterBinding.ensureInitialized();

  group('Location Flow Integration Tests', () {
    late LocationResolverImpl locationResolver;
    late FakeGeolocator fakeGeolocator;
    late FakeTimer fakeTimer;

    /// Platform guard skips GPS only on desktop platforms (not web or mobile)
    /// Web uses GPS via injectable GeolocatorService, mobile uses native GPS
    /// Only desktop (macOS/Windows/Linux) skips GPS and returns fallback
    bool isPlatformGuardActive() =>
        !kIsWeb && !Platform.isAndroid && !Platform.isIOS;

    /// Get expected coordinates when GPS is set up but platform guard may be active
    LatLng expectedLocationForGpsSetup(LatLng gpsCoordinates) {
      return isPlatformGuardActive() ? TestData.aviemore : gpsCoordinates;
    }

    setUp(() {
      fakeGeolocator = FakeGeolocator();
      fakeTimer = FakeTimer();
      SharedPreferences.setMockInitialValues({});

      // Inject fake geolocator for controllable GPS behavior
      locationResolver = LocationResolverImpl(
        geolocatorService: fakeGeolocator,
      );
    });

    tearDown(() {
      fakeGeolocator.reset();
      fakeTimer.clear();
    });

    group('Complete 5-Tier Fallback Chain', () {
      test(
        'Tier 1: Last known position available - returns immediately',
        () async {
          // Skip on web: getLastKnownPosition is not supported on web platform
          // Web skips directly to getCurrentPosition (Tier 2)
          if (kIsWeb) {
            // On web, this test verifies GPS success path instead
            fakeGeolocator.setPermission(LocationPermission.whileInUse);
            fakeGeolocator.setLocationServiceEnabled(true);
            fakeGeolocator.setResponseDelay(const Duration(milliseconds: 50));
            final gpsPos = TestData.createPosition(
              latitude: TestData.edinburgh.latitude,
              longitude: TestData.edinburgh.longitude,
            );
            fakeGeolocator.setCurrentPosition(gpsPos);
          } else {
            // Arrange - native platforms use last known position
            final lastKnownPos = TestData.createPosition(
              latitude: TestData.edinburgh.latitude,
              longitude: TestData.edinburgh.longitude,
            );
            fakeGeolocator.setLastKnownPosition(lastKnownPos);
          }

          final stopwatch = Stopwatch()..start();

          // Act
          final result = await locationResolver.getLatLon();

          // Assert
          stopwatch.stop();
          // Web needs slightly more time for GPS path vs instant last-known
          // ignore: prefer_const_declarations
          final maxTime = kIsWeb ? 200 : 100;
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(maxTime),
            reason:
                'Position should resolve quickly (${kIsWeb ? "web GPS" : "last known"})',
          );

          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          final expectedLocation = expectedLocationForGpsSetup(
            TestData.edinburgh,
          );
          expect(location.coordinates.latitude,
              closeTo(expectedLocation.latitude, 0.001));
          expect(
            location.coordinates.longitude,
            closeTo(expectedLocation.longitude, 0.001),
          );
        },
      );

      test('Tier 2: GPS success when last known unavailable', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(true);
        fakeGeolocator.setResponseDelay(const Duration(milliseconds: 800));

        final gpsPos = TestData.createPosition(
          latitude: TestData.glasgow.latitude,
          longitude: TestData.glasgow.longitude,
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
        final expectedLocation = expectedLocationForGpsSetup(TestData.glasgow);
        expect(location.coordinates.latitude,
            closeTo(expectedLocation.latitude, 0.001));
        expect(location.coordinates.longitude,
            closeTo(expectedLocation.longitude, 0.001));
      });

      test('Tier 3: Cached manual location when GPS fails', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Set up cached manual location (using Edinburgh - within Scotland bounds)
        SharedPreferences.setMockInitialValues({
          'manual_location_version': '1.0',
          'manual_location_lat': TestData.edinburgh.latitude,
          'manual_location_lon': TestData.edinburgh.longitude,
          'manual_location_timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Act
        final result = await locationResolver.getLatLon();

        // Assert
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(location.coordinates.latitude,
            closeTo(TestData.edinburgh.latitude, 0.001));
        expect(
          location.coordinates.longitude,
          closeTo(TestData.edinburgh.longitude, 0.001),
        );
      });

      test(
        'Tier 4: allowDefault=false returns Left when manual entry needed',
        () async {
          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.denied);
          // No cached location

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
        'Tier 5: Scotland centroid as final fallback when allowDefault=true',
        () async {
          // Arrange
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.denied);
          // No cached location

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
      );
    });

    group('Performance Budget Enforcement', () {
      test(
        'total resolution completes within 2.5s budget under worst conditions',
        () async {
          // Arrange - Simulate worst case: slow GPS that times out
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.whileInUse);
          fakeGeolocator.setLocationServiceEnabled(true);

          // Configure timeout behavior based on platform
          // Web uses 10s timeout, native uses 3s timeout
          // We set response delay to trigger timeout exception quickly
          // ignore: prefer_const_declarations
          final platformTimeout =
              kIsWeb ? const Duration(seconds: 10) : const Duration(seconds: 3);
          fakeGeolocator.setResponseDelay(
            const Duration(seconds: 1),
          ); // Small delay before throwing
          fakeGeolocator.setException(
            TimeoutException('GPS timeout', platformTimeout),
          );

          final stopwatch = Stopwatch()..start();

          // Act
          final result = await locationResolver.getLatLon(allowDefault: true);

          // Assert
          stopwatch.stop();
          // Allow more time on web due to longer permission/service checks
          // ignore: prefer_const_declarations
          final maxTime = kIsWeb ? 1500 : 2500;
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(maxTime),
            reason: 'Total resolution should complete within budget',
          );

          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(
            location.coordinates.latitude,
            closeTo(TestData.aviemore.latitude, 0.001),
          );
        },
      );

      test('cached location lookup is fast (<200ms)', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        SharedPreferences.setMockInitialValues({
          'manual_location_version': '1.0',
          'manual_location_lat': TestData.edinburgh.latitude,
          'manual_location_lon': TestData.edinburgh.longitude,
          'manual_location_timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await locationResolver.getLatLon();

        // Assert
        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'SharedPreferences access should be <200ms',
        );

        expect(result.isRight(), isTrue);
      });
    });

    group('Manual Location Persistence', () {
      test('manual location persists across app restart simulation', () async {
        // Arrange - First session: save manual location
        const testLocation = TestData.glasgow;
        const placeName = 'Glasgow City Centre';

        await locationResolver.saveManual(testLocation, placeName: placeName);

        // Simulate app restart by creating new instances
        final newFakeGeolocator = FakeGeolocator();

        // Configure GPS to fail so it falls back to cache
        newFakeGeolocator.setLastKnownPosition(null);
        newFakeGeolocator.setPermission(LocationPermission.denied);

        // Inject fake geolocator into new resolver
        final newLocationResolver = LocationResolverImpl(
          geolocatorService: newFakeGeolocator,
        );

        // Act - Second session: retrieve location
        final result = await newLocationResolver.getLatLon();

        // Assert
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(location.coordinates.latitude,
            closeTo(testLocation.latitude, 0.001));
        expect(location.coordinates.longitude,
            closeTo(testLocation.longitude, 0.001));

        // Verify place name is also persisted
        final cache = LocationCache();
        final savedPlace = await cache.loadPlaceName();
        expect(savedPlace, equals(placeName));
      });

      test('version compatibility check works correctly', () async {
        // Arrange - Set up cache with different version
        SharedPreferences.setMockInitialValues({
          'manual_location_version': '2.0', // Future version
          'manual_location_lat': TestData.edinburgh.latitude,
          'manual_location_lon': TestData.edinburgh.longitude,
          'manual_location_timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert - Should fall back to Scotland centroid due to version incompatibility
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(
          location.coordinates.latitude,
          closeTo(TestData.aviemore.latitude, 0.001),
        );
      });
    });

    group('Permission Flow Testing', () {
      test('permission granted flow works end-to-end', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(true);

        final gpsPos = TestData.createPosition(
          latitude: TestData.edinburgh.latitude,
          longitude: TestData.edinburgh.longitude,
        );
        fakeGeolocator.setCurrentPosition(gpsPos);

        // Act
        final result = await locationResolver.getLatLon();

        // Assert
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        final expectedLocation = expectedLocationForGpsSetup(
          TestData.edinburgh,
        );
        expect(location.coordinates.latitude,
            closeTo(expectedLocation.latitude, 0.001));
        expect(location.coordinates.longitude,
            closeTo(expectedLocation.longitude, 0.001));
      });

      test('permission denied flow falls back correctly', () async {
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
      });

      test('permission deniedForever flow handles gracefully', () async {
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

    group('Error Resilience Testing', () {
      test('handles GPS hardware failure gracefully', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(true);
        fakeGeolocator.setException(Exception('GPS hardware failure'));

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert - Should not crash, fall back to default
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(
          location.coordinates.latitude,
          closeTo(TestData.aviemore.latitude, 0.001),
        );
      });

      test('handles SharedPreferences corruption without crash', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Set up corrupted cache data
        SharedPreferences.setMockInitialValues({
          'manual_location_version': '1.0',
          'manual_location_lat': double.nan, // Corrupted data
          'manual_location_lon': TestData.edinburgh.longitude,
          'manual_location_timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert - Should handle corruption gracefully
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(
          location.coordinates.latitude,
          closeTo(TestData.aviemore.latitude, 0.001),
        );
      });

      test('handles location service disabled scenario', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(false); // Services disabled

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(
          location.coordinates.latitude,
          closeTo(TestData.aviemore.latitude, 0.001),
        );
      });
    });

    group('Concurrent Request Handling', () {
      test('handles multiple concurrent location requests safely', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(true);
        fakeGeolocator.setResponseDelay(const Duration(milliseconds: 200));

        final gpsPos = TestData.createPosition(
          latitude: TestData.glasgow.latitude,
          longitude: TestData.glasgow.longitude,
        );
        fakeGeolocator.setCurrentPosition(gpsPos);

        // Act - Make multiple concurrent requests
        final futures = List.generate(5, (_) => locationResolver.getLatLon());
        final results = await Future.wait(futures);

        // Assert - All should succeed with same result
        final expectedLocation = expectedLocationForGpsSetup(TestData.glasgow);
        for (final result in results) {
          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(location.coordinates.latitude,
              closeTo(expectedLocation.latitude, 0.001));
          expect(
            location.coordinates.longitude,
            closeTo(expectedLocation.longitude, 0.001),
          );
        }
      });
    });

    group('Cache Consistency', () {
      test(
        'saved manual location is immediately available in next request',
        () async {
          // Arrange
          const testLocation = TestData.edinburgh;
          const placeName = 'Test Location';

          // Configure GPS to fail so it uses cache
          fakeGeolocator.setLastKnownPosition(null);
          fakeGeolocator.setPermission(LocationPermission.denied);

          // Act - Save and immediately retrieve
          await locationResolver.saveManual(testLocation, placeName: placeName);
          final result = await locationResolver.getLatLon();

          // Assert
          expect(result.isRight(), isTrue);
          final location = result.getOrElse(() => TestData.aviemoreResolved);
          expect(location.coordinates.latitude,
              closeTo(testLocation.latitude, 0.001));
          expect(location.coordinates.longitude,
              closeTo(testLocation.longitude, 0.001));
        },
      );

      test('cache timestamp is updated on save', () async {
        // Arrange
        const testLocation = TestData.glasgow;
        final beforeSave = DateTime.now().millisecondsSinceEpoch;

        // Act
        await locationResolver.saveManual(testLocation);

        // Assert
        final cache = LocationCache();
        final timestamp = await cache.getTimestamp();
        expect(timestamp, isNotNull);
        expect(timestamp!, greaterThanOrEqualTo(beforeSave));
      });
    });

    group('Real-World Scenarios', () {
      test('first app launch with GPS available scenario', () async {
        // Arrange - Fresh install, no cache, GPS available
        SharedPreferences.setMockInitialValues({});

        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(true);

        final gpsPos = TestData.createPosition(
          latitude: TestData.edinburgh.latitude,
          longitude: TestData.edinburgh.longitude,
        );
        fakeGeolocator.setCurrentPosition(gpsPos);

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await locationResolver.getLatLon();

        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        final expectedLocation = expectedLocationForGpsSetup(
          TestData.edinburgh,
        );
        expect(location.coordinates.latitude,
            closeTo(expectedLocation.latitude, 0.001));
        expect(location.coordinates.longitude,
            closeTo(expectedLocation.longitude, 0.001));
      });

      test('user denies GPS permission scenario', () async {
        // Arrange
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.denied);

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert - Should fall back to Scotland centroid
        expect(result.isRight(), isTrue);
        final location = result.getOrElse(() => TestData.aviemoreResolved);
        expect(
          location.coordinates.latitude,
          closeTo(TestData.aviemore.latitude, 0.001),
        );
      });

      test('poor GPS signal timeout scenario', () async {
        // Arrange - GPS permission granted but signal times out
        fakeGeolocator.setLastKnownPosition(null);
        fakeGeolocator.setPermission(LocationPermission.whileInUse);
        fakeGeolocator.setLocationServiceEnabled(true);
        fakeGeolocator.setException(
          TimeoutException('GPS timeout', const Duration(seconds: 2)),
        );

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await locationResolver.getLatLon(allowDefault: true);

        // Assert
        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2500),
          reason: 'Should complete within budget even with GPS timeout',
        );
        expect(result.isRight(), isTrue);
      });
    });
  });
}
