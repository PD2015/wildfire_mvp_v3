import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../models/home_state.dart';
import '../models/location_models.dart';
import '../services/location_resolver.dart';
import '../services/fire_risk_service.dart';
import '../features/location_picker/services/what3words_service.dart';
import '../features/location_picker/services/geocoding_service.dart';
import '../utils/location_utils.dart';
import '../config/feature_flags.dart';

/// Home screen controller managing location and fire risk data with ChangeNotifier
///
/// Implements robust state management for the home screen with proper error
/// handling, re-entrancy protection, and constitutional compliance. Integrates
/// with existing A1-A5 services using dependency injection.
///
/// Features:
/// - Multi-tier fallback for location and fire risk data
/// - 8-second global deadline inherited from A2 FireRiskService
/// - Re-entrancy protection to prevent overlapping requests
/// - Privacy-compliant logging with coordinate redaction
/// - Graceful error handling with retry capability
///
/// Constitutional compliance:
/// - C1: Clean architecture with dependency injection
/// - C2: Privacy-first logging (no raw coordinates)
/// - C5: Resilient error handling with visible retry options
class HomeController extends ChangeNotifier {
  static const Duration _globalDeadline = Duration(seconds: 8);

  final LocationResolver _locationResolver;
  final FireRiskService _fireRiskService;
  final What3wordsService? _what3wordsService;
  final GeocodingService? _geocodingService;

  HomeState _state = HomeStateLoading(startTime: DateTime.now());
  bool _isLoading = false;
  Timer? _timeoutTimer;

  // Track manual location details for source attribution
  String? _manualPlaceName;
  bool _isManualLocation = false;

  /// Current state of the home screen
  HomeState get state => _state;

  /// Whether the controller is currently loading data
  bool get isLoading => _isLoading;

  /// Creates a HomeController with required service dependencies
  ///
  /// [locationResolver] - Service for location resolution with fallback chain
  /// [fireRiskService] - Service for fire risk data with orchestrated fallback
  /// [what3wordsService] - Optional service for what3words address lookup
  /// [geocodingService] - Optional service for reverse geocoding (place names)
  HomeController({
    required LocationResolver locationResolver,
    required FireRiskService fireRiskService,
    What3wordsService? what3wordsService,
    GeocodingService? geocodingService,
  })  : _locationResolver = locationResolver,
        _fireRiskService = fireRiskService,
        _what3wordsService = what3wordsService,
        _geocodingService = geocodingService {
    developer.log('HomeController initialized', name: 'HomeController');
  }

