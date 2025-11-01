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

  const HomeStateLoading({this.isRetry = false, required this.startTime});

  @override
  List<Object?> get props => [isRetry, startTime];

  @override
  String toString() =>
      'HomeStateLoading(isRetry: $isRetry, startTime: $startTime)';
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

  const HomeStateSuccess({
    required this.riskData,
    required this.location,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [riskData, location, lastUpdated];

  @override
  String toString() =>
      'HomeStateSuccess(riskData: $riskData, location: $location, lastUpdated: $lastUpdated)';
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
