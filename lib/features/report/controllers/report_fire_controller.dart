import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/picked_location.dart';
import 'package:wildfire_mvp_v3/models/location_display_state.dart';
import 'package:wildfire_mvp_v3/services/location_state_manager.dart';

/// Controller for Report Fire screen
///
/// Lightweight controller that delegates location management to the shared
/// LocationStateManager. Handles only fire-report-specific concerns:
/// - Navigation to location picker in fireReport mode
/// - Processing picked location results
///
/// Architecture pattern:
/// - LocationStateManager handles: GPS fetch, what3words, geocoding, state
/// - ReportFireController handles: navigation, fire-report-specific logic
///
/// This separation enables:
/// - Consistent location UX across Home, Report Fire, and future screens
/// - Reuse of LocationCard widget without duplication
/// - Single source of truth for location state
///
/// Constitutional compliance:
/// - C2: Delegates coordinate logging to LocationStateManager
/// - C4: Transparency - never implies app contacts emergency services
class ReportFireController extends ChangeNotifier {
  final LocationStateManager _locationStateManager;

  /// Whether the location picker is currently open
  bool _isPickerOpen = false;

  ReportFireController({
    required LocationStateManager locationStateManager,
  }) : _locationStateManager = locationStateManager {
    // Listen to location state changes and forward to our listeners
    _locationStateManager.addListener(_onLocationStateChanged);
  }

  /// Current location display state from shared manager
  LocationDisplayState get locationState => _locationStateManager.state;

  /// The shared location state manager (for screens that need direct access)
  LocationStateManager get locationStateManager => _locationStateManager;

  /// Whether the location picker is currently open
  bool get isPickerOpen => _isPickerOpen;

  void _onLocationStateChanged() {
    notifyListeners();
  }

  /// Initialize the controller by fetching GPS location
  ///
  /// Call this when the Report Fire screen is first displayed.
  /// Delegates to LocationStateManager.initialize().
  Future<void> initialize() async {
    await _locationStateManager.initialize();
  }

  /// Open location picker for fire location
  ///
  /// Navigates to LocationPickerScreen in [LocationPickerMode.fireReport] mode.
  /// Handles result when user confirms selection.
  ///
  /// The picker shows:
  /// - Emergency reminder banner at top
  /// - "Set Fire Location" title
  /// - "Use This Location" confirm button
  Future<void> openLocationPicker(BuildContext context) async {
    _isPickerOpen = true;
    notifyListeners();

    try {
      // Get current location to pass to picker as initial position
      final currentState = _locationStateManager.state;
      final currentLocation = currentState is LocationDisplaySuccess
          ? currentState.coordinates
          : null;
      final currentPlaceName = currentState is LocationDisplaySuccess
          ? currentState.formattedLocation ?? currentState.placeName
          : null;

      final result = await context.push<PickedLocation>(
        '/location-picker',
        extra: LocationPickerExtras(
          mode: LocationPickerMode.fireReport,
          initialLocation: currentLocation,
          initialPlaceName: currentPlaceName,
        ),
      );

      if (result != null) {
        await _locationStateManager.setManualLocation(
          result.coordinates,
          placeName: result.placeName,
        );
      }
    } finally {
      _isPickerOpen = false;
      notifyListeners();
    }
  }

  /// Clear the fire location and return to GPS
  ///
  /// Delegates to LocationStateManager.useGpsLocation().
  Future<void> useGpsLocation() async {
    await _locationStateManager.useGpsLocation();
  }

  /// Refresh location data
  ///
  /// Useful for pull-to-refresh or returning to foreground.
  Future<void> refresh() async {
    await _locationStateManager.refresh();
  }

  @override
  void dispose() {
    _locationStateManager.removeListener(_onLocationStateChanged);
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Future: Fire report submission methods
  // ──────────────────────────────────────────────────────────────────────────
  //
  // When implementing actual fire report submission, add these methods:
  //
  // /// Set fire description text
  // void setFireDescription(String description) { ... }
  //
  // /// Add photo to report
  // Future<void> addPhoto(File image) async { ... }
  //
  // /// Submit fire report to backend
  // Future<void> submitFireReport() async { ... }
}
