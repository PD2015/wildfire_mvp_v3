import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

/// Sealed base class for map state hierarchy
///
/// Implementation: TBD in T010
sealed class MapState extends Equatable {
  const MapState();
}

/// Loading state - initial or refreshing
class MapLoading extends MapState {
  const MapLoading();

  @override
  List<Object?> get props => [];
}

/// Success state with fire incidents and location
class MapSuccess extends MapState {
  final List<FireIncident> incidents;
  final LatLng centerLocation;
  final Freshness freshness;
  final DateTime lastUpdated;

  MapSuccess({
    required this.incidents,
    required this.centerLocation,
    required this.freshness,
    required this.lastUpdated,
  }) {
    _validate();
  }

  /// Validation per data-model.md
  void _validate() {
    if (!centerLocation.isValid) {
      throw ArgumentError(
        'MapSuccess centerLocation must have valid coordinates',
      );
    }
    if (lastUpdated.isAfter(DateTime.now())) {
      throw ArgumentError('MapSuccess lastUpdated must not be in the future');
    }
  }

  @override
  List<Object?> get props => [
    incidents,
    centerLocation,
    freshness,
    lastUpdated,
  ];
}

/// Error state with optional cached data
class MapError extends MapState {
  final String message;
  final List<FireIncident>? cachedIncidents;
  final LatLng? lastKnownLocation;

  MapError({
    required this.message,
    this.cachedIncidents,
    this.lastKnownLocation,
  }) {
    _validate();
  }

  /// Validation per data-model.md
  void _validate() {
    if (message.isEmpty) {
      throw ArgumentError('MapError message must be non-empty');
    }
  }

  @override
  List<Object?> get props => [message, cachedIncidents, lastKnownLocation];
}
