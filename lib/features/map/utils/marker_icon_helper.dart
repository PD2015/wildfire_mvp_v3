import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';

/// Helper utility for creating custom fire marker icons
///
/// Provides two marker styles:
/// 1. **Flame pins** (low zoom): Teardrop markers with fire icon for overview
/// 2. **Pixel squares** (high zoom): Square markers representing satellite
///    detection footprint (~375m for VIIRS), matching GWIS/FIRMS display
///
/// Usage:
/// ```dart
/// await MarkerIconHelper.initialize();
/// final pinIcon = MarkerIconHelper.getIcon('high');      // Flame pin
/// final pixelIcon = MarkerIconHelper.getPixelIcon('high'); // Pixel square
/// ```
class MarkerIconHelper {
  /// Cached flame pin icons by intensity
  static final Map<String, BitmapDescriptor> _iconCache = {};

  /// Cached pixel square icons by intensity
  static final Map<String, BitmapDescriptor> _pixelCache = {};

  /// Whether icons have been initialized
  static bool _isInitialized = false;

  /// Check if icons are ready to use
  static bool get isReady => _isInitialized;

  /// Flame pin size in logical pixels (close to Google Maps default ~27px)
  static const double _iconSize = 28.0;

  /// Pixel square size - represents satellite detection footprint
  /// VIIRS detects ~375m pixels, this renders as visible square on map
  static const double _pixelSize = 16.0;

