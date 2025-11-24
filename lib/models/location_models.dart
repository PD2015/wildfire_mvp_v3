import 'package:equatable/equatable.dart';

/// Geographic coordinate representation with validation
class LatLng extends Equatable {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  /// Validates that coordinates are within valid GPS bounds
  /// Latitude: [-90.0, 90.0], Longitude: [-180.0, 180.0]
  bool get isValid {
    return !latitude.isNaN &&
        !longitude.isNaN &&
        !latitude.isInfinite &&
        !longitude.isInfinite &&
        latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }

  /// Factory constructor with validation
  factory LatLng.validated(double latitude, double longitude) {
    final coords = LatLng(latitude, longitude);
    if (!coords.isValid) {
      throw ArgumentError(
        'Invalid coordinates: lat=$latitude, lon=$longitude. '
        'Valid ranges: lat[-90,90], lon[-180,180]',
      );
    }
    return coords;
  }

  @override
  List<Object> get props => [latitude, longitude];

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// Location resolution error types
enum LocationError {
  /// GPS permission denied by user
  permissionDenied,

  /// GPS hardware unavailable or location services disabled
  gpsUnavailable,

  /// Location request timed out
  timeout,

  /// Invalid input provided (e.g., invalid coordinates)
  invalidInput,
}

/// Location resolution method for provenance tracking
enum LocationMethod {
  /// GPS position from device
  gps,

  /// Last known position from device cache
  deviceCache,

  /// Manual coordinates entered by user
  manual,

  /// Default fallback location (Scotland centroid)
  defaultLocation,
}

/// Location source for UI display and user trust building
///
/// Simplified classification for user-facing display, derived from LocationMethod.
/// Used to show appropriate icons, labels, and trust-building messaging.
enum LocationSource {
  /// Live GPS location from device
  gps,

  /// User-entered manual coordinates
  manual,

  /// Previously saved location (shown during offline/error states)
  cached,

  /// System default location (Scotland/test region)
  defaultFallback,
}
