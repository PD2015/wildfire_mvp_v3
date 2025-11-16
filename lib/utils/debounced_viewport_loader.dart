import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/models/lat_lng_bounds.dart' as bounds;
import 'package:wildfire_mvp_v3/models/location_models.dart' as models;

/// Debounced viewport loader for preventing API spam during map navigation.
///
/// Implements 300ms debounce delay for camera position changes.
/// Cancels in-flight requests when new viewport queries arrive.
///
/// **Best Practice**: Uses GoogleMapController.getVisibleRegion() for accurate
/// viewport bounds instead of manual zoom-based calculations.
///
/// Usage:
/// ```dart
/// final loader = DebouncedViewportLoader(
///   onViewportChanged: (bounds) async {
///     await _mapController.refreshMapData(bounds);
///   },
/// );
///
/// // After GoogleMap onMapCreated:
/// loader.setMapController(mapController);
///
/// // In GoogleMap onCameraMove callback:
/// loader.onCameraMove(newPosition);
/// ```
class DebouncedViewportLoader {
  final Future<void> Function(bounds.LatLngBounds) onViewportChanged;
  final Duration debounceDuration;

  Timer? _debounceTimer;
  CameraPosition? _lastPosition;
  bounds.LatLngBounds? _lastLoadedBounds; // Track last bounds we loaded for
  bool _isLoading = false;
  GoogleMapController?
      _mapController; // Actual map controller for accurate bounds

