import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/api_error.dart';
import '../models/burnt_area.dart';
import '../models/fire_data_mode.dart';
import '../models/lat_lng_bounds.dart';
import '../models/location_models.dart';
import 'effis_burnt_area_service.dart';

/// Cached wrapper for EffisBurntAreaService
///
/// Implements a bundle-first caching strategy:
/// - Both current (2025) and historical (2024) years load from bundled assets
/// - Bundles are updated weekly via GitHub Actions
/// - Live API fallback only if bundle >9 days old AND bundle load fails
///
/// This provides instant data loading for users while still getting fresh data
/// through weekly automated updates.
///
/// Asset location: assets/cache/burnt_areas_{year}_uk.json
/// Bundle format: { year, region, generatedAt, features[] }
///
/// Part of 021-live-fire-data feature implementation.
class CachedBurntAreaService implements EffisBurntAreaService {
  /// The underlying live service for fallback
  final EffisBurntAreaService _liveService;

  /// Cache of data by year (loaded from assets)
  final Map<int, List<BurntArea>> _dataCache = {};

  /// Cached bundle metadata (generatedAt timestamp) by year
  final Map<int, DateTime> _bundleTimestamps = {};

  /// Staleness threshold - if bundle is older than this, try live API as fallback
  static const Duration stalenessThreshold = Duration(days: 9);

  /// Bundled years - dynamically computed from current date
  /// Current year and previous year are always bundled
  static Set<int> get bundledYears {
    final currentYear = DateTime.now().year;
    return {currentYear - 1, currentYear};
  }

  /// Asset path pattern for bundled data
  static const String _assetPathPattern =
      'assets/cache/burnt_areas_{year}_uk.json';

