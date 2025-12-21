import 'package:equatable/equatable.dart';
import '../services/models/fire_risk.dart';
import 'location_models.dart';

/// Sealed class hierarchy representing all possible states of the Home screen
///
/// Provides exhaustive pattern matching for UI state management with clear
/// separation between loading, success, and error conditions. Each state
/// includes the minimum data needed for proper UI rendering and user feedback.
///
/// Constitutional compliance:
/// - C5: Error states are explicit and visible, no silent failures
/// - C4: Success state includes source attribution for transparency
/// - C2: No PII exposure (coordinates handled via service layer with redaction)
sealed class HomeState extends Equatable {
  const HomeState();
}

/// Loading state during data fetching operations
///
/// Indicates the system is actively retrieving location and fire risk data.
/// Supports retry scenarios by tracking whether this is an initial load
/// or a retry attempt for better user feedback.
class HomeStateLoading extends HomeState {
  /// Whether this loading state is from a retry action
  final bool isRetry;

  /// Timestamp when loading operation started
  final DateTime startTime;

  /// Last known location (from previous success or cached state)
  /// Used to display location context to user during loading
  final LatLng? lastKnownLocation;

  /// Timestamp when lastKnownLocation was captured
  /// Used to determine if location is stale (>1 hour old)
  final DateTime? lastKnownLocationTimestamp;

  /// Whether what3words address is currently being resolved
  final bool isWhat3wordsLoading;

  /// Whether geocoding (place name) is currently being resolved
  final bool isGeocodingLoading;

  const HomeStateLoading({
    this.isRetry = false,
    required this.startTime,
    this.lastKnownLocation,
    this.lastKnownLocationTimestamp,
    this.isWhat3wordsLoading = false,
    this.isGeocodingLoading = false,
  });

  /// Whether the last known location is stale (>1 hour old)
  ///
  /// Returns false if no timestamp is available.
  /// Used to show "may be outdated" warning in UI.
  bool get isLocationStale {
    if (lastKnownLocationTimestamp == null) {
      return false;
    }
    return DateTime.now().difference(lastKnownLocationTimestamp!) >
        const Duration(hours: 1);
  }

  @override
  List<Object?> get props => [
    isRetry,
    startTime,
    lastKnownLocation,
    lastKnownLocationTimestamp,
    isWhat3wordsLoading,
    isGeocodingLoading,
  ];

  @override
  String toString() =>
      'HomeStateLoading(isRetry: $isRetry, startTime: $startTime, lastKnownLocation: $lastKnownLocation, lastKnownLocationTimestamp: $lastKnownLocationTimestamp, isStale: $isLocationStale, isWhat3wordsLoading: $isWhat3wordsLoading, isGeocodingLoading: $isGeocodingLoading)';
}

/// Successfully loaded state with all required display data
///
/// Contains complete fire risk information, location context, and source
/// attribution for transparency. This state enables full UI rendering
/// with timestamp display and retry capability.
class HomeStateSuccess extends HomeState {
  /// Current fire risk assessment data
  final FireRisk riskData;

  /// Location information used for the risk assessment
  final LatLng location;

  /// When this risk data was last fetched (for "Updated X ago" display)
  final DateTime lastUpdated;

  /// Source of the location data (GPS, manual, cached, or default)
  /// Used for UI display and trust-building messaging
  final LocationSource locationSource;

  /// Optional human-readable place name (e.g., "Edinburgh City Centre")
  /// Only populated for manual locations where user provided a name
  final String? placeName;

  /// Optional what3words address (e.g., "///index.home.raft")
  /// Resolved automatically from coordinates after location is obtained
  /// Note: Never log this value per C2 privacy compliance
  final String? what3words;

  /// Optional formatted location from reverse geocoding (e.g., "Near Aviemore, Highland")
  /// Provides human-readable context for coordinates
  final String? formattedLocation;

  /// Whether what3words address is still being resolved
  final bool isWhat3wordsLoading;

  /// Whether geocoding (formatted location) is still being resolved
  final bool isGeocodingLoading;

  const HomeStateSuccess({
    required this.riskData,
    required this.location,
    required this.lastUpdated,
    required this.locationSource,
    this.placeName,
    this.what3words,
    this.formattedLocation,
    this.isWhat3wordsLoading = false,
    this.isGeocodingLoading = false,
  });

  /// Copy with method for partial updates
  HomeStateSuccess copyWith({
    FireRisk? riskData,
    LatLng? location,
    DateTime? lastUpdated,
    LocationSource? locationSource,
    String? placeName,
    String? what3words,
    String? formattedLocation,
    bool? isWhat3wordsLoading,
    bool? isGeocodingLoading,
  }) {
    return HomeStateSuccess(
      riskData: riskData ?? this.riskData,
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      locationSource: locationSource ?? this.locationSource,
      placeName: placeName ?? this.placeName,
      what3words: what3words ?? this.what3words,
      formattedLocation: formattedLocation ?? this.formattedLocation,
      isWhat3wordsLoading: isWhat3wordsLoading ?? this.isWhat3wordsLoading,
      isGeocodingLoading: isGeocodingLoading ?? this.isGeocodingLoading,
    );
  }

  @override
  List<Object?> get props => [
    riskData,
    location,
    lastUpdated,
    locationSource,
    placeName,
    what3words,
    formattedLocation,
    isWhat3wordsLoading,
    isGeocodingLoading,
  ];

  @override
  String toString() =>
      'HomeStateSuccess(riskData: $riskData, location: $location, lastUpdated: $lastUpdated, source: $locationSource, placeName: $placeName, what3words: [REDACTED], formattedLocation: $formattedLocation, isWhat3wordsLoading: $isWhat3wordsLoading, isGeocodingLoading: $isGeocodingLoading)';
}

/// Error state with optional cached data for graceful degradation
///
/// Represents failure conditions while potentially showing stale but useful
/// data to the user. Includes retry capability and clear error messaging
/// for debugging and user feedback.
class HomeStateError extends HomeState {
  /// Human-readable error message for debugging and user display
  final String errorMessage;

  /// Optional cached fire risk data to display during error conditions
  /// Enables graceful degradation when fresh data is unavailable
  final FireRisk? cachedData;

  /// Optional location context for cached data display
  final LatLng? cachedLocation;

  /// Whether retry functionality should be available to the user
  final bool canRetry;

  const HomeStateError({
    required this.errorMessage,
    this.cachedData,
    this.cachedLocation,
    this.canRetry = true,
  });

  /// Whether this error state has cached data available for display
  bool get hasCachedData => cachedData != null && cachedLocation != null;

  @override
  List<Object?> get props => [
    errorMessage,
    cachedData,
    cachedLocation,
    canRetry,
  ];

  @override
  String toString() =>
      'HomeStateError(errorMessage: $errorMessage, hasCachedData: $hasCachedData, canRetry: $canRetry)';
}
