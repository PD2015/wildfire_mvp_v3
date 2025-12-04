import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_models.dart';
import '../config/feature_flags.dart';
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
  static const LatLng _scotlandCentroid = LatLng(
    57.2,
    -3.8,
  ); // Aviemore, UK - emulator GPS workaround
  // static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);

  /// Cache keys for SharedPreferences persistence
  static const String _versionKey = 'manual_location_version';
  static const String _latKey = 'manual_location_lat';
  static const String _lonKey = 'manual_location_lon';
  static const String _placeKey = 'manual_location_place';
  static const String _timestampKey = 'manual_location_timestamp';
  static const String _currentVersion = '1.0';

  @override
  Future<Either<LocationError, LatLng>> getLatLon({
    bool allowDefault = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Platform guard: Skip GPS on web/unsupported platforms OR when TEST_REGION is explicitly set
      const isTestRegionSet = FeatureFlags.testRegion != 'scotland';

      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        const platformName = kIsWeb ? 'web' : 'macos';
        debugPrint('Platform guard: Skipping GPS on $platformName');
        return await _fallbackToCache(allowDefault);
      }

      if (isTestRegionSet) {
        debugPrint(
          'TEST_REGION=${FeatureFlags.testRegion}: Skipping GPS to use test region coordinates',
        );
        // Return error to trigger MapController's test region fallback
        // Don't use default centroid when test region is explicitly set
        return const Left(LocationError.gpsUnavailable);
      }

      // Tier 1 & 2: Try GPS with timeout
      final gpsResult = await _tryGps();
      if (gpsResult.isRight()) {
        final coords = gpsResult.getOrElse(() => _scotlandCentroid);
        debugPrint(
          'Location resolved via GPS: ${GeographicUtils.logRedact(coords.latitude, coords.longitude)}',
        );
        return Right(coords);
      } else {
        debugPrint('GPS unavailable: ${gpsResult.fold((e) => e, (r) => '')}');
      }

      // Tier 3: SharedPreferences cached manual location
      final cacheResult = await _tryCache();
      if (cacheResult.isRight()) {
        final coords = cacheResult.getOrElse(() => _scotlandCentroid);
        debugPrint(
          'Location resolved via cache: ${GeographicUtils.logRedact(coords.latitude, coords.longitude)}',
        );
        return Right(coords);
      }

      // Tier 4: Manual entry (caller responsibility)
      if (!allowDefault) {
        debugPrint(
          'Location resolution requires manual entry (allowDefault=false)',
        );
        return const Left(LocationError.permissionDenied);
      }

      // Tier 5: Scotland centroid default
      debugPrint(
        'Location resolved via default: ${GeographicUtils.logRedact(_scotlandCentroid.latitude, _scotlandCentroid.longitude)}',
      );
      return const Right(_scotlandCentroid);
    } catch (e) {
      debugPrint('Location resolution error: $e');
      if (allowDefault) {
        debugPrint(
          'Falling back to default: ${GeographicUtils.logRedact(_scotlandCentroid.latitude, _scotlandCentroid.longitude)}',
        );
        return const Right(_scotlandCentroid);
      }
      return const Left(LocationError.gpsUnavailable);
    } finally {
      stopwatch.stop();
      debugPrint(
        'Total location resolution time: ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  /// Tier 1-2: Try GPS (last known + fresh fix with 3s timeout)
  /// Returns coordinates or error if GPS unavailable
  Future<Either<String, LatLng>> _tryGps() async {
    try {
      // Check if location services are enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const Left('Location services disabled');
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left('Location permission permanently denied');
      }

      // Try last known position first (instant, may be stale)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return Right(LatLng(lastKnown.latitude, lastKnown.longitude));
      }

      // Get fresh position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 3),
      );

      return Right(LatLng(position.latitude, position.longitude));
    } catch (e) {
      return Left('GPS error: $e');
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
        // Validate coordinates are not NaN, not infinite, and in correct range
        final isValidNumber =
            !lat.isNaN && !lon.isNaN && !lat.isInfinite && !lon.isInfinite;
        // Scotland is between latitudes 54.5-60.9 and longitudes -8.6 to -0.7
        final isValidLatitude = lat >= 54.0 && lat <= 61.0;
        final isValidLongitude = lon >= -9.0 && lon <= 0.0;

        if (isValidNumber && isValidLatitude && isValidLongitude) {
          return Right(LatLng(lat, lon));
        } else {
          // Clear corrupted cache (NaN, infinite, or out of range coordinates)
          debugPrint(
            'Invalid cached coordinates: lat=$lat, lon=$lon. Clearing cache.',
          );
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
    bool allowDefault,
  ) async {
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
        'Invalid coordinates: ${location.latitude}, ${location.longitude}',
      );
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
        'Manual location saved: ${GeographicUtils.logRedact(location.latitude, location.longitude)}${placeName != null ? ' ($placeName)' : ''}',
      );
    } catch (e) {
      debugPrint('Failed to save manual location: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearManualLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.remove(_versionKey),
        prefs.remove(_latKey),
        prefs.remove(_lonKey),
        prefs.remove(_placeKey),
        prefs.remove(_timestampKey),
      ]);

      debugPrint('Manual location cleared from cache');
    } catch (e) {
      debugPrint('Failed to clear manual location: $e');
      rethrow;
    }
  }

  @override
  Future<(LatLng, String?)?> loadCachedManualLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check version compatibility
      final version = prefs.getString(_versionKey);
      if (version != _currentVersion) {
        return null;
      }

      final lat = prefs.getDouble(_latKey);
      final lon = prefs.getDouble(_lonKey);

      if (lat != null && lon != null) {
        // Validate coordinates
        final isValidNumber =
            !lat.isNaN && !lon.isNaN && !lat.isInfinite && !lon.isInfinite;
        final isValidLatitude = lat >= 54.0 && lat <= 61.0;
        final isValidLongitude = lon >= -9.0 && lon <= 0.0;

        if (isValidNumber && isValidLatitude && isValidLongitude) {
          final placeName = prefs.getString(_placeKey);
          debugPrint(
            'Loaded cached manual location: ${GeographicUtils.logRedact(lat, lon)}${placeName != null ? ' ($placeName)' : ''}',
          );
          return (LatLng(lat, lon), placeName);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Failed to load cached manual location: $e');
      return null;
    }
  }
}
