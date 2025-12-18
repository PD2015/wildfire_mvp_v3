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
/// Implements a hybrid caching strategy:
/// - Historical years (e.g., 2024): Load from bundled asset (instant, offline)
/// - Current season (e.g., 2025): Fetch live from EFFIS API
///
/// This is efficient because historical fire data doesn't change - once a fire
/// season ends, that year's data is frozen and can be bundled with the app.
///
/// Asset location: assets/cache/burnt_areas_{year}_uk.json
///
/// Part of 021-live-fire-data feature implementation.
class CachedBurntAreaService implements EffisBurntAreaService {
  /// The underlying live service for current season data
  final EffisBurntAreaService _liveService;

  /// Cache of historical data by year (loaded from assets)
  final Map<int, List<BurntArea>> _historicalCache = {};

  /// Years that are considered historical (bundled as assets)
  /// Add new years here as fire seasons end
  static const Set<int> historicalYears = {2024};

  /// Asset path pattern for historical data
  static const String _assetPathPattern =
      'assets/cache/burnt_areas_{year}_uk.json';

  CachedBurntAreaService({
    required EffisBurntAreaService liveService,
  }) : _liveService = liveService;

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
    int? maxFeatures,
  }) async {
    final targetYear = seasonFilter.year;

    // Check if this is a historical year (bundled data available)
    if (historicalYears.contains(targetYear)) {
      debugPrint(
          '🗺️ CachedBurntAreaService: Loading $targetYear from bundled asset');
      return _loadFromAsset(targetYear, bounds);
    }

    // Current season - use live service
    debugPrint(
        '🗺️ CachedBurntAreaService: Fetching $targetYear from live EFFIS');
    return _liveService.getBurntAreas(
      bounds: bounds,
      seasonFilter: seasonFilter,
      timeout: timeout,
      maxRetries: maxRetries,
      maxFeatures: maxFeatures,
    );
  }

  /// Load historical data from bundled asset file
  ///
  /// Returns cached data filtered to the requested bounds.
  /// Loads from asset only once per year, then caches in memory.
  Future<Either<ApiError, List<BurntArea>>> _loadFromAsset(
    int year,
    LatLngBounds bounds,
  ) async {
    try {
      // Check memory cache first
      if (!_historicalCache.containsKey(year)) {
        final assetPath =
            _assetPathPattern.replaceAll('{year}', year.toString());
        debugPrint('🗺️ CachedBurntAreaService: Loading asset $assetPath');

        final jsonString = await rootBundle.loadString(assetPath);
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        final features = jsonData['features'] as List<dynamic>;

        final burntAreas = features.map((feature) {
          final f = feature as Map<String, dynamic>;
          return _parseBurntAreaFromAsset(f, year);
        }).toList();

        _historicalCache[year] = burntAreas;
        debugPrint(
            '🗺️ CachedBurntAreaService: Loaded ${burntAreas.length} burnt areas for $year');
      }

      // Filter to requested bounds
      final allAreas = _historicalCache[year]!;
      final filtered = allAreas.where((area) {
        final centroid = area.centroid;
        return _isInBounds(centroid, bounds);
      }).toList();

      debugPrint(
          '🗺️ CachedBurntAreaService: Returning ${filtered.length} of ${allAreas.length} areas within bounds');
      return Right(filtered);
    } catch (e) {
      debugPrint('🗺️ CachedBurntAreaService: Error loading asset: $e');
      return Left(ApiError(
        message: 'Failed to load cached burnt area data: $e',
        statusCode: null,
      ));
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
      return LatLng(
        (c[0] as num).toDouble(),
        (c[1] as num).toDouble(),
      );
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
    _historicalCache.clear();
  }

  /// Check if a year has cached data available
  static bool hasCachedData(int year) {
    return historicalYears.contains(year);
  }
}
