import 'package:equatable/equatable.dart';
import 'location_models.dart';

/// Unified location display state for LocationCard across all screens
///
/// This sealed class provides a consistent state model for location display
/// that can be used by any screen that needs to show the LocationCard widget.
/// Extracts the location-specific state from HomeController/ReportFireController
/// to enable reuse.
///
/// Used by:
/// - HomeScreen (via HomeController wrapping LocationStateManager)
/// - ReportFireScreen (via ReportFireController wrapping LocationStateManager)
/// - Future: MapScreen, any screen needing location display
///
/// Constitutional compliance:
/// - C2: Coordinates stored at full precision, UI layer handles redaction
/// - C3: Loading states enable proper loading indicators
sealed class LocationDisplayState extends Equatable {
  const LocationDisplayState();
}

/// Initial state before any location resolution
///
/// Used when the screen first loads before GPS is attempted.
class LocationDisplayInitial extends LocationDisplayState {
  const LocationDisplayInitial();

  @override
  List<Object?> get props => [];
}

/// Loading state during location resolution
///
/// Shows loading indicator in LocationCard. Can optionally display
/// last known location while loading for better UX.
class LocationDisplayLoading extends LocationDisplayState {
  /// Optional last known location to display while loading
  final LatLng? lastKnownLocation;

  /// Optional place name from last known location
  final String? lastKnownPlaceName;

  const LocationDisplayLoading({
    this.lastKnownLocation,
    this.lastKnownPlaceName,
  });

  @override
  List<Object?> get props => [lastKnownLocation, lastKnownPlaceName];
}

/// Successful location state with all display data
///
/// Contains everything needed to render a complete LocationCard:
/// - Core location (coordinates, source)
/// - Enhanced data (what3words, place name)
/// - Loading states for async enrichment
class LocationDisplaySuccess extends LocationDisplayState {
  /// Resolved coordinates
  final LatLng coordinates;

  /// How the location was obtained (GPS, manual, cached, default)
  final LocationSource source;

  /// User-provided place name (if manually set)
  final String? placeName;

  /// what3words address (e.g., "///daring.lion.race")
  final String? what3words;

  /// Whether what3words is currently loading
  final bool isWhat3wordsLoading;

  /// Formatted location from reverse geocoding (e.g., "Near Aviemore, Highland")
  final String? formattedLocation;

  /// Whether geocoding is currently loading
  final bool isGeocodingLoading;

  /// When the location was last updated
  final DateTime lastUpdated;

  const LocationDisplaySuccess({
    required this.coordinates,
    required this.source,
    this.placeName,
    this.what3words,
    this.isWhat3wordsLoading = false,
    this.formattedLocation,
    this.isGeocodingLoading = false,
    required this.lastUpdated,
  });

  /// Creates a copy with updated fields
  LocationDisplaySuccess copyWith({
    LatLng? coordinates,
    LocationSource? source,
    String? placeName,
    String? what3words,
    bool? isWhat3wordsLoading,
    String? formattedLocation,
    bool? isGeocodingLoading,
    DateTime? lastUpdated,
    bool clearPlaceName = false,
    bool clearWhat3words = false,
    bool clearFormattedLocation = false,
  }) {
    return LocationDisplaySuccess(
      coordinates: coordinates ?? this.coordinates,
      source: source ?? this.source,
      placeName: clearPlaceName ? null : (placeName ?? this.placeName),
      what3words: clearWhat3words ? null : (what3words ?? this.what3words),
      isWhat3wordsLoading: isWhat3wordsLoading ?? this.isWhat3wordsLoading,
      formattedLocation: clearFormattedLocation
          ? null
          : (formattedLocation ?? this.formattedLocation),
      isGeocodingLoading: isGeocodingLoading ?? this.isGeocodingLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        coordinates,
        source,
        placeName,
        what3words,
        isWhat3wordsLoading,
        formattedLocation,
        isGeocodingLoading,
        lastUpdated,
      ];
}

/// Error state when location resolution fails
///
/// Can optionally include cached location for degraded display.
class LocationDisplayError extends LocationDisplayState {
  /// Error message for debugging (not shown to user directly)
  final String message;

  /// Whether retry is possible
  final bool canRetry;

  /// Optional cached location to display in degraded mode
  final LatLng? cachedLocation;

  const LocationDisplayError({
    required this.message,
    this.canRetry = true,
    this.cachedLocation,
  });

  @override
  List<Object?> get props => [message, canRetry, cachedLocation];
}
