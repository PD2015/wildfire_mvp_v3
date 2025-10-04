import 'package:dartz/dartz.dart';
import 'cache_service.dart';
import 'models/fire_risk.dart';
import '../utils/geohash_utils.dart';

/// Type-safe cache interface for FireRisk data
///
/// Extends generic CacheService with FireRisk-specific convenience methods
/// for coordinate-based caching operations.
abstract class FireRiskCache extends CacheService<FireRisk> {
  /// Get cached FireRisk data for specific coordinates
  ///
  /// Convenience method that generates geohash key from coordinates
  /// and retrieves cached FireRisk data.
  ///
  /// Parameters:
  /// - [lat]: Latitude in decimal degrees
  /// - [lon]: Longitude in decimal degrees
  ///
  /// Returns:
  /// - Some(FireRisk) if cached data exists and is not expired
  /// - None() if no valid cached data for the location
  Future<Option<FireRisk>> getForCoordinates(double lat, double lon) async {
    final geohash = GeohashUtils.encode(lat, lon, precision: 5);
    return await get(geohash);
  }
}
