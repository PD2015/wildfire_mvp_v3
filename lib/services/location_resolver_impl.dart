import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_models.dart';
import '../utils/location_utils.dart';
import 'location_resolver.dart';
import 'geolocator_service.dart';

/// Concrete implementation of LocationResolver with 5-tier fallback strategy
///
/// Provides headless location resolution with privacy-compliant logging
/// and graceful handling of platform limitations and permission changes.
class LocationResolverImpl implements LocationResolver {
  final GeolocatorService _geolocatorService;

  /// Create LocationResolver with optional geolocator service dependency
  /// Uses production GeolocatorServiceImpl by default
  LocationResolverImpl({GeolocatorService? geolocatorService})
      : _geolocatorService = geolocatorService ?? GeolocatorServiceImpl();
  /// Scotland centroid - rural central location to avoid city bias
  static const LatLng _scotlandCentroid = LatLng(56.5, -4.2);

  /// Total resolution budget to prevent UI blocking
  static const Duration _totalTimeout = Duration(milliseconds: 2500);

  /// GPS-specific timeout
  static const Duration _gpsTimeout = Duration(seconds: 2);

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

      // Tier 1: Last known device position (instant)
      final lastKnownResult = await _tryLastKnownPosition();
      if (lastKnownResult.isRight()) {
        final coords = lastKnownResult.getOrElse(() => _scotlandCentroid);
        debugPrint(
            'Location resolved via last known: ${LocationUtils.logRedact(coords.latitude, coords.longitude)}');
        return Right(coords);
      }

      // Tier 2: GPS fix with timeout (within total budget)
      final remainingTime =
          _totalTimeout.inMilliseconds - stopwatch.elapsedMilliseconds;
      if (remainingTime > 0) {
        final gpsTimeout = Duration(
            milliseconds: remainingTime.clamp(0, _gpsTimeout.inMilliseconds));
        final gpsResult = await _tryGpsFix(gpsTimeout);
        if (gpsResult.isRight()) {
          final coords = gpsResult.getOrElse(() => _scotlandCentroid);
          debugPrint(
              'Location resolved via GPS: ${LocationUtils.logRedact(coords.latitude, coords.longitude)}');
          return Right(coords);
        }
      }

      // Tier 3: SharedPreferences cached manual location
      final cacheResult = await _tryCache();
      if (cacheResult.isRight()) {
        final coords = cacheResult.getOrElse(() => _scotlandCentroid);
        debugPrint(
            'Location resolved via cache: ${LocationUtils.logRedact(coords.latitude, coords.longitude)}');
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
          'Location resolved via default: ${LocationUtils.logRedact(_scotlandCentroid.latitude, _scotlandCentroid.longitude)}');
      return const Right(_scotlandCentroid);
    } catch (e) {
      debugPrint('Location resolution error: $e');
      if (allowDefault) {
        debugPrint(
            'Falling back to default: ${LocationUtils.logRedact(_scotlandCentroid.latitude, _scotlandCentroid.longitude)}');
        return const Right(_scotlandCentroid);
      }
      return const Left(LocationError.gpsUnavailable);
    } finally {
      stopwatch.stop();
      debugPrint(
          'Total location resolution time: ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  /// Attempts to get last known position (Tier 1)
  Future<Either<LocationError, LatLng>> _tryLastKnownPosition() async {
    try {
      final position = await _geolocatorService.getLastKnownPosition();

      if (position != null) {
        final coords = LatLng(position.latitude, position.longitude);
        if (coords.isValid) {
          return Right(coords);
        }
      }

      return const Left(LocationError.gpsUnavailable);
    } catch (e) {
      debugPrint('Last known position error: $e');
      return const Left(LocationError.gpsUnavailable);
    }
  }

  /// Attempts GPS fix with timeout (Tier 2)
  Future<Either<LocationError, LatLng>> _tryGpsFix(Duration timeout) async {
    try {
      // Check location services
      if (!await _geolocatorService.isLocationServiceEnabled()) {
        return const Left(LocationError.gpsUnavailable);
      }

      // Check and request permissions
      var permission = await _geolocatorService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocatorService.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const Left(LocationError.permissionDenied);
      }

      // Get current position with timeout
      final position = await _geolocatorService.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: timeout,
      );

      final coords = LatLng(position.latitude, position.longitude);
      if (coords.isValid) {
        return Right(coords);
      }

      return const Left(LocationError.invalidInput);
    } on TimeoutException {
      return const Left(LocationError.timeout);
    } catch (e) {
      debugPrint('GPS fix error: $e');
      if (e.toString().toLowerCase().contains('permission')) {
        return const Left(LocationError.permissionDenied);
      }
      return const Left(LocationError.gpsUnavailable);
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
        final coords = LatLng(lat, lon);
        if (coords.isValid) {
          return Right(coords);
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
          'Manual location saved: ${LocationUtils.logRedact(location.latitude, location.longitude)}${placeName != null ? ' ($placeName)' : ''}');
    } catch (e) {
      debugPrint('Failed to save manual location: $e');
      rethrow;
    }
  }
}
