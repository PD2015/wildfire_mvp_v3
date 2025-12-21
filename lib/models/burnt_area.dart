import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Burnt area polygon from EFFIS WFS MODIS sensor data
///
/// Immutable value object representing a historical burnt area.
/// Part of 021-live-fire-data feature implementation.
///
/// Data source: EFFIS WFS GetFeature response
/// - Layer: modis.ba.poly
/// - Sensor: MODIS (Moderate Resolution Imaging Spectroradiometer)
class BurntArea extends Equatable {
  /// Unique identifier (EFFIS ID)
  final String id;

  /// Polygon boundary points (>= 3 points required)
  ///
  /// Points should be in clockwise order per GeoJSON spec.
  /// First and last points may be identical (closed ring).
  final List<LatLng> boundaryPoints;

  /// Total burnt area in hectares
  final double areaHectares;

  /// Date when fire was first detected
  final DateTime fireDate;

  /// Fire season year (e.g., 2025)
  final int seasonYear;

  /// Land cover breakdown by percentage
  ///
  /// Keys: "forest", "shrubland", "grassland", "agriculture", "other"
  /// Values: 0.0 - 1.0 (percentages)
  final Map<String, double>? landCoverBreakdown;

  /// Whether this polygon has been simplified via Douglas-Peucker
  ///
  /// True if point count reduced for performance.
  /// Original point count available via originalPointCount.
  final bool isSimplified;

  /// Original point count before simplification
  ///
  /// null if not simplified or unknown.
  final int? originalPointCount;

