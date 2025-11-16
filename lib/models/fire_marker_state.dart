// Fire marker state management for map interactions
// Implements Task 6 of 018-map-fire-information specification
// Manages marker selection, hover states, and visual feedback

import 'package:equatable/equatable.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';

/// State for individual fire markers on the map
///
/// Manages visual states for fire incident markers:
/// - Normal: Default marker appearance
/// - Selected: Marker is selected (bottom sheet showing)
/// - Hovered: Marker is being hovered/highlighted
/// - Loading: Marker data is being fetched
abstract class FireMarkerState extends Equatable {
  /// Fire incident ID this state applies to
  final String fireIncidentId;

  const FireMarkerState({required this.fireIncidentId});

  /// Check if marker is in selected state
  bool get isSelected => this is FireMarkerSelected;

  /// Check if marker is in hovered state
  bool get isHovered => this is FireMarkerHovered;

  /// Check if marker is in loading state
  bool get isLoading => this is FireMarkerLoading;

  /// Check if marker is in normal state
  bool get isNormal => this is FireMarkerNormal;

  @override
  List<Object?> get props => [fireIncidentId];
}

/// Normal marker state (default appearance)
class FireMarkerNormal extends FireMarkerState {
  const FireMarkerNormal({required super.fireIncidentId});

  @override
  String toString() => 'FireMarkerNormal(id: $fireIncidentId)';
}

/// Selected marker state (bottom sheet is showing for this marker)
class FireMarkerSelected extends FireMarkerState {
  /// Fire incident data associated with this marker
  final FireIncident fireIncident;

  /// Timestamp when marker was selected
  final DateTime selectedAt;

  FireMarkerSelected({
    required super.fireIncidentId,
    required this.fireIncident,
    DateTime? selectedAt,
  }) : selectedAt = selectedAt ?? DateTime.now().toUtc();

  @override
  List<Object?> get props => [fireIncidentId, fireIncident, selectedAt];

  @override
  String toString() =>
      'FireMarkerSelected(id: $fireIncidentId, selectedAt: $selectedAt)';
}

/// Hovered marker state (user is hovering over marker)
class FireMarkerHovered extends FireMarkerState {
  /// Optional preview data to show in tooltip
  final String? previewText;

  /// Timestamp when hover started
  final DateTime hoveredAt;

  FireMarkerHovered({
    required super.fireIncidentId,
    this.previewText,
    DateTime? hoveredAt,
  }) : hoveredAt = hoveredAt ?? DateTime.now().toUtc();

  @override
  List<Object?> get props => [fireIncidentId, previewText, hoveredAt];

  @override
  String toString() =>
      'FireMarkerHovered(id: $fireIncidentId, preview: $previewText)';
}

/// Loading marker state (fetching detailed data)
class FireMarkerLoading extends FireMarkerState {
  /// Optional loading message
  final String? loadingMessage;

  /// Timestamp when loading started
  final DateTime loadingStarted;

  FireMarkerLoading({
    required super.fireIncidentId,
    this.loadingMessage,
    DateTime? loadingStarted,
  }) : loadingStarted = loadingStarted ?? DateTime.now().toUtc();

  @override
  List<Object?> get props => [fireIncidentId, loadingMessage, loadingStarted];

  @override
  String toString() =>
      'FireMarkerLoading(id: $fireIncidentId, message: $loadingMessage)';
}

/// Collection state for managing multiple fire markers
class FireMarkerCollectionState extends Equatable {
  /// Map of marker states by fire incident ID
  final Map<String, FireMarkerState> markerStates;

  /// Currently selected marker ID (if any)
  final String? selectedMarkerId;

  /// Currently hovered marker ID (if any)
  final String? hoveredMarkerId;

  const FireMarkerCollectionState({
    this.markerStates = const {},
    this.selectedMarkerId,
    this.hoveredMarkerId,
  });

  /// Get state for specific marker
  FireMarkerState? getMarkerState(String fireIncidentId) {
    return markerStates[fireIncidentId];
  }

  /// Check if any marker is selected
  bool get hasSelection => selectedMarkerId != null;

  /// Check if any marker is hovered
  bool get hasHover => hoveredMarkerId != null;

  /// Get currently selected marker state
  FireMarkerState? get selectedMarkerState {
    if (selectedMarkerId != null) {
      return markerStates[selectedMarkerId];
    }
    return null;
  }

  /// Get currently hovered marker state
  FireMarkerState? get hoveredMarkerState {
    if (hoveredMarkerId != null) {
      return markerStates[hoveredMarkerId];
    }
    return null;
  }

