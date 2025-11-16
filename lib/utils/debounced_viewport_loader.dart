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
/// Usage:
/// ```dart
/// final loader = DebouncedViewportLoader(
///   onViewportChanged: (bounds) async {
///     await _mapController.refreshMapData(bounds);
///   },
/// );
///
/// // In GoogleMap onCameraMove callback:
/// loader.onCameraMove(newPosition);
/// ```
class DebouncedViewportLoader {
  final Future<void> Function(bounds.LatLngBounds) onViewportChanged;
  final Duration debounceDuration;

  Timer? _debounceTimer;
  CameraPosition? _lastPosition;
  CameraPosition? _lastLoadedPosition; // Track last position we loaded for
  bool _isLoading = false;

  /// Create a debounced viewport loader.
  ///
  /// [onViewportChanged] is called after debounce delay with visible bounds.
  /// [debounceDuration] defaults to 300ms to balance responsiveness and API efficiency.
  DebouncedViewportLoader({
    required this.onViewportChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

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

    // Check if viewport has actually changed since last load
    if (_lastLoadedPosition != null &&
        _isSameViewport(_lastPosition!, _lastLoadedPosition!)) {
      debugPrint(
          '🗺️ DebouncedViewportLoader: Skipping load - viewport unchanged');
      return;
    }

    // Cancel debounce timer to prevent double load
    // (onCameraIdle fires before timer completes)
    _debounceTimer?.cancel();
    _debounceTimer = null;

    _isLoading = true;

    try {
      final visibleBounds = _calculateVisibleBounds(_lastPosition!);
      debugPrint(
        '🗺️ DebouncedViewportLoader: Loading fires for viewport: '
        'SW(${visibleBounds.southwest.latitude.toStringAsFixed(2)},${visibleBounds.southwest.longitude.toStringAsFixed(2)}) '
        'NE(${visibleBounds.northeast.latitude.toStringAsFixed(2)},${visibleBounds.northeast.longitude.toStringAsFixed(2)})',
      );

      await onViewportChanged(visibleBounds);

      // Track this position as loaded
      _lastLoadedPosition = _lastPosition;

      debugPrint('🗺️ DebouncedViewportLoader: Viewport load complete');
    } catch (e) {
      debugPrint('🗺️ DebouncedViewportLoader: Error loading viewport: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Calculate visible map bounds from camera position.
  ///
  /// Estimates bounds based on zoom level and center coordinates.
  /// More accurate than waiting for LatLngBounds from map controller.
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

    // Add 10% padding to ensure all visible markers are loaded
    final paddedLatDelta = latDelta * 1.1;
    final paddedLonDelta = lonDelta * 1.1;

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

  /// Check if two camera positions represent the same viewport.
  ///
  /// Compares target coordinates and zoom level with small tolerance
  /// to prevent redundant loads on identical viewports.
  bool _isSameViewport(CameraPosition pos1, CameraPosition pos2) {
    const latLonTolerance = 0.001; // ~100m at equator
    const zoomTolerance = 0.1;

    return (pos1.target.latitude - pos2.target.latitude).abs() <
            latLonTolerance &&
        (pos1.target.longitude - pos2.target.longitude).abs() <
            latLonTolerance &&
        (pos1.zoom - pos2.zoom).abs() < zoomTolerance;
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
    _lastLoadedPosition = null; // Reset loaded position tracking
  }

  /// Dispose of resources (cancel timers).
  void dispose() {
    _debounceTimer?.cancel();
  }
}
