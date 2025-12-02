import 'package:equatable/equatable.dart';
import '../../../models/location_models.dart';

/// Result returned from LocationPickerScreen via Navigator.pop
///
/// Contains the selected location and optional metadata.
/// Used by:
/// - HomeScreen: to update risk assessment location
/// - ReportFireScreen: to get what3words for clipboard copy
class PickedLocation extends Equatable {
  /// Selected coordinates (validated)
  final LatLng coordinates;

  /// what3words address (null if API was unavailable or still loading)
  final String? what3words;

  /// Human-readable place name from search or reverse geocode
  final String? placeName;

  /// Timestamp when location was selected (for audit/debugging)
  final DateTime selectedAt;

  const PickedLocation({
    required this.coordinates,
    this.what3words,
    this.placeName,
    required this.selectedAt,
  });

  /// Creates a PickedLocation with current timestamp
  factory PickedLocation.now({
    required LatLng coordinates,
    String? what3words,
    String? placeName,
  }) {
    return PickedLocation(
      coordinates: coordinates,
      what3words: what3words,
      placeName: placeName,
      selectedAt: DateTime.now(),
    );
  }

  /// Whether this result has a what3words address
  bool get hasWhat3words => what3words != null && what3words!.isNotEmpty;

  /// Whether this result has a place name
  bool get hasPlaceName => placeName != null && placeName!.isNotEmpty;

  /// Display text for the location
  ///
  /// Priority: placeName > what3words > coordinates
  String get displayText {
    if (hasPlaceName) return placeName!;
    if (hasWhat3words) return '///$what3words';
    return '${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';
  }

  @override
  List<Object?> get props => [coordinates, what3words, placeName, selectedAt];

  @override
  String toString() =>
      'PickedLocation(coordinates: $coordinates, what3words: $what3words, placeName: $placeName, selectedAt: $selectedAt)';
}
