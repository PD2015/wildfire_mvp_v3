import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:wildfire_mvp_v3/models/location_display_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/location_state_manager.dart';
import 'package:wildfire_mvp_v3/services/location_resolver.dart';
import 'package:wildfire_mvp_v3/features/report/controllers/report_fire_controller.dart';

/// Mock LocationResolver for testing
///
/// Returns a default location without actually accessing GPS or preferences.
class MockLocationResolver implements LocationResolver {
  final LatLng defaultLocation;
  final LocationSource defaultSource;
  LatLng? _savedManualLocation;
  String? _savedPlaceName;

  MockLocationResolver({
    this.defaultLocation = const LatLng(57.2, -3.8), // Aviemore
    this.defaultSource = LocationSource.gps,
  });

  @override
  Future<Either<LocationError, ResolvedLocation>> getLatLon({
    bool allowDefault = true,
  }) async {
    if (_savedManualLocation != null) {
      return Right(
        ResolvedLocation(
          coordinates: _savedManualLocation!,
          source: LocationSource.cached,
          placeName: _savedPlaceName,
        ),
      );
    }
    return Right(
      ResolvedLocation(coordinates: defaultLocation, source: defaultSource),
    );
  }

  @override
  Future<void> saveManual(LatLng location, {String? placeName}) async {
    _savedManualLocation = location;
    _savedPlaceName = placeName;
  }

  @override
  Future<void> clearManualLocation() async {
    _savedManualLocation = null;
    _savedPlaceName = null;
  }

  @override
  Future<(LatLng, String?)?> loadCachedManualLocation() async {
    if (_savedManualLocation != null) {
      return (_savedManualLocation!, _savedPlaceName);
    }
    return null;
  }
}

/// Mock LocationStateManager for testing
///
/// Provides a controllable LocationStateManager that doesn't require
/// real services. Can be configured with initial state.
class MockLocationStateManager extends ChangeNotifier
    implements LocationStateManager {
  LocationDisplayState _state;
  bool _isManualLocation = false;

  MockLocationStateManager({LocationDisplayState? initialState})
      : _state = initialState ?? const LocationDisplayInitial();

  @override
  LocationDisplayState get state => _state;

  @override
  bool get isManualLocation => _isManualLocation;

  /// Set state directly for testing
  void setState(LocationDisplayState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    // Immediately transition to a success state for testing
    _state = LocationDisplaySuccess(
      coordinates: const LatLng(57.2, -3.8),
      source: LocationSource.gps,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    // No-op for testing
  }

  @override
  Future<void> setManualLocation(LatLng location, {String? placeName}) async {
    _isManualLocation = true;
    _state = LocationDisplaySuccess(
      coordinates: location,
      source: LocationSource.manual,
      placeName: placeName,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  Future<void> useGpsLocation() async {
    _isManualLocation = false;
    _state = LocationDisplaySuccess(
      coordinates: const LatLng(57.2, -3.8),
      source: LocationSource.gps,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }
}

/// Creates a ReportFireController with mock dependencies for testing
///
/// Usage:
/// ```dart
/// final controller = createMockReportFireController();
/// await tester.pumpWidget(MaterialApp(
///   home: ReportFireScreen(controller: controller),
/// ));
/// ```
ReportFireController createMockReportFireController({
  LocationDisplayState? initialState,
}) {
  final mockManager = MockLocationStateManager(initialState: initialState);
  return ReportFireController(locationStateManager: mockManager);
}
