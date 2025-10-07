import 'package:equatable/equatable.dart';

/// Location resolution error types
enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  gpsUnavailable,
  timeout,
  networkError,
  unknown,
}

/// Location error with context
class LocationError extends Equatable {
  final LocationErrorType type;
  final String message;
  final String? details;

  const LocationError({
    required this.type,
    required this.message,
    this.details,
  });

  factory LocationError.serviceDisabled() {
    return const LocationError(
      type: LocationErrorType.serviceDisabled,
      message: 'Location services are disabled',
    );
  }

  factory LocationError.permissionDenied() {
    return const LocationError(
      type: LocationErrorType.permissionDenied,
      message: 'Location permission denied',
    );
  }

  factory LocationError.gpsUnavailable(String details) {
    return LocationError(
      type: LocationErrorType.gpsUnavailable,
      message: 'GPS unavailable',
      details: details,
    );
  }

  @override
  List<Object?> get props => [type, message, details];

  @override
  String toString() => 'LocationError($type: $message${details != null ? ' - $details' : ''})';
}
