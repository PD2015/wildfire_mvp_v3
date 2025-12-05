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
import 'geolocator_service.dart';

/// Concrete implementation of LocationResolver with 5-tier fallback strategy
///
/// Provides headless location resolution with privacy-compliant logging
/// and graceful handling of platform limitations and permission changes.
///
/// GPS operations are abstracted via [GeolocatorService] for testability.
class LocationResolverImpl implements LocationResolver {
  /// Create LocationResolver with optional injectable dependencies.
  ///
  /// [geolocatorService] - GPS abstraction, defaults to real implementation.
  /// Pass a fake in tests for controllable behavior.
  LocationResolverImpl({
    GeolocatorService? geolocatorService,
  }) : _geolocatorService = geolocatorService ?? GeolocatorServiceImpl();

  final GeolocatorService _geolocatorService;

  /// Aviemore coordinates - used as default fallback for testing
  /// Located in Cairngorms National Park, Scotland - an area with
  /// typical fire activity data in EFFIS for realistic testing.
  static const LatLng _aviemoreLocation = LatLng(57.2, -3.8);

  /// Real Scotland geographic centroid - used in production builds
  /// This is the approximate geographic center of Scotland.
  static const LatLng _scotlandCentroid = LatLng(55.8642, -4.2518);

  /// Default fallback location when GPS and cache are unavailable
  ///
  /// Controlled by DEV_MODE environment variable:
  /// - DEV_MODE=true (default): Uses Aviemore (57.2, -3.8) for testing
  /// - DEV_MODE=false: Uses real Scotland centroid (55.8642, -4.2518)
  ///
  /// Note: This must be `static final` (not `static const`) because the
  /// ternary expression isn't a constant expression even though both branches
  /// are const. The analyzer incorrectly suggests const but it won't compile.
  // ignore: prefer_const_declarations
  static final LatLng _defaultFallbackLocation =
      FeatureFlags.devMode ? _aviemoreLocation : _scotlandCentroid;

  /// Cache keys for SharedPreferences persistence
  static const String _versionKey = 'manual_location_version';
  static const String _latKey = 'manual_location_lat';
  static const String _lonKey = 'manual_location_lon';
  static const String _placeKey = 'manual_location_place';
  static const String _timestampKey = 'manual_location_timestamp';
  static const String _currentVersion = '1.0';

  @override
  Future<Either<LocationError, ResolvedLocation>> getLatLon({
    bool allowDefault = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Platform guard: Skip GPS on desktop platforms only
      // - Desktop (macOS/Windows/Linux): No GPS hardware available
      // - Mobile (Android/iOS): Native GPS available
      // - Web: Geolocation API available (requires HTTPS in production)
      //
      // Web GPS is now safe because GeolocatorService is injectable,
      // allowing tests to use FakeGeolocatorService instead of real browser API.
      const isTestRegionSet = FeatureFlags.testRegion != 'scotland';

      // Only skip GPS on desktop platforms (macOS, Windows, Linux)
      // Web and mobile can attempt GPS
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        debugPrint('Platform guard: Skipping GPS on desktop');
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
        final coords = gpsResult.getOrElse(() => _defaultFallbackLocation);
        debugPrint(
          'Location resolved via GPS: ${GeographicUtils.logRedact(coords.latitude, coords.longitude)}',
        );
        return Right(ResolvedLocation(
          coordinates: coords,
          source: LocationSource.gps,
        ));
      } else {
        debugPrint('GPS unavailable: ${gpsResult.fold((e) => e, (r) => '')}');
      }

      // Tier 3: SharedPreferences cached manual location
      final cacheResult = await _tryCache();
      if (cacheResult.isRight()) {
        final (coords, placeName) =
            cacheResult.getOrElse(() => (_defaultFallbackLocation, null));
        debugPrint(
          'Location resolved via cache: ${GeographicUtils.logRedact(coords.latitude, coords.longitude)}',
        );
        return Right(ResolvedLocation(
          coordinates: coords,
          source: LocationSource.cached,
          placeName: placeName,
        ));
      }

      // Tier 4: Manual entry (caller responsibility)
      // On web, we NEVER silently fall back to default location because:
      // 1. Users expect their phone to know their location
      // 2. Showing wrong location (Aviemore) is worse than prompting for manual entry
      // 3. On desktop, silent fallback is OK since no GPS is expected
      if (!allowDefault || kIsWeb) {
        debugPrint(
          'Location resolution requires manual entry (allowDefault=$allowDefault, kIsWeb=$kIsWeb)',
        );
        return const Left(LocationError.permissionDenied);
      }

      // Tier 5: Default fallback location
      debugPrint(
        'Location resolved via default: ${GeographicUtils.logRedact(_defaultFallbackLocation.latitude, _defaultFallbackLocation.longitude)}${FeatureFlags.devMode ? ' (DEV_MODE)' : ''}',
      );
      return Right(ResolvedLocation(
        coordinates: _defaultFallbackLocation,
        source: LocationSource.defaultFallback,
      ));
    } catch (e) {
      debugPrint('Location resolution error: $e');
      if (allowDefault) {
        debugPrint(
          'Falling back to default: ${GeographicUtils.logRedact(_defaultFallbackLocation.latitude, _defaultFallbackLocation.longitude)}',
        );
        return Right(ResolvedLocation(
          coordinates: _defaultFallbackLocation,
          source: LocationSource.defaultFallback,
        ));
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
      final serviceEnabled =
          await _geolocatorService.isLocationServiceEnabled();
      debugPrint('GPS: Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        return const Left('Location services disabled');
      }

      // Check permission status
      LocationPermission permission =
          await _geolocatorService.checkPermission();
      debugPrint('GPS: Initial permission status: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('GPS: Requesting permission...');
        permission = await _geolocatorService.requestPermission();
        debugPrint('GPS: Permission after request: $permission');
        if (permission == LocationPermission.denied) {
          return const Left('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left('Location permission permanently denied');
      }

      // Try last known position first (instant, may be stale)
      // Note: getLastKnownPosition is NOT supported on web - throws PlatformException
      // We skip it on web rather than catching the exception for cleaner control flow
      if (!kIsWeb) {
        final lastKnown = await _geolocatorService.getLastKnownPosition();
        if (lastKnown != null) {
          debugPrint('GPS: Using last known position');
          return Right(LatLng(lastKnown.latitude, lastKnown.longitude));
        }
      }

      // Get fresh position with timeout
      // Web browsers may take longer for first GPS acquisition
      const timeout = Duration(seconds: 8);

      debugPrint(
          'GPS: Acquiring fresh position (${timeout.inSeconds}s timeout)...');
      final position = await _geolocatorService.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: timeout,
      );

      return Right(LatLng(position.latitude, position.longitude));
    } catch (e) {
      return Left('GPS error: $e');
    }
  }

  /// Attempts to load from SharedPreferences cache (Tier 3)
  ///
  /// Includes TTL check - cached locations older than 1 hour are ignored
  /// to prevent stale locations from previous sessions overriding GPS.
  ///
  /// Returns tuple of (LatLng, placeName?) for source attribution.
  Future<Either<LocationError, (LatLng, String?)>> _tryCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check version compatibility
      final version = prefs.getString(_versionKey);
      if (version != _currentVersion) {
        debugPrint('Cache version mismatch or missing: $version');
        return const Left(LocationError.gpsUnavailable);
      }

      // Check if cached location has expired (>1 hour old)
      final timestampMs = prefs.getInt(_timestampKey);
      if (timestampMs != null) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        final age = DateTime.now().difference(cachedAt);
        if (age > _maxCacheAge) {
          debugPrint(
            'Cache expired (age: ${age.inMinutes} min). Skipping.',
          );
          return const Left(LocationError.gpsUnavailable);
        }
      } else {
        // No timestamp means old-format cache - treat as expired
        debugPrint('Cache has no timestamp. Treating as expired.');
        return const Left(LocationError.gpsUnavailable);
      }

