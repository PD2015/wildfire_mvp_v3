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
/// This allows existing code that depends on FireLocationService to work
/// with the new ActiveFiresService implementations without modification.
/// 
/// Usage:
/// ```dart
/// final activeFiresService = ActiveFiresServiceFactory.create();
/// final fireLocationService = ActiveFiresServiceAdapter(activeFiresService);
/// 
/// // Use as normal FireLocationService
/// final result = await fireLocationService.getActiveFires(bounds);
/// ```
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