import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';

/// Mock fire service that loads data from assets/mock/active_fires.json
/// 
/// Never-fail fallback for development and offline testing.
class MockFireService implements FireLocationService {
  List<FireIncident>? _cachedIncidents;

  /// Load and parse mock data from assets
  Future<List<FireIncident>> _loadMockData() async {
    if (_cachedIncidents != null) {
      return _cachedIncidents!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/mock/active_fires.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final features = jsonData['features'] as List<dynamic>;

      _cachedIncidents = features.map((feature) {
        return FireIncident.fromJson(feature as Map<String, dynamic>).copyWith(
          source: DataSource.mock,
          freshness: Freshness.mock,
        );
      }).toList();

      return _cachedIncidents!;
    } catch (e) {
      // Even mock service shouldn't fail - return empty list
      return [];
    }
  }

  @override
  Future<Either<ApiError, List<FireIncident>>> getActiveFires(
    LatLngBounds bounds,
  ) async {
    final allIncidents = await _loadMockData();

    // Filter by bbox if incidents are available
    final filtered = allIncidents.where((incident) {
      return bounds.contains(incident.location);
    }).toList();

    // Always return Right (never fails)
    return Right(filtered);
  }
}
