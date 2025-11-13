// ActiveFiresService interface for fetching fire incident data
// Supports both live EFFIS API and mock data based on MAP_LIVE_DATA flag
// Part of Phase 2: Service Layer Implementation (Task 7)

import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/active_fires_response.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';

/// Service interface for fetching active fire incidents within a geographic viewport
/// 
/// Provides abstraction over data sources (live EFFIS API vs mock data) based on
/// the MAP_LIVE_DATA environment variable configuration.
/// 
/// Constitutional Compliance:
/// - C1: Clean architecture with dartz Either for error handling
/// - C2: Privacy-compliant logging with coordinate redaction
/// - C3: Accessible error messages in user language
/// - C4: Consistent API patterns across all service implementations
/// - C5: Comprehensive test coverage with mock implementations
abstract class ActiveFiresService {
  /// Fetch active fire incidents within the specified viewport bounds
  /// 
  /// Returns filtered and sorted fire incidents based on:
  /// - Geographic bounds (southwest/northeast corners)
  /// - Optional confidence threshold (default: 50%)
  /// - Optional FRP minimum (default: 0.0 MW)
  /// - Sorted by detection time (newest first)
  /// 
  /// [bounds] - Geographic viewport for incident filtering
  /// [confidenceThreshold] - Minimum confidence percentage (0-100)
  /// [minFrp] - Minimum Fire Radiative Power in megawatts
  /// [deadline] - Request timeout duration (default: 10 seconds)
  /// 
  /// Returns:
  /// - Right(ActiveFiresResponse) on success with filtered incidents
  /// - Left(ApiError) on failure (network, parsing, timeout, etc.)
  /// 
  /// Example Usage:
  /// ```dart
  /// final viewport = LatLngBounds(
  ///   southwest: LatLng(55.0, -4.0),
  ///   northeast: LatLng(56.0, -3.0),
  /// );
  /// 
  /// final result = await service.getIncidentsForViewport(
  ///   bounds: viewport,
  ///   confidenceThreshold: 75.0,
  ///   minFrp: 100.0,
  /// );
  /// 
  /// result.fold(
  ///   (error) => print('Error: ${error.message}'),
  ///   (response) => print('Found ${response.incidents.length} incidents'),
  /// );
  /// ```
  Future<Either<ApiError, ActiveFiresResponse>> getIncidentsForViewport({
    required LatLngBounds bounds,
    double confidenceThreshold = 50.0,
    double minFrp = 0.0,
    Duration? deadline,
  });

  /// Get a single fire incident by ID
  /// 
  /// [incidentId] - Unique identifier for the fire incident
  /// [deadline] - Request timeout duration (default: 5 seconds)
  /// 
  /// Returns:
  /// - Right(FireIncident) on success
  /// - Left(ApiError) on failure (not found, network error, etc.)
  Future<Either<ApiError, FireIncident>> getIncidentById({
    required String incidentId,
    Duration? deadline,
  });

  /// Check service health and connectivity
  /// 
  /// Performs a lightweight connectivity test to verify the service
  /// can communicate with its data source.
  /// 
  /// Returns:
  /// - Right(true) if service is healthy
  /// - Left(ApiError) if service is unavailable
  Future<Either<ApiError, bool>> checkHealth();

  /// Get service metadata and capabilities
  /// 
  /// Returns information about the service implementation:
  /// - Data source type (live/mock)
  /// - Last update time
  /// - Geographic coverage
  /// - Rate limiting information
  ServiceMetadata get metadata;
}

/// Metadata describing service capabilities and status
class ServiceMetadata {
  /// Type of data source being used
  final DataSourceType sourceType;
  
  /// Human-readable description of the data source
  final String description;
  
  /// Last successful update timestamp (UTC)
  final DateTime? lastUpdate;
  
  /// Geographic bounds this service covers
  final LatLngBounds? coverage;
  
  /// Rate limiting information
  final RateLimitInfo? rateLimit;
  
  /// Whether the service supports real-time updates
  final bool supportsRealTime;
  
  /// Maximum number of incidents returned per request
  final int maxIncidentsPerRequest;

  const ServiceMetadata({
    required this.sourceType,
    required this.description,
    this.lastUpdate,
    this.coverage,
    this.rateLimit,
    this.supportsRealTime = false,
    this.maxIncidentsPerRequest = 1000,
  });

  @override
  String toString() => 'ServiceMetadata($sourceType: $description)';
}

/// Rate limiting configuration for API services
class RateLimitInfo {
  /// Maximum requests per time window
  final int maxRequests;
  
  /// Time window duration
  final Duration timeWindow;
  
  /// Current usage count
  final int currentUsage;
  
  /// When the current window resets
  final DateTime windowReset;

  const RateLimitInfo({
    required this.maxRequests,
    required this.timeWindow,
    required this.currentUsage,
    required this.windowReset,
  });

  /// Whether rate limit is currently exceeded
  bool get isExceeded => currentUsage >= maxRequests;
  
  /// Time until rate limit resets
  Duration get resetIn => windowReset.difference(DateTime.now());

  @override
  String toString() => 'RateLimit($currentUsage/$maxRequests, resets in ${resetIn.inMinutes}m)';
}

/// Types of data sources supported by ActiveFiresService
enum DataSourceType {
  /// Live data from EFFIS (European Forest Fire Information System)
  live('EFFIS Live API'),
  
  /// Mock data for testing and development
  mock('Mock Test Data'),
  
  /// Cached data from previous API calls
  cached('Cached Data');

  const DataSourceType(this.description);
  
  /// Human-readable description
  final String description;
}