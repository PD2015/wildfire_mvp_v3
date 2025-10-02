/// FireRiskService implementation with fallback orchestration
///
/// Implements the FireRiskService interface with a robust fallback chain:
/// EFFIS → SEPA (Scotland only) → Cache → Mock
///
/// Features:
/// - Never-fail guarantee with mock fallback
/// - Per-service timeout enforcement within global deadline
/// - Privacy-preserving logging (C2 compliance)
/// - Scotland-aware routing for SEPA service
/// - Comprehensive telemetry hooks
library fire_risk_service_impl;

import 'dart:async';
import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/risk_level.dart';
import 'contracts/service_contracts.dart';
import 'fire_risk_service.dart';
import 'models/fire_risk.dart';
import 'mock_service.dart';
import 'telemetry/orchestrator_telemetry.dart';
import 'utils/geo_utils.dart';

/// Implementation of FireRiskService with fallback orchestration
///
/// Orchestrates multiple fire risk data sources with intelligent fallback:
/// 1. EFFIS (European Forest Fire Information System) - Primary global source
/// 2. SEPA (Scottish Environment Protection Agency) - Scotland-specific fallback
/// 3. Cache - Previously successful data
/// 4. Mock - Guaranteed fallback that never fails
///
/// **Timing budgets within 8-second default deadline**:
/// - EFFIS: 3 seconds maximum
/// - SEPA: 2 seconds maximum (Scotland only)
/// - Cache: 1 second maximum
/// - Mock: <100ms guaranteed
///
/// **Geographic routing**:
/// - Scotland bounds: 54.6-60.9°N, -9.0-1.0°E (includes all Scottish territory)
/// - SEPA attempted only for coordinates within Scotland boundaries
/// - Uses `GeographicUtils.isInScotland()` for routing decisions
///
/// **Error handling patterns**:
/// ```dart
/// final result = await service.getCurrent(lat: lat, lon: lon);
/// result.fold(
///   (error) => {
///     // Only validation errors (NaN, out-of-range coordinates)
///     // All service failures trigger fallback, never return Left()
///   },
///   (fireRisk) => {
///     // Always succeeds with one of: effis, sepa, cache, mock
///     // Check fireRisk.source and fireRisk.freshness for data quality
///   },
/// );
/// ```
///
/// **Usage examples**:
/// ```dart
/// // Basic usage with defaults
/// final service = FireRiskServiceImpl(
///   effisService: effisService,  // A1 EffisService implementation
///   mockService: MockService.defaultStrategy(),
/// );
///
/// // Edinburgh coordinates (Scotland - will try SEPA if EFFIS fails)
/// final edinburgh = await service.getCurrent(lat: 55.9533, lon: -3.1883);
///
/// // New York coordinates (non-Scotland - skips SEPA)
/// final newYork = await service.getCurrent(lat: 40.7128, lon: -74.0060);
///
/// // Custom deadline (shorter timeout)
/// final urgent = await service.getCurrent(
///   lat: 55.9533,
///   lon: -3.1883,
///   deadline: Duration(seconds: 5),
/// );
///
/// // Full configuration with all services
/// final fullService = FireRiskServiceImpl(
///   effisService: effisService,
///   sepaService: sepaService,        // Optional
///   cacheService: cacheService,      // Optional
///   mockService: MockService.deterministicStrategy(), // Required
///   telemetry: SpyTelemetry(),       // Optional, NoOpTelemetry() default
/// );
/// ```
///
/// **Telemetry integration**:
/// ```dart
/// final telemetry = SpyTelemetry();
/// final service = FireRiskServiceImpl(..., telemetry: telemetry);
///
/// await service.getCurrent(lat: lat, lon: lon);
///
/// // Inspect fallback sequence
/// final attempts = telemetry.eventsOfType<AttemptStartEvent>();
/// final fallbacks = telemetry.eventsOfType<FallbackDepthEvent>();
/// // Verify: attempts = [effis, sepa?, cache?, mock]
/// // Verify: fallbacks track depth progression: 0 → 1 → 2 → 3
/// ```
///
/// **A1 Integration points**:
/// - Requires A1's `EffisService` implementation for primary data source
/// - Reuses A1's `EffisFwiResult` and `ApiError` types for consistency
/// - Converts EFFIS FWI data to normalized `FireRisk` objects
/// - Preserves A1's coordinate validation and error handling patterns
class FireRiskServiceImpl implements FireRiskService {
  final EffisService _effisService;
  final SepaService? _sepaService;
  final CacheService? _cacheService;
  final MockService _mockService;
  final OrchestratorTelemetry _telemetry;
  final Duration _defaultDeadline;

