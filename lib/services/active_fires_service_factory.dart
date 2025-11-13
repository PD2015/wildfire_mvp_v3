// ActiveFiresService factory for creating appropriate implementation based on MAP_LIVE_DATA
// Provides dependency injection and service selection based on environment flags
// Part of Phase 2: Service Layer Implementation (Task 8)

import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/mock_active_fires_service.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';

/// Factory for creating ActiveFiresService implementations
/// 
/// Selects appropriate implementation based on MAP_LIVE_DATA environment flag:
/// - MAP_LIVE_DATA=true: Live EFFIS API service (when implemented)
/// - MAP_LIVE_DATA=false: Mock service for development/testing
class ActiveFiresServiceFactory {
  /// Create appropriate ActiveFiresService based on environment configuration
  /// 
  /// Returns:
  /// - MockActiveFiresService when MAP_LIVE_DATA=false (default)
  /// - LiveActiveFiresService when MAP_LIVE_DATA=true (future implementation)
  /// 
  /// Example usage:
  /// ```dart
  /// final activeFiresService = ActiveFiresServiceFactory.create();
  /// final result = await activeFiresService.getIncidentsForViewport(
  ///   bounds: viewportBounds,
  /// );
  /// ```
  static ActiveFiresService create() {
    if (FeatureFlags.mapLiveData) {
      // TODO: Implement LiveActiveFiresService for EFFIS API integration
      // For now, fall back to mock service even when live data is requested
      return MockActiveFiresService();
    } else {
      return MockActiveFiresService();
    }
  }

  /// Create mock service explicitly (for testing)
  static ActiveFiresService createMock() => MockActiveFiresService();

  /// Check if live data is enabled
  static bool get isLiveDataEnabled => FeatureFlags.mapLiveData;

  /// Get current service type description
  static String get currentServiceType => 
      isLiveDataEnabled ? 'Live EFFIS Data (Mock Fallback)' : 'Mock Test Data';
}