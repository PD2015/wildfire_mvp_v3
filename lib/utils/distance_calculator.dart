// Distance calculation utilities for fire information sheet
// Implements Task 3 of 018-map-fire-information specification
// Calculates distance and bearing between user location and fire incidents

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/utils/geo_utils.dart';

/// Utility class for calculating distances and bearings between geographic points
///
/// Designed for fire information sheet to show user-friendly distance/direction
/// like "3.2 km NE" for each fire incident relative to user location.
class DistanceCalculator {
  /// Earth's mean radius in meters (WGS84)
  static const double _earthRadiusMeters = 6371000.0;

  /// Calculate great circle distance between two points in meters
  ///
  /// Uses the haversine formula for accurate distance calculation.
  /// Returns distance in meters with precision suitable for fire incidents.
  static double distanceInMeters(LatLng from, LatLng to) {
    if (from == to) return 0.0;

    // Convert coordinates to radians
    final lat1Rad = _degreesToRadians(from.latitude);
    final lat2Rad = _degreesToRadians(to.latitude);
    final deltaLatRad = _degreesToRadians(to.latitude - from.latitude);
    final deltaLonRad = _degreesToRadians(to.longitude - from.longitude);

    // Haversine formula
    final a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) *
            math.sin(deltaLonRad / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Calculate distance using geolocator for high accuracy
  ///
  /// Falls back to our implementation if geolocator fails.
  /// Useful for validation against geolocator's implementation.
  static double distanceInMetersGeolocator(LatLng from, LatLng to) {
    try {
      return Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );
    } catch (e) {
      // Fall back to our implementation
      return distanceInMeters(from, to);
    }
  }

  /// Calculate bearing from one point to another in degrees (0-360)
  ///
  /// Returns bearing as degrees where:
  /// - 0° = North, 90° = East, 180° = South, 270° = West
  static double bearingInDegrees(LatLng from, LatLng to) {
    if (from == to) return 0.0;

    final lat1Rad = _degreesToRadians(from.latitude);
    final lat2Rad = _degreesToRadians(to.latitude);
    final deltaLonRad = _degreesToRadians(to.longitude - from.longitude);

    final y = math.sin(deltaLonRad) * math.cos(lat2Rad);
    final x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    // Normalize to 0-360 range
    return (bearingDeg + 360) % 360;
  }

  /// Convert bearing to cardinal direction (N, NE, E, SE, etc.)
  ///
  /// Returns user-friendly cardinal directions with 8-point precision.
  /// Perfect for fire information sheet display.
  static String bearingToCardinal(double bearingDegrees) {
    const directions = [
      'N', // 0°
      'NE', // 45°
      'E', // 90°
      'SE', // 135°
      'S', // 180°
      'SW', // 225°
      'W', // 270°
      'NW', // 315°
    ];

    // Each cardinal direction covers 45 degrees (360/8)
    final index = ((bearingDegrees + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Get combined distance and direction string for display
  ///
  /// Returns formatted string like "3.2 km NE" or "450 m SW".
  /// Perfect for fire information sheet incident cards.
  static String formatDistanceAndDirection(LatLng from, LatLng to) {
    final distanceMeters = distanceInMeters(from, to);
    final bearingDegrees = bearingInDegrees(from, to);
    final cardinal = bearingToCardinal(bearingDegrees);

    if (distanceMeters < 1000) {
      // Show meters for distances under 1 km
      return '${distanceMeters.round()} m $cardinal';
    } else {
      // Show kilometers with 1 decimal place for longer distances
      final distanceKm = distanceMeters / 1000;
      return '${distanceKm.toStringAsFixed(1)} km $cardinal';
    }
  }

  /// Privacy-compliant distance calculation with logging
  ///
  /// Uses GeographicUtils.logRedact for coordinate logging compliance.
  /// Suitable for service layer usage with privacy requirements.
  static String calculateDistanceWithLogging(
    LatLng userLocation,
    LatLng fireLocation,
  ) {
    final userLocationLog = GeographicUtils.logRedact(
      userLocation.latitude,
      userLocation.longitude,
    );
    final fireLocationLog = GeographicUtils.logRedact(
      fireLocation.latitude,
      fireLocation.longitude,
    );

    final result = formatDistanceAndDirection(userLocation, fireLocation);

    // Privacy-compliant logging
    debugPrint(
      'Distance calculation: User at $userLocationLog to fire at $fireLocationLog = $result',
    );

    return result;
  }

  /// Validate that coordinates are within reasonable bounds
  ///
  /// Helps catch edge cases and invalid coordinates before calculation.
  static bool areValidCoordinates(LatLng coord1, LatLng coord2) {
    return coord1.isValid && coord2.isValid;
  }

  /// Calculate distance with validation and error handling
  ///
  /// Returns null if coordinates are invalid or calculation fails.
  /// Suitable for production use with proper error handling.
  static String? calculateDistanceSafe(
    LatLng? userLocation,
    LatLng? fireLocation,
  ) {
    if (userLocation == null || fireLocation == null) return null;

    if (!areValidCoordinates(userLocation, fireLocation)) return null;

    try {
      return formatDistanceAndDirection(userLocation, fireLocation);
    } catch (e) {
      // Log error but don't expose coordinates
      debugPrint('Distance calculation failed: Invalid coordinates');
      return null;
    }
  }

  /// Helper methods for coordinate conversion
  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
  static double _radiansToDegrees(double radians) => radians * (180 / math.pi);

  /// Test method to verify calculations against known distances
  ///
  /// Useful for unit testing and validation. Returns true if calculation
  /// is within acceptable tolerance of expected value.
  static bool verifyKnownDistance({
    required LatLng point1,
    required LatLng point2,
    required double expectedMeters,
    double tolerancePercent = 0.1, // 0.1% tolerance
  }) {
    final calculated = distanceInMeters(point1, point2);
    final difference = (calculated - expectedMeters).abs();
    final tolerance = expectedMeters * tolerancePercent / 100;

    return difference <= tolerance;
  }
}
