/// Geohash utilities for spatial cache key generation
///
/// Provides geospatial functions for converting coordinates to geohash strings
/// for privacy-compliant cache keying with spatial locality.
class GeohashUtils {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode coordinates to geohash string at specified precision
  ///
  /// Parameters:
  /// - [lat]: Latitude in decimal degrees (-90 to 90)
  /// - [lon]: Longitude in decimal degrees (-180 to 180)
  /// - [precision]: Character count for geohash (default: 5 for ~4.9km resolution)
  ///
  /// Returns: Geohash string with spatial locality property
  ///
  /// Reference: Edinburgh (55.9533, -3.1883) at precision 5 -> "gcvwr"
  static String encode(double lat, double lon, {int precision = 5}) {
    if (precision <= 0) {
      throw ArgumentError('Precision must be positive');
    }
    if (lat < -90 || lat > 90) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }
    if (lon < -180 || lon > 180) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }

    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;

    String geohash = '';
    int bits = 0;
    int bitCount = 0;
    bool isLon = true;

    while (geohash.length < precision) {
      double mid;
      if (isLon) {
        mid = (lonMin + lonMax) / 2;
        if (lon >= mid) {
          bits = (bits << 1) | 1;
          lonMin = mid;
        } else {
          bits = bits << 1;
          lonMax = mid;
        }
      } else {
        mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          bits = (bits << 1) | 1;
          latMin = mid;
        } else {
          bits = bits << 1;
          latMax = mid;
        }
      }

      isLon = !isLon;
      bitCount++;

      if (bitCount == 5) {
        geohash += _base32[bits];
        bits = 0;
        bitCount = 0;
      }
    }

    return geohash;
  }

  /// Validate geohash format using base32 character set
  ///
  /// Parameters:
  /// - [geohash]: String to validate
  ///
  /// Returns: true if geohash contains only valid base32 characters
  static bool isValid(String geohash) {
    if (geohash.isEmpty) return false;
    return RegExp(r'^[0-9bcdefghjkmnpqrstuvwxyz]+$').hasMatch(geohash);
  }
}
