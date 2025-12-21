import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Navigation extras for the location picker route
///
/// Bundles all parameters needed when navigating to the location picker screen.
/// Used with go_router's `extra` parameter.
class LocationPickerExtras {
  /// The mode determines UI behavior (risk location vs fire report)
  final LocationPickerMode mode;

  /// Optional initial location to center the map on
  /// If null, map will default to Scotland centroid
  final LatLng? initialLocation;

  /// Optional initial place name to display
  final String? initialPlaceName;

  const LocationPickerExtras({
    required this.mode,
    this.initialLocation,
    this.initialPlaceName,
  });
}

/// Mode for location picker behavior based on entry point
///
/// Determines:
/// - UI variations (title, banners, emphasis)
/// - What happens on confirmation
/// - Whether location is persisted or just returned
enum LocationPickerMode {
  /// Picking location for fire risk assessment (from HomeScreen)
  ///
  /// Behavior:
  /// - Title: "Select Location"
  /// - No emergency banner
  /// - On confirm: saves to LocationResolver, then Navigator.pop
  /// - Primary action emphasis on coordinates
  riskLocation,

  /// Picking location for fire report (from ReportFireScreen)
  ///
  /// Behavior:
  /// - Title: "Set Fire Location"
  /// - Shows emergency reminder banner at top
  /// - On confirm: returns result without saving (for clipboard copy)
  /// - Primary action emphasis on what3words (for 999 calls)
  fireReport,
}

/// Extension methods for LocationPickerMode
extension LocationPickerModeExtension on LocationPickerMode {
  /// Display title for the AppBar
  String get title => switch (this) {
    LocationPickerMode.riskLocation => 'Select Location',
    LocationPickerMode.fireReport => 'Set Fire Location',
  };

  /// Whether to show emergency reminder banner
  bool get showEmergencyBanner => this == LocationPickerMode.fireReport;

  /// Confirm button text
  String get confirmButtonText => switch (this) {
    LocationPickerMode.riskLocation => 'Confirm Location',
    LocationPickerMode.fireReport => 'Use This Location',
  };
}