  CachedBurntAreaService({required EffisBurntAreaService liveService})
      : _liveService = liveService;

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
    int? maxFeatures,
  }) async {
    final targetYear = seasonFilter.year;

    // Strategy: Bundle-first for ALL years
    // 1. Try to load from bundled asset (instant)
    // 2. If bundle fails OR is stale (>9 days), try live API as fallback

    debugPrint(
      '🗺️ CachedBurntAreaService: Loading $targetYear (${seasonFilter.displayLabel}) from bundle',
    );

    final bundleResult = await _loadFromAsset(targetYear, bounds);

    return bundleResult.fold(
      (bundleError) async {
        // Bundle failed to load - try live API
        debugPrint(
          '🗺️ CachedBurntAreaService: Bundle failed, trying live API: ${bundleError.message}',
        );
        return _liveService.getBurntAreas(
          bounds: bounds,
          seasonFilter: seasonFilter,
          timeout: timeout,
          maxRetries: maxRetries,
          maxFeatures: maxFeatures,
        );
      },
      (bundleData) async {
        // Bundle loaded successfully - check if stale
        final bundleTimestamp = _bundleTimestamps[targetYear];

        // Check staleness - only if we have a timestamp
        if (bundleTimestamp != null) {
          final age = DateTime.now().difference(bundleTimestamp);
          if (age > stalenessThreshold) {
            debugPrint(
              '🗺️ CachedBurntAreaService: Bundle is stale (${bundleTimestamp.toIso8601String()}), trying live API',
            );

            // Try live API, but fall back to bundle data if it fails
            final liveResult = await _liveService.getBurntAreas(
              bounds: bounds,
              seasonFilter: seasonFilter,
              timeout: timeout,
              maxRetries: maxRetries,
              maxFeatures: maxFeatures,
            );

            return liveResult.fold(
              (liveError) {
                // Live failed, return bundle data (better than nothing)
                debugPrint(
                  '🗺️ CachedBurntAreaService: Live API failed, using stale bundle: ${liveError.message}',
                );
                return Right(bundleData);
              },
              (liveData) {
                debugPrint(
                  '🗺️ CachedBurntAreaService: Live API success, returning ${liveData.length} areas',
                );
                return Right(liveData);
              },
            );
          }
        }

        // Bundle is fresh (or no timestamp) - return it directly
        debugPrint(
          '🗺️ CachedBurntAreaService: Bundle is fresh, returning ${bundleData.length} areas',
        );
        return Right(bundleData);
      },
    );
  }

  /// Load data from bundled asset file
  ///
  /// Returns cached data filtered to the requested bounds.
  /// Loads from asset only once per year, then caches in memory.
  /// Also parses and caches the generatedAt timestamp for staleness checks.
  Future<Either<ApiError, List<BurntArea>>> _loadFromAsset(
    int year,
    LatLngBounds bounds,
  ) async {
    try {
      // Check memory cache first
      if (!_dataCache.containsKey(year)) {
        final assetPath = _assetPathPattern.replaceAll(
          '{year}',
          year.toString(),
        );
        debugPrint('🗺️ CachedBurntAreaService: Loading asset $assetPath');

        final jsonString = await rootBundle.loadString(assetPath);
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;

        // Parse and cache the generatedAt timestamp
        final generatedAtStr = jsonData['generatedAt'] as String?;
        if (generatedAtStr != null) {
          final generatedAt = DateTime.tryParse(generatedAtStr);
          if (generatedAt != null) {
            _bundleTimestamps[year] = generatedAt;
            debugPrint(
              '🗺️ CachedBurntAreaService: Bundle generated at $generatedAtStr',
            );
          }
        }

        final features = jsonData['features'] as List<dynamic>;

        final burntAreas = features.map((feature) {
          final f = feature as Map<String, dynamic>;
          return _parseBurntAreaFromAsset(f, year);
        }).toList();

        _dataCache[year] = burntAreas;
        debugPrint(
          '🗺️ CachedBurntAreaService: Loaded ${burntAreas.length} burnt areas for $year',
        );
      }

      // Filter to requested bounds
      final allAreas = _dataCache[year]!;
      final filtered = allAreas.where((area) {
        final centroid = area.centroid;
        return _isInBounds(centroid, bounds);
      }).toList();

      debugPrint(
        '🗺️ CachedBurntAreaService: Returning ${filtered.length} of ${allAreas.length} areas within bounds',
      );
      return Right(filtered);
    } catch (e) {
      debugPrint('🗺️ CachedBurntAreaService: Error loading asset: $e');
      return Left(
        ApiError(
          message: 'Failed to load cached burnt area data: $e',
          statusCode: null,
        ),
      );
    }
  }

  /// Parse a burnt area from the bundled asset JSON format
  BurntArea _parseBurntAreaFromAsset(Map<String, dynamic> feature, int year) {
    final id = feature['id'].toString();
    final fireDateStr = feature['fireDate'] as String;
    final areaHa = (feature['areaHa'] as num?)?.toDouble() ?? 0.0;
    final province = feature['province'] as String?;
    final coords = feature['coords'] as List<dynamic>;

    // Parse coordinates (format: [[lat, lon], [lat, lon], ...])
    final boundaryPoints = coords.map((coord) {
      final c = coord as List<dynamic>;
      return LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble());
    }).toList();

    // Parse fire date
    final fireDate =
        DateTime.tryParse(fireDateStr)?.toUtc() ?? DateTime.now().toUtc();

    // Create land cover breakdown with province if available
    Map<String, double>? landCover;
    if (province != null) {
      landCover = {'province': 1.0}; // Store province info
    }

    return BurntArea(
      id: id,
      boundaryPoints: boundaryPoints,
      areaHectares: areaHa,
      fireDate: fireDate,
      seasonYear: year,
      landCoverBreakdown: landCover,
      isSimplified: false,
    );
  }

  /// Check if a point is within the given bounds
  bool _isInBounds(LatLng point, LatLngBounds bounds) {
    return point.latitude >= bounds.southwest.latitude &&
        point.latitude <= bounds.northeast.latitude &&
        point.longitude >= bounds.southwest.longitude &&
        point.longitude <= bounds.northeast.longitude;
  }

  /// Clear the memory cache (useful for testing)
  void clearCache() {
    _dataCache.clear();
    _bundleTimestamps.clear();
  }

  /// Check if a year has bundled data available
  static bool hasBundledData(int year) {
    return bundledYears.contains(year);
  }

  /// Get the bundle timestamp for a year (if loaded)
  DateTime? getBundleTimestamp(int year) {
    return _bundleTimestamps[year];
  }

  /// Check if the bundle for a year is stale
  bool isBundleStale(int year) {
    final timestamp = _bundleTimestamps[year];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) > stalenessThreshold;
  }
}