  /// Get all marker IDs in loading state
  List<String> get loadingMarkerIds {
    return markerStates.entries
        .where((entry) => entry.value.isLoading)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get all marker IDs in selected state
  List<String> get selectedMarkerIds {
    return markerStates.entries
        .where((entry) => entry.value.isSelected)
        .map((entry) => entry.key)
        .toList();
  }

  /// Create a copy with updated marker states
  FireMarkerCollectionState copyWith({
    Map<String, FireMarkerState>? markerStates,
    String? selectedMarkerId,
    String? hoveredMarkerId,
  }) {
    return FireMarkerCollectionState(
      markerStates: markerStates ?? this.markerStates,
      selectedMarkerId: selectedMarkerId,
      hoveredMarkerId: hoveredMarkerId,
    );
  }

  /// Add or update a marker state
  FireMarkerCollectionState updateMarker({
    required String fireIncidentId,
    required FireMarkerState state,
  }) {
    final newMarkerStates = Map<String, FireMarkerState>.from(markerStates);
    newMarkerStates[fireIncidentId] = state;

    String? newSelectedId = selectedMarkerId;
    String? newHoveredId = hoveredMarkerId;

    // Update selected/hovered tracking based on new state
    if (state.isSelected) {
      newSelectedId = fireIncidentId;
    } else if (selectedMarkerId == fireIncidentId) {
      newSelectedId = null;
    }

    if (state.isHovered) {
      newHoveredId = fireIncidentId;
    } else if (hoveredMarkerId == fireIncidentId) {
      newHoveredId = null;
    }

    return copyWith(
      markerStates: newMarkerStates,
      selectedMarkerId: newSelectedId,
      hoveredMarkerId: newHoveredId,
    );
  }

  /// Remove a marker state
  FireMarkerCollectionState removeMarker(String fireIncidentId) {
    if (!markerStates.containsKey(fireIncidentId)) {
      return this;
    }

    final newMarkerStates = Map<String, FireMarkerState>.from(markerStates);
    newMarkerStates.remove(fireIncidentId);

    return copyWith(
      markerStates: newMarkerStates,
      selectedMarkerId:
          selectedMarkerId == fireIncidentId ? null : selectedMarkerId,
      hoveredMarkerId:
          hoveredMarkerId == fireIncidentId ? null : hoveredMarkerId,
    );
  }

  /// Clear all marker states
  FireMarkerCollectionState clearAll() {
    return const FireMarkerCollectionState();
  }

  /// Select a specific marker (deselects others)
  FireMarkerCollectionState selectMarker({
    required String fireIncidentId,
    required FireIncident fireIncident,
  }) {
    // First, set all markers to normal state
    final normalStates = <String, FireMarkerState>{};
    for (final id in markerStates.keys) {
      normalStates[id] = FireMarkerNormal(fireIncidentId: id);
    }

    // Then set the selected marker
    normalStates[fireIncidentId] = FireMarkerSelected(
      fireIncidentId: fireIncidentId,
      fireIncident: fireIncident,
    );

    return copyWith(
      markerStates: normalStates,
      selectedMarkerId: fireIncidentId,
      hoveredMarkerId: null,
    );
  }

  /// Hover over a marker (if not already selected)
  FireMarkerCollectionState hoverMarker({
    required String fireIncidentId,
    String? previewText,
  }) {
    // Don't hover if already selected
    if (selectedMarkerId == fireIncidentId) {
      return this;
    }

    final currentState = markerStates[fireIncidentId];
    if (currentState == null || currentState.isLoading) {
      return this; // Can't hover over loading or non-existent markers
    }

    return updateMarker(
      fireIncidentId: fireIncidentId,
      state: FireMarkerHovered(
        fireIncidentId: fireIncidentId,
        previewText: previewText,
      ),
    );
  }

  /// Stop hovering over a marker
  FireMarkerCollectionState unhoverMarker(String fireIncidentId) {
    if (hoveredMarkerId != fireIncidentId) {
      return this;
    }

    return updateMarker(
      fireIncidentId: fireIncidentId,
      state: FireMarkerNormal(fireIncidentId: fireIncidentId),
    );
  }

  /// Set marker to loading state
  FireMarkerCollectionState setLoading({
    required String fireIncidentId,
    String? loadingMessage,
  }) {
    return updateMarker(
      fireIncidentId: fireIncidentId,
      state: FireMarkerLoading(
        fireIncidentId: fireIncidentId,
        loadingMessage: loadingMessage,
      ),
    );
  }

  /// Reset marker to normal state
  FireMarkerCollectionState setNormal(String fireIncidentId) {
    return updateMarker(
      fireIncidentId: fireIncidentId,
      state: FireMarkerNormal(fireIncidentId: fireIncidentId),
    );
  }

  @override
  List<Object?> get props => [markerStates, selectedMarkerId, hoveredMarkerId];

  @override
  String toString() {
    return 'FireMarkerCollectionState('
        'markers: ${markerStates.length}, '
        'selected: $selectedMarkerId, '
        'hovered: $hoveredMarkerId)';
  }
}
