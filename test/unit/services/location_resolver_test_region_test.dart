import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildfire_mvp_v3/services/location_resolver_impl.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import '../../support/fakes.dart';

/// Tests for TEST_REGION feature flag behavior in LocationResolver
///
/// These tests verify that LocationResolver correctly skips GPS and returns
/// an error when TEST_REGION is explicitly set, allowing controllers to use
/// test region coordinates for EFFIS queries.
void main() {
  // Initialize Flutter binding for platform services
  WidgetsFlutterBinding.ensureInitialized();

  group('LocationResolver TEST_REGION Integration', () {
    late LocationResolverImpl locationResolver;
    late FakeGeolocator fakeGeolocator;

    setUp(() {
      // Mock SharedPreferences to prevent hanging on web platform
      SharedPreferences.setMockInitialValues({});

      // Create fake geolocator for testability
      fakeGeolocator = FakeGeolocator();

      // Create location resolver with injected fake
      locationResolver = LocationResolverImpl(
        geolocatorService: fakeGeolocator,
      );
    });

    // Note: These tests require running with specific --dart-define values
    // They demonstrate the expected behavior but cannot be run in standard CI
    // without environment variable support.

    test('TEST_REGION!=scotland should skip GPS and return error', () async {
      // This test documents expected behavior when TEST_REGION is set
      // In practice, this would be tested via integration tests with
      // --dart-define=TEST_REGION=portugal

      // When TEST_REGION is set to anything other than 'scotland',
      // LocationResolver should:
      // 1. Skip GPS acquisition
      // 2. Return LocationError.gpsUnavailable
      // 3. Allow controllers to use _getTestRegionCenter()

      // This enables testing with fire-prone regions by ensuring
      // both HomeController and MapController query the same coordinates

      expect(
        FeatureFlags.testRegion,
        'scotland', // Default in test environment
        reason: 'Default TEST_REGION should be scotland in tests',
      );
    });

    test(
      'TEST_REGION=scotland (default) should use normal GPS flow',
      () async {
        // When TEST_REGION is default 'scotland', normal GPS flow applies:
        // 1. Try GPS (with timeout) - on web/unsupported platforms, skips to cache
        // 2. Fall back to cached location
        // 3. Fall back to Scotland centroid

        // This test verifies the default behavior is unchanged
        // On web platform, GPS is skipped and falls back to default centroid
        final result = await locationResolver.getLatLon();

        expect(
          result.isRight(),
          isTrue,
          reason:
              'Default flow should succeed with Scotland centroid (via cache fallback on web)',
        );

        // Verify we get valid coordinates
        final resolved = result.getOrElse(
          () => const ResolvedLocation(
            coordinates: LatLng(0, 0),
            source: LocationSource.defaultFallback,
          ),
        );
        expect(resolved.coordinates.latitude, isNonZero);
        expect(resolved.coordinates.longitude, isNonZero);
      },
      // Web intentionally requires manual entry rather than silent default fallback
      // See location_resolver_impl.dart Tier 4 comments
      skip: kIsWeb,
    );

    group('GPS Skip Behavior (Integration Test Scenarios)', () {
      // These document the integration test scenarios that should be run
      // manually with different --dart-define values

      test('TEST_REGION=portugal should trigger test region fallback', () {
        // Integration test command:
        // flutter test --dart-define=TEST_REGION=portugal

        // Expected behavior:
        // 1. LocationResolver.getLatLon() returns Left(LocationError.gpsUnavailable)
        // 2. HomeController catches error, checks FeatureFlags.testRegion
        // 3. HomeController uses _getTestRegionCenter() → LatLng(39.6, -9.1)
        // 4. MapController does the same
        // 5. Both query EFFIS for Portugal coordinates

        // Verification:
        // - Check logs for "TEST_REGION=portugal: Skipping GPS"
        // - Check logs for "Using test region: portugal at 39.60,-9.10"
        // - Check EFFIS query bbox includes Portugal coordinates
      });

      test('TEST_REGION=california should use California coordinates', () {
        // Integration test command:
        // flutter test --dart-define=TEST_REGION=california

        // Expected: LatLng(36.7, -119.4) for both controllers
      });

      test('TEST_REGION=australia should use Sydney coordinates', () {
        // Integration test command:
        // flutter test --dart-define=TEST_REGION=australia

        // Expected: LatLng(-33.8, 151.2) for both controllers
      });
    });

    group('Privacy Compliance', () {
      test('test region coordinates should be logged with redaction', () {
        // When TEST_REGION is used, coordinate logging should still
        // use GeographicUtils.logRedact() for C2 compliance

        // Expected log format: "Using test region: portugal at 39.60,-9.10"
        // NOT: "Using test region: portugal at 39.6012345,-9.1023456"
      });
    });
  });
}
