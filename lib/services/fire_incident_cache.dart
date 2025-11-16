import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
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
/// - **Viewport Queries**: Geohash-based spatial indexing for efficient bounds queries
///
/// ## Task 8 Enhancements
/// - Added `getIncidentsForViewport()` for efficient viewport-based queries
/// - Geohash spatial indexing enables fast lookups across multiple cache entries
/// - Aggregates incidents from all overlapping cache entries within bounds
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

  /// Get all cached fire incidents within viewport bounds (Task 8)
  ///
  /// Performs geohash-based spatial query to find all cache entries that
  /// overlap with the requested viewport. Aggregates incidents from all
  /// matching cache entries and filters to ensure they fall within bounds.
  ///
  /// Strategy:
  /// 1. Calculate geohash neighbors for viewport coverage
  /// 2. Query cache entries for all overlapping geohashes
  /// 3. Aggregate and deduplicate incidents across entries
  /// 4. Filter incidents to ensure they fall within exact bounds
  /// 5. Mark all incidents with Freshness.cached
  ///
  /// Parameters:
  /// - [bounds]: Map viewport bounds to query
  ///
  /// Returns:
  /// - Some(List<FireIncident>) with all cached incidents within bounds
  /// - None() if no valid cached data overlaps the viewport
  ///
  /// Performance: <200ms target even with multiple cache entries
  /// Privacy: Uses geohash spatial keys, no raw coordinates in lookups
  Future<Option<List<FireIncident>>> getIncidentsForViewport(
    gmaps.LatLngBounds bounds,
  );
}
