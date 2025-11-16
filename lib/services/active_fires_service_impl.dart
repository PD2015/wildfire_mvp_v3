// Live EFFIS API implementation of ActiveFiresService
// Fetches real-time fire incident data from EFFIS WFS service
// Part of Phase 2: Service Layer Implementation (Task 6)

import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:http/http.dart' as http;
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/active_fires_response.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/effis_service.dart';
import 'package:wildfire_mvp_v3/services/effis_service_impl.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/services/utils/geo_utils.dart';

/// Live EFFIS API implementation providing real-time fire incident data
///
/// Fetches active fires from EFFIS (European Forest Fire Information System)
/// WFS service and converts them to FireIncident objects for application use.
///
/// Features:
/// - Real-time fire data from EFFIS WFS burnt_areas_current_year layer
/// - Geographic filtering by viewport bounds
/// - Confidence and FRP threshold filtering
/// - 8-second timeout for API requests
/// - Comprehensive error handling with retry capability
///
/// Constitutional Compliance:
/// - C1: Clean architecture with dependency injection
/// - C2: Privacy-compliant logging with coordinate redaction
/// - C5: Resilient error handling with proper timeouts
///
/// Usage:
/// ```dart
/// final httpClient = http.Client();
/// final service = ActiveFiresServiceImpl(httpClient: httpClient);
///
/// final result = await service.getIncidentsForViewport(
///   bounds: viewportBounds,
///   confidenceThreshold: 75.0,
///   minFrp: 5.0,
/// );
///
/// result.fold(
///   (error) => print('Error: ${error.message}'),
///   (response) => print('Found ${response.incidents.length} fires'),
/// );
/// ```
class ActiveFiresServiceImpl implements ActiveFiresService {
  final EffisService _effisService;

  /// Create service with injected HTTP client
  ///
  /// [httpClient] - HTTP client for network requests (enables testing)
  ActiveFiresServiceImpl({required http.Client httpClient})
      : _effisService = EffisServiceImpl(httpClient: httpClient);

  /// Create service with injected EFFIS service (for testing)
  ActiveFiresServiceImpl.withEffisService(EffisService effisService)
      : _effisService = effisService;

  @override
  ServiceMetadata get metadata => ServiceMetadata(
        sourceType: DataSourceType.live,
        description:
            'Live EFFIS fire incident data from European Forest Fire Information System',
        lastUpdate: DateTime.now(),
        coverage: const LatLngBounds(
          southwest: LatLng(-60.0, -180.0), // Global coverage
          northeast: LatLng(85.0, 180.0),
        ),
        supportsRealTime: true,
        maxIncidentsPerRequest: 1000,
      );

  @override
  Future<Either<ApiError, ActiveFiresResponse>> getIncidentsForViewport({
    required LatLngBounds bounds,
    double confidenceThreshold = 50.0,
    double minFrp = 0.0,
    Duration? deadline,
  }) async {
    final timeout = deadline ?? const Duration(seconds: 8);

    developer.log(
      'ActiveFiresServiceImpl: Fetching EFFIS fires for bounds: '
      'SW(${GeographicUtils.logRedact(bounds.southwest.latitude, bounds.southwest.longitude)}) '
      'NE(${GeographicUtils.logRedact(bounds.northeast.latitude, bounds.northeast.longitude)})',
      name: 'ActiveFiresServiceImpl',
    );

    try {
      // Call EFFIS service to get raw fire data
      final effisResult = await _effisService.getActiveFires(
        bounds,
        timeout: timeout,
      );

      return effisResult.fold(
        (error) {
          developer.log(
            'ActiveFiresServiceImpl: EFFIS API error: ${error.message}',
            name: 'ActiveFiresServiceImpl',
            level: 900,
          );
          return Left(error);
        },
        (effisFires) {
          // Convert EffisFire objects to FireIncident objects
          final incidents = effisFires
              .map((effisFire) => effisFire.toFireIncident())
              .toList();

          developer.log(
            'ActiveFiresServiceImpl: Converted ${incidents.length} EFFIS fires to FireIncidents',
            name: 'ActiveFiresServiceImpl',
          );

          // Apply confidence and FRP filtering
          final filteredIncidents = incidents.where((incident) {
            // Check confidence threshold
            if (incident.confidence != null &&
                incident.confidence! < confidenceThreshold) {
              return false;
            }

            // Check FRP threshold
            if (incident.frp != null && incident.frp! < minFrp) {
              return false;
            }

            return true;
          }).toList();

          // Sort by detection time (newest first)
          filteredIncidents.sort((a, b) {
            return b.detectedAt.compareTo(a.detectedAt); // Descending order
          });

          developer.log(
            'ActiveFiresServiceImpl: Filtered to ${filteredIncidents.length} incidents '
            '(confidence≥$confidenceThreshold%, FRP≥${minFrp}MW)',
            name: 'ActiveFiresServiceImpl',
          );

          // Convert our LatLngBounds to google_maps_flutter LatLngBounds
          final gmapsBounds = gmaps.LatLngBounds(
            southwest: gmaps.LatLng(
              bounds.southwest.latitude,
              bounds.southwest.longitude,
            ),
            northeast: gmaps.LatLng(
              bounds.northeast.latitude,
              bounds.northeast.longitude,
            ),
          );

          // Create response
          final response = ActiveFiresResponse(
            incidents: filteredIncidents,
            queriedBounds: gmapsBounds,
            responseTimeMs: timeout.inMilliseconds,
            dataSource: DataSource.effis,
            totalCount: filteredIncidents.length,
            timestamp: DateTime.now().toUtc(),
          );

          return Right(response);
        },
      );
    } catch (e) {
      developer.log(
        'ActiveFiresServiceImpl: Unexpected error: $e',
        name: 'ActiveFiresServiceImpl',
        level: 1000,
      );
      return Left(ApiError(
        message: 'Unexpected error fetching fire incidents: $e',
      ));
    }
  }

  @override
  Future<Either<ApiError, FireIncident>> getIncidentById({
    required String incidentId,
    Duration? deadline,
  }) async {
    // EFFIS WFS doesn't support direct ID lookups, would need to fetch all
    // and filter. For now, return not implemented error.
    developer.log(
      'ActiveFiresServiceImpl: getIncidentById not implemented for EFFIS service',
      name: 'ActiveFiresServiceImpl',
      level: 900,
    );

    return Left(ApiError(
      message: 'Direct incident lookup not supported by EFFIS WFS service',
    ));
  }

  @override
  Future<Either<ApiError, bool>> checkHealth() async {
    try {
      // Perform a minimal query to test service availability
      // Use small bounds in Europe where EFFIS has good coverage
      const testBounds = LatLngBounds(
        southwest: LatLng(40.0, -10.0), // Western Europe
        northeast: LatLng(45.0, -5.0),
      );

      final result = await _effisService.getActiveFires(
        testBounds,
        timeout: const Duration(seconds: 5),
      );

      return result.fold(
        (error) {
          developer.log(
            'ActiveFiresServiceImpl: Health check failed: ${error.message}',
            name: 'ActiveFiresServiceImpl',
            level: 900,
          );
          return const Right(false); // Service unhealthy but didn't throw
        },
        (_) {
          developer.log(
            'ActiveFiresServiceImpl: Health check passed',
            name: 'ActiveFiresServiceImpl',
          );
          return const Right(true); // Service healthy
        },
      );
    } catch (e) {
      developer.log(
        'ActiveFiresServiceImpl: Health check exception: $e',
        name: 'ActiveFiresServiceImpl',
        level: 1000,
      );
      return Left(ApiError(
        message: 'Health check failed: $e',
      ));
    }
  }
}
