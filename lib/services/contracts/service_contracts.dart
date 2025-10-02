import 'package:dartz/dartz.dart';
import '../../models/api_error.dart';
import '../../models/effis_fwi_result.dart';
import '../models/fire_risk.dart';

/// Stable dependency contracts for FireRiskService orchestrator
///
/// These interfaces define the minimal contracts that the FireRiskService
/// orchestrator depends on, allowing A2 to be compiled and tested without
/// requiring full implementations of A1 (EffisService) or A5 (CacheService).
///
/// This enables:
/// - Independent development and testing of the orchestrator
/// - Clean dependency injection and mocking for tests
/// - Loose coupling between service layers

/// Contract for EFFIS (European Forest Fire Information System) service
///
/// Provides Fire Weather Index data for global coordinates.
/// This contract matches the A1 EffisService implementation.
abstract class EffisService {
  /// Gets Fire Weather Index data for specified coordinates
  ///
  /// [lat] Latitude in decimal degrees (-90.0 to 90.0)
  /// [lon] Longitude in decimal degrees (-180.0 to 180.0)
  ///
  /// Returns Either<ApiError, EffisFwiResult> where:
  /// - Left: Network errors, API errors, or service unavailable
  /// - Right: Valid FWI result with risk level and timestamp
  Future<Either<ApiError, EffisFwiResult>> getFwi({
    required double lat,
    required double lon,
  });
}

/// Contract for SEPA (Scottish Environment Protection Agency) service
///
/// Provides Scotland-specific fire risk data for coordinates within
/// Scottish boundaries (54.6°N-60.9°N, 9.0°W-1.0°E).
abstract class SepaService {
  /// Gets current fire risk for Scotland coordinates
  ///
  /// Should only be called for coordinates within Scotland boundaries.
  /// Implementation may return errors for non-Scotland coordinates.
  ///
  /// [lat] Latitude in decimal degrees (Scotland: 54.6°N-60.9°N)
  /// [lon] Longitude in decimal degrees (Scotland: 9.0°W-1.0°E)
  ///
  /// Returns Either<ApiError, FireRisk> where:
  /// - Left: Network errors, API errors, service unavailable, or out of region
  /// - Right: Valid fire risk assessment with SEPA source attribution
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
  });
}

/// Contract for cache service providing fire risk data persistence
///
/// Stores and retrieves FireRisk data with TTL (Time To Live) management.
/// Implementation handles encryption, privacy protection, and automatic cleanup.
abstract class CacheService {
  /// Retrieves cached fire risk data by key
  ///
  /// [key] Cache key (typically geohash-based for privacy protection)
  ///
  /// Returns Option<FireRisk> where:
  /// - Some(FireRisk): Fresh cached data (within TTL)
  /// - None: Cache miss, expired data, or cache unavailable
  Future<Option<FireRisk>> get({required String key});

  /// Stores fire risk data in cache with TTL
  ///
  /// [key] Cache key (typically geohash-based for privacy protection)
  /// [value] FireRisk data to cache (should preserve original source attribution)
  /// [ttl] Time to live duration (typically 1-6 hours for fire risk data)
  ///
  /// Implementation should:
  /// - Encrypt sensitive data for privacy compliance
  /// - Handle storage failures gracefully (don't throw)
  /// - Automatically clean up expired entries
  Future<void> set({
    required String key,
    required FireRisk value,
    required Duration ttl,
  });
}
