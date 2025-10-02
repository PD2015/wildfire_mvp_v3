/// Geographic utilities for coordinate validation and privacy-preserving operations
///
/// Provides Scotland boundary detection, privacy-preserving coordinate logging,
/// and geohash generation for cache keys. All operations respect C2 privacy gate
/// by avoiding raw coordinate exposure in logs.
library geo_utils;

/// Geographic utilities for coordinate processing and boundary detection
class GeographicUtils {
  /// Scotland geographic boundaries (includes St Kilda and outer islands)
  ///
  /// Boundaries selected to include:
  /// - Mainland Scotland
  /// - Hebrides (including St Kilda at ~57.8°N, -8.6°W)
  /// - Orkney and Shetland islands
  /// - Berwick-upon-Tweed border area
  static const double _scotlandMinLat = 54.6;
  static const double _scotlandMaxLat = 60.9;
  static const double _scotlandMinLon = -9.0;
  static const double _scotlandMaxLon = 1.0;

  /// Determines if coordinates fall within Scotland boundaries
  ///
  /// Uses inclusive rectangular boundary that encompasses all Scottish territory
  /// including outer islands (St Kilda, Shetland, Orkney).
  ///
  /// Returns `false` for invalid coordinates (NaN, infinity, out of world bounds).
  ///
  /// Examples:
  /// ```dart
  /// GeographicUtils.isInScotland(55.9533, -3.1883); // Edinburgh -> true
  /// GeographicUtils.isInScotland(51.5074, -0.1278); // London -> false
  /// GeographicUtils.isInScotland(57.8, -8.6);       // St Kilda -> true
  /// ```
  static bool isInScotland(double lat, double lon) {
    // Reject invalid coordinates
    if (!_isValidCoordinate(lat, lon)) {
      return false;
    }

    return lat >= _scotlandMinLat &&
        lat <= _scotlandMaxLat &&
        lon >= _scotlandMinLon &&
        lon <= _scotlandMaxLon;
  }

  /// Privacy-preserving coordinate logging (C2 compliance)
  ///
  /// Rounds coordinates to 2 decimal places (~1.1km resolution) to prevent
  /// exact location identification while preserving general area information
  /// for debugging and telemetry.
  ///
  /// Returns format: "lat,lon" with 2dp precision
  ///
  /// Examples:
  /// ```dart
  /// GeographicUtils.logRedact(55.953252, -3.188267); // "55.95,-3.19"
  /// GeographicUtils.logRedact(51.507351, -0.127758); // "51.51,-0.13"
  /// ```
  static String logRedact(double lat, double lon) {
    if (!_isValidCoordinate(lat, lon)) {
      return 'INVALID_COORDS';
    }

    final roundedLat = (lat * 100).round() / 100;
    final roundedLon = (lon * 100).round() / 100;

    return '${roundedLat.toStringAsFixed(2)},${roundedLon.toStringAsFixed(2)}';
  }

  /// Generates geohash for cache key generation
  ///
  /// Creates location-based cache keys with configurable precision.
  /// Higher precision = smaller geographic areas = more cache entries.
  ///
  /// Default precision of 5 provides ~4.9km × 4.9km resolution, suitable
  /// for fire weather data caching without excessive cache fragmentation.
  ///
  /// Examples:
  /// ```dart
  /// GeographicUtils.geohash(55.9533, -3.1883);      // "gcvwr" (Edinburgh)
  /// GeographicUtils.geohash(51.5074, -0.1278, precision: 6); // "gcpvj0"
  /// ```
  static String geohash(double lat, double lon, {int precision = 5}) {
    if (!_isValidCoordinate(lat, lon)) {
      throw ArgumentError(
          'Invalid coordinates for geohash: lat=$lat, lon=$lon');
    }

    if (precision < 1 || precision > 12) {
      throw ArgumentError(
          'Geohash precision must be between 1 and 12, got: $precision');
    }

    return _generateGeohash(lat, lon, precision);
  }

  /// Validates coordinate ranges and finite values
  static bool _isValidCoordinate(double lat, double lon) {
    return lat.isFinite &&
        lon.isFinite &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

  /// Base32 encoding for geohash generation
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Generates geohash using binary subdivision algorithm
  static String _generateGeohash(double lat, double lon, int precision) {
    var latMin = -90.0;
    var latMax = 90.0;
    var lonMin = -180.0;
    var lonMax = 180.0;

    var geohash = '';
    var bits = 0;
    var bitCount = 0;
    var isEvenBit = true; // Start with longitude bit

    while (geohash.length < precision) {
      if (isEvenBit) {
        // Longitude bit
        final lonMid = (lonMin + lonMax) / 2;
        if (lon >= lonMid) {
          bits = (bits << 1) | 1;
          lonMin = lonMid;
        } else {
          bits = bits << 1;
          lonMax = lonMid;
        }
      } else {
        // Latitude bit
        final latMid = (latMin + latMax) / 2;
        if (lat >= latMid) {
          bits = (bits << 1) | 1;
          latMin = latMid;
        } else {
          bits = bits << 1;
          latMax = latMid;
        }
      }

      isEvenBit = !isEvenBit;
      bitCount++;

      if (bitCount == 5) {
        geohash += _base32[bits];
        bits = 0;
        bitCount = 0;
      }
    }

    return geohash;
  }
}
