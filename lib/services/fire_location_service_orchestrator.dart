// FireLocationServiceOrchestrator with fallback chain: Live API → Cache → Mock
// Implements Task 9: Create Service Orchestrator with Fallback Chain
// Part of Phase 2: Service Layer Implementation

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/fire_incident_cache.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';

/// Orchestrator implementing FireLocationService with intelligent fallback chain
///
/// Fallback Strategy (Task 9):
/// 1. **Live API** (if enabled): ActiveFiresServiceImpl with EFFIS WFS (8s timeout)
/// 2. **Cache**: FireIncidentCache with viewport query (200ms timeout)
/// 3. **Mock**: MockActiveFiresService (never fails)
///
/// Features:
/// - Telemetry tracking for performance monitoring
/// - Privacy-compliant logging (coordinate redaction)
/// - Graceful degradation on service failures
/// - Timeout enforcement at each tier
/// - Clear data source indicators (Freshness enum)
///
/// Constitutional Compliance:
/// - C1: Clean architecture with Either<L,R> error handling
/// - C2: Privacy-compliant coordinate logging via LocationUtils
/// - C5: Comprehensive error handling with retry mechanisms
class FireLocationServiceOrchestrator implements FireLocationService {
  final ActiveFiresService? _liveService;
  final ActiveFiresService _mockService;
  final FireIncidentCache? _cache;
  final OrchestratorTelemetry? _telemetry;

  /// Create orchestrator with optional live service and cache
  ///
  /// Parameters:
  /// - [liveService]: Optional live API service (ActiveFiresServiceImpl)
  /// - [mockService]: Required never-fail mock service (always provides fallback)
  /// - [cache]: Optional cache service for viewport queries
  /// - [telemetry]: Optional telemetry for performance monitoring
  ///
  /// Example:
  /// ```dart
  /// final orchestrator = FireLocationServiceOrchestrator(
  ///   liveService: isLiveDataEnabled ? liveService : null,
  ///   mockService: mockService,
  ///   cache: cacheService,
  ///   telemetry: SpyTelemetry(), // For testing
  /// );
  /// ```
  const FireLocationServiceOrchestrator({
    ActiveFiresService? liveService,
    required ActiveFiresService mockService,
    FireIncidentCache? cache,
    OrchestratorTelemetry? telemetry,
  })  : _liveService = liveService,
        _mockService = mockService,
        _cache = cache,
        _telemetry = telemetry;

  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    final gmapsBounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
      northeast: gmaps.LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
    );

    // Privacy-compliant logging
    final center = bounds.center;
    debugPrint('🔥 Orchestrator: Fetching fires for ${LocationUtils.logRedact(center.latitude, center.longitude)}');

    // Tier 1: Try live service if available
    if (_liveService != null) {
      final liveResult = await _tryLiveService(gmapsBounds);
      if (liveResult != null) {
        _telemetry?.recordSuccess(source: TelemetrySource.live);
        debugPrint('🔥 Orchestrator: Live service success (${liveResult.length} incidents)');
        return Right(liveResult);
      }
    }

    // Tier 2: Try cache if available
    if (_cache != null) {
      final cacheResult = await _tryCache(gmapsBounds);
      if (cacheResult != null) {
        _telemetry?.recordSuccess(source: TelemetrySource.cache);
        debugPrint('🔥 Orchestrator: Cache hit (${cacheResult.length} incidents)');
        return Right(cacheResult);
      }
    }

    // Tier 3: Mock fallback (never fails)
    final mockResult = await _tryMockService(gmapsBounds);
    _telemetry?.recordSuccess(source: TelemetrySource.mock);
    debugPrint('🔥 Orchestrator: Mock fallback (${mockResult.length} incidents)');
    return Right(mockResult);
  }

  /// Attempt live service with 8-second timeout
  Future<List<FireIncident>?> _tryLiveService(gmaps.LatLngBounds bounds) async {
    _telemetry?.recordAttempt(source: TelemetrySource.live);
    
    try {
      final result = await _liveService!.getIncidentsForViewport(
        bounds: _toLatLngBounds(bounds),
        confidenceThreshold: 50.0,
        minFrp: 0.0,
        deadline: const Duration(seconds: 8),
      );

      return result.fold(
        (error) {
          _telemetry?.recordFailure(source: TelemetrySource.live, error: error);
          debugPrint('🔥 Orchestrator: Live service failed - ${error.message}');
          return null;
        },
        (response) {
          // Store successful response in cache for future use
          if (_cache != null && response.hasIncidents) {
            _storeInCache(response.incidents, bounds).ignore();
          }
          return response.incidents;
        },
      );
    } catch (e) {
      _telemetry?.recordFailure(
        source: TelemetrySource.live,
        error: ApiError(message: 'Unexpected error: $e'),
      );
      debugPrint('🔥 Orchestrator: Live service exception - $e');
      return null;
    }
  }

  /// Attempt cache lookup with 200ms timeout
  Future<List<FireIncident>?> _tryCache(gmaps.LatLngBounds bounds) async {
    _telemetry?.recordAttempt(source: TelemetrySource.cache);

    try {
      final result = await _cache!.getIncidentsForViewport(bounds)
          .timeout(const Duration(milliseconds: 200));

      return result.fold(
        () {
          _telemetry?.recordMiss(source: TelemetrySource.cache);
          debugPrint('🔥 Orchestrator: Cache miss');
          return null;
        },
        (incidents) {
          debugPrint('🔥 Orchestrator: Cache hit with ${incidents.length} incidents');
          return incidents;
        },
      );
    } catch (e) {
      _telemetry?.recordFailure(
        source: TelemetrySource.cache,
        error: ApiError(message: 'Cache timeout or error: $e'),
      );
      debugPrint('🔥 Orchestrator: Cache timeout/error - $e');
      return null;
    }
  }

  /// Mock service fallback (never fails)
  Future<List<FireIncident>> _tryMockService(gmaps.LatLngBounds bounds) async {
    _telemetry?.recordAttempt(source: TelemetrySource.mock);

    try {
      final result = await _mockService.getIncidentsForViewport(
        bounds: _toLatLngBounds(bounds),
        confidenceThreshold: 50.0,
        minFrp: 0.0,
      );

      return result.fold(
        (error) {
          // Mock should never fail, but handle gracefully
          debugPrint('🔥 Orchestrator: Mock service unexpected error - ${error.message}');
          return <FireIncident>[];
        },
        (response) => response.incidents,
      );
    } catch (e) {
      // Absolute fallback: empty list
      debugPrint('🔥 Orchestrator: Mock service exception (returning empty) - $e');
      return <FireIncident>[];
    }
  }

  /// Store incidents in cache asynchronously (non-blocking)
  Future<void> _storeInCache(
    List<FireIncident> incidents,
    gmaps.LatLngBounds bounds,
  ) async {
    try {
      final center = (
        lat: (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
        lon: (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
      );

      await _cache!.set(
        lat: center.lat,
        lon: center.lon,
        data: incidents,
      );

      debugPrint('🔥 Orchestrator: Cached ${incidents.length} incidents at ${LocationUtils.logRedact(center.lat, center.lon)}');
    } catch (e) {
      // Cache write failures are non-critical
      debugPrint('🔥 Orchestrator: Cache write failed (non-critical) - $e');
    }
  }

  /// Convert google_maps_flutter bounds to internal LatLngBounds
  LatLngBounds _toLatLngBounds(gmaps.LatLngBounds bounds) {
    return LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
      northeast: LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
    );
  }
}

