import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import 'models/fire_risk.dart';

/// Service interface for fire risk assessment with fallback orchestration
///
/// Implements a robust fallback chain to ensure fire risk data is always
/// available, even when primary services are unavailable:
///
/// 1. EFFIS (primary) - Global fire weather data
/// 2. SEPA (secondary) - Scotland-specific data when coordinates are in Scotland
/// 3. Cache (tertiary) - Previously successful results ≤6 hours old
/// 4. Mock (final) - Guaranteed fallback that never fails
///
/// The service includes timing budgets to prevent UI blocking:
/// - Total deadline: 8 seconds (configurable)
/// - Per-service timeouts: EFFIS 3s, SEPA 2s, Cache 1s, Mock <100ms
///
/// Never-fail guarantee: Always returns Either<ApiError, FireRisk> where
/// Left(ApiError) only occurs for input validation errors (invalid coordinates).
/// All other failures trigger the fallback chain, ultimately succeeding with
/// mock data if all upstream services are unavailable.
abstract class FireRiskService {
  /// Gets current fire risk for specified coordinates using fallback orchestration
  ///
  /// Attempts data sources in priority order until successful or mock fallback:
  /// 1. EFFIS service (always attempted first)
  /// 2. SEPA service (only for Scotland coordinates: 54.6°N-60.9°N, 9.0°W-1.0°E)
  /// 3. Cache service (only if previous services failed and fresh data available)
  /// 4. Mock service (guaranteed success, never fails)
  ///
  /// [lat] Latitude in decimal degrees (-90.0 to 90.0)
  /// [lon] Longitude in decimal degrees (-180.0 to 180.0)
  /// [deadline] Maximum time budget for all fallback attempts (default: 8 seconds)
  ///
  /// Returns:
  /// - Left(ApiError): Only for input validation errors (NaN, ±Infinity, out of range)
  /// - Right(FireRisk): Always successful due to guaranteed mock fallback
  ///
  /// The returned FireRisk includes:
  /// - source: Which service provided the data (effis, sepa, cache, mock)
  /// - freshness: Data recency indicator (live, cached, mock)
  /// - observedAt: UTC timestamp of when data was originally collected
  /// - level: Risk classification based on Fire Weather Index or equivalent
  /// - fwi: Fire Weather Index value (nullable for cached/mock sources)
  ///
  /// Example usage:
  /// ```dart
  /// final result = await fireRiskService.getCurrent(
  ///   lat: 55.9533, // Edinburgh
  ///   lon: -3.1883,
  /// );
  ///
  /// result.fold(
  ///   (error) => handleValidationError(error),
  ///   (fireRisk) => displayRisk(fireRisk),
  /// );
  /// ```
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
    Duration? deadline,
  });
}
