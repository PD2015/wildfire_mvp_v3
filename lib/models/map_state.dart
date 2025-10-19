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

  const MapSuccess({
    required this.incidents,
    required this.centerLocation,
    required this.freshness,
    required this.lastUpdated,
  });

  /// TODO: T010 - Implement validation (valid centerLocation)
  
  @override
  List<Object?> get props => [incidents, centerLocation, freshness, lastUpdated];
}

/// Error state with optional cached data
class MapError extends MapState {
  final String message;
  final List<FireIncident>? cachedIncidents;
  final LatLng? lastKnownLocation;

  const MapError({
    required this.message,
    this.cachedIncidents,
    this.lastKnownLocation,
  });

  /// TODO: T010 - Implement validation (non-empty message)

  @override
  List<Object?> get props => [message, cachedIncidents, lastKnownLocation];
}
