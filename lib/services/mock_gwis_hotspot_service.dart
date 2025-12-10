import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/hotspot.dart';
import '../models/lat_lng_bounds.dart';
import '../models/fire_data_mode.dart';
import 'gwis_hotspot_service.dart';

/// Mock implementation of GwisHotspotService for development and fallback
///
/// Loads hotspot data from assets/mock/hotspots.json.
/// Used when live GWIS API is unavailable or for testing.
///
/// Part of 021-live-fire-data feature implementation.
class MockGwisHotspotService implements GwisHotspotService {
  List<Hotspot>? _cachedHotspots;

  /// Load and parse mock hotspot data from assets
  Future<List<Hotspot>> _loadMockData() async {
    if (_cachedHotspots != null) {
      return _cachedHotspots!;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/mock/hotspots.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final features = jsonData['features'] as List<dynamic>;

      _cachedHotspots = features.map((feature) {
        return Hotspot.fromJson(feature as Map<String, dynamic>);
      }).toList();

      return _cachedHotspots!;
    } catch (e) {
      // Mock service should never fail - return empty list
      return [];
    }
  }

  @override
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
    int maxRetries = 3,
  }) async {
    final allHotspots = await _loadMockData();

    // Filter by bounding box
    final filtered = allHotspots.where((hotspot) {
      return bounds.contains(hotspot.location);
    }).toList();

    // Always return Right (mock service never fails)
    return Right(filtered);
  }
}
