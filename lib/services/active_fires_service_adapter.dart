// Adapter to bridge ActiveFiresService to FireLocationService interface
// Allows gradual migration from FireLocationService to ActiveFiresService
// Part of Phase 2: Service Layer Implementation (Task 8)

import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';

/// Adapter that implements FireLocationService using ActiveFiresService
/// 
/// **DEPRECATED**: This adapter is no longer needed. Use `FireLocationServiceOrchestrator`
/// directly in your composition root instead. The orchestrator provides the same
/// functionality with better error handling, caching, and telemetry support.
/// 
/// **Migration Guide**:
/// ```dart
/// // Old approach (deprecated):
/// final activeFiresService = ActiveFiresServiceFactory.create();
/// final fireLocationService = ActiveFiresServiceAdapter(activeFiresService);
/// 
/// // New approach (recommended):
/// final prefs = await SharedPreferences.getInstance();
/// final cache = FireIncidentCacheImpl(prefs);
/// final liveService = const String.fromEnvironment('MAP_LIVE_DATA') == 'true'
///     ? ActiveFiresServiceImpl(httpClient: httpClient)
///     : null;
/// final mockService = MockActiveFiresService();
/// final orchestrator = FireLocationServiceOrchestrator(
///   liveService: liveService,
///   cacheService: cache,
///   mockService: mockService,
/// );
/// ```
/// 
/// **Why migrate?**
/// - 3-tier fallback chain (Live → Cache → Mock) with timeout enforcement
/// - Automatic cache population for offline support
/// - Telemetry events for monitoring service health
/// - Better error messages and debugging information
/// 
/// **See**: `lib/services/fire_location_service_orchestrator.dart` for implementation
/// **See**: `lib/main.dart` for example composition root setup
@Deprecated('Use FireLocationServiceOrchestrator instead. '
    'This adapter will be removed in a future version. '
    'See class documentation for migration guide.')
class ActiveFiresServiceAdapter implements FireLocationService {
  final ActiveFiresService _activeFiresService;

  /// Create adapter wrapping an ActiveFiresService
  const ActiveFiresServiceAdapter(this._activeFiresService);

  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    try {
      final result = await _activeFiresService.getIncidentsForViewport(
        bounds: bounds,
        confidenceThreshold: 50.0, // Default confidence threshold
        minFrp: 0.0, // No minimum FRP filter
        deadline: const Duration(seconds: 8), // Match FireLocationService timeout
      );

      return result.fold(
        (error) => Left(error),
        (response) => Right(response.incidents),
      );
    } catch (e) {
      return Left(ApiError(
        message: 'Service adapter error: $e',
      ));
    }
  }

  /// Access to underlying ActiveFiresService for advanced features
  ActiveFiresService get activeFiresService => _activeFiresService;

  /// Get service metadata
  ServiceMetadata get metadata => _activeFiresService.metadata;

  /// Check service health
  Future<Either<ApiError, bool>> checkHealth() => 
      _activeFiresService.checkHealth();
}