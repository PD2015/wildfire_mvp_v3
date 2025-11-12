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

/// Geographic bounds defined by southwest and northeast corners
class LatLngBounds extends Equatable {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  /// Factory constructor with validation
  factory LatLngBounds.validated({
    required LatLng southwest,
    required LatLng northeast,
  }) {
    if (!southwest.isValid || !northeast.isValid) {
      throw ArgumentError('Invalid coordinates in bounds');
    }

    if (southwest.latitude >= northeast.latitude) {
      throw ArgumentError(
        'Southwest latitude (${southwest.latitude}) must be less than '
        'northeast latitude (${northeast.latitude})',
      );
    }

    if (southwest.longitude >= northeast.longitude) {
      throw ArgumentError(
        'Southwest longitude (${southwest.longitude}) must be less than '
        'northeast longitude (${northeast.longitude})',
      );
    }

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  /// Check if a coordinate is within these bounds
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  /// Calculate the center point of these bounds
  LatLng get center {
    final centerLat = (southwest.latitude + northeast.latitude) / 2;
    final centerLon = (southwest.longitude + northeast.longitude) / 2;
    return LatLng(centerLat, centerLon);
  }

  /// Calculate the span of these bounds
  LatLng get span {
    final latSpan = northeast.latitude - southwest.latitude;
    final lonSpan = northeast.longitude - southwest.longitude;
    return LatLng(latSpan, lonSpan);
  }

  /// Expand bounds by the given distance in degrees
  LatLngBounds expand(double degrees) {
    return LatLngBounds(
      southwest: LatLng(
        southwest.latitude - degrees,
        southwest.longitude - degrees,
      ),
      northeast: LatLng(
        northeast.latitude + degrees,
        northeast.longitude + degrees,
      ),
    );
  }

  @override
  List<Object> get props => [southwest, northeast];

  @override
  String toString() => 'LatLngBounds($southwest, $northeast)';
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
