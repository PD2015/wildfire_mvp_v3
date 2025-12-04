/// LocationUtils provides privacy-compliant coordinate utilities
/// for the LocationResolver service, ensuring Gate C2 compliance
/// by preventing PII exposure in logs.
class LocationUtils {
  /// Privacy-compliant coordinate logging with 2 decimal precision
  /// Prevents PII exposure in logs per Gate C2 requirements
  ///
  /// Example: logRedact(55.9533, -3.1883) → "55.95,-3.19"
  ///
  /// Returns "Invalid location" if coordinates are invalid (NaN, Infinity,
  /// or out of valid GPS range).
  ///
  /// Validation rules:
  /// - Latitude must be in range [-90.0, 90.0]
  /// - Longitude must be in range [-180.0, 180.0]
  /// - No NaN or Infinity values allowed
  static String logRedact(double lat, double lon) {
    try {
      // Validate for NaN and Infinity
      if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite) {
        return 'Invalid location';
      }

      // Validate coordinate ranges
      if (!isValidCoordinate(lat, lon)) {
        return 'Invalid location';
      }

      return '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    } catch (e) {
      // Catch any unexpected errors (e.g., null values passed as doubles)
      return 'Invalid location';
    }
  }

  /// High-precision coordinate formatting for emergency services (5dp = ~1m accuracy)
  ///
  /// Used on Report Fire screen where exact coordinates help fire service locate fires.
  /// Format: "57.04850, -3.59620" (with space after comma for readability)
  ///
  /// Example: formatPrecise(57.0485, -3.5962) → "57.04850, -3.59620"
  ///
  /// Returns "Invalid location" if coordinates are invalid.
  ///
  /// Note: This is for DISPLAY only. For logging, always use logRedact() to comply
  /// with C2 privacy requirements.
  static String formatPrecise(double lat, double lon) {
    try {
      // Validate for NaN and Infinity
      if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite) {
        return 'Invalid location';
      }

      // Validate coordinate ranges
      if (!isValidCoordinate(lat, lon)) {
        return 'Invalid location';
      }

      return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
    } catch (e) {
      return 'Invalid location';
    }
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
