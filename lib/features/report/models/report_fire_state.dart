import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart' as app;
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

/// Location data for fire report helper
///
/// Stores user-selected fire location to help communicate with emergency services.
/// This is purely informational - it does NOT submit any report.
///
/// Used by [ReportFireLocationHelperCard] to display location details
/// that users can read out when calling 999/101/Crimestoppers.
///
/// Constitutional compliance:
/// - C2: Coordinates only logged via redacted format in controller
/// - C4: Clear that this is helper data, not a submitted report
class ReportFireLocation extends Equatable {
  /// Selected coordinates (required)
  final app.LatLng coordinates;

  /// Human-readable place name from search or reverse geocode (optional)
  final String? nearestPlaceName;

  /// Validated what3words address (optional)
  final What3wordsAddress? what3words;

  /// Timestamp when location was selected
  final DateTime selectedAt;

  const ReportFireLocation({
    required this.coordinates,
    this.nearestPlaceName,
    this.what3words,
    required this.selectedAt,
  });

  /// Factory to create from [PickedLocation] result
  ///
  /// Parses raw what3words string into validated [What3wordsAddress].
  /// Returns null for what3words if parsing fails or input is null.
  factory ReportFireLocation.fromPickedLocation({
    required app.LatLng coordinates,
    String? what3wordsRaw,
    String? placeName,
  }) {
    return ReportFireLocation(
      coordinates: coordinates,
      nearestPlaceName: placeName,
      what3words: what3wordsRaw != null
          ? What3wordsAddress.tryParse(what3wordsRaw)
          : null,
      selectedAt: DateTime.now(),
    );
  }

  /// Formatted coordinates with 5dp precision for emergency services
  ///
  /// 5 decimal places provides ~1.1m accuracy, recommended for fire service.
  /// Format: "55.95330, -3.18830"
  String get formattedCoordinates =>
      '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}';

  /// Plain text for clipboard copy
  ///
  /// Includes all available location data in a format suitable for
  /// pasting into notes before calling emergency services.
  ///
  /// Example output:
  /// ```
  /// Nearest place: Cairngorms National Park
  /// Coordinates: 57.04850, -3.59620
  /// what3words: ///slurs.this.name
  /// ```
  String toClipboardText() {
    final buffer = StringBuffer();
    if (nearestPlaceName != null) {
      buffer.writeln('Nearest place: $nearestPlaceName');
    }
    buffer.writeln('Coordinates: $formattedCoordinates');
    if (what3words != null) {
      buffer.writeln('what3words: ${what3words!.displayFormat}');
    }
    return buffer.toString().trim();
  }

  @override
  List<Object?> get props =>
      [coordinates, nearestPlaceName, what3words, selectedAt];

  @override
  String toString() =>
      'ReportFireLocation(coords: $formattedCoordinates, place: $nearestPlaceName, w3w: ${what3words?.words})';
}

/// State for Report Fire screen
///
/// Currently holds optional fire location for the helper card.
/// Designed for future extension when actual fire report submission is implemented.
///
/// Future fields (when implementing report submission):
/// - fireDescription: String?
/// - photoUrls: List<String>?
/// - isSubmitting: bool
/// - submissionError: String?
/// - submittedAt: DateTime?
class ReportFireState extends Equatable {
  /// Optional location set by user for the fire
  final ReportFireLocation? fireLocation;

  const ReportFireState({
    this.fireLocation,
  });

  /// Initial state with no location set
  const ReportFireState.initial() : fireLocation = null;

  /// Create copy with updated fields
  ///
  /// Use [clearLocation] = true to explicitly clear the location.
  ReportFireState copyWith({
    ReportFireLocation? fireLocation,
    bool clearLocation = false,
  }) {
    return ReportFireState(
      fireLocation: clearLocation ? null : (fireLocation ?? this.fireLocation),
    );
  }

  /// Whether user has set a fire location
  bool get hasLocation => fireLocation != null;

  @override
  List<Object?> get props => [fireLocation];

  @override
  String toString() => 'ReportFireState(hasLocation: $hasLocation)';
}
