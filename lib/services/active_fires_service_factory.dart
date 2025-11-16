// ActiveFiresService factory for creating appropriate implementation based on MAP_LIVE_DATA
// Provides dependency injection and service selection based on environment flags
// Part of Phase 2: Service Layer Implementation (Task 8)

import 'package:http/http.dart' as http;
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service_impl.dart';
import 'package:wildfire_mvp_v3/services/mock_active_fires_service.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';

/// Factory for creating ActiveFiresService implementations
///
/// Selects appropriate implementation based on MAP_LIVE_DATA environment flag:
/// - MAP_LIVE_DATA=true: Live EFFIS API service
/// - MAP_LIVE_DATA=false: Mock service for development/testing
class ActiveFiresServiceFactory {
  /// Create appropriate ActiveFiresService based on environment configuration
  ///
  /// [httpClient] - Optional HTTP client for live service (required if MAP_LIVE_DATA=true)
  ///
  /// Returns:
  /// - MockActiveFiresService when MAP_LIVE_DATA=false (default)
  /// - ActiveFiresServiceImpl when MAP_LIVE_DATA=true
  ///
  /// Example usage:
  /// ```dart
  /// final httpClient = http.Client();
  /// final activeFiresService = ActiveFiresServiceFactory.create(httpClient: httpClient);
  /// final result = await activeFiresService.getIncidentsForViewport(
  ///   bounds: viewportBounds,
  /// );
  /// ```
  static ActiveFiresService create({http.Client? httpClient}) {
    if (FeatureFlags.mapLiveData) {
      // Use live EFFIS API service
      if (httpClient == null) {
        throw ArgumentError(
          'httpClient is required when MAP_LIVE_DATA=true for live EFFIS API service',
        );
      }
      return ActiveFiresServiceImpl(httpClient: httpClient);
    } else {
      // Use mock service for development/testing
      return MockActiveFiresService();
    }
  }

  /// Create mock service explicitly (for testing)
  static ActiveFiresService createMock() => MockActiveFiresService();

  /// Create live service explicitly (for testing)
  static ActiveFiresService createLive({required http.Client httpClient}) =>
      ActiveFiresServiceImpl(httpClient: httpClient);

  /// Check if live data is enabled
  static bool get isLiveDataEnabled => FeatureFlags.mapLiveData;

  /// Get current service type description
  static String get currentServiceType =>
      isLiveDataEnabled ? 'Live EFFIS Data' : 'Mock Test Data';
}
