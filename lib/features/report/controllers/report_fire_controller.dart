import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/picked_location.dart';
import 'package:wildfire_mvp_v3/features/report/models/report_fire_state.dart';

/// Controller for Report Fire screen
///
/// Manages location helper state and navigation to LocationPickerScreen.
/// Designed for future extension with fire report submission.
///
/// Constitutional compliance:
/// - C2: Uses redacted logging for coordinates (5dp in formattedCoordinates)
/// - C4: Transparency - never implies app contacts emergency services
///
/// Usage:
/// ```dart
/// final controller = ReportFireController();
/// // Listen to state changes
/// controller.addListener(() {
///   // Rebuild UI with controller.state
/// });
/// // Open location picker
/// await controller.openLocationPicker(context);
/// ```
class ReportFireController extends ChangeNotifier {
  ReportFireState _state = const ReportFireState.initial();

  /// Current state
  ReportFireState get state => _state;

  /// Update state and notify listeners
  void _updateState(ReportFireState newState) {
    _state = newState;
    notifyListeners();
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
    final result = await context.push<PickedLocation>(
      '/location-picker',
      extra: LocationPickerMode.fireReport,
    );

    if (result != null) {
      onLocationPicked(result);
    }
  }

  /// Process picked location from LocationPickerScreen
  ///
  /// Maps [PickedLocation] to [ReportFireLocation] model,
  /// parsing the raw what3words string into validated address.
  void onLocationPicked(PickedLocation picked) {
    final newLocation = ReportFireLocation.fromPickedLocation(
      coordinates: picked.coordinates,
      what3wordsRaw: picked.what3words,
      placeName: picked.placeName,
    );

    _updateState(_state.copyWith(fireLocation: newLocation));

    // C2 compliant: only log formatted coordinates (5dp precision)
    debugPrint('🔥 Fire location set: ${newLocation.formattedCoordinates}');
  }

  /// Clear the fire location
  ///
  /// Resets state to initial (no location).
  void clearLocation() {
    _updateState(_state.copyWith(clearLocation: true));
    debugPrint('🔥 Fire location cleared');
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
  // /// Remove photo from report
  // void removePhoto(int index) { ... }
  //
  // /// Submit fire report to backend
  // Future<void> submitFireReport() async {
  //   _updateState(_state.copyWith(isSubmitting: true));
  //   try {
  //     await _fireReportService.submit(_state);
  //     _updateState(_state.copyWith(
  //       isSubmitting: false,
  //       submittedAt: DateTime.now(),
  //     ));
  //   } catch (e) {
  //     _updateState(_state.copyWith(
  //       isSubmitting: false,
  //       submissionError: e.toString(),
  //     ));
  //   }
  // }
  //
  // /// Reset report to initial state
  // void resetReport() {
  //   _updateState(const ReportFireState.initial());
  // }
}
