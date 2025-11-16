import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';
import 'package:wildfire_mvp_v3/models/bottom_sheet_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart' as bounds;
import 'package:wildfire_mvp_v3/services/fire_location_service.dart';
import 'package:wildfire_mvp_v3/services/fire_risk_service.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/utils/distance_calculator.dart';
import 'package:wildfire_mvp_v3/config/feature_flags.dart';

/// MapController manages state for MapScreen
///
/// Orchestrates location resolution, fire data fetching, risk assessment,
/// and bottom sheet state for fire incident details.
class MapController extends ChangeNotifier {
  final LocationResolver _locationResolver;
  final FireLocationService _fireLocationService;
  final FireRiskService _fireRiskService;

  MapState _state = const MapLoading();
  BottomSheetState _bottomSheetState = const BottomSheetHidden();

  MapState get state => _state;
  BottomSheetState get bottomSheetState => _bottomSheetState;

  MapController({
    required LocationResolver locationResolver,
    required FireLocationService fireLocationService,
    required FireRiskService fireRiskService,
  })  : _locationResolver = locationResolver,
        _fireLocationService = fireLocationService,
        _fireRiskService = fireRiskService;

  /// Get test region coordinates based on TEST_REGION environment variable
  static LatLng _getTestRegionCenter() {
    final region = FeatureFlags.testRegion.toLowerCase();

    switch (region) {
      case 'portugal':
        return const LatLng(39.6, -9.1); // Lisbon area
      case 'spain':
        return const LatLng(40.4, -3.7); // Madrid area
      case 'greece':
        return const LatLng(37.9, 23.7); // Athens area
      case 'california':
        return const LatLng(36.7, -119.4); // Central California
      case 'australia':
        return const LatLng(-33.8, 151.2); // Sydney area
      case 'scotland':
      default:
        return const LatLng(57.2, -3.8); // Aviemore, Scotland
    }
  }

  /// Initialize controller and load initial map data
  Future<void> initialize() async {
    _state = const MapLoading();
    notifyListeners();

    try {
      // Step 1: Resolve location
      final locationResult = await _locationResolver.getLatLon();

      final LatLng centerLocation = locationResult.fold((error) {
        // Use test region based on environment variable
        final testCenter = _getTestRegionCenter();
        debugPrint(
          '🗺️ Using test region: ${FeatureFlags.testRegion} at ${testCenter.latitude},${testCenter.longitude}',
        );
        return testCenter;
      }, (location) => location);

      // Step 2: Create default bbox around location (~220km radius to cover all of Scotland)
      final mapBounds = bounds.LatLngBounds(
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
      debugPrint(
        '🗺️ MapController: Fetching fires for bounds: SW(${mapBounds.southwest.latitude},${mapBounds.southwest.longitude}) NE(${mapBounds.northeast.latitude},${mapBounds.northeast.longitude})',
      );
      final firesResult = await _fireLocationService.getActiveFires(mapBounds);

      firesResult.fold(
        (error) {
          debugPrint(
            '🗺️ MapController: Error loading fires: ${error.message}',
          );
          _state = MapError(
            message: 'Failed to load fire data: ${error.message}',
            lastKnownLocation: centerLocation,
          );
        },
        (incidents) {
          debugPrint(
            '🗺️ MapController: Loaded ${incidents.length} fire incidents',
          );
          if (incidents.isNotEmpty) {
            debugPrint(
              '🗺️ MapController: First incident: ${incidents.first.description} at ${incidents.first.location.latitude},${incidents.first.location.longitude}',
            );
            debugPrint(
              '🗺️ MapController: Freshness: ${incidents.first.freshness}, Source: ${incidents.first.source}',
            );
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
      _state = MapError(message: 'Initialization failed: $e');
      notifyListeners();
    }
  }

  /// Refresh fire data for visible map region
  Future<void> refreshMapData(bounds.LatLngBounds visibleBounds) async {
    final previousState = _state;

    _state = const MapLoading();
    notifyListeners();

    try {
      final firesResult = await _fireLocationService.getActiveFires(
        visibleBounds,
      );

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
            _state = MapError(message: 'Failed to refresh: ${error.message}');
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

  /// Show fire incident details in bottom sheet
  Future<void> showFireDetails(String fireIncidentId) async {
    debugPrint('🗒️ MapController: Showing fire details for $fireIncidentId');

    _bottomSheetState = BottomSheetLoading(
      fireIncidentId: fireIncidentId,
      loadingMessage: 'Loading fire details...',
    );
    notifyListeners();

    try {
      // Find the fire incident in current state
      if (_state is! MapSuccess) {
        _bottomSheetState = BottomSheetError(
          message: 'Map data not available. Please wait for map to load.',
        );
        notifyListeners();
        return;
      }

      final mapState = _state as MapSuccess;
      final fireIncident = mapState.incidents.firstWhere(
        (incident) => incident.id == fireIncidentId,
        orElse: () => throw Exception('Fire incident not found'),
      );

      // Get user location for distance calculation
      LatLng? userLocation;
      String? distanceAndDirection;

      try {
        final locationResult = await _locationResolver.getLatLon();
        locationResult.fold(
          (error) {
            debugPrint(
                '🗒️ MapController: Could not get user location for distance: $error');
          },
          (location) {
            userLocation = location;
            distanceAndDirection =
                DistanceCalculator.formatDistanceAndDirection(
                    location, fireIncident.location);
          },
        );
      } catch (e) {
        debugPrint('🗒️ MapController: Error calculating distance: $e');
      }

      _bottomSheetState = BottomSheetLoaded(
        fireIncident: fireIncident,
        userLocation: userLocation,
        distanceAndDirection: distanceAndDirection,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('🗒️ MapController: Error showing fire details: $e');
      _bottomSheetState = BottomSheetError(
        message: 'Failed to load fire details: $e',
      );
      notifyListeners();
    }
  }

  /// Hide bottom sheet
  void hideBottomSheet() {
    debugPrint('🗒️ MapController: Hiding bottom sheet');
    _bottomSheetState = const BottomSheetHidden();
    notifyListeners();
  }

  /// Retry loading fire details (for error state)
  Future<void> retryLoadFireDetails() async {
    if (_bottomSheetState is BottomSheetError) {
      final errorState = _bottomSheetState as BottomSheetError;
      if (errorState.fireIncidentId != null) {
        await showFireDetails(errorState.fireIncidentId!);
      }
    }
  }

  @override
  void dispose() {
    // Clean up any listeners or resources
    super.dispose();
  }
}
