import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_state.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/picked_location.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/place_search_result.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/what3words_service.dart';
import 'package:wildfire_mvp_v3/features/location_picker/services/geocoding_service.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';

/// Controller for LocationPickerScreen
///
/// Manages state transitions for the location picker flow:
/// 1. Initial state (optional pre-populated location)
/// 2. Searching state (user typing, debounced API calls)
/// 3. Selected state (resolving what3words and place name)
/// 4. Error state (recoverable errors with retry)
///
/// Follows the app's ChangeNotifier pattern for state management.
class LocationPickerController extends ChangeNotifier {
  final What3wordsService _what3wordsService;
  final GeocodingService _geocodingService;
  final LocationPickerMode mode;

  /// Debounce timer for search input
  Timer? _searchDebounceTimer;

  /// Debounce timer for camera idle (map-first mode)
  Timer? _cameraIdleDebounceTimer;

  /// Current state
  LocationPickerState _state = const LocationPickerInitial();
  LocationPickerState get state => _state;

  /// Current map type (terrain, satellite, hybrid)
  gmaps.MapType _mapType = gmaps.MapType.terrain;
  gmaps.MapType get mapType => _mapType;

  /// Duration to wait after user stops typing before searching
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Duration to wait after camera stops moving before fetching w3w
  static const Duration cameraIdleDebounce = Duration(milliseconds: 300);

