// Mock implementation of ActiveFiresService for testing and development
// Provides realistic fire incident data when MAP_LIVE_DATA=false
// Part of Phase 2: Service Layer Implementation (Task 7)

import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:wildfire_mvp_v3/models/api_error.dart';
import 'package:wildfire_mvp_v3/models/active_fires_response.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/services/active_fires_service.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';

/// Mock implementation providing realistic test data for development
///
/// Generates deterministic fire incidents based on seed locations within
/// Scotland, with realistic confidence levels, FRP values, and detection times.
///
/// Used when MAP_LIVE_DATA environment variable is set to "false"
class MockActiveFiresService implements ActiveFiresService {
  /// Pre-generated fire incidents for consistent testing
  static final List<FireIncident> _mockIncidents = _generateMockIncidents();

  @override
  ServiceMetadata get metadata => ServiceMetadata(
        sourceType: DataSourceType.mock,
        description: 'Mock fire incident data for testing and development',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 15)),
        coverage: const LatLngBounds(
          southwest: LatLng(54.5, -8.5), // Scotland approximate bounds
          northeast: LatLng(60.9, 0.5),
        ),
        supportsRealTime: false,
        maxIncidentsPerRequest: 500,
      );

  @override
  Future<Either<ApiError, ActiveFiresResponse>> getIncidentsForViewport({
    required LatLngBounds bounds,
    double confidenceThreshold = 50.0,
    double minFrp = 0.0,
    Duration? deadline,
  }) async {
    try {
      // Simulate realistic network delay
      await Future.delayed(
          const Duration(milliseconds: 150 + 100)); // 250ms total

      // Validate input bounds
      if (!bounds.southwest.isValid || !bounds.northeast.isValid) {
        return Left(ApiError(
          message: 'Invalid viewport bounds: $bounds',
          statusCode: 400,
        ));
      }

      // Filter incidents within bounds and meeting criteria
      final filteredIncidents = _mockIncidents.where((incident) {
        return bounds.contains(incident.location) &&
            (incident.confidence ?? 0) >= confidenceThreshold &&
            (incident.frp ?? 0) >= minFrp;
      }).toList();

      // Convert our LatLngBounds to Google Maps bounds for response
      final gmapsBounds = gmaps.LatLngBounds(
        southwest:
            gmaps.LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
        northeast:
            gmaps.LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
      );

      // Create response with filtering metadata
      final response = ActiveFiresResponse(
        incidents: filteredIncidents,
        queriedBounds: gmapsBounds,
        responseTimeMs: 250, // Simulated response time
        dataSource: DataSource.mock,
        totalCount: filteredIncidents.length,
        timestamp: DateTime.now().toUtc(),
      );

      return Right(response);
    } catch (e) {
      return Left(ApiError(
        message: 'Mock service error: $e',
      ));
    }
  }

  @override
  Future<Either<ApiError, FireIncident>> getIncidentById({
    required String incidentId,
    Duration? deadline,
  }) async {
    try {
      // Simulate realistic network delay
      await Future.delayed(const Duration(milliseconds: 100));

      final incident = _mockIncidents.firstWhere(
        (incident) => incident.id == incidentId,
        orElse: () => throw StateError('Incident not found'),
      );

      return Right(incident);
    } on StateError {
      return Left(ApiError(
        message: 'Fire incident $incidentId not found',
        statusCode: 404,
      ));
    } catch (e) {
      return Left(ApiError(
        message: 'Failed to get incident: $e',
      ));
    }
  }

  @override
  Future<Either<ApiError, bool>> checkHealth() async {
    // Simulate health check delay
    await Future.delayed(const Duration(milliseconds: 50));
    return const Right(true); // Mock service is always healthy
  }

  /// Generate realistic mock fire incidents across Scotland
  static List<FireIncident> _generateMockIncidents() {
    final random = Random(42); // Fixed seed for deterministic results
    final incidents = <FireIncident>[];
    final now = DateTime.now().toUtc();

    // High-risk locations across Scotland with realistic scenarios
    const riskLocations = [
      // Highland wildfires (typical hotspots)
      _MockFireLocation(
        LatLng(57.2, -3.8), // Near Aviemore - Cairngorms
        'Highland Moorland Fire',
        intensity: 'high',
        baseConfidence: 90.0,
        baseFrp: 1500.0,
      ),
      _MockFireLocation(
        LatLng(56.8, -5.1), // Glen Coe area
        'Mountain Grassland Fire',
        intensity: 'moderate',
        baseConfidence: 75.0,
        baseFrp: 800.0,
      ),
      // Central Belt incidents
      _MockFireLocation(
        LatLng(55.9, -3.2), // Near Edinburgh
        'Urban Fringe Vegetation Fire',
        intensity: 'low',
        baseConfidence: 85.0,
        baseFrp: 300.0,
      ),
      _MockFireLocation(
        LatLng(55.8, -4.3), // Near Glasgow
        'Industrial Area Wildfire',
        intensity: 'moderate',
        baseConfidence: 80.0,
        baseFrp: 600.0,
      ),
      // Southern Scotland
      _MockFireLocation(
        LatLng(55.1, -3.4), // Borders region
        'Forest Edge Fire',
        intensity: 'high',
        baseConfidence: 95.0,
        baseFrp: 1800.0,
      ),
      // Western Islands
      _MockFireLocation(
        LatLng(56.5, -6.2), // Isle of Skye
        'Coastal Heathland Fire',
        intensity: 'moderate',
        baseConfidence: 70.0,
        baseFrp: 500.0,
      ),
      // Northern Scotland
      _MockFireLocation(
        LatLng(58.2, -4.1), // Sutherland
        'Remote Highland Fire',
        intensity: 'high', // Changed from 'very_high' to valid 'high'
        baseConfidence: 88.0,
        baseFrp: 2200.0,
      ),
    ];

    // Generate incidents from risk locations
    for (int i = 0; i < riskLocations.length; i++) {
      final location = riskLocations[i];

      // Add some random variation to coordinates (within ~500m)
      final latVariation = (random.nextDouble() - 0.5) * 0.01; // ±0.005°
      final lonVariation = (random.nextDouble() - 0.5) * 0.01;

      final adjustedLocation = LatLng(
        location.coordinates.latitude + latVariation,
        location.coordinates.longitude + lonVariation,
      );

      // Generate realistic detection time (last 1-6 hours)
      final hoursAgo = 1 + random.nextInt(5); // 1-5 hours ago
      final minutesAgo = random.nextInt(60); // 0-59 minutes
      final detectedAt = now.subtract(
        Duration(hours: hoursAgo, minutes: minutesAgo),
      );

      // Add confidence variation (±10%)
      final confidenceVariation = (random.nextDouble() - 0.5) * 20; // ±10%
      final confidence =
          (location.baseConfidence + confidenceVariation).clamp(50.0, 100.0);

      // Add FRP variation (±30%)
      final frpVariation = (random.nextDouble() - 0.5) * 0.6; // ±30%
      final frp = (location.baseFrp * (1 + frpVariation)).clamp(100.0, 5000.0);

      final incident = FireIncident(
        id: 'mock_fire_${i.toString().padLeft(3, '0')}',
        location: adjustedLocation,
        source: DataSource.mock,
        freshness: Freshness.mock,
        timestamp: detectedAt,
        detectedAt: detectedAt,
        intensity: location.intensity,
        confidence: confidence,
        frp: frp,
        sensorSource: 'MODIS', // Realistic sensor
        description:
            '${location.description} - ${LocationUtils.logRedact(adjustedLocation.latitude, adjustedLocation.longitude)}',
        lastUpdate: detectedAt.add(Duration(minutes: random.nextInt(30))),
      );

      incidents.add(incident);
    }

    // Sort by detection time (newest first)
    incidents.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

    return incidents;
  }
}

/// Helper class for mock fire location generation
class _MockFireLocation {
  final LatLng coordinates;
  final String description;
  final String intensity;
  final double baseConfidence;
  final double baseFrp;

  const _MockFireLocation(
    this.coordinates,
    this.description, {
    required this.intensity,
    required this.baseConfidence,
    required this.baseFrp,
  });
}