  /// Gets test region center coordinates based on TEST_REGION environment variable
  ///
  /// Returns coordinates for the configured test region. Used when LocationResolver
  /// returns an error due to TEST_REGION being set (GPS disabled for testing).
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
      default: // 'scotland' or unknown
        return const LatLng(57.2, -3.8); // Aviemore, Scotland
    }
  }

  /// Loads current location and fire risk data
  ///
  /// Implements the complete data loading flow:
  /// 1. Get location via LocationResolver (GPS → cached → manual → default)
  /// 2. Get fire risk via FireRiskService (EFFIS → SEPA → cache → mock)
  /// 3. Update state with results or error conditions
  ///
  /// Includes re-entrancy protection and timeout handling.
  Future<void> load() async {
    if (_isLoading) {
      developer.log(
        'Load request ignored - already loading',
        name: 'HomeController',
      );
      return;
    }

    await _performLoad(isRetry: false);
  }

  /// Retries the data loading operation
  ///
  /// Similar to load() but marks the operation as a retry for better
  /// user feedback. Includes the same re-entrancy protection and timeout.
  Future<void> retry() async {
    if (_isLoading) {
      developer.log(
        'Retry request ignored - already loading',
        name: 'HomeController',
      );
      return;
    }

    await _performLoad(isRetry: true);
  }

  /// Sets a manual location and refreshes fire risk data
  ///
  /// Saves the provided location via LocationResolver and immediately
  /// fetches fresh fire risk data for the new coordinates.
  ///
  /// [location] - Validated coordinates to use for fire risk assessment
  /// [placeName] - Optional human-readable name for the location
  Future<void> setManualLocation(LatLng location, {String? placeName}) async {
    if (_isLoading) {
      developer.log(
        'Manual location request ignored - already loading',
        name: 'HomeController',
      );
      return;
    }

    try {
      // Save the manual location via LocationResolver
      await _locationResolver.saveManual(location, placeName: placeName);

      // Track that this is a manual location
      _isManualLocation = true;
      _manualPlaceName = placeName;

      developer.log(
        'Manual location set: ${LocationUtils.logRedact(location.latitude, location.longitude)}${placeName != null ? ' ($placeName)' : ''}',
        name: 'HomeController',
      );

      // Immediately refresh with the new location - pass the location directly
      // to bypass LocationResolver.getLatLon() which would try GPS first
      await _performLoad(isRetry: false, overrideLocation: location);
    } catch (e) {
      developer.log(
        'Failed to set manual location: $e',
        name: 'HomeController',
      );
      _updateState(
        HomeStateError(
          errorMessage: 'Failed to save location: ${e.toString()}',
          canRetry: true,
        ),
      );
    }
  }

  /// Refreshes current data (debounced for app lifecycle scenarios)
  ///
  /// Intended for use with app lifecycle events like returning to foreground.
  /// Implements simple debouncing to prevent excessive requests.
  Future<void> refresh() async {
    // Simple debouncing - only refresh if not currently loading
    if (!_isLoading) {
      await load();
    }
  }

  /// Core data loading implementation with timeout and error handling
  ///
  /// [overrideLocation] - If provided, skip LocationResolver and use this
  ///   location directly. Used when setManualLocation has just been called
  ///   to ensure the manual location is used instead of GPS.
  Future<void> _performLoad({
    required bool isRetry,
    LatLng? overrideLocation,
  }) async {
    _isLoading = true;

    // Capture last known location and timestamp from current state if available
    final LatLng? lastKnownLocation;
    final DateTime? lastKnownLocationTimestamp;

    switch (_state) {
      case HomeStateSuccess(:final location, :final lastUpdated):
        lastKnownLocation = location;
        lastKnownLocationTimestamp = lastUpdated;
      case HomeStateError(:final cachedLocation) when cachedLocation != null:
        lastKnownLocation = cachedLocation;
        // For error states, we don't have a reliable timestamp, so use null
        // This will cause isLocationStale to return false (no warning shown)
        lastKnownLocationTimestamp = null;
      default:
        lastKnownLocation = null;
        lastKnownLocationTimestamp = null;
    }

    _updateState(HomeStateLoading(
      isRetry: isRetry,
      startTime: DateTime.now(),
      lastKnownLocation: lastKnownLocation,
      lastKnownLocationTimestamp: lastKnownLocationTimestamp,
    ));

    // Set up global timeout
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_globalDeadline, () {
      if (_isLoading) {
        developer.log(
          'Global deadline exceeded (${_globalDeadline.inSeconds}s)',
          name: 'HomeController',
        );
        _handleTimeout();
      }
    });

    try {
      late final LatLng location;
      late final LocationSource locationSource;

      // Step 1: Use override location if provided (from setManualLocation)
      // Otherwise resolve location via LocationResolver
      if (overrideLocation != null) {
        location = overrideLocation;
        locationSource = LocationSource.manual;
        developer.log(
          'Using override location: ${LocationUtils.logRedact(location.latitude, location.longitude)} (source: manual)',
          name: 'HomeController',
        );
      } else {
        // Resolve location via LocationResolver (GPS → Cache → Default)
        final locationResult = await _locationResolver.getLatLon(
          allowDefault: true,
        );

        switch (locationResult) {
          case Right(:final value):
            location = value;
            // Determine location source based on whether it was manually set
            if (_isManualLocation) {
              locationSource = LocationSource.manual;
            } else {
              // GPS or cached from LocationResolver
              locationSource = LocationSource.gps;
            }
            developer.log(
              'Location resolved: ${LocationUtils.logRedact(location.latitude, location.longitude)} (source: $locationSource)',
              name: 'HomeController',
            );
          case Left(:final value):
            // If TEST_REGION is set, use test region center (same as MapController)
            // Otherwise, treat as error
            if (FeatureFlags.testRegion != 'scotland') {
              location = _getTestRegionCenter();
              locationSource = LocationSource.defaultFallback;
              developer.log(
                'Using test region: ${FeatureFlags.testRegion} at ${LocationUtils.logRedact(location.latitude, location.longitude)}',
                name: 'HomeController',
              );
            } else {
              developer.log(
                'Location resolution failed: $value',
                name: 'HomeController',
              );
              _finishLoading();
              _updateState(
                HomeStateError(
                  errorMessage:
                      'Location unavailable: ${_getLocationErrorMessage(value)}',
                  canRetry: true,
                ),
              );
              return;
            }
        }
      }

      // Step 2: Get fire risk data
      final riskResult = await _fireRiskService.getCurrent(
        lat: location.latitude,
        lon: location.longitude,
        deadline: _globalDeadline,
      );

      switch (riskResult) {
        case Right(:final value):
          developer.log(
            'Fire risk data obtained: ${value.level} from ${value.source}',
            name: 'HomeController',
          );
          developer.log(
            '🔥🔥🔥 FIRE RISK RESULT: ${value.level} from ${value.source} (FWI: ${value.fwi})',
            name: 'HomeController',
          );
          _finishLoading();
          _updateState(
            HomeStateSuccess(
              riskData: value,
              location: location,
              lastUpdated: DateTime.now(),
              locationSource: locationSource,
              placeName: _isManualLocation ? _manualPlaceName : null,
            ),
          );

          // Fetch what3words and geocoding data in parallel (non-blocking)
          // These enhance the display but don't block the core fire risk functionality
          _fetchLocationMetadata(location);

          // Reset manual location flag after successful load
          // (but keep place name for next retry if needed)
          _isManualLocation = false;
        case Left(:final value):
          developer.log(
            'Fire risk service failed: ${value.message}',
            name: 'HomeController',
          );
          _finishLoading();
          _updateState(
            HomeStateError(
              errorMessage: 'Fire risk data unavailable: ${value.message}',
              canRetry: true,
            ),
          );
      }
    } catch (e) {
      developer.log('Unexpected error during load: $e', name: 'HomeController');
      _finishLoading();
      _updateState(
        HomeStateError(
          errorMessage: 'Unexpected error: ${e.toString()}',
          canRetry: true,
        ),
      );
    }
  }

  /// Fetches what3words address and formatted location in parallel
  ///
  /// This is a non-blocking operation that enhances the display after
  /// the core fire risk data has loaded. Updates state via copyWith
  /// as each service responds.
  ///
  /// Graceful degradation: if services are not injected or fail,
  /// the corresponding fields remain null.
  void _fetchLocationMetadata(LatLng location) {
    // Mark loading states if services are available
    final currentState = _state;
    if (currentState is! HomeStateSuccess) return;

    // Start with loading indicators for available services
    if (_what3wordsService != null || _geocodingService != null) {
      _updateState(currentState.copyWith(
        isWhat3wordsLoading: _what3wordsService != null,
        isGeocodingLoading: _geocodingService != null,
      ));
    }

    // Fetch what3words address (if service available)
    if (_what3wordsService != null) {
      _what3wordsService!
          .convertTo3wa(
        lat: location.latitude,
        lon: location.longitude,
      )
          .then((result) {
        final state = _state;
        if (state is HomeStateSuccess) {
          switch (result) {
            case Right(:final value):
              developer.log(
                'What3words resolved for ${LocationUtils.logRedact(location.latitude, location.longitude)}',
                name: 'HomeController',
              );
              // NOTE: Never log the actual what3words address (privacy - C2)
              _updateState(state.copyWith(
                what3words: value.displayFormat,
                isWhat3wordsLoading: false,
              ));
            case Left(:final value):
              developer.log(
                'What3words failed: ${value.userMessage}',
                name: 'HomeController',
              );
              _updateState(state.copyWith(
                isWhat3wordsLoading: false,
              ));
          }
        }
      });
    }

    // Fetch formatted location via reverse geocoding (if service available)
    if (_geocodingService != null) {
      _geocodingService!
          .reverseGeocode(
        lat: location.latitude,
        lon: location.longitude,
      )
          .then((result) {
        final state = _state;
        if (state is HomeStateSuccess) {
          switch (result) {
            case Right(:final value):
              developer.log(
                'Geocoding resolved: $value',
                name: 'HomeController',
              );
              _updateState(state.copyWith(
                formattedLocation: value,
                isGeocodingLoading: false,
              ));
            case Left(:final value):
              developer.log(
                'Geocoding failed: $value',
                name: 'HomeController',
              );
              _updateState(state.copyWith(
                isGeocodingLoading: false,
              ));
          }
        }
      });
    }
  }

  /// Handles global timeout scenario
  void _handleTimeout() {
    if (_isLoading) {
      developer.log(
        'Operation timed out after ${_globalDeadline.inSeconds}s',
        name: 'HomeController',
      );
      _finishLoading();
      _updateState(
        HomeStateError(
          errorMessage:
              'Request timed out after ${_globalDeadline.inSeconds} seconds',
          canRetry: true,
        ),
      );
    }
  }

  /// Cleans up loading state and timers
  void _finishLoading() {
    _isLoading = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Updates state and notifies listeners
  void _updateState(HomeState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Converts LocationError enum to human-readable message
  String _getLocationErrorMessage(LocationError error) {
    switch (error) {
      case LocationError.permissionDenied:
        return 'Location permission denied';
      case LocationError.gpsUnavailable:
        return 'GPS unavailable or disabled';
      case LocationError.timeout:
        return 'Location request timed out';
      case LocationError.invalidInput:
        return 'Invalid location input';
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    developer.log('HomeController disposed', name: 'HomeController');
    super.dispose();
  }
}
