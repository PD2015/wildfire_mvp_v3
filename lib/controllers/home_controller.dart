import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../models/home_state.dart';
import '../models/location_models.dart';
import '../services/location_resolver.dart';
import '../services/fire_risk_service.dart';
import '../utils/location_utils.dart';

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

  HomeState _state = HomeStateLoading(startTime: DateTime.now());
  bool _isLoading = false;
  Timer? _timeoutTimer;

  /// Current state of the home screen
  HomeState get state => _state;

  /// Whether the controller is currently loading data
  bool get isLoading => _isLoading;

  /// Creates a HomeController with required service dependencies
  ///
  /// [locationResolver] - Service for location resolution with fallback chain
  /// [fireRiskService] - Service for fire risk data with orchestrated fallback
  HomeController({
    required LocationResolver locationResolver,
    required FireRiskService fireRiskService,
  })  : _locationResolver = locationResolver,
        _fireRiskService = fireRiskService {
    developer.log('HomeController initialized', name: 'HomeController');
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
      developer.log('Load request ignored - already loading',
          name: 'HomeController');
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
      developer.log('Retry request ignored - already loading',
          name: 'HomeController');
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
      developer.log('Manual location request ignored - already loading',
          name: 'HomeController');
      return;
    }

    try {
      // Save the manual location via LocationResolver
      await _locationResolver.saveManual(location, placeName: placeName);
      developer.log(
          'Manual location set: ${LocationUtils.logRedact(location.latitude, location.longitude)}${placeName != null ? ' ($placeName)' : ''}',
          name: 'HomeController');

      // Immediately refresh with the new location
      await _performLoad(isRetry: false);
    } catch (e) {
      developer.log('Failed to set manual location: $e',
          name: 'HomeController');
      _updateState(HomeStateError(
        errorMessage: 'Failed to save location: ${e.toString()}',
        canRetry: true,
      ));
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
  Future<void> _performLoad({required bool isRetry}) async {
    _isLoading = true;
    _updateState(HomeStateLoading(
      isRetry: isRetry,
      startTime: DateTime.now(),
    ));

    // Set up global timeout
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_globalDeadline, () {
      if (_isLoading) {
        developer.log(
            'Global deadline exceeded (${_globalDeadline.inSeconds}s)',
            name: 'HomeController');
        _handleTimeout();
      }
    });

    try {
      // Step 1: Resolve location
      final locationResult =
          await _locationResolver.getLatLon(allowDefault: true);

      late final LatLng location;
      switch (locationResult) {
        case Right(:final value):
          location = value;
          developer.log(
              'Location resolved: ${LocationUtils.logRedact(location.latitude, location.longitude)}',
              name: 'HomeController');
        case Left(:final value):
          developer.log('Location resolution failed: $value',
              name: 'HomeController');
          _finishLoading();
          _updateState(HomeStateError(
            errorMessage:
                'Location unavailable: ${_getLocationErrorMessage(value)}',
            canRetry: true,
          ));
          return;
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
              name: 'HomeController');
          print('🔥🔥🔥 FIRE RISK RESULT: ${value.level} from ${value.source} (FWI: ${value.fwi})');
          _finishLoading();
          _updateState(HomeStateSuccess(
            riskData: value,
            location: location,
            lastUpdated: DateTime.now(),
          ));
        case Left(:final value):
          developer.log('Fire risk service failed: ${value.message}',
              name: 'HomeController');
          _finishLoading();
          _updateState(HomeStateError(
            errorMessage: 'Fire risk data unavailable: ${value.message}',
            canRetry: true,
          ));
      }
    } catch (e) {
      developer.log('Unexpected error during load: $e', name: 'HomeController');
      _finishLoading();
      _updateState(HomeStateError(
        errorMessage: 'Unexpected error: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Handles global timeout scenario
  void _handleTimeout() {
    if (_isLoading) {
      developer.log('Operation timed out after ${_globalDeadline.inSeconds}s',
          name: 'HomeController');
      _finishLoading();
      _updateState(HomeStateError(
        errorMessage:
            'Request timed out after ${_globalDeadline.inSeconds} seconds',
        canRetry: true,
      ));
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