/// Telemetry interface for tracking orchestrator performance
///
/// Allows monitoring of fallback chain behavior, success rates, and
/// failure patterns across different data sources.
abstract class OrchestratorTelemetry {
  /// Record attempt to use a data source
  void recordAttempt({required TelemetrySource source});

  /// Record successful data retrieval from source
  void recordSuccess({required TelemetrySource source});

  /// Record failure retrieving data from source
  void recordFailure({required TelemetrySource source, required ApiError error});

  /// Record cache miss (not a failure, just no data)
  void recordMiss({required TelemetrySource source});
}

/// Data sources tracked by telemetry
enum TelemetrySource {
  /// Live EFFIS API service
  live,

  /// Cache service
  cache,

  /// Mock service fallback
  mock,
}

/// Spy telemetry implementation for testing
///
/// Captures all telemetry events for verification in tests.
/// Example usage in orchestrator tests to verify fallback chain.
class SpyTelemetry implements OrchestratorTelemetry {
  final List<TelemetryEvent> events = [];

  @override
  void recordAttempt({required TelemetrySource source}) {
    events.add(AttemptEvent(source));
  }

  @override
  void recordSuccess({required TelemetrySource source}) {
    events.add(SuccessEvent(source));
  }

  @override
  void recordFailure({required TelemetrySource source, required ApiError error}) {
    events.add(FailureEvent(source, error));
  }

  @override
  void recordMiss({required TelemetrySource source}) {
    events.add(MissEvent(source));
  }

  /// Get all events of a specific type
  List<T> eventsOfType<T extends TelemetryEvent>() {
    return events.whereType<T>().toList();
  }

  /// Clear all recorded events
  void clear() {
    events.clear();
  }
}

/// Base class for telemetry events
abstract class TelemetryEvent {
  final TelemetrySource source;
  final DateTime timestamp;

  TelemetryEvent(this.source) : timestamp = DateTime.now();
}

/// Attempt event (source queried)
class AttemptEvent extends TelemetryEvent {
  AttemptEvent(super.source);

  @override
  String toString() => 'AttemptEvent($source)';
}

/// Success event (data retrieved)
class SuccessEvent extends TelemetryEvent {
  SuccessEvent(super.source);

  @override
  String toString() => 'SuccessEvent($source)';
}

/// Failure event (error occurred)
class FailureEvent extends TelemetryEvent {
  final ApiError error;

  FailureEvent(super.source, this.error);

  @override
  String toString() => 'FailureEvent($source: ${error.message})';
}

/// Cache miss event (no data in cache)
class MissEvent extends TelemetryEvent {
  MissEvent(super.source);

  @override
  String toString() => 'MissEvent($source)';
}