  /// Centroid location for marker positioning
  ///
  /// Calculated as average of all boundary points.
  LatLng get centroid {
    if (boundaryPoints.isEmpty) {
      return const LatLng(0, 0);
    }

    double sumLat = 0;
    double sumLon = 0;
    for (final point in boundaryPoints) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }
    return LatLng(
      sumLat / boundaryPoints.length,
      sumLon / boundaryPoints.length,
    );
  }

  /// Intensity level based on area size
  ///
  /// Returns "low" | "moderate" | "high" based on hectares:
  /// - < 10 ha: low
  /// - 10-100 ha: moderate
  /// - > 100 ha: high
  String get intensity {
    if (areaHectares < 10) return 'low';
    if (areaHectares < 100) return 'moderate';
    return 'high';
  }

  const BurntArea({
    required this.id,
    required this.boundaryPoints,
    required this.areaHectares,
    required this.fireDate,
    required this.seasonYear,
    this.landCoverBreakdown,
    this.isSimplified = false,
    this.originalPointCount,
  });

  /// Validation constructor that checks business rules
  factory BurntArea.validated({
    required String id,
    required List<LatLng> boundaryPoints,
    required double areaHectares,
    required DateTime fireDate,
    required int seasonYear,
    Map<String, double>? landCoverBreakdown,
    bool isSimplified = false,
    int? originalPointCount,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('BurntArea id must be non-empty');
    }
    if (boundaryPoints.length < 3) {
      throw ArgumentError(
        'BurntArea must have at least 3 boundary points, got ${boundaryPoints.length}',
      );
    }
    if (areaHectares < 0) {
      throw ArgumentError('BurntArea areaHectares must be non-negative');
    }
    if (seasonYear < 2000 || seasonYear > DateTime.now().year + 1) {
      throw ArgumentError(
        'BurntArea seasonYear must be between 2000 and next year',
      );
    }

    return BurntArea(
      id: id,
      boundaryPoints: boundaryPoints,
      areaHectares: areaHectares,
      fireDate: fireDate,
      seasonYear: seasonYear,
      landCoverBreakdown: landCoverBreakdown,
      isSimplified: isSimplified,
      originalPointCount: originalPointCount,
    );
  }

  /// Factory for creating from EFFIS WFS GML response
  ///
  /// Expected structure after XML parsing:
  /// ```dart
  /// {
  ///   'id': 'MODIS.BA.12345',
  ///   'geometry': {
  ///     'type': 'Polygon',
  ///     'coordinates': [[[lon, lat], [lon, lat], ...]]
  ///   },
  ///   'properties': {
  ///     'area_ha': 45.7,
  ///     'firedate': '2025-07-15',
  ///     'year': 2025,
  ///     'lc_forest': 0.45,
  ///     'lc_shrub': 0.30,
  ///     'lc_grass': 0.15,
  ///     'lc_agri': 0.05,
  ///     'lc_other': 0.05
  ///   }
  /// }
  /// ```
  factory BurntArea.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? json;
    final geometry = json['geometry'] as Map<String, dynamic>?;

    // Parse polygon geometry
    List<LatLng> boundaryPoints = [];
    if (geometry != null &&
        geometry['type'] == 'Polygon' &&
        geometry['coordinates'] != null) {
      final coords = geometry['coordinates'] as List;
      if (coords.isNotEmpty) {
        final ring = coords[0] as List;
        boundaryPoints = ring.map((coord) {
          final c = coord as List;
          return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
        }).toList();
      }
    }

    // Parse area
    final areaHectares =
        (properties['area_ha'] as num?)?.toDouble() ??
        (properties['areaHectares'] as num?)?.toDouble() ??
        0.0;

    // Parse fire date
    DateTime fireDate;
    final fireDateStr =
        properties['firedate'] as String? ?? properties['fireDate'] as String?;
    if (fireDateStr != null) {
      fireDate =
          DateTime.tryParse(fireDateStr)?.toUtc() ?? DateTime.now().toUtc();
    } else {
      fireDate = DateTime.now().toUtc();
    }

    // Parse season year
    final seasonYear =
        (properties['year'] as num?)?.toInt() ??
        (properties['seasonYear'] as num?)?.toInt() ??
        fireDate.year;

    // Parse land cover breakdown
    Map<String, double>? landCoverBreakdown;
    if (properties.containsKey('lc_forest') ||
        properties.containsKey('landCoverBreakdown')) {
      if (properties['landCoverBreakdown'] is Map) {
        landCoverBreakdown = Map<String, double>.from(
          properties['landCoverBreakdown'] as Map,
        );
      } else {
        landCoverBreakdown = {
          'forest': (properties['lc_forest'] as num?)?.toDouble() ?? 0.0,
          'shrubland': (properties['lc_shrub'] as num?)?.toDouble() ?? 0.0,
          'grassland': (properties['lc_grass'] as num?)?.toDouble() ?? 0.0,
          'agriculture': (properties['lc_agri'] as num?)?.toDouble() ?? 0.0,
          'other': (properties['lc_other'] as num?)?.toDouble() ?? 0.0,
        };
      }
    }

    // Check if simplified
    final isSimplified = properties['isSimplified'] as bool? ?? false;
    final originalPointCount = properties['originalPointCount'] as int?;

    return BurntArea(
      id:
          json['id']?.toString() ??
          'ba_${DateTime.now().millisecondsSinceEpoch}',
      boundaryPoints: boundaryPoints,
      areaHectares: areaHectares,
      fireDate: fireDate,
      seasonYear: seasonYear,
      landCoverBreakdown: landCoverBreakdown,
      isSimplified: isSimplified,
      originalPointCount: originalPointCount,
    );
  }

  /// Convert to JSON for caching/serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        boundaryPoints.map((p) => [p.longitude, p.latitude]).toList(),
      ],
    },
    'properties': {
      'area_ha': areaHectares,
      'firedate': fireDate.toIso8601String().split('T').first,
      'year': seasonYear,
      if (landCoverBreakdown != null) 'landCoverBreakdown': landCoverBreakdown,
      'isSimplified': isSimplified,
      if (originalPointCount != null) 'originalPointCount': originalPointCount,
    },
  };

  /// Factory for test data with reasonable defaults
  factory BurntArea.test({
    String? id,
    required List<LatLng> boundaryPoints,
    double areaHectares = 50.0,
    DateTime? fireDate,
    int? seasonYear,
    Map<String, double>? landCoverBreakdown,
    bool isSimplified = false,
    int? originalPointCount,
  }) {
    final now = DateTime.now().toUtc();
    return BurntArea(
      id: id ?? 'test_ba_${now.millisecondsSinceEpoch}',
      boundaryPoints: boundaryPoints,
      areaHectares: areaHectares,
      fireDate: fireDate ?? now,
      seasonYear: seasonYear ?? now.year,
      landCoverBreakdown: landCoverBreakdown,
      isSimplified: isSimplified,
      originalPointCount: originalPointCount,
    );
  }

  /// Create a simplified copy with reduced point count
  ///
  /// Used after Douglas-Peucker simplification.
  BurntArea copyWithSimplified({required List<LatLng> simplifiedPoints}) {
    return BurntArea(
      id: id,
      boundaryPoints: simplifiedPoints,
      areaHectares: areaHectares,
      fireDate: fireDate,
      seasonYear: seasonYear,
      landCoverBreakdown: landCoverBreakdown,
      isSimplified: true,
      originalPointCount: boundaryPoints.length,
    );
  }

  @override
  List<Object?> get props => [
    id,
    boundaryPoints,
    areaHectares,
    fireDate,
    seasonYear,
    landCoverBreakdown,
    isSimplified,
    originalPointCount,
  ];
}
