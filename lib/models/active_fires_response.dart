// ActiveFiresResponse model for API responses containing multiple fire incidents
// Implements Task 2 of 018-map-fire-information specification
// Wraps fire incidents with metadata for viewport queries and caching

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// Response wrapper for fire incident queries with viewport bounds
///
/// Designed for EFFIS API responses and viewport-based filtering.
/// Includes metadata for caching and performance tracking.
class ActiveFiresResponse extends Equatable {
  /// List of fire incidents within the queried bounds
  final List<FireIncident> incidents;

  /// Geographic bounds that were queried for this response
  final gmaps.LatLngBounds queriedBounds;

  /// API response time in milliseconds for performance monitoring
  final int responseTimeMs;

  /// Data source for this response (EFFIS, mock, etc.)
  final DataSource dataSource;

  /// Total number of incidents found (may exceed incidents.length due to filtering)
  final int totalCount;

  /// Timestamp when this response was created
  final DateTime timestamp;

  const ActiveFiresResponse({
    required this.incidents,
    required this.queriedBounds,
    required this.responseTimeMs,
    required this.dataSource,
    required this.totalCount,
    required this.timestamp,
  });

  /// Factory for empty response (no fires found)
  factory ActiveFiresResponse.empty({
    required gmaps.LatLngBounds bounds,
    required DataSource dataSource,
    int responseTimeMs = 0,
  }) {
    return ActiveFiresResponse(
      incidents: const [],
      queriedBounds: bounds,
      responseTimeMs: responseTimeMs,
      dataSource: dataSource,
      totalCount: 0,
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Factory from EFFIS API JSON response
  factory ActiveFiresResponse.fromJson({
    required Map<String, dynamic> json,
    required gmaps.LatLngBounds queriedBounds,
    required int responseTimeMs,
    required DataSource dataSource,
  }) {
    final features = json['features'] as List? ?? [];

    final incidents = features
        .cast<Map<String, dynamic>>()
        .map((feature) => FireIncident.fromJson(feature))
        .where((incident) => _isWithinBounds(incident.location, queriedBounds))
        .toList();

    return ActiveFiresResponse(
      incidents: incidents,
      queriedBounds: queriedBounds,
      responseTimeMs: responseTimeMs,
      dataSource: dataSource,
      totalCount: features.length, // Total before filtering
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Factory for caching/deserialization from stored JSON
  factory ActiveFiresResponse.fromCacheJson(Map<String, dynamic> json) {
    final incidents = (json['incidents'] as List)
        .map(
          (incident) =>
              FireIncident.fromCacheJson(incident as Map<String, dynamic>),
        )
        .toList();

    final boundsJson = json['queriedBounds'] as Map<String, dynamic>;
    final queriedBounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        boundsJson['southwest']['latitude'] as double,
        boundsJson['southwest']['longitude'] as double,
      ),
      northeast: gmaps.LatLng(
        boundsJson['northeast']['latitude'] as double,
        boundsJson['northeast']['longitude'] as double,
      ),
    );

    return ActiveFiresResponse(
      incidents: incidents,
      queriedBounds: queriedBounds,
      responseTimeMs: json['responseTimeMs'] as int,
      dataSource: DataSource.values.firstWhere(
        (e) => e.toString().split('.').last == json['dataSource'],
        orElse: () => DataSource.mock,
      ),
      totalCount: json['totalCount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
    );
  }

  /// Serialize for caching
  Map<String, dynamic> toJson() {
    return {
      'incidents': incidents.map((incident) => incident.toJson()).toList(),
      'queriedBounds': {
        'southwest': {
          'latitude': queriedBounds.southwest.latitude,
          'longitude': queriedBounds.southwest.longitude,
        },
        'northeast': {
          'latitude': queriedBounds.northeast.latitude,
          'longitude': queriedBounds.northeast.longitude,
        },
      },
      'responseTimeMs': responseTimeMs,
      'dataSource': dataSource.toString().split('.').last,
      'totalCount': totalCount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  ActiveFiresResponse copyWith({
    List<FireIncident>? incidents,
    gmaps.LatLngBounds? queriedBounds,
    int? responseTimeMs,
    DataSource? dataSource,
    int? totalCount,
    DateTime? timestamp,
  }) {
    return ActiveFiresResponse(
      incidents: incidents ?? this.incidents,
      queriedBounds: queriedBounds ?? this.queriedBounds,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      dataSource: dataSource ?? this.dataSource,
      totalCount: totalCount ?? this.totalCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if response is empty (no incidents found)
  bool get isEmpty => incidents.isEmpty;

  /// Check if response has incidents
  bool get hasIncidents => incidents.isNotEmpty;

  /// Filter incidents by minimum confidence threshold
  ActiveFiresResponse filterByConfidence(double minConfidence) {
    final filtered = incidents
        .where(
          (incident) =>
              incident.confidence != null &&
              incident.confidence! >= minConfidence,
        )
        .toList();

    return copyWith(incidents: filtered, totalCount: filtered.length);
  }

  /// Filter incidents by fire radiative power threshold
  ActiveFiresResponse filterByFrp(double minFrp) {
    final filtered = incidents
        .where((incident) => incident.frp != null && incident.frp! >= minFrp)
        .toList();

    return copyWith(incidents: filtered, totalCount: filtered.length);
  }

  /// Validate that all incidents fall within the queried bounds
  bool get isValid {
    if (incidents.isEmpty) return true;

    return incidents.every(
      (incident) => _isWithinBounds(incident.location, queriedBounds),
    );
  }

  /// Get incidents sorted by detection time (most recent first)
  List<FireIncident> get incidentsByDetectionTime {
    final sorted = List<FireIncident>.from(incidents);
    sorted.sort((a, b) {
      final aTime = a.detectedAt ?? a.timestamp;
      final bTime = b.detectedAt ?? b.timestamp;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  /// Get incidents sorted by confidence (highest first)
  List<FireIncident> get incidentsByConfidence {
    final withConfidence = incidents
        .where((incident) => incident.confidence != null)
        .toList();
    withConfidence.sort((a, b) => b.confidence!.compareTo(a.confidence!));
    return withConfidence;
  }

  /// Check if location is within bounds (with small tolerance for edge cases)
  static bool _isWithinBounds(LatLng location, gmaps.LatLngBounds bounds) {
    const tolerance = 0.0001; // ~11 meters tolerance

    return location.latitude >= (bounds.southwest.latitude - tolerance) &&
        location.latitude <= (bounds.northeast.latitude + tolerance) &&
        location.longitude >= (bounds.southwest.longitude - tolerance) &&
        location.longitude <= (bounds.northeast.longitude + tolerance);
  }

  @override
  List<Object?> get props => [
    incidents,
    queriedBounds,
    responseTimeMs,
    dataSource,
    totalCount,
    timestamp,
  ];

  @override
  String toString() {
    return 'ActiveFiresResponse(incidents: ${incidents.length}/$totalCount, '
        'bounds: ${queriedBounds.southwest} to ${queriedBounds.northeast}, '
        'source: $dataSource, response: ${responseTimeMs}ms)';
  }
}
