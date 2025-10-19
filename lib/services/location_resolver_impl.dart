import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_models.dart';
import 'utils/geo_utils.dart';
import 'location_resolver.dart';

/// Concrete implementation of LocationResolver with 5-tier fallback strategy
///
/// Provides headless location resolution with privacy-compliant logging
/// and graceful handling of platform limitations and permission changes.
class LocationResolverImpl implements LocationResolver {
  /// Create LocationResolver
  LocationResolverImpl();

  /// Scotland centroid coordinates for default fallback location
  // ORIGINAL: static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);
  // TEST MODE: Aviemore coordinates to test UK fire risk services
  static const LatLng _scotlandCentroid =
      LatLng(57.2, -3.8); // Aviemore, UK - emulator GPS workaround
  // static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);

  /// Cache keys for SharedPreferences persistence
  static const String _versionKey = 'manual_location_version';
  static const String _latKey = 'manual_location_lat';
  static const String _lonKey = 'manual_location_lon';
  static const String _placeKey = 'manual_location_place';
  static const String _timestampKey = 'manual_location_timestamp';
  static const String _currentVersion = '1.0';

  @override
  Future<Either<LocationError, LatLng>> getLatLon(
      {bool allowDefault = true}) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Platform guard: Skip GPS attempts on web/unsupported platforms
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        debugPrint(
            'Platform guard: Skipping GPS on ${kIsWeb ? 'web' : Platform.operatingSystem}');
        return await _fallbackToCache(allowDefault);
      }

      // Tier 1: Skip last known position to force fresh GPS (emulator has stale coordinates)
      // TEMPORARILY DISABLED: Last known device position (instant)
      // final lastKnownResult = await _tryLastKnownPosition();
      // if (lastKnownResult.isRight()) {
      //   final coords = lastKnownResult.getOrElse(() => _scotlandCentroid);
      //   debugPrint(
      //       'Location resolved via last known: ${LocationUtils.logRedact(coords.latitude, coords.longitude)}');
      //   return Right(coords);
      // }

      // Tier 1: GPS fix temporarily bypassed due to emulator GPS issues
      // Force use of Aviemore coordinates to test UK fire risk services (EFFIS + SEPA)
      debugPrint(
          'GPS temporarily bypassed - using Aviemore coordinates for UK testing');
      // final remainingTime =
      //     _totalTimeout.inMilliseconds - stopwatch.elapsedMilliseconds;
      // if (remainingTime > 0) {
      //   final gpsTimeout = Duration(
      //       milliseconds: remainingTime.clamp(0, _gpsTimeout.inMilliseconds));
      //   final gpsResult = await _tryGpsFix(gpsTimeout);
      //   if (gpsResult.isRight()) {
      //     final coords = gpsResult.getOrElse(() => _scotlandCentroid);
      //     debugPrint(
      //         'Location resolved via GPS: ${LocationUtils.logRedact(coords.latitude, coords.longitude)}');
      //     return Right(coords);
      //   }
      // }

      // Tier 3: SharedPreferences cached manual location
      final cacheResult = await _tryCache();
      if (cacheResult.isRight()) {
        final coords = cacheResult.getOrElse(() => _scotlandCentroid);
        debugPrint(
            'Location resolved via cache: ${GeographicUtils.logRedact(coords.latitude, coords.longitude)}');
        return Right(coords);
      }

      // Tier 4: Manual entry (caller responsibility)
      if (!allowDefault) {
        debugPrint(
            'Location resolution requires manual entry (allowDefault=false)');
        return const Left(LocationError.permissionDenied);
      }

      // Tier 5: Scotland centroid default
      debugPrint(
          'Location resolved via default: ${GeographicUtils.logRedact(_scotlandCentroid.latitude, _scotlandCentroid.longitude)}');
      return const Right(_scotlandCentroid);
    } catch (e) {
      debugPrint('Location resolution error: $e');
      if (allowDefault) {
        debugPrint(
            'Falling back to default: ${GeographicUtils.logRedact(_scotlandCentroid.latitude, _scotlandCentroid.longitude)}');
        return const Right(_scotlandCentroid);
      }
      return const Left(LocationError.gpsUnavailable);
    } finally {
      stopwatch.stop();
      debugPrint(
          'Total location resolution time: ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  /// Attempts to load from SharedPreferences cache (Tier 3)
  Future<Either<LocationError, LatLng>> _tryCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check version compatibility
      final version = prefs.getString(_versionKey);
      if (version != _currentVersion) {
        debugPrint('Cache version mismatch or missing: $version');
        return const Left(LocationError.gpsUnavailable);
      }

      final lat = prefs.getDouble(_latKey);
      final lon = prefs.getDouble(_lonKey);

      if (lat != null && lon != null) {
        // Validate coordinates are in correct range
        // Scotland is between latitudes 54.5-60.9 and longitudes -8.6 to -0.7
        final isValidLatitude = lat >= 54.0 && lat <= 61.0;
        final isValidLongitude = lon >= -9.0 && lon <= 0.0;
        
        if (isValidLatitude && isValidLongitude) {
          return Right(LatLng(lat, lon));
        } else {
          // Clear corrupted cache (likely has wrong sign on longitude)
          debugPrint('Invalid cached coordinates: lat=$lat, lon=$lon. Clearing cache.');
          await prefs.remove(_latKey);
          await prefs.remove(_lonKey);
          await prefs.remove(_versionKey);
        }
      }

      return const Left(LocationError.gpsUnavailable);
    } catch (e) {
      debugPrint('Cache read error: $e');
      return const Left(LocationError.gpsUnavailable);
    }
  }

  /// Fallback to cache when GPS is unavailable
  Future<Either<LocationError, LatLng>> _fallbackToCache(
      bool allowDefault) async {
    final cacheResult = await _tryCache();
    if (cacheResult.isRight()) {
      return cacheResult;
    }

    if (allowDefault) {
      return const Right(_scotlandCentroid);
    }

    // When GPS is unavailable due to platform restrictions and manual entry needed
    return const Left(LocationError.permissionDenied);
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {
    if (!location.isValid) {
      throw ArgumentError(
          'Invalid coordinates: ${location.latitude}, ${location.longitude}');
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setString(_versionKey, _currentVersion),
        prefs.setDouble(_latKey, location.latitude),
        prefs.setDouble(_lonKey, location.longitude),
        prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch),
        if (placeName != null) prefs.setString(_placeKey, placeName),
      ]);

      debugPrint(
          'Manual location saved: ${GeographicUtils.logRedact(location.latitude, location.longitude)}${placeName != null ? ' ($placeName)' : ''}');
    } catch (e) {
      debugPrint('Failed to save manual location: $e');
      rethrow;
    }
  }
}
