import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_models.dart';

/// Persistent cache for manually entered location coordinates.
///
/// Provides version-compatible storage to SharedPreferences with:
/// - Corruption-safe reads with graceful fallback
/// - Version tracking for future compatibility
/// - Optional place name storage
/// - Timestamp tracking for cache freshness
///
/// Storage keys:
/// - 'manual_location_version': '1.0' (format compatibility)
/// - 'manual_location_lat': double latitude value
/// - 'manual_location_lon': double longitude value
/// - 'manual_location_place': string display name (optional)
/// - 'manual_location_timestamp': int milliseconds since epoch
class LocationCache {
  static const String _versionKey = 'manual_location_version';
  static const String _latKey = 'manual_location_lat';
  static const String _lonKey = 'manual_location_lon';
  static const String _placeKey = 'manual_location_place';
  static const String _timestampKey = 'manual_location_timestamp';
  static const String _currentVersion = '1.0';

  /// Save manual location coordinates to persistent storage
  ///
  /// [location] - The coordinates to save
  /// [placeName] - Optional human-readable place name
  ///
  /// Throws no exceptions - failures are logged but do not crash
  Future<void> save(LatLng location, {String? placeName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Save all values atomically where possible
      await Future.wait([
        prefs.setString(_versionKey, _currentVersion),
        prefs.setDouble(_latKey, location.latitude),
        prefs.setDouble(_lonKey, location.longitude),
        prefs.setInt(_timestampKey, timestamp),
      ]);

      // Save optional place name
      if (placeName != null && placeName.isNotEmpty) {
        await prefs.setString(_placeKey, placeName);
      } else {
        await prefs.remove(_placeKey);
      }
    } catch (e) {
      // Graceful degradation - log error but don't crash app (Gate C5)
      // In production, this would use proper logging
      debugPrint('LocationCache.save failed: $e');
    }
  }

  /// Load cached manual location coordinates
  ///
  /// Returns the cached location or null if:
  /// - No cached location exists
  /// - Cached data is corrupted
  /// - Version incompatibility (future-proofing)
  /// - Coordinates are invalid
  ///
  /// Never throws exceptions (Gate C5)
  Future<LatLng?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check version compatibility
      final version = prefs.getString(_versionKey);
      if (version != _currentVersion) {
        // In future versions, could handle migration here
        return null;
      }

      // Load coordinate data
      final lat = prefs.getDouble(_latKey);
      final lon = prefs.getDouble(_lonKey);

      if (lat == null || lon == null) {
        return null;
      }

      // Validate coordinates before returning
      final location = LatLng(lat, lon);
      if (!location.isValid) {
        // Corrupted data - clear invalid cache
        await _clearCorruptedData(prefs);
        return null;
      }

      return location;
    } catch (e) {
      // Corruption or other error - graceful degradation (Gate C5)
      debugPrint('LocationCache.load failed: $e');

      // Attempt to clear potentially corrupted data
      try {
        final prefs = await SharedPreferences.getInstance();
        await _clearCorruptedData(prefs);
      } catch (clearError) {
        debugPrint('LocationCache clear corrupted data failed: $clearError');
      }

      return null;
    }
  }

  /// Load cached place name if available
  ///
  /// Returns the cached place name or null if not available.
  /// Safe to call even if coordinates are not cached.
  Future<String?> loadPlaceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_placeKey);
    } catch (e) {
      debugPrint('LocationCache.loadPlaceName failed: $e');
      return null;
    }
  }

  /// Get timestamp of last saved location
  ///
  /// Returns milliseconds since epoch, or null if no location cached.
  Future<int?> getTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_timestampKey);
    } catch (e) {
      debugPrint('LocationCache.getTimestamp failed: $e');
      return null;
    }
  }

  /// Clear all cached location data
  ///
  /// Useful for user privacy or testing purposes.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearCorruptedData(prefs);
    } catch (e) {
      debugPrint('LocationCache.clear failed: $e');
    }
  }

  /// Internal helper to clear potentially corrupted cache data
  Future<void> _clearCorruptedData(SharedPreferences prefs) async {
    await Future.wait([
      prefs.remove(_versionKey),
      prefs.remove(_latKey),
      prefs.remove(_lonKey),
      prefs.remove(_placeKey),
      prefs.remove(_timestampKey),
    ]);
  }
}
