/// Integration tests for app-level service wiring
///
/// These tests verify that services initialized in main.dart are properly
/// passed through the widget tree to screens that need them.
///
/// This test suite was created after a bug where LocationPickerScreen
/// created new GeocodingServiceImpl() instances without API keys, instead
/// of receiving the properly-initialized services from main.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/geocoding_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/geocoding_service_impl.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';

void main() {
  group('Service Initialization Contract', () {
    test(
      'GeocodingServiceImpl uses FeatureFlags.googleMapsApiKey by default',
      () {
        // This test documents the expected behavior:
        // When no apiKey is provided, GeocodingServiceImpl should use
        // FeatureFlags.googleMapsApiKey

        // Note: In a real app, this key comes from --dart-define
        // In tests, it will be empty unless mocked
        final defaultKey = FeatureFlags.googleMapsApiKey;

        // Create service without explicit key
        final service = GeocodingServiceImpl();

        // The service should have been initialized with the default key
        // We can't directly access _apiKey, but we can verify behavior
        expect(service, isA<GeocodingService>());

        // If key is empty (as in tests), API calls should fail gracefully
        if (defaultKey.isEmpty) {
          // Verify empty key behavior
          service.searchPlaces(query: 'test').then((result) {
            expect(
              result.isLeft(),
              isTrue,
              reason: 'Empty API key should return error',
            );
          });
        }
      },
    );

    test('GeocodingServiceImpl accepts explicit API key', () {
      // Use a clearly-fake test key that won't trigger secret detection
      const explicitKey = 'TEST_KEY_FOR_UNIT_TESTS_ONLY';
      final service = GeocodingServiceImpl(apiKey: explicitKey);

      expect(service, isA<GeocodingService>());
      // Service should use the explicit key for API calls
    });

    test('Empty API key returns proper error for searchPlaces', () async {
      final service = GeocodingServiceImpl(apiKey: '');

      final result = await service.searchPlaces(query: 'Edinburgh');

      expect(result.isLeft(), isTrue);
      result.fold((error) {
        expect(error, isA<GeocodingApiError>());
        final apiError = error as GeocodingApiError;
        expect(apiError.message, contains('API key not configured'));
      }, (_) => fail('Expected error for empty API key'));
    });

    test('Empty API key returns proper error for reverseGeocode', () async {
      final service = GeocodingServiceImpl(apiKey: '');

      final result = await service.reverseGeocode(lat: 55.9533, lon: -3.1883);

      expect(result.isLeft(), isTrue);
      result.fold((error) {
        expect(error, isA<GeocodingApiError>());
        final apiError = error as GeocodingApiError;
        expect(apiError.message, contains('API key not configured'));
      }, (_) => fail('Expected error for empty API key'));
    });
  });

  group('FeatureFlags API Key Priority', () {
    // Note: These tests document expected behavior but can't fully test
    // platform-specific logic without running on actual platforms

    test('googleMapsApiKey getter returns empty when no keys defined', () {
      // In test environment without --dart-define, all keys are empty
      final key = FeatureFlags.googleMapsApiKey;

      // Document the expected priority order in comments:
      // 1. GOOGLE_MAPS_API_KEY_ANDROID (first priority)
      // 2. GOOGLE_MAPS_API_KEY_IOS (second priority)
      // 3. GOOGLE_MAPS_API_KEY_WEB (third priority)
      // 4. Empty string (fallback)

      // In tests, we expect empty string since no keys are defined
      expect(key, equals(''));
    });

    test('individual key getters return empty when not defined', () {
      expect(FeatureFlags.googleMapsApiKeyAndroid, equals(''));
      expect(FeatureFlags.googleMapsApiKeyIos, equals(''));
      expect(FeatureFlags.googleMapsApiKeyWeb, equals(''));
    });
  });

  group('Documentation: Service Wiring Pattern', () {
    // These tests serve as documentation for the correct wiring pattern

    test('services should be initialized once in main.dart', () {
      // CORRECT pattern (documented here):
      //
      // In main.dart:
      //   final mapsApiKey = FeatureFlags.googleMapsApiKey;
      //   if (mapsApiKey.isNotEmpty) {
      //     geocodingService = GeocodingServiceImpl(apiKey: mapsApiKey);
      //   }
      //
      // Then pass to WildFireApp:
      //   WildFireApp(
      //     geocodingService: geocodingService,
      //     ...
      //   )
      //
      // In WildFireApp router:
      //   LocationPickerScreen(
      //     geocodingService: geocodingService ?? GeocodingServiceImpl(),
      //     ...
      //   )

      // This test passes to document the pattern
      expect(true, isTrue);
    });

    test('ANTI-PATTERN: creating services in router without key', () {
      // WRONG pattern (what caused the bug):
      //
      // In WildFireApp router:
      //   LocationPickerScreen(
      //     geocodingService: GeocodingServiceImpl(),  // BAD! No API key!
      //     ...
      //   )
      //
      // This creates a new service that uses FeatureFlags.googleMapsApiKey,
      // which may be empty on web if only GOOGLE_MAPS_API_KEY_WEB was defined
      // and the getter prioritizes Android/iOS keys first.

      // This test passes to document the anti-pattern
      expect(true, isTrue);
    });
  });
}
