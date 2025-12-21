import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../models/location_display_state.dart';
import '../models/location_models.dart';
import '../features/location_picker/services/what3words_service.dart';
import '../features/location_picker/services/geocoding_service.dart';
import '../utils/location_utils.dart';
import 'location_resolver.dart';

/// Shared location state manager for consistent location handling across screens
///
/// Encapsulates all location-related logic that was previously duplicated in
/// HomeController and would have been in ReportFireController. Any screen that
/// needs to display location information can use this manager.
///
/// Features:
/// - GPS location fetching with timeout
/// - Manual location setting
/// - what3words address resolution
/// - Reverse geocoding for place names
/// - Consistent state management via LocationDisplayState
///
/// Usage:
/// ```dart
/// final manager = LocationStateManager(
///   locationResolver: locationResolver,
///   what3wordsService: what3wordsService,
///   geocodingService: geocodingService,
/// );
///
/// // Auto-fetch GPS on init
/// await manager.initialize();
///
/// // Listen for state changes
/// manager.addListener(() {
///   final state = manager.state;
///   // Update UI with LocationCard
/// });
/// ```
///
/// Constitutional compliance:
/// - C1: Clean separation of concerns
/// - C2: Privacy-compliant logging via LocationUtils.logRedact()
class LocationStateManager extends ChangeNotifier {
  final LocationResolver _locationResolver;
  final What3wordsService? _what3wordsService;
  final GeocodingService? _geocodingService;

  LocationDisplayState _state = const LocationDisplayInitial();
  bool _isManualLocation = false;

  /// Current location display state
  LocationDisplayState get state => _state;

  /// Whether the current location was manually set
  bool get isManualLocation => _isManualLocation;

  /// Creates a LocationStateManager with required service dependencies
  ///
  /// [locationResolver] - Service for GPS/cache/manual location fetching
  /// [what3wordsService] - Optional service for what3words address lookup
  /// [geocodingService] - Optional service for reverse geocoding
  LocationStateManager({
    required LocationResolver locationResolver,
    What3wordsService? what3wordsService,
    GeocodingService? geocodingService,
  })  : _locationResolver = locationResolver,
        _what3wordsService = what3wordsService,
        _geocodingService = geocodingService {
    developer.log('LocationStateManager created', name: 'LocationStateManager');
  }

  /// Initialize manager by fetching GPS location
  ///
  /// Call this on screen initialization to auto-populate location.
  /// Updates state to Loading, then Success or Error.
  Future<void> initialize() async {
    await _fetchLocation();
  }

  /// Refresh location data (re-fetch from GPS)
  ///
  /// Useful for pull-to-refresh or returning to foreground.
  Future<void> refresh() async {
    if (_state is LocationDisplayLoading) {
      developer.log(
        'Refresh ignored - already loading',
        name: 'LocationStateManager',
      );
      return;
    }
    await _fetchLocation();
  }

  /// Set a manual location from the location picker
  ///
  /// [location] - Validated coordinates
  /// [placeName] - Optional user-provided place name
  Future<void> setManualLocation(LatLng location, {String? placeName}) async {
    try {
      // Save to persistent storage
      await _locationResolver.saveManual(location, placeName: placeName);

      _isManualLocation = true;

      developer.log(
        'Manual location set: ${LocationUtils.logRedact(location.latitude, location.longitude)}${placeName != null ? ' ($placeName)' : ''}',
        name: 'LocationStateManager',
      );

      // Update state with the new location
      _updateState(
        LocationDisplaySuccess(
          coordinates: location,
          source: LocationSource.manual,
          placeName: placeName,
          lastUpdated: DateTime.now(),
          isWhat3wordsLoading: _what3wordsService != null,
          isGeocodingLoading: _geocodingService != null,
        ),
      );

      // Fetch enrichment data (what3words, geocoding)
      _fetchEnrichmentData(location);
    } catch (e) {
      developer.log(
        'Failed to set manual location: $e',
        name: 'LocationStateManager',
      );
      _updateState(
        LocationDisplayError(
          message: 'Failed to save location: ${e.toString()}',
          canRetry: true,
        ),
      );
    }
  }

  /// Clear manual location and return to GPS
  ///
  /// Clears persistent storage and re-fetches GPS location.
  Future<void> useGpsLocation() async {
    try {
      await _locationResolver.clearManualLocation();

      _isManualLocation = false;

      developer.log('Returning to GPS location', name: 'LocationStateManager');

      await _fetchLocation();
    } catch (e) {
      developer.log(
        'Failed to clear manual location: $e',
        name: 'LocationStateManager',
      );
      // Try to fetch anyway
      _isManualLocation = false;
      await _fetchLocation();
    }
  }