  /// Per-service timeout budgets
  static const Duration _effisTimeout = Duration(seconds: 3);
  static const Duration _sepaTimeout = Duration(seconds: 2);
  static const Duration _cacheTimeout = Duration(seconds: 1);
  static const Duration _mockTimeout = Duration(milliseconds: 100);

  /// Creates FireRiskService implementation with dependency injection
  ///
  /// Required dependencies:
  /// - [effisService]: Primary global fire weather data source
  /// - [mockService]: Guaranteed fallback service
  ///
  /// Optional dependencies:
  /// - [sepaService]: Scotland-specific data source
  /// - [cacheService]: Caching layer for previous results
  /// - [telemetry]: Observability hooks for monitoring
  /// - [defaultDeadline]: Global timeout (default 8 seconds)
  FireRiskServiceImpl({
    required EffisService effisService,
    required MockService mockService,
    SepaService? sepaService,
    CacheService? cacheService,
    OrchestratorTelemetry? telemetry,
    Duration defaultDeadline = const Duration(seconds: 8),
  })  : _effisService = effisService,
        _sepaService = sepaService,
        _cacheService = cacheService,
        _mockService = mockService,
        _telemetry = telemetry ?? const NoOpTelemetry(),
        _defaultDeadline = defaultDeadline;

  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  }) async {
    final effectiveDeadline = deadline ?? _defaultDeadline;
    final stopwatch = Stopwatch()..start();

    // Validate coordinates first
    final coordinateValidation = _validateCoordinates(lat, lon);
    if (coordinateValidation != null) {
      return Left(coordinateValidation);
    }

    var fallbackDepth = 0;

    try {
      // Attempt 1: EFFIS (always first, global coverage)
      _telemetry.onFallbackDepth(fallbackDepth);
      final effisResult =
          await _attemptEffis(lat, lon, stopwatch, effectiveDeadline);
      if (effisResult != null) {
        _telemetry.onComplete(TelemetrySource.effis, stopwatch.elapsed);
        return Right(effisResult);
      }
      fallbackDepth++;

      // Attempt 2: SEPA (only for Scotland coordinates)
      if (_sepaService != null && GeographicUtils.isInScotland(lat, lon)) {
        _telemetry.onFallbackDepth(fallbackDepth);
        final sepaResult =
            await _attemptSepa(lat, lon, stopwatch, effectiveDeadline);
        if (sepaResult != null) {
          _telemetry.onComplete(TelemetrySource.sepa, stopwatch.elapsed);
          return Right(sepaResult);
        }
        fallbackDepth++;
      }

      // Attempt 3: Cache (if available and time remaining)
      if (_cacheService != null) {
        _telemetry.onFallbackDepth(fallbackDepth);
        final cacheResult =
            await _attemptCache(lat, lon, stopwatch, effectiveDeadline);
        if (cacheResult != null) {
          _telemetry.onComplete(TelemetrySource.cache, stopwatch.elapsed);
          return Right(cacheResult);
        }
        fallbackDepth++;
      }

      // Final fallback: Mock (guaranteed to succeed)
      _telemetry.onFallbackDepth(fallbackDepth);
      final mockResult = await _attemptMock(lat, lon);
      _telemetry.onComplete(TelemetrySource.mock, stopwatch.elapsed);
      return Right(mockResult);
    } catch (e) {
      // Absolute fallback - should never happen due to mock guarantee
      final mockResult = await _mockService.getCurrent(lat: lat, lon: lon);
      _telemetry.onComplete(TelemetrySource.mock, stopwatch.elapsed);
      return Right(mockResult);
    }
  }

  /// Validates coordinate ranges and finite values
  ApiError? _validateCoordinates(double lat, double lon) {
    if (!lat.isFinite || !lon.isFinite) {
      return ApiError(message: 'Coordinates must be finite numbers');
    }

    if (lat < -90.0 || lat > 90.0) {
      return ApiError(message: 'Latitude must be between -90 and 90 degrees');
    }

    if (lon < -180.0 || lon > 180.0) {
      return ApiError(
          message: 'Longitude must be between -180 and 180 degrees');
    }

    return null;
  }

  /// Attempts to get data from EFFIS service with timeout
  Future<FireRisk?> _attemptEffis(
      double lat, double lon, Stopwatch stopwatch, Duration deadline) async {
    if (stopwatch.elapsed >= deadline) return null;

    final remainingTime = deadline - stopwatch.elapsed;
    final timeoutDuration =
        remainingTime < _effisTimeout ? remainingTime : _effisTimeout;

    _telemetry.onAttemptStart(TelemetrySource.effis);
    final attemptStopwatch = Stopwatch()..start();

    try {
      final result = await _effisService
          .getFwi(lat: lat, lon: lon)
          .timeout(timeoutDuration);

      _telemetry.onAttemptEnd(
          TelemetrySource.effis, attemptStopwatch.elapsed, result.isRight());

      return result.fold(
        (error) => null,
        (effisFwi) => FireRisk.fromEffis(
          level: effisFwi.riskLevel,
          fwi: effisFwi.fwi,
          observedAt: effisFwi.datetime,
        ),
      );
    } catch (e) {
      _telemetry.onAttemptEnd(
          TelemetrySource.effis, attemptStopwatch.elapsed, false);
      return null;
    }
  }

  /// Attempts to get data from SEPA service with timeout
  Future<FireRisk?> _attemptSepa(
      double lat, double lon, Stopwatch stopwatch, Duration deadline) async {
    if (stopwatch.elapsed >= deadline) return null;

    final remainingTime = deadline - stopwatch.elapsed;
    final timeoutDuration =
        remainingTime < _sepaTimeout ? remainingTime : _sepaTimeout;

    _telemetry.onAttemptStart(TelemetrySource.sepa);
    final attemptStopwatch = Stopwatch()..start();

    try {
      final result = await _sepaService!
          .getCurrent(lat: lat, lon: lon)
          .timeout(timeoutDuration);

      _telemetry.onAttemptEnd(
          TelemetrySource.sepa, attemptStopwatch.elapsed, result.isRight());

      return result.fold(
        (error) => null,
        (fireRisk) => fireRisk,
      );
    } catch (e) {
      _telemetry.onAttemptEnd(
          TelemetrySource.sepa, attemptStopwatch.elapsed, false);
      return null;
    }
  }

  /// Attempts to get data from cache with timeout
  Future<FireRisk?> _attemptCache(
      double lat, double lon, Stopwatch stopwatch, Duration deadline) async {
    if (stopwatch.elapsed >= deadline) return null;

    final remainingTime = deadline - stopwatch.elapsed;
    final timeoutDuration =
        remainingTime < _cacheTimeout ? remainingTime : _cacheTimeout;

    _telemetry.onAttemptStart(TelemetrySource.cache);
    final attemptStopwatch = Stopwatch()..start();

    try {
      final cacheKey = GeographicUtils.geohash(lat, lon);
      final result =
          await _cacheService!.get(key: cacheKey).timeout(timeoutDuration);

      final hasValue = result.isSome();
      _telemetry.onAttemptEnd(
          TelemetrySource.cache, attemptStopwatch.elapsed, hasValue);

      return result.fold(
        () => null,
        (fireRisk) => fireRisk,
      );
    } catch (e) {
      _telemetry.onAttemptEnd(
          TelemetrySource.cache, attemptStopwatch.elapsed, false);
      return null;
    }
  }

  /// Gets mock data (guaranteed to succeed within 100ms)
  Future<FireRisk> _attemptMock(double lat, double lon) async {
    _telemetry.onAttemptStart(TelemetrySource.mock);
    final attemptStopwatch = Stopwatch()..start();

    try {
      final result = await _mockService
          .getCurrent(lat: lat, lon: lon)
          .timeout(_mockTimeout);

      _telemetry.onAttemptEnd(
          TelemetrySource.mock, attemptStopwatch.elapsed, true);
      return result;
    } catch (e) {
      // Absolute fallback - create mock data directly if service fails
      _telemetry.onAttemptEnd(
          TelemetrySource.mock, attemptStopwatch.elapsed, false);
      return FireRisk.fromMock(
        level: RiskLevel.moderate,
        observedAt: DateTime.now().toUtc(),
      );
    }
  }
}