  /// Create a debounced viewport loader.
  ///
  /// [onViewportChanged] is called after debounce delay with visible bounds.
  /// [debounceDuration] defaults to 300ms to balance responsiveness and API efficiency.
  ///
  /// **Important**: Call [setMapController] after map creation to enable
  /// accurate viewport bounds via GoogleMapController.getVisibleRegion().
  DebouncedViewportLoader({
    required this.onViewportChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  /// Set the GoogleMapController for accurate viewport bounds.
  ///
  /// **Must be called after GoogleMap onMapCreated callback.**
  /// Enables use of getVisibleRegion() instead of manual calculations.
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    debugPrint(
        '🗺️ DebouncedViewportLoader: Map controller set - using accurate viewport bounds');
  }

  /// Handle camera movement event.
  ///
  /// Debounces rapid camera changes (pan, zoom) to prevent excessive API calls.
  /// Only triggers load after user stops moving map for [debounceDuration].
  void onCameraMove(CameraPosition position) {
    _lastPosition = position;

    // Cancel existing timer
    _debounceTimer?.cancel();

    // Start new debounce timer
    _debounceTimer = Timer(debounceDuration, () {
      _triggerLoad();
    });
  }

  /// Handle camera idle event (user stopped moving map).
  ///
  /// Immediately triggers load if no load in progress.
  /// This ensures load happens even if debounce timer hasn't fired yet.
  void onCameraIdle() {
    if (_lastPosition != null && !_isLoading) {
      _debounceTimer?.cancel();
      _triggerLoad();
    }
  }

  /// Trigger viewport load with current camera position.
  Future<void> _triggerLoad() async {
    if (_lastPosition == null || _isLoading) {
      return;
    }

    // Cancel debounce timer to prevent double load
    // (onCameraIdle fires before timer completes)
    _debounceTimer?.cancel();
    _debounceTimer = null;

    _isLoading = true;

    try {
      // Use GoogleMapController.getVisibleRegion() for accurate bounds
      // Falls back to calculation if controller not available yet
      bounds.LatLngBounds visibleBounds;

      if (_mapController != null) {
        // BEST PRACTICE: Use actual visible region from GoogleMapController
        final region = await _mapController!.getVisibleRegion();

        // Convert google_maps_flutter.LatLngBounds to our bounds.LatLngBounds
        visibleBounds = bounds.LatLngBounds(
          southwest: models.LatLng(
            region.southwest.latitude,
            region.southwest.longitude,
          ),
          northeast: models.LatLng(
            region.northeast.latitude,
            region.northeast.longitude,
          ),
        );

        debugPrint(
          '🗺️ DebouncedViewportLoader: Using accurate getVisibleRegion() bounds: '
          'SW(${visibleBounds.southwest.latitude.toStringAsFixed(4)},${visibleBounds.southwest.longitude.toStringAsFixed(4)}) '
          'NE(${visibleBounds.northeast.latitude.toStringAsFixed(4)},${visibleBounds.northeast.longitude.toStringAsFixed(4)})',
        );
      } else {
        // Fallback: Calculate approximate bounds (less accurate)
        visibleBounds = _calculateVisibleBounds(_lastPosition!);
        debugPrint(
          '🗺️ DebouncedViewportLoader: Using calculated bounds (map controller not set): '
          'SW(${visibleBounds.southwest.latitude.toStringAsFixed(4)},${visibleBounds.southwest.longitude.toStringAsFixed(4)}) '
          'NE(${visibleBounds.northeast.latitude.toStringAsFixed(4)},${visibleBounds.northeast.longitude.toStringAsFixed(4)})',
        );
      }

      // Check if bounds have significantly changed since last load
      if (_lastLoadedBounds != null &&
          _isSameBounds(visibleBounds, _lastLoadedBounds!)) {
        debugPrint(
            '🗺️ DebouncedViewportLoader: Skipping load - viewport unchanged');
        _isLoading = false;
        return;
      }

      await onViewportChanged(visibleBounds);

      // Track this bounds as loaded
      _lastLoadedBounds = visibleBounds;

      debugPrint('🗺️ DebouncedViewportLoader: Viewport load complete');
    } catch (e) {
      debugPrint('🗺️ DebouncedViewportLoader: Error loading viewport: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Calculate visible map bounds from camera position.
  ///
  /// **FALLBACK ONLY**: Used when GoogleMapController not available yet.
  /// Less accurate than getVisibleRegion() due to manual zoom calculations.
  /// Prefers getVisibleRegion() when map controller is set.
  bounds.LatLngBounds _calculateVisibleBounds(CameraPosition position) {
    // Approximate visible area based on zoom level
    // Zoom level 0: whole world (~360° longitude, ~170° latitude)
    // Each zoom level doubles map scale (halves visible area)
    // Formula: visible_degrees = base_degrees / (2 ^ zoom)

    const baseLatDegrees = 170.0; // Approximate world height in degrees
    const baseLonDegrees = 360.0; // World width in degrees

    final zoom = position.zoom;
    final scale = 1.0 / (1 << zoom.toInt()); // 2^zoom using bit shift

    final latDelta = (baseLatDegrees * scale) / 2;
    final lonDelta = (baseLonDegrees * scale) / 2;

    // Add 25% padding to ensure all visible markers are loaded
    // Increased from 10% to catch markers near viewport edges
    final paddedLatDelta = latDelta * 1.25;
    final paddedLonDelta = lonDelta * 1.25;

    return bounds.LatLngBounds(
      southwest: models.LatLng(
        (position.target.latitude - paddedLatDelta).clamp(-90.0, 90.0),
        (position.target.longitude - paddedLonDelta).clamp(-180.0, 180.0),
      ),
      northeast: models.LatLng(
        (position.target.latitude + paddedLatDelta).clamp(-90.0, 90.0),
        (position.target.longitude + paddedLonDelta).clamp(-180.0, 180.0),
      ),
    );
  }

  /// Check if two bounds represent the same viewport.
  ///
  /// Compares southwest/northeast corners with small tolerance
  /// to prevent redundant loads on identical viewports.
  bool _isSameBounds(bounds.LatLngBounds bounds1, bounds.LatLngBounds bounds2) {
    const tolerance = 0.0001; // ~10m at equator - very precise

    return (bounds1.southwest.latitude - bounds2.southwest.latitude).abs() <
            tolerance &&
        (bounds1.southwest.longitude - bounds2.southwest.longitude).abs() <
            tolerance &&
        (bounds1.northeast.latitude - bounds2.northeast.latitude).abs() <
            tolerance &&
        (bounds1.northeast.longitude - bounds2.northeast.longitude).abs() <
            tolerance;
  }

  /// Check if loader is currently loading data.
  bool get isLoading => _isLoading;

  /// Get last camera position processed.
  CameraPosition? get lastPosition => _lastPosition;

  /// Cancel any pending loads and reset state.
  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isLoading = false;
    _lastPosition = null;
    _lastLoadedBounds = null; // Reset loaded bounds tracking
  }

  /// Dispose of resources (cancel timers).
  void dispose() {
    _debounceTimer?.cancel();
  }
}
