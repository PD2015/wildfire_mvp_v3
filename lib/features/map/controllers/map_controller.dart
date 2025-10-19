import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart';
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// MapController manages state for MapScreen
///
/// Orchestrates location resolution, fire data fetching, risk assessment.
class MapController extends ChangeNotifier {
  final LocationResolver _locationResolver;
  final FireLocationService _fireLocationService;
  final FireRiskService _fireRiskService;

  MapState _state = const MapLoading();

  MapState get state => _state;

  MapController({
    required LocationResolver locationResolver,
    required FireLocationService fireLocationService,
    required FireRiskService fireRiskService,
  })  : _locationResolver = locationResolver,
        _fireLocationService = fireLocationService,
        _fireRiskService = fireRiskService;

  /// Initialize controller and load initial map data
  Future<void> initialize() async {
    _state = const MapLoading();
    notifyListeners();

    try {
      // Step 1: Resolve location
      final locationResult = await _locationResolver.getLatLon();

      final LatLng centerLocation = locationResult.fold(
        (error) {
          // Fallback to Scotland centroid if location fails
          return const LatLng(55.8642, -4.2518); // Glasgow area
        },
        (location) => location,
      );

      // Step 2: Create default bbox around location (~220km radius to cover all of Scotland)
      final bounds = LatLngBounds(
        southwest: LatLng(
          centerLocation.latitude - 2.0,
          centerLocation.longitude - 2.0,
        ),
        northeast: LatLng(
          centerLocation.latitude + 2.0,
          centerLocation.longitude + 2.0,
        ),
      );

      // Step 3: Fetch fire incidents
      print(
          '🗺️ MapController: Fetching fires for bounds: SW(${bounds.southwest.latitude},${bounds.southwest.longitude}) NE(${bounds.northeast.latitude},${bounds.northeast.longitude})');
      final firesResult = await _fireLocationService.getActiveFires(bounds);

      firesResult.fold(
        (error) {
          print('🗺️ MapController: Error loading fires: ${error.message}');
          _state = MapError(
            message: 'Failed to load fire data: ${error.message}',
            lastKnownLocation: centerLocation,
          );
        },
        (incidents) {
          print('🗺️ MapController: Loaded ${incidents.length} fire incidents');
          if (incidents.isNotEmpty) {
            print(
                '🗺️ MapController: First incident: ${incidents.first.description} at ${incidents.first.location.latitude},${incidents.first.location.longitude}');
            print(
                '🗺️ MapController: Freshness: ${incidents.first.freshness}, Source: ${incidents.first.source}');
          }
          _state = MapSuccess(
            incidents: incidents,
            centerLocation: centerLocation,
            freshness:
                incidents.isEmpty ? Freshness.live : incidents.first.freshness,
            lastUpdated: DateTime.now(),
          );
        },
      );

      notifyListeners();
    } catch (e) {
      _state = MapError(
        message: 'Initialization failed: $e',
      );
      notifyListeners();
    }
  }

  /// Refresh fire data for visible map region
  Future<void> refreshMapData(LatLngBounds visibleBounds) async {
    final previousState = _state;

    _state = const MapLoading();
    notifyListeners();

    try {
      final firesResult =
          await _fireLocationService.getActiveFires(visibleBounds);

      firesResult.fold(
        (error) {
          // Preserve previous data if available
          if (previousState is MapSuccess) {
            _state = MapError(
              message: 'Failed to refresh: ${error.message}',
              cachedIncidents: previousState.incidents,
              lastKnownLocation: previousState.centerLocation,
            );
          } else {
            _state = MapError(
              message: 'Failed to refresh: ${error.message}',
            );
          }
        },
        (incidents) {
          _state = MapSuccess(
            incidents: incidents,
            centerLocation: visibleBounds.center,
            freshness:
                incidents.isEmpty ? Freshness.live : incidents.first.freshness,
            lastUpdated: DateTime.now(),
          );
        },
      );

      notifyListeners();
    } catch (e) {
      _state = MapError(
        message: 'Refresh failed: $e',
        cachedIncidents:
            previousState is MapSuccess ? previousState.incidents : null,
        lastKnownLocation:
            previousState is MapSuccess ? previousState.centerLocation : null,
      );
      notifyListeners();
    }
  }

  /// Check fire risk at specific location
  Future<Either<String, dynamic>> checkRiskAt(LatLng location) async {
    try {
      final riskResult = await _fireRiskService.getCurrent(
        lat: location.latitude,
        lon: location.longitude,
      );

      return riskResult.fold(
        (error) => Left('Risk check failed: ${error.message}'),
        (fireRisk) => Right(fireRisk),
      );
    } catch (e) {
      return Left('Risk check error: $e');
    }
  }

  @override
  void dispose() {
    // Clean up any listeners or resources
    super.dispose();
  }
}
