// Bottom sheet state management for fire information sheet
// Implements Task 6 of 018-map-fire-information specification
// Manages display states, loading, error handling, and user interactions

import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Base state for fire information bottom sheet
/// 
/// Represents all possible states of the bottom sheet:
/// - Hidden: Sheet is not displayed
/// - Loading: Fetching fire incident details
/// - Loaded: Fire incident data available for display
/// - Error: Error occurred, with retry capability
abstract class BottomSheetState extends Equatable {
  const BottomSheetState();

  /// Check if bottom sheet should be visible
  bool get isVisible => this is! BottomSheetHidden;
  
  /// Check if bottom sheet is in loading state
  bool get isLoading => this is BottomSheetLoading;
  
  /// Check if bottom sheet has data to display
  bool get hasData => this is BottomSheetLoaded;
  
  /// Check if bottom sheet is in error state
  bool get hasError => this is BottomSheetError;

  /// Get fire incident data if available
  FireIncident? get fireIncident {
    if (this is BottomSheetLoaded) {
      return (this as BottomSheetLoaded).fireIncident;
    }
    return null;
  }

  /// Get error message if in error state
  String? get errorMessage {
    if (this is BottomSheetError) {
      return (this as BottomSheetError).message;
    }
    return null;
  }

  @override
  List<Object?> get props => [];
}

/// Bottom sheet is hidden (not displayed)
class BottomSheetHidden extends BottomSheetState {
  const BottomSheetHidden();

  @override
  String toString() => 'BottomSheetHidden()';
}

/// Bottom sheet is loading fire incident details
class BottomSheetLoading extends BottomSheetState {
  /// Fire incident ID being loaded
  final String fireIncidentId;
  
  /// Optional message to display during loading
  final String? loadingMessage;

  const BottomSheetLoading({
    required this.fireIncidentId,
    this.loadingMessage,
  });

  @override
  List<Object?> get props => [fireIncidentId, loadingMessage];

  @override
  String toString() => 'BottomSheetLoading(id: $fireIncidentId, message: $loadingMessage)';
}

/// Bottom sheet loaded with fire incident data
class BottomSheetLoaded extends BottomSheetState {
  /// Fire incident to display in bottom sheet
  final FireIncident fireIncident;
  
  /// User's current location for distance calculations
  final LatLng? userLocation;
  
  /// Formatted distance and direction string (e.g., "3.2 km NE")
  final String? distanceAndDirection;
  
  /// Timestamp when data was loaded
  final DateTime loadedAt;

  BottomSheetLoaded({
    required this.fireIncident,
    this.userLocation,
    this.distanceAndDirection,
    DateTime? loadedAt,
  }) : loadedAt = loadedAt ?? DateTime.now().toUtc();

  /// Create loaded state with current timestamp
  factory BottomSheetLoaded.now({
    required FireIncident fireIncident,
    LatLng? userLocation,
    String? distanceAndDirection,
  }) {
    return BottomSheetLoaded(
      fireIncident: fireIncident,
      userLocation: userLocation,
      distanceAndDirection: distanceAndDirection,
      loadedAt: DateTime.now().toUtc(),
    );
  }

  /// Check if location-based features are available
  bool get hasLocationInfo => userLocation != null && distanceAndDirection != null;

  /// Get fire risk level for display styling
  String get riskLevel {
    // Map intensity to risk level for UI
    switch (fireIncident.intensity.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'moderate':
        return 'Moderate';
      case 'high':
        return 'High';
      default:
        return 'Unknown';
    }
  }

  /// Get confidence display string
  String get confidenceDisplay {
    if (fireIncident.confidence != null) {
      return '${fireIncident.confidence!.toStringAsFixed(0)}%';
    }
    return 'Unknown';
  }

  /// Get FRP display string
  String get frpDisplay {
    if (fireIncident.frp != null) {
      return '${fireIncident.frp!.toStringAsFixed(0)} MW';
    }
    return 'Unknown';
  }