  LocationPickerController({
    required What3wordsService what3wordsService,
    required GeocodingService geocodingService,
    required this.mode,
    LatLng? initialLocation,
    What3wordsAddress? initialWhat3words,
    String? initialPlaceName,
  })  : _what3wordsService = what3wordsService,
        _geocodingService = geocodingService {
    if (initialLocation != null ||
        initialWhat3words != null ||
        initialPlaceName != null) {
      _state = LocationPickerInitial(
        initialLocation: initialLocation,
        initialWhat3words: initialWhat3words,
        initialPlaceName: initialPlaceName,
      );
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _cameraIdleDebounceTimer?.cancel();
    super.dispose();
  }

  /// Update state and notify listeners
  void _updateState(LocationPickerState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Handle search text input with debouncing (T013)
  ///
  /// - Detects what3words format (///word.word.word) for direct resolution
  /// - Debounces regular text for place search
  void onSearchTextChanged(String query) {
    _searchDebounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      // Return to initial state
      _updateState(LocationPickerInitial(
        initialLocation: _getLastKnownLocation(),
        initialWhat3words: _getLastKnownWhat3words(),
        initialPlaceName: _getLastKnownPlaceName(),
      ));
      return;
    }

    // Check for what3words format (T014)
    if (What3wordsAddress.looksLikeWhat3words(trimmed)) {
      _handleWhat3wordsInput(trimmed);
      return;
    }

    // Start searching state immediately for UI feedback
    _updateState(LocationPickerSearching(
      query: trimmed,
      isLoading: true,
    ));

    // Debounce the actual API call
    _searchDebounceTimer = Timer(searchDebounce, () {
      _performPlaceSearch(trimmed);
    });
  }

  /// Handle what3words address input (T014)
  Future<void> _handleWhat3wordsInput(String input) async {
    final address = What3wordsAddress.tryParse(input);
    if (address == null) {
      _updateState(const LocationPickerError(
        message: 'Invalid what3words format. Use word.word.word',
        isWhat3wordsError: true,
      ));
      return;
    }

    _updateState(LocationPickerSearching(
      query: input,
      isLoading: true,
    ));

    final result =
        await _what3wordsService.convertToCoordinates(words: address.words);

    result.fold(
      (error) => _updateState(LocationPickerError(
        message: error.userMessage,
        isWhat3wordsError: true,
      )),
      (coords) => _updateState(LocationPickerSelected(
        coordinates: coords,
        what3words: address,
        isResolvingPlaceName: true,
      )),
    );

    // If we got coordinates, also fetch the place name
    if (_state is LocationPickerSelected) {
      final selected = _state as LocationPickerSelected;
      _resolveReversePlaceName(selected.coordinates);
    }
  }

  /// Perform debounced place search (T013)
  Future<void> _performPlaceSearch(String query) async {
    final result = await _geocodingService.searchPlaces(query: query);

    // Check if state is still searching for this query
    if (_state is! LocationPickerSearching) return;
    final currentState = _state as LocationPickerSearching;
    if (currentState.query != query) return;

    result.fold(
      (error) => _updateState(LocationPickerError(
        message: 'Search failed: ${error.toString()}',
        previousState: currentState,
      )),
      (results) => _updateState(currentState.copyWith(
        suggestions: results,
        isLoading: false,
      )),
    );
  }

  /// Handle place search result selection
  Future<void> onPlaceSelected(PlaceSearchResult place) async {
    LatLng? coords = place.coordinates;

    if (coords == null) {
      // Need to resolve coordinates from place_id
      _updateState(LocationPickerSelected(
        coordinates: const LatLng(0, 0), // Temporary placeholder
        placeName: place.name,
        isResolvingWhat3words: true,
        isResolvingPlaceName: false,
      ));

      final result =
          await _geocodingService.getPlaceCoordinates(placeId: place.placeId);
      result.fold(
        (error) {
          _updateState(const LocationPickerError(
            message: 'Could not resolve location',
          ));
        },
        (resolvedCoords) {
          coords = resolvedCoords;
          _updateState(LocationPickerSelected(
            coordinates: resolvedCoords,
            placeName: place.name,
            isResolvingWhat3words: true,
          ));
          // Resolve what3words after successful coordinate resolution
          _resolveWhat3words(resolvedCoords);
        },
      );
    } else {
      _updateState(LocationPickerSelected(
        coordinates: coords,
        placeName: place.name,
        isResolvingWhat3words: true,
      ));
      // Resolve what3words for the coordinates
      _resolveWhat3words(coords);
    }
  }

  /// Handle map tap to select location (T015)
  void onMapTapped(LatLng coordinates) {
    _updateState(LocationPickerSelected(
      coordinates: coordinates,
      isResolvingWhat3words: true,
      isResolvingPlaceName: true,
    ));

    // Resolve both what3words and place name in parallel
    _resolveWhat3words(coordinates);
    _resolveReversePlaceName(coordinates);
  }

  /// Handle camera idle event from map-first picker
  ///
  /// Called when user stops panning the map. Updates coordinates and
  /// triggers debounced what3words resolution.
  ///
  /// C2 compliance: Logs coordinates with 2dp precision only.
  void setLocationFromCamera(LatLng coordinates) {
    _cameraIdleDebounceTimer?.cancel();

    // Log with redacted coordinates per C2
    debugPrint(
        'Camera idle at: ${LocationUtils.logRedact(coordinates.latitude, coordinates.longitude)}');

    // Update state with new coordinates immediately
    _updateState(LocationPickerSelected(
      coordinates: coordinates,
      what3words: _getLastKnownWhat3words(),
      placeName: null, // Reset place name for new location
      isResolvingWhat3words: true,
      isResolvingPlaceName: false, // Don't resolve place name on pan (too slow)
    ));

    // Debounce the what3words fetch
    _cameraIdleDebounceTimer = Timer(cameraIdleDebounce, () {
      _resolveWhat3words(coordinates);
    });
  }

  /// Cycle through map types: terrain → satellite → hybrid → terrain
  void cycleMapType() {
    switch (_mapType) {
      case gmaps.MapType.terrain:
        _mapType = gmaps.MapType.satellite;
      case gmaps.MapType.satellite:
        _mapType = gmaps.MapType.hybrid;
      case gmaps.MapType.hybrid:
        _mapType = gmaps.MapType.terrain;
      default:
        _mapType = gmaps.MapType.terrain;
    }
    notifyListeners();
  }

  /// Set map type directly
  void setMapType(gmaps.MapType type) {
    _mapType = type;
    notifyListeners();
  }

  /// Get current coordinates for map centering
  LatLng? get currentCoordinates {
    return switch (_state) {
      LocationPickerInitial(:final initialLocation) => initialLocation,
      LocationPickerSelected(:final coordinates) => coordinates,
      _ => null,
    };
  }

  /// Whether what3words is still loading
  bool get isWhat3wordsLoading {
    return switch (_state) {
      LocationPickerSelected(:final isResolvingWhat3words) =>
        isResolvingWhat3words,
      _ => false,
    };
  }

  /// Get what3words error message if any
  String? get what3wordsError {
    if (_state is LocationPickerError) {
      final error = _state as LocationPickerError;
      if (error.isWhat3wordsError) {
        return error.message;
      }
    }
    return null;
  }

  /// Resolve what3words address for coordinates
  Future<void> _resolveWhat3words(LatLng coords) async {
    final result = await _what3wordsService.convertTo3wa(
      lat: coords.latitude,
      lon: coords.longitude,
    );

    // Only update if still in selected state with same coordinates
    if (_state is! LocationPickerSelected) return;
    final currentState = _state as LocationPickerSelected;
    if (currentState.coordinates != coords) return;

    result.fold(
      (error) {
        debugPrint('what3words resolution failed: ${error.userMessage}');
        _updateState(currentState.copyWith(
          isResolvingWhat3words: false,
          // Don't fail the whole selection, just skip w3w
        ));
      },
      (address) => _updateState(currentState.copyWith(
        what3words: address,
        isResolvingWhat3words: false,
      )),
    );
  }

  /// Resolve place name from coordinates (reverse geocoding)
  Future<void> _resolveReversePlaceName(LatLng coords) async {
    final result = await _geocodingService.reverseGeocode(
      lat: coords.latitude,
      lon: coords.longitude,
    );

    // Only update if still in selected state with same coordinates
    if (_state is! LocationPickerSelected) return;
    final currentState = _state as LocationPickerSelected;
    if (currentState.coordinates != coords) return;

    result.fold(
      (error) {
        debugPrint('Reverse geocoding failed: $error');
        _updateState(currentState.copyWith(
          isResolvingPlaceName: false,
          // Don't fail the whole selection, just skip place name
        ));
      },
      (placeName) => _updateState(currentState.copyWith(
        placeName: placeName,
        isResolvingPlaceName: false,
      )),
    );
  }

  /// Confirm current selection and return result (T016)
  ///
  /// Returns null if not in selected state or still resolving.
  PickedLocation? confirmSelection() {
    if (_state is! LocationPickerSelected) return null;
    final selected = _state as LocationPickerSelected;

    // Allow confirmation even if what3words/place not fully resolved
    return PickedLocation.now(
      coordinates: selected.coordinates,
      what3words: selected.what3words?.words,
      placeName: selected.placeName,
    );
  }

  /// Reset to initial state
  void reset() {
    _searchDebounceTimer?.cancel();
    _updateState(const LocationPickerInitial());
  }

  /// Retry from error state
  void retry() {
    if (_state is LocationPickerError) {
      final errorState = _state as LocationPickerError;
      if (errorState.previousState != null) {
        _updateState(errorState.previousState!);
      } else {
        _updateState(const LocationPickerInitial());
      }
    }
  }

  // Helper methods to extract last known values from states
  LatLng? _getLastKnownLocation() {
    return switch (_state) {
      LocationPickerInitial(:final initialLocation) => initialLocation,
      LocationPickerSelected(:final coordinates) => coordinates,
      _ => null,
    };
  }

  What3wordsAddress? _getLastKnownWhat3words() {
    return switch (_state) {
      LocationPickerInitial(:final initialWhat3words) => initialWhat3words,
      LocationPickerSelected(:final what3words) => what3words,
      _ => null,
    };
  }

  String? _getLastKnownPlaceName() {
    return switch (_state) {
      LocationPickerInitial(:final initialPlaceName) => initialPlaceName,
      LocationPickerSelected(:final placeName) => placeName,
      _ => null,
    };
  }
}
