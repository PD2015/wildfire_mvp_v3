import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/burnt_area.dart';
import '../models/location_models.dart';
import '../models/lat_lng_bounds.dart';
import '../models/fire_data_mode.dart';
import 'effis_burnt_area_service.dart';

/// Mock implementation of EffisBurntAreaService for development and fallback
///
/// Loads burnt area data from assets/mock/mock_burnt_areas.json.
/// Used when live EFFIS API is unavailable or for testing.
///
/// Data format matches the cache bundle format:
/// ```json
/// {
///   "burntAreas": [
///     {
///       "id": "mock_ba_001",
///       "fireDate": "2025-04-15",
///       "areaHa": 125.5,
///       "province": "Highland",
///       "coords": [[57.5, -5.0], [57.51, -5.0], ...],
///       "isMockData": true
///     }
///   ]
/// }
/// ```
///
/// Mirrors the live service behavior:
/// - BurntAreaSeasonFilter.thisSeason → returns burnt areas from current year
/// - BurntAreaSeasonFilter.lastSeason → returns burnt areas from previous year
///
/// Part of 021-live-fire-data feature implementation.
class MockEffisBurntAreaService implements EffisBurntAreaService {
  List<BurntArea>? _cachedBurntAreas;

  /// Injectable clock for testing - defaults to DateTime.now()
  final DateTime Function() _clock;

  MockEffisBurntAreaService({DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now());

  /// Load and parse mock burnt area data from assets
  ///
  /// Uses bundle format parsing (same as CachedBurntAreaService) for consistency.
  Future<List<BurntArea>> _loadMockData() async {
    if (_cachedBurntAreas != null) {
      return _cachedBurntAreas!;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/mock/mock_burnt_areas.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final features = jsonData['burntAreas'] as List<dynamic>;

      _cachedBurntAreas = features.map((feature) {
        return _parseBurntAreaFromAsset(feature as Map<String, dynamic>);
      }).toList();

      return _cachedBurntAreas!;
    } catch (e) {
      // Mock service should never fail - return empty list
      return [];
    }
  }

  /// Parse a burnt area from the bundle JSON format
  ///
  /// Bundle format uses [lat, lon] coordinate order (same as cache bundles).
  BurntArea _parseBurntAreaFromAsset(Map<String, dynamic> feature) {
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

    // Parse fire date and extract season year
    final fireDate =
        DateTime.tryParse(fireDateStr)?.toUtc() ?? DateTime.now().toUtc();
    final seasonYear = fireDate.year;

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
      seasonYear: seasonYear,
      landCoverBreakdown: landCover,
      isSimplified: false,
    );
  }

  @override
  Future<Either<ApiError, List<BurntArea>>> getBurntAreas({
    required LatLngBounds bounds,
    required BurntAreaSeasonFilter seasonFilter,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
    int? maxFeatures,
  }) async {
    final allBurntAreas = await _loadMockData();
    final now = _clock();

    // Calculate target year based on current time (mirrors live service)
    // Live service uses seasonFilter.year which is based on DateTime.now()
    final targetYear = switch (seasonFilter) {
      BurntAreaSeasonFilter.thisSeason => now.year,
      BurntAreaSeasonFilter.lastSeason => now.year - 1,
    };

    // Filter by bounding box and season year (mirrors EFFIS WFS CQL_FILTER=year=YYYY)
    var filtered = allBurntAreas.where((area) {
      // Check if centroid is within bounds
      final inBounds = bounds.contains(area.centroid);
      // Check if year matches filter
      final matchesYear = area.seasonYear == targetYear;
      return inBounds && matchesYear;
    }).toList();

    // Apply maxFeatures limit if specified (mirrors WFS maxFeatures parameter)
    if (maxFeatures != null && filtered.length > maxFeatures) {
      filtered = filtered.take(maxFeatures).toList();
    }

    // Always return Right (mock service never fails)
    return Right(filtered);
  }
}