  /// Initialize and pre-load all marker icons (both flame pins and pixel squares)
  ///
  /// Call this during widget initialization to avoid async icon loading
  /// when markers are first created.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Future.wait([
        // Flame pin icons for low zoom
        _createIconFromMaterial('low', _getColorForIntensity('low')),
        _createIconFromMaterial('moderate', _getColorForIntensity('moderate')),
        _createIconFromMaterial('high', _getColorForIntensity('high')),
        _createIconFromMaterial('unknown', RiskPalette.midGray),
        // Pixel square icons for high zoom
        _createPixelIcon('low', _getColorForIntensity('low')),
        _createPixelIcon('moderate', _getColorForIntensity('moderate')),
        _createPixelIcon('high', _getColorForIntensity('high')),
        _createPixelIcon('unknown', RiskPalette.midGray),
      ]);

      _isInitialized = true;
      debugPrint('🔥 MarkerIconHelper: All flame and pixel icons initialized');
    } catch (e) {
      debugPrint('⚠️ MarkerIconHelper: Failed to initialize icons: $e');
    }
  }

  /// Get the appropriate flame icon for the given intensity
  ///
  /// Returns a fallback default marker if icons haven't been initialized.
  static BitmapDescriptor getIcon(String intensity) {
    final normalizedIntensity = intensity.toLowerCase();

    if (!_isInitialized) {
      debugPrint(
        '⚠️ MarkerIconHelper: Icons not initialized, using default marker',
      );
      return _getFallbackMarker(normalizedIntensity);
    }

    return _iconCache[normalizedIntensity] ??
        _iconCache['unknown'] ??
        BitmapDescriptor.defaultMarker;
  }

  /// Get pixel square icon for high-zoom satellite footprint display
  ///
  /// These icons represent the actual satellite detection pixel (~375m VIIRS).
  /// Use at zoom >= 10 for precise fire location display matching GWIS/FIRMS.
  /// Returns a fallback default marker if icons haven't been initialized.
  static BitmapDescriptor getPixelIcon(String intensity) {
    final normalizedIntensity = intensity.toLowerCase();

    if (!_isInitialized) {
      debugPrint(
        '⚠️ MarkerIconHelper: Icons not initialized, using default marker',
      );
      return _getFallbackMarker(normalizedIntensity);
    }

    return _pixelCache[normalizedIntensity] ??
        _pixelCache['unknown'] ??
        BitmapDescriptor.defaultMarker;
  }

  /// Get color for intensity level using RiskPalette
  static Color _getColorForIntensity(String intensity) {
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
  static BitmapDescriptor _getFallbackMarker(String intensity) {
    switch (intensity) {
      case 'high':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'moderate':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'low':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
    }
  }

  /// Create a pixel square icon for satellite footprint display
  ///
  /// Renders as a filled square with a contrasting border, representing
  /// the actual satellite detection pixel (~375m for VIIRS sensors).
  static Future<void> _createPixelIcon(String intensity, Color color) async {
    try {
      final bytes = await _renderPixelSquare(color, _pixelSize);
      final descriptor = BitmapDescriptor.bytes(bytes);
      _pixelCache[intensity] = descriptor;
      debugPrint('🔲 Created pixel icon for intensity: $intensity');
    } catch (e) {
      debugPrint('⚠️ Failed to create pixel icon for $intensity: $e');
      _pixelCache[intensity] = _getFallbackMarker(intensity);
    }
  }

  /// Render a pixel square to PNG bytes
  ///
  /// Square with filled color and contrasting border for visibility
  static Future<Uint8List> _renderPixelSquare(Color color, double size) async {
    const double scale = 2.0;
    final double scaledSize = size * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(2, 2, scaledSize - 2, scaledSize - 2),
      shadowPaint,
    );

    // Draw filled square with intensity color
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, scaledSize - 2, scaledSize - 2),
      fillPaint,
    );

    // Draw contrasting border for visibility against map
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTWH(1, 1, scaledSize - 4, scaledSize - 4),
      borderPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(scaledSize.toInt(), scaledSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert pixel icon to bytes');
    }

    return byteData.buffer.asUint8List();
  }

  /// Create a marker icon from Material Icons.local_fire_department
  static Future<void> _createIconFromMaterial(
    String intensity,
    Color color,
  ) async {
    try {
      final bytes = await _renderMaterialIcon(
        Icons.local_fire_department,
        color,
        _iconSize,
      );
      final descriptor = BitmapDescriptor.bytes(bytes);
      _iconCache[intensity] = descriptor;
      debugPrint('🔥 Created flame icon for intensity: $intensity');
    } catch (e) {
      debugPrint('⚠️ Failed to create flame icon for $intensity: $e');
      _iconCache[intensity] = _getFallbackMarker(intensity);
    }
  }

  /// Render a Material icon to PNG bytes with Google-style teardrop pin shape
  static Future<Uint8List> _renderMaterialIcon(
    IconData icon,
    Color color,
    double size,
  ) async {
    // Use 2x scale for crisp rendering on retina displays
    const double scale = 2.0;
    final double scaledSize = size * scale;

    // Pin dimensions - use 1.6 ratio like Google Maps default markers
    final double pinWidth = scaledSize;
    final double pinHeight = scaledSize * 1.6;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw shadow first (offset down and right)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final shadowPath = _createTeardropPath(
      pinWidth / 2 + 3, // Offset right
      6, // Offset down
      pinWidth * 0.42,
      pinHeight,
    );
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw white teardrop background
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pinPath = _createTeardropPath(
      pinWidth / 2,
      0,
      pinWidth * 0.42,
      pinHeight,
    );
    canvas.drawPath(pinPath, bgPaint);

    // Draw subtle border for definition
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(pinPath, borderPaint);

    // Draw the icon using TextPainter with icon font
    // Position icon in the circular part (upper portion of teardrop)
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: pinWidth * 0.55,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Center the icon horizontally, position in upper circular area
    final circleRadius = pinWidth * 0.42;
    final circleCenterY = circleRadius; // Center of the circular part
    final iconOffset = Offset(
      (pinWidth - textPainter.width) / 2,
      circleCenterY - (textPainter.height / 2),
    );

    textPainter.paint(canvas, iconOffset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(pinWidth.toInt(), pinHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert icon to bytes');
    }

    return byteData.buffer.asUint8List();
  }

  /// Create a teardrop/pin path like Google Maps markers
  ///
  /// The shape is a circle at the top with a pointed bottom.
  /// [centerX] - horizontal center of the pin
  /// [topY] - top edge of the circular part
  /// [radius] - radius of the circular part
  /// [totalHeight] - total height including the point
  static Path _createTeardropPath(
    double centerX,
    double topY,
    double radius,
    double totalHeight,
  ) {
    final path = Path();

    // The circular part center
    final circleCenterY = topY + radius;

    // Point at the bottom
    final pointY = topY + totalHeight * 0.85;

    // Start at the bottom point
    path.moveTo(centerX, pointY);

    // Draw left curve from point up to the circle
    // Using quadratic bezier for smooth curve
    path.quadraticBezierTo(
      centerX - radius * 0.8, // Control point X (pulls curve outward)
      circleCenterY + radius * 0.6, // Control point Y
      centerX - radius, // End at left edge of circle
      circleCenterY, // At circle center height
    );

    // Draw the circular top (arc from left to right)
    path.arcToPoint(
      Offset(centerX + radius, circleCenterY),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Draw right curve from circle down to point
    path.quadraticBezierTo(
      centerX + radius * 0.8, // Control point X (pulls curve outward)
      circleCenterY + radius * 0.6, // Control point Y
      centerX, // End at bottom point
      pointY,
    );

    path.close();
    return path;
  }
}
