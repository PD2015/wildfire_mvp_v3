import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:wildfire_mvp_v3/features/map/utils/hotspot_style_helper.dart';
import 'package:wildfire_mvp_v3/models/hotspot_cluster.dart';

/// Builds cluster markers for grouped hotspots on Google Maps
///
/// Creates circular badge markers with count labels that represent
/// aggregated hotspots. Follows Google Maps cluster marker style.
///
/// Part of 021-live-fire-data feature implementation.
///
/// Usage:
/// ```dart
/// final markers = await HotspotClusterMarker.buildMarkers(
///   clusters: clusterList,
///   onTap: (cluster) => zoomToFit(cluster.bounds),
/// );
/// ```
class HotspotClusterMarker {
  /// Cache of generated marker icons by size and color
  static final Map<String, gmap.BitmapDescriptor> _iconCache = {};

  /// Build a set of cluster markers for all clusters
  ///
  /// Returns markers with tap handlers that receive cluster bounds
  /// for zoom-to-fit functionality.
  static Future<Set<gmap.Marker>> buildMarkers({
    required List<HotspotCluster> clusters,
    required void Function(HotspotCluster) onTap,
  }) async {
    final markers = <gmap.Marker>{};

    for (final cluster in clusters) {
      final icon = await _getClusterIcon(cluster);

      markers.add(gmap.Marker(
        markerId: gmap.MarkerId('cluster_${cluster.id}'),
        position: gmap.LatLng(
          cluster.center.latitude,
          cluster.center.longitude,
        ),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        onTap: () => onTap(cluster),
        infoWindow: gmap.InfoWindow(
          title: '${cluster.count} fire detections',
          snippet: 'Tap to zoom in',
        ),
      ));
    }

    return markers;
  }

  /// Get or create a cluster icon for the given cluster
  static Future<gmap.BitmapDescriptor> _getClusterIcon(
    HotspotCluster cluster,
  ) async {
    final sizeCategory =
        HotspotStyleHelper.getClusterSizeCategory(cluster.count);
    final color = HotspotStyleHelper.getClusterColor(cluster.maxFrp);
    final cacheKey = '${sizeCategory}_${color.toARGB32()}';

    // Return cached icon if available
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    // Generate new icon
    final icon = await _generateClusterIcon(cluster.count, sizeCategory, color);
    _iconCache[cacheKey] = icon;
    return icon;
  }

  /// Generate a circular cluster marker icon
  static Future<gmap.BitmapDescriptor> _generateClusterIcon(
    int count,
    String sizeCategory,
    Color color,
  ) async {
    final radius = HotspotStyleHelper.getClusterRadius(count);
    final size = (radius * 2).toInt();

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Draw circle background
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      paint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(radius, radius),
      radius - 1,
      borderPaint,
    );

    // Draw count text
    final textPainter = TextPainter(
      text: TextSpan(
        text: _formatCount(count),
        style: TextStyle(
          color: Colors.white,
          fontSize: _getFontSize(sizeCategory),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return gmap.BitmapDescriptor.defaultMarkerWithHue(
        gmap.BitmapDescriptor.hueRed,
      );
    }

    return gmap.BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Format count for display (use K suffix for large numbers)
  static String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Get font size based on marker size category
  static double _getFontSize(String sizeCategory) {
    switch (sizeCategory) {
      case 'small':
        return 12.0;
      case 'medium':
        return 14.0;
      case 'large':
        return 16.0;
      default:
        return 12.0;
    }
  }

  /// Clear the icon cache (for testing or memory management)
  static void clearCache() {
    _iconCache.clear();
  }

  /// Get accessibility label for a cluster marker
  ///
  /// Returns a descriptive label for screen readers.
  static String getAccessibilityLabel(HotspotCluster cluster) {
    return '${cluster.count} fire detections, tap to zoom';
  }
}
