/// LocationUtils provides privacy-compliant coordinate utilities
/// for the LocationResolver service, ensuring Gate C2 compliance
/// by preventing PII exposure in logs.
class LocationUtils {
  /// Privacy-compliant coordinate logging with 2 decimal precision
  /// Prevents PII exposure in logs per Gate C2 requirements
  ///
  /// Example: logRedact(55.9533, -3.1883) → "55.95,-3.19"
  static String logRedact(double lat, double lon) {
    return '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
  }

  /// Validate coordinate ranges
  ///
  /// Returns true if coordinates are within valid GPS bounds:
  /// - Latitude: [-90.0, 90.0]
  /// - Longitude: [-180.0, 180.0]
  static bool isValidCoordinate(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }
}