  /// Create a copy with updated fields
  BottomSheetLoaded copyWith({
    FireIncident? fireIncident,
    LatLng? userLocation,
    String? distanceAndDirection,
    DateTime? loadedAt,
  }) {
    return BottomSheetLoaded(
      fireIncident: fireIncident ?? this.fireIncident,
      userLocation: userLocation ?? this.userLocation,
      distanceAndDirection: distanceAndDirection ?? this.distanceAndDirection,
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }

  @override
  List<Object?> get props => [fireIncident, userLocation, distanceAndDirection, loadedAt];

  @override
  String toString() {
    return 'BottomSheetLoaded(id: ${fireIncident.id}, '
           'location: ${hasLocationInfo ? distanceAndDirection : 'no location'}, '
           'risk: $riskLevel)';
  }
}

/// Bottom sheet error state with retry capability
class BottomSheetError extends BottomSheetState {
  /// Error message to display to user
  final String message;
  
  /// Fire incident ID that failed to load
  final String? fireIncidentId;
  
  /// Whether retry is possible
  final bool canRetry;
  
  /// Optional underlying error for debugging
  final Object? error;
  
  /// Timestamp when error occurred
  final DateTime occurredAt;

  BottomSheetError({
    required this.message,
    this.fireIncidentId,
    this.canRetry = true,
    this.error,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now().toUtc();

  /// Create error state with current timestamp
  factory BottomSheetError.now({
    required String message,
    String? fireIncidentId,
    bool canRetry = true,
    Object? error,
  }) {
    return BottomSheetError(
      message: message,
      fireIncidentId: fireIncidentId,
      canRetry: canRetry,
      error: error,
      occurredAt: DateTime.now().toUtc(),
    );
  }

  /// Common error states
  factory BottomSheetError.networkError(String fireIncidentId) {
    return BottomSheetError.now(
      message: 'Unable to load fire details. Check your connection.',
      fireIncidentId: fireIncidentId,
      canRetry: true,
    );
  }

  factory BottomSheetError.notFound(String fireIncidentId) {
    return BottomSheetError.now(
      message: 'Fire incident not found or no longer active.',
      fireIncidentId: fireIncidentId,
      canRetry: false,
    );
  }

  factory BottomSheetError.permissionDenied() {
    return BottomSheetError.now(
      message: 'Location permission required for distance calculations.',
      canRetry: false,
    );
  }

  factory BottomSheetError.generic([Object? error]) {
    return BottomSheetError.now(
      message: 'Unable to load fire details. Please try again.',
      canRetry: true,
      error: error,
    );
  }

  @override
  List<Object?> get props => [message, fireIncidentId, canRetry, error, occurredAt];

  @override
  String toString() {
    return 'BottomSheetError(message: $message, '
           'id: $fireIncidentId, canRetry: $canRetry)';
  }
}

/// State transition utilities for bottom sheet management
class BottomSheetStateTransitions {
  /// Show loading state when user taps fire marker
  static BottomSheetState showLoading({
    required String fireIncidentId,
    String? message,
  }) {
    return BottomSheetLoading(
      fireIncidentId: fireIncidentId,
      loadingMessage: message ?? 'Loading fire details...',
    );
  }

  /// Show loaded state with fire incident data
  static BottomSheetState showLoaded({
    required FireIncident fireIncident,
    LatLng? userLocation,
    String? distanceAndDirection,
  }) {
    return BottomSheetLoaded.now(
      fireIncident: fireIncident,
      userLocation: userLocation,
      distanceAndDirection: distanceAndDirection,
    );
  }

  /// Show error state with retry capability
  static BottomSheetState showError({
    required String message,
    String? fireIncidentId,
    bool canRetry = true,
    Object? error,
  }) {
    return BottomSheetError.now(
      message: message,
      fireIncidentId: fireIncidentId,
      canRetry: canRetry,
      error: error,
    );
  }

  /// Hide bottom sheet
  static BottomSheetState hide() {
    return const BottomSheetHidden();
  }

  /// Transition from error to loading (retry)
  static BottomSheetState retryFromError(BottomSheetError errorState) {
    if (!errorState.canRetry || errorState.fireIncidentId == null) {
      return errorState; // Cannot retry
    }

    return BottomSheetLoading(
      fireIncidentId: errorState.fireIncidentId!,
      loadingMessage: 'Retrying...',
    );
  }

  /// Update loaded state with new location data
  static BottomSheetState updateLocation({
    required BottomSheetLoaded currentState,
    required LatLng userLocation,
    required String distanceAndDirection,
  }) {
    return currentState.copyWith(
      userLocation: userLocation,
      distanceAndDirection: distanceAndDirection,
    );
  }
}