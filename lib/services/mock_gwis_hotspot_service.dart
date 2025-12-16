import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dartz/dartz.dart';
import '../models/api_error.dart';
import '../models/hotspot.dart';
import '../models/lat_lng_bounds.dart';
import '../models/fire_data_mode.dart';
import 'hotspot_service.dart';

/// Mock implementation of HotspotService for development and fallback.
///
/// Loads hotspot data from assets/mock/hotspots.json.
/// Used when live APIs (FIRMS, GWIS) are unavailable or for testing.
///
/// Mirrors the live service behavior:
/// - HotspotTimeFilter.today → returns hotspots from last 24 hours
/// - HotspotTimeFilter.thisWeek → returns hotspots from last 7 days
///
/// Mock data dates are interpreted relative to current date to simulate
/// the GWIS viirs.hs.today and viirs.hs.week layer behavior.
///
/// Part of 021-live-fire-data feature implementation.
class MockHotspotService implements HotspotService {
  List<Hotspot>? _cachedHotspots;

  /// Injectable clock for testing - defaults to DateTime.now()
  final DateTime Function() _clock;

  MockHotspotService({DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now());

  @override
  String get serviceName => 'Mock';

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
    final now = _clock();

    // Filter by bounding box
    var filtered = allHotspots.where((hotspot) {
      return bounds.contains(hotspot.location);
    }).toList();

    // Filter by time - mirrors GWIS layer behavior:
    // viirs.hs.today = last 24 hours
    // viirs.hs.week = last 7 days
    switch (timeFilter) {
      case HotspotTimeFilter.today:
        final cutoff = now.subtract(const Duration(hours: 24));
        filtered = filtered.where((h) => h.detectedAt.isAfter(cutoff)).toList();
      case HotspotTimeFilter.thisWeek:
        final cutoff = now.subtract(const Duration(days: 7));
        filtered = filtered.where((h) => h.detectedAt.isAfter(cutoff)).toList();
    }

    // Always return Right (mock service never fails)
    return Right(filtered);
  }
}

/// Backwards-compatible type alias for existing code.
/// @deprecated Use [MockHotspotService] instead.
typedef MockGwisHotspotService = MockHotspotService;