  /// Core location fetching implementation
  Future<void> _fetchLocation() async {
    // Capture last known location for display during loading
    LatLng? lastKnown;
    String? lastPlaceName;

    if (_state is LocationDisplaySuccess) {
      final success = _state as LocationDisplaySuccess;
      lastKnown = success.coordinates;
      lastPlaceName = success.formattedLocation ?? success.placeName;
    }

    _updateState(
      LocationDisplayLoading(
        lastKnownLocation: lastKnown,
        lastKnownPlaceName: lastPlaceName,
      ),
    );

    try {
      // First check for cached manual location (persisted across navigation)
      final cached = await _locationResolver.loadCachedManualLocation();
      if (cached != null) {
        final (location, placeName) = cached;
        _isManualLocation = true;

        developer.log(
          'Using cached manual location: ${LocationUtils.logRedact(location.latitude, location.longitude)}${placeName != null ? ' ($placeName)' : ''}',
          name: 'LocationStateManager',
        );

        _updateState(
          LocationDisplaySuccess(
            coordinates: location,
            source: LocationSource.manual,
            placeName: placeName,
            lastUpdated: DateTime.now(),
            isWhat3wordsLoading: _what3wordsService != null,
            isGeocodingLoading: _geocodingService != null,
          ),
        );

        // Fetch enrichment data
        _fetchEnrichmentData(location);
        return;
      }

      // No cached manual location - use GPS/fallback chain
      _isManualLocation = false;
      final result = await _locationResolver.getLatLon(allowDefault: true);

      switch (result) {
        case Right(:final value):
          final resolved = value;
          final location = resolved.coordinates;

          developer.log(
            'Location resolved: ${LocationUtils.logRedact(location.latitude, location.longitude)} (source: ${resolved.source.name})',
            name: 'LocationStateManager',
          );

          _updateState(
            LocationDisplaySuccess(
              coordinates: location,
              source: resolved.source,
              placeName: resolved.placeName,
              lastUpdated: DateTime.now(),
              isWhat3wordsLoading: _what3wordsService != null,
              isGeocodingLoading: _geocodingService != null,
            ),
          );

          // Fetch enrichment data
          _fetchEnrichmentData(location);

        case Left(:final value):
          developer.log(
            'Location resolution failed: $value',
            name: 'LocationStateManager',
          );
          _updateState(
            LocationDisplayError(
              message: _getErrorMessage(value),
              canRetry: true,
              cachedLocation: lastKnown,
            ),
          );
      }
    } catch (e) {
      developer.log(
        'Unexpected error fetching location: $e',
        name: 'LocationStateManager',
      );
      _updateState(
        LocationDisplayError(
          message: 'Unexpected error: ${e.toString()}',
          canRetry: true,
          cachedLocation: lastKnown,
        ),
      );
    }
  }

  /// Fetch what3words and geocoding data asynchronously
  void _fetchEnrichmentData(LatLng location) {
    final currentState = _state;
    if (currentState is! LocationDisplaySuccess) return;

    // Fetch what3words address
    if (_what3wordsService != null) {
      _what3wordsService!
          .convertTo3wa(lat: location.latitude, lon: location.longitude)
          .then((result) {
        final state = _state;
        if (state is LocationDisplaySuccess) {
          switch (result) {
            case Right(:final value):
              developer.log(
                'What3words resolved for ${LocationUtils.logRedact(location.latitude, location.longitude)}',
                name: 'LocationStateManager',
              );
              _updateState(
                state.copyWith(
                  what3words: value.displayFormat,
                  isWhat3wordsLoading: false,
                ),
              );
            case Left(:final value):
              developer.log(
                'What3words failed: ${value.userMessage}',
                name: 'LocationStateManager',
              );
              _updateState(state.copyWith(isWhat3wordsLoading: false));
          }
        }
      });
    }

    // Fetch formatted location via reverse geocoding
    if (_geocodingService != null) {
      _geocodingService!
          .reverseGeocode(lat: location.latitude, lon: location.longitude)
          .then((result) {
        final state = _state;
        if (state is LocationDisplaySuccess) {
          switch (result) {
            case Right(:final value):
              developer.log(
                'Geocoding resolved: $value',
                name: 'LocationStateManager',
              );
              _updateState(
                state.copyWith(
                  formattedLocation: value,
                  isGeocodingLoading: false,
                ),
              );
            case Left(:final value):
              developer.log(
                'Geocoding failed: $value',
                name: 'LocationStateManager',
              );
              _updateState(state.copyWith(isGeocodingLoading: false));
          }
        }
      });
    }
  }

  /// Convert LocationError to user-friendly message
  String _getErrorMessage(LocationError error) {
    return switch (error) {
      LocationError.permissionDenied => 'Location permission denied',
      LocationError.gpsUnavailable => 'GPS unavailable or disabled',
      LocationError.timeout => 'Location request timed out',
      LocationError.invalidInput => 'Invalid location input',
    };
  }

  /// Update state and notify listeners
  void _updateState(LocationDisplayState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    developer.log(
      'LocationStateManager disposed',
      name: 'LocationStateManager',
    );
    super.dispose();
  }
}
