import 'package:equatable/equatable.dart';
import 'lat_lng.dart';

/// Debugging modification types
enum DebuggingModificationType {
  gpsBypass,
  cacheClearing,
  mockResponse,
  stateReset,
}

/// Debugging state modification
class DebuggingModification extends Equatable {
  final DebuggingModificationType type;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final bool isActive;

  const DebuggingModification({
    required this.type,
    required this.parameters,
    required this.timestamp,
    required this.isActive,
  });

  factory DebuggingModification.gpsBypass({
    required LatLng coordinates,
    required bool isActive,
  }) {
    return DebuggingModification(
      type: DebuggingModificationType.gpsBypass,
      parameters: {
        'coordinates': coordinates.toMap(),
        'enabled': isActive,
      },
      timestamp: DateTime.now(),
      isActive: isActive,
    );
  }

  factory DebuggingModification.cacheClearing({
    required List<String> keysToPreserve,
    required bool isActive,
  }) {
    return DebuggingModification(
      type: DebuggingModificationType.cacheClearing,
      parameters: {
        'keys_to_preserve': keysToPreserve,
        'clear_all_except': true,
      },
      timestamp: DateTime.now(),
      isActive: isActive,
    );
  }

  @override
  List<Object?> get props => [type, parameters, timestamp, isActive];

  @override
  String toString() => 'DebuggingModification($type, active: $isActive)';
}