      final lat = prefs.getDouble(_latKey);
      final lon = prefs.getDouble(_lonKey);
      final placeName = prefs.getString(_placeKey);

      if (lat != null && lon != null) {
        // Validate coordinates are not NaN, not infinite, and in correct range
        final isValidNumber =
            !lat.isNaN && !lon.isNaN && !lat.isInfinite && !lon.isInfinite;
        // Scotland is between latitudes 54.5-60.9 and longitudes -8.6 to -0.7
        final isValidLatitude = lat >= 54.0 && lat <= 61.0;
        final isValidLongitude = lon >= -9.0 && lon <= 0.0;

        if (isValidNumber && isValidLatitude && isValidLongitude) {
          return Right((LatLng(lat, lon), placeName));
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
  Future<Either<LocationError, ResolvedLocation>> _fallbackToCache(
    bool allowDefault,
  ) async {
    final cacheResult = await _tryCache();
    if (cacheResult.isRight()) {
      final (coords, placeName) =
          cacheResult.getOrElse(() => (_defaultFallbackLocation, null));
      return Right(ResolvedLocation(
        coordinates: coords,
        source: LocationSource.cached,
        placeName: placeName,
      ));
    }

    if (allowDefault) {
      return Right(ResolvedLocation(
        coordinates: _defaultFallbackLocation,
        source: LocationSource.defaultFallback,
      ));
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

  /// Maximum age for cached manual locations before requiring GPS refresh.
  ///
  /// Set to 1 hour to balance user convenience (don't lose manual location
  /// during short navigation) with freshness (don't use stale location from
  /// previous browser sessions on different devices).
  ///
  /// This prevents the bug where:
  /// 1. User sets manual location on desktop browser
  /// 2. Later opens app on phone browser (same domain = shared localStorage)
  /// 3. Stale manual location overrides phone's GPS
  static const Duration _maxCacheAge = Duration(hours: 1);

  @override
  Future<(LatLng, String?)?> loadCachedManualLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check version compatibility
      final version = prefs.getString(_versionKey);
      if (version != _currentVersion) {
        return null;
      }

      // Check if cached location has expired (>1 hour old)
      final timestampMs = prefs.getInt(_timestampKey);
      if (timestampMs != null) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        final age = DateTime.now().difference(cachedAt);
        if (age > _maxCacheAge) {
          debugPrint(
            'Cached manual location expired (age: ${age.inMinutes} minutes). Will use GPS.',
          );
          // Clear stale cache to prevent future checks
          await clearManualLocation();
          return null;
        }
      } else {
        // No timestamp means old-format cache - treat as expired
        debugPrint('Cached manual location has no timestamp. Will use GPS.');
        await clearManualLocation();
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
          final timestampMs = prefs.getInt(_timestampKey);
          final age = timestampMs != null
              ? DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(timestampMs))
              : Duration.zero;
          debugPrint(
            'Loaded cached manual location: ${GeographicUtils.logRedact(lat, lon)}${placeName != null ? ' ($placeName)' : ''} (age: ${age.inMinutes} min)',
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
