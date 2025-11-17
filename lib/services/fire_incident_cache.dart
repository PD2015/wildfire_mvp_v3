import 'package:dartz/dartz.dart';
import 'cache_service.dart';
import '../models/fire_incident.dart';
import '../utils/geohash_utils.dart';

/// Type-safe cache interface for List<FireIncident> data
///
/// Extends generic CacheService with FireIncident-specific convenience methods
/// for coordinate-based caching operations with geohash spatial keys.
///
/// ## Caching Strategy (T018)
/// - **Key Generation**: Geohash of bbox center at precision 5 (~4.9km)
/// - **TTL**: 6 hours for fire incident data freshness
/// - **Capacity**: 100 entries with LRU eviction
/// - **Freshness Marking**: Cached incidents marked with Freshness.cached
///
/// Note: MVP uses bbox center for cache keys. May over-reuse cache across
/// large map pans. Consider viewport-corners hashing in A11+ if needed.
abstract class FireIncidentCache extends CacheService<List<FireIncident>> {
  /// Get cached fire incident data for specific coordinates
  ///
  /// Convenience method that generates geohash key from coordinates
  /// and retrieves cached fire incident list.
  ///
  /// Parameters:
  /// - [lat]: Latitude in decimal degrees
  /// - [lon]: Longitude in decimal degrees
  ///
  /// Returns:
  /// - Some(List<FireIncident>) if cached data exists and is not expired
  /// - None() if no valid cached data for the location
  Future<Option<List<FireIncident>>> getForCoordinates(
    double lat,
    double lon,
  ) async {
    final geohash = GeohashUtils.encode(lat, lon, precision: 5);
    return await get(geohash);
  }
}
