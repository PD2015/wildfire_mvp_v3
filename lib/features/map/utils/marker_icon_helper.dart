import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Helper utility for creating custom flame marker icons
///
/// Provides flame-shaped markers colored by fire intensity level.
/// Icons are programmatically drawn for consistent branding and
/// cached to avoid repeated generation.
///
/// Usage:
/// ```dart
/// final helper = MarkerIconHelper();
/// await helper.initialize(); // Pre-load all icons
/// final icon = helper.getIcon('high'); // Get cached icon
/// ```
class MarkerIconHelper {
  /// Cached marker icons by intensity
  final Map<String, BitmapDescriptor> _iconCache = {};

  /// Whether icons have been initialized
  bool _isInitialized = false;

  /// Check if icons are ready to use
  bool get isReady => _isInitialized;

  /// Icon size in logical pixels (will be scaled for device pixel ratio)
  static const double _iconSize = 48.0;

  /// Initialize and pre-load all flame icons
  ///
  /// Call this during widget initialization to avoid async icon loading
  /// when markers are first created.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Future.wait([
      _createFlameIcon('low', _getColorForIntensity('low')),
      _createFlameIcon('moderate', _getColorForIntensity('moderate')),
      _createFlameIcon('high', _getColorForIntensity('high')),
      _createFlameIcon('unknown', RiskPalette.midGray),
    ]);

    _isInitialized = true;
    debugPrint('🔥 MarkerIconHelper: All flame icons initialized');
  }

  /// Get the appropriate flame icon for the given intensity
  ///
  /// Returns a fallback default marker if icons haven't been initialized.
  BitmapDescriptor getIcon(String intensity) {
    final normalizedIntensity = intensity.toLowerCase();

    if (!_isInitialized) {
      debugPrint(
          '⚠️ MarkerIconHelper: Icons not initialized, using default marker');
      return _getFallbackMarker(normalizedIntensity);
    }

    return _iconCache[normalizedIntensity] ??
        _iconCache['unknown'] ??
        BitmapDescriptor.defaultMarker;
  }

  /// Get color for intensity level using RiskPalette
  Color _getColorForIntensity(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'high':
        return RiskPalette.veryHigh; // Red
      case 'moderate':
        return RiskPalette.high; // Orange
      case 'low':
        return RiskPalette.low; // Green
      default:
        return RiskPalette.midGray; // Gray for unknown
    }
  }

  /// Fallback to default hue-based markers if custom icons not ready
  BitmapDescriptor _getFallbackMarker(String intensity) {
    switch (intensity) {
      case 'high':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'moderate':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'low':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
    }
  }

  /// Create a flame-shaped icon with the given color
  Future<void> _createFlameIcon(String intensity, Color color) async {
    try {
      final bytes = await _drawFlameIcon(color);
      final descriptor = BitmapDescriptor.bytes(bytes);
      _iconCache[intensity] = descriptor;
      debugPrint('🔥 Created flame icon for intensity: $intensity');
    } catch (e) {
      debugPrint('⚠️ Failed to create flame icon for $intensity: $e');
      // Use fallback marker on failure
      _iconCache[intensity] = _getFallbackMarker(intensity);
    }
  }

  /// Draw a flame icon using Canvas
  ///
  /// Creates a stylized flame shape with gradient fill and
  /// drop shadow for visibility on the map.
  Future<Uint8List> _drawFlameIcon(Color color) async {
    // Use higher resolution for crisp icons on high-DPI screens
    const double scale = 3.0;
    const double size = _iconSize * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw drop shadow for visibility
    _drawFlamePath(
      canvas,
      size,
      Colors.black.withValues(alpha: 0.3),
      offset: const Offset(2, 2),
    );

    // Draw main flame
    _drawFlamePath(canvas, size, color);

    // Draw inner highlight for depth
    _drawFlameHighlight(canvas, size, color);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert flame icon to bytes');
    }

    return byteData.buffer.asUint8List();
  }

  /// Draw the flame shape path
  void _drawFlamePath(
    Canvas canvas,
    double size,
    Color color, {
    Offset offset = Offset.zero,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Flame shape - stylized fire icon
    // Base point at bottom center, flame curves up with tongues
    final centerX = size / 2 + offset.dx;
    final bottom = size * 0.95 + offset.dy;
    final top = size * 0.08 + offset.dy;

    // Start at bottom center point
    path.moveTo(centerX, bottom);

    // Left side of flame - curves outward then up
    path.quadraticBezierTo(
      centerX - size * 0.35 + offset.dx,
      bottom - size * 0.15,
      centerX - size * 0.30 + offset.dx,
      bottom - size * 0.40,
    );

    // Left tongue of flame
    path.quadraticBezierTo(
      centerX - size * 0.35 + offset.dx,
      bottom - size * 0.55,
      centerX - size * 0.20 + offset.dx,
      bottom - size * 0.65,
    );

    // Curve to top point
    path.quadraticBezierTo(
      centerX - size * 0.15 + offset.dx,
      top + size * 0.15,
      centerX,
      top,
    );

    // Right side - mirror of left
    path.quadraticBezierTo(
      centerX + size * 0.15 + offset.dx,
      top + size * 0.15,
      centerX + size * 0.20 + offset.dx,
      bottom - size * 0.65,
    );

    // Right tongue of flame
    path.quadraticBezierTo(
      centerX + size * 0.35 + offset.dx,
      bottom - size * 0.55,
      centerX + size * 0.30 + offset.dx,
      bottom - size * 0.40,
    );

    // Curve back to bottom center
    path.quadraticBezierTo(
      centerX + size * 0.35 + offset.dx,
      bottom - size * 0.15,
      centerX,
      bottom,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draw inner highlight for 3D depth effect
  void _drawFlameHighlight(Canvas canvas, double size, Color baseColor) {
    // Lighter inner flame
    final highlightColor = Color.lerp(baseColor, Colors.yellow, 0.4)!;

    final paint = Paint()
      ..color = highlightColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path = Path();

    final centerX = size / 2;
    final bottom = size * 0.85;
    final top = size * 0.25;

    // Smaller inner flame shape
    path.moveTo(centerX, bottom);

    path.quadraticBezierTo(
      centerX - size * 0.15,
      bottom - size * 0.20,
      centerX - size * 0.12,
      bottom - size * 0.40,
    );

    path.quadraticBezierTo(
      centerX - size * 0.10,
      top + size * 0.10,
      centerX,
      top,
    );

    path.quadraticBezierTo(
      centerX + size * 0.10,
      top + size * 0.10,
      centerX + size * 0.12,
      bottom - size * 0.40,
    );

    path.quadraticBezierTo(
      centerX + size * 0.15,
      bottom - size * 0.20,
      centerX,
      bottom,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  /// Dispose of cached icons
  void dispose() {
    _iconCache.clear();
    _isInitialized = false;
  }
}
