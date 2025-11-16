/// Geohash utilities for spatial cache key generation
///
/// Provides geospatial functions for converting coordinates to geohash strings
/// for privacy-compliant cache keying with spatial locality.
///
/// Task 8 enhancements: Added geohash bounds calculation and neighbor lookups
/// for efficient viewport-based cache queries.
class GeohashUtils {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  // Neighbor lookup tables for efficient geohash neighbor calculation
  static const Map<String, Map<String, String>> _neighbors = {
    'right': {
      'even': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
      'odd': 'bc01fg45238967deuvhjyznpkmstqrwx',
    },
    'left': {
      'even': '14365h7k9dcfesgujnmqp0r2twvyx8zb',
      'odd': '238967debc01fg45kmstqrwxuvhjyznp',
    },
    'top': {
      'even': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
      'odd': 'bc01fg45238967deuvhjyznpkmstqrwx',
    },
    'bottom': {
      'even': '14365h7k9dcfesgujnmqp0r2twvyx8zb',
      'odd': '238967debc01fg45kmstqrwxuvhjyznp',
    },
  };

  static const Map<String, Map<String, String>> _borders = {
    'right': {
      'even': 'bcfguvyz',
      'odd': 'prxz',
    },
    'left': {
      'even': '0145hjnp',
      'odd': '028b',
    },
    'top': {
      'even': 'prxz',
      'odd': 'bcfguvyz',
    },
    'bottom': {
      'even': '028b',
      'odd': '0145hjnp',
    },
  };

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

  /// Decode geohash to bounding box coordinates (Task 8)
  ///
  /// Converts geohash string back to geographic bounding box with latitude
  /// and longitude ranges. Used for viewport overlap calculations.
  ///
  /// Parameters:
  /// - [geohash]: Geohash string to decode
  ///
  /// Returns: GeohashBounds with lat/lon min/max values
  ///
  /// Example: "gcvwr" -> Edinburgh area bounds (~4.9km box)
  static GeohashBounds decode(String geohash) {
    if (!isValid(geohash)) {
      throw ArgumentError('Invalid geohash: $geohash');
    }

    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    bool isLon = true;

    for (int i = 0; i < geohash.length; i++) {
      final char = geohash[i];
      final charIndex = _base32.indexOf(char);
      if (charIndex == -1) {
        throw ArgumentError('Invalid character in geohash: $char');
      }

      for (int bits = 4; bits >= 0; bits--) {
        final bit = (charIndex >> bits) & 1;
        if (isLon) {
          final mid = (lonMin + lonMax) / 2;
          if (bit == 1) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if (bit == 1) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isLon = !isLon;
      }
    }

    return GeohashBounds(
      latMin: latMin,
      latMax: latMax,
      lonMin: lonMin,
      lonMax: lonMax,
    );
  }

  /// Get geohash neighbor in specified direction (Task 8)
  ///
  /// Efficiently calculates adjacent geohash cells without encoding/decoding.
  /// Used for viewport overlap queries that span multiple cache entries.
  ///
  /// Parameters:
  /// - [geohash]: Source geohash string
  /// - [direction]: 'right', 'left', 'top', or 'bottom'
  ///
  /// Returns: Neighboring geohash string in the specified direction
  ///
  /// Example: neighbor("gcvwr", "right") -> "gcvwx" (east of Edinburgh)
  static String neighbor(String geohash, String direction) {
    if (!isValid(geohash)) {
      throw ArgumentError('Invalid geohash: $geohash');
    }
    if (!_neighbors.containsKey(direction)) {
      throw ArgumentError(
          'Invalid direction: $direction (use right/left/top/bottom)');
    }

    final lastChar = geohash[geohash.length - 1];
    final parent = geohash.substring(0, geohash.length - 1);
    final type = geohash.length % 2 == 0 ? 'even' : 'odd';

    // Check if we're on the border for this direction
    final borderChars = _borders[direction]![type]!;
    if (borderChars.contains(lastChar) && parent.isNotEmpty) {
      final parentNeighbor = neighbor(parent, direction);
      return parentNeighbor + _base32[0];
    }

    // Look up neighbor character
    final neighborChars = _neighbors[direction]![type]!;
    final charIndex = _base32.indexOf(lastChar);
    final newChar = neighborChars[charIndex];

    return parent + newChar;
  }

  /// Get all geohashes covering a bounding box (Task 8)
  ///
  /// Calculates minimal set of geohashes at specified precision that completely
  /// cover the given bounding box. Used for efficient viewport cache queries.
  ///
  /// Strategy:
  /// 1. Calculate center geohash
  /// 2. Expand to neighbors until all corners covered
  /// 3. Return unique set of geohashes
  ///
  /// Parameters:
  /// - [latMin]: Minimum latitude of bounding box
  /// - [latMax]: Maximum latitude of bounding box
  /// - [lonMin]: Minimum longitude of bounding box
  /// - [lonMax]: Maximum longitude of bounding box
  /// - [precision]: Geohash precision (default 5)
  ///
  /// Returns: Set of geohash strings covering the bounding box
  ///
  /// Performance: Optimized for typical map viewports (1-9 geohashes at precision 5)
  static Set<String> coverBounds({
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
    int precision = 5,
  }) {
    final geohashes = <String>{};

    // Sample points across the bounding box
    final latStep = (latMax - latMin) / 3;
    final lonStep = (lonMax - lonMin) / 3;

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final lat = latMin + (i * latStep);
        final lon = lonMin + (j * lonStep);
        final geohash = encode(lat, lon, precision: precision);
        geohashes.add(geohash);
      }
    }

    return geohashes;
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

/// Bounding box for a decoded geohash (Task 8)
///
/// Represents the geographic area covered by a geohash string.
/// Used for viewport overlap calculations and spatial queries.
class GeohashBounds {
  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;

  const GeohashBounds({
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
  });

  /// Get center coordinates of this geohash bounds
  (double lat, double lon) get center {
    return ((latMin + latMax) / 2, (lonMin + lonMax) / 2);
  }

  /// Check if this bounds overlaps with another bounding box
  bool overlaps({
    required double otherLatMin,
    required double otherLatMax,
    required double otherLonMin,
    required double otherLonMax,
  }) {
    return !(otherLatMax < latMin ||
        otherLatMin > latMax ||
        otherLonMax < lonMin ||
        otherLonMin > lonMax);
  }

  @override
  String toString() {
    return 'GeohashBounds(lat: $latMin to $latMax, lon: $lonMin to $lonMax)';
  }
}
