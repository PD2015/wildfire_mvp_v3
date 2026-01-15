import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';
import 'place_search_result.dart';

/// Sealed class hierarchy for LocationPickerController state
///
/// Follows the app's established sealed class pattern for exhaustive
/// switch handling in widgets. Each state carries only the data
/// needed for that specific UI configuration.
sealed class LocationPickerState extends Equatable {
  const LocationPickerState();
}

/// Initial state - ready for user input
///
/// May have a pre-populated location from current user location
/// or a previously selected location being edited.
class LocationPickerInitial extends LocationPickerState {
  /// Optional pre-populated coordinates
  final LatLng? initialLocation;

  /// Optional pre-populated what3words address
  final What3wordsAddress? initialWhat3words;

  /// Optional pre-populated place name
  final String? initialPlaceName;

  const LocationPickerInitial({
    this.initialLocation,
    this.initialWhat3words,
    this.initialPlaceName,
  });

  @override
  List<Object?> get props => [
        initialLocation,
        initialWhat3words,
        initialPlaceName,
      ];
}

/// User is typing in the search field
///
/// Shows search suggestions as user types. Debounced API calls
/// populate the suggestions list.
class LocationPickerSearching extends LocationPickerState {
  /// Current search query text
  final String query;

  /// Autocomplete suggestions from Geocoding API
  final List<PlaceSearchResult> suggestions;

  /// True while fetching suggestions
  final bool isLoading;

  const LocationPickerSearching({
    required this.query,
    this.suggestions = const [],
    this.isLoading = false,
  });

  LocationPickerSearching copyWith({
    String? query,
    List<PlaceSearchResult>? suggestions,
    bool? isLoading,
  }) =>
      LocationPickerSearching(
        query: query ?? this.query,
        suggestions: suggestions ?? this.suggestions,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [query, suggestions, isLoading];
}

/// Location selected and being resolved/confirmed
///
/// User has tapped a suggestion or the map. Now resolving
/// what3words address and preparing for confirmation.
class LocationPickerSelected extends LocationPickerState {
  /// Selected coordinates
  final LatLng coordinates;

  /// Place name from search result or reverse geocoding
  final String? placeName;

  /// Resolved what3words address (may be loading)
  final What3wordsAddress? what3words;

  /// True while resolving what3words
  final bool isResolvingWhat3words;

  /// True while reverse geocoding place name
  final bool isResolvingPlaceName;

  const LocationPickerSelected({
    required this.coordinates,
    this.placeName,
    this.what3words,
    this.isResolvingWhat3words = false,
    this.isResolvingPlaceName = false,
  });

  /// Check if all resolutions are complete
  bool get isFullyResolved => !isResolvingWhat3words && !isResolvingPlaceName;

  LocationPickerSelected copyWith({
    LatLng? coordinates,
    String? placeName,
    What3wordsAddress? what3words,
    bool? isResolvingWhat3words,
    bool? isResolvingPlaceName,
  }) =>
      LocationPickerSelected(
        coordinates: coordinates ?? this.coordinates,
        placeName: placeName ?? this.placeName,
        what3words: what3words ?? this.what3words,
        isResolvingWhat3words:
            isResolvingWhat3words ?? this.isResolvingWhat3words,
        isResolvingPlaceName: isResolvingPlaceName ?? this.isResolvingPlaceName,
      );

  @override
  List<Object?> get props => [
        coordinates,
        placeName,
        what3words,
        isResolvingWhat3words,
        isResolvingPlaceName,
      ];
}

/// Error state - recoverable user input errors
///
/// Displayed when search fails, what3words resolution fails,
/// or invalid input is detected. User can retry or correct input.
class LocationPickerError extends LocationPickerState {
  /// Error message to display
  final String message;

  /// Previous state to restore on retry
  final LocationPickerState? previousState;

  /// Whether error is for what3words specifically
  final bool isWhat3wordsError;

  const LocationPickerError({
    required this.message,
    this.previousState,
    this.isWhat3wordsError = false,
  });

  @override
  List<Object?> get props => [message, previousState, isWhat3wordsError];
}
