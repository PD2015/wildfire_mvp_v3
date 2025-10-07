import 'package:equatable/equatable.dart';

/// Debugging modification entity for tracking changes made during debugging session
class DebuggingModification extends Equatable {
  final String modificationId;
  final String filePath;
  final String description;
  final ModificationType type;
  final List<String> affectedMethods;
  final bool isProductionReady;
  final String? restorationNotes;
  final DateTime createdAt;
  final String? createdBy;
  
  const DebuggingModification({
    required this.modificationId,
    required this.filePath,
    required this.description,
    required this.type,
    required this.affectedMethods,
    required this.isProductionReady,
    this.restorationNotes,
    required this.createdAt,
    this.createdBy,
  });
  
  @override
  List<Object?> get props => [
    modificationId, 
    filePath, 
    description, 
    type, 
    affectedMethods, 
    isProductionReady, 
    restorationNotes,
    createdAt,
    createdBy,
  ];

  /// Check if modification needs restoration before production
  bool get needsRestoration => !isProductionReady;

  /// Check if modification has restoration instructions
  bool get hasRestorationNotes => restorationNotes != null && restorationNotes!.isNotEmpty;

  /// Get modification age in days
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Check if modification is stale (older than 30 days)
  bool get isStale => ageInDays > 30;

  /// Create a copy with modified properties
  DebuggingModification copyWith({
    String? modificationId,
    String? filePath,
    String? description,
    ModificationType? type,
    List<String>? affectedMethods,
    bool? isProductionReady,
    String? restorationNotes,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return DebuggingModification(
      modificationId: modificationId ?? this.modificationId,
      filePath: filePath ?? this.filePath,
      description: description ?? this.description,
      type: type ?? this.type,
      affectedMethods: affectedMethods ?? this.affectedMethods,
      isProductionReady: isProductionReady ?? this.isProductionReady,
      restorationNotes: restorationNotes ?? this.restorationNotes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'modificationId': modificationId,
      'filePath': filePath,
      'description': description,
      'type': type.name,
      'affectedMethods': affectedMethods,
      'isProductionReady': isProductionReady,
      'restorationNotes': restorationNotes,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// Create from JSON
  factory DebuggingModification.fromJson(Map<String, dynamic> json) {
    return DebuggingModification(
      modificationId: json['modificationId'] as String,
      filePath: json['filePath'] as String,
      description: json['description'] as String,
      type: ModificationType.values.firstWhere((t) => t.name == json['type']),
      affectedMethods: List<String>.from(json['affectedMethods'] as List),
      isProductionReady: json['isProductionReady'] as bool,
      restorationNotes: json['restorationNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
    );
  }

  /// Validate modification data
  bool get isValid {
    return modificationId.isNotEmpty &&
           filePath.isNotEmpty &&
           description.isNotEmpty &&
           affectedMethods.isNotEmpty &&
           (isProductionReady || hasRestorationNotes);
  }

  /// Generate modification report
  String get report {
    return '''
Debugging Modification Report:
  ID: $modificationId
  File: $filePath
  Type: ${type.name}
  Description: $description
  Affected Methods: ${affectedMethods.join(', ')}
  Production Ready: $isProductionReady
  Created: ${createdAt.toIso8601String()}
  Age: $ageInDays days
  ${hasRestorationNotes ? 'Restoration Notes: $restorationNotes' : ''}
''';
  }

  /// Create GPS bypass modification
  factory DebuggingModification.gpsBypass({
    required DateTime createdAt,
    String? createdBy,
  }) {
    return DebuggingModification(
      modificationId: 'gps_bypass_aviemore',
      filePath: 'lib/services/location_resolver_impl.dart',
      description: 'GPS bypass to return hardcoded Aviemore coordinates (57.2, -3.8) for debugging',
      type: ModificationType.gpsBypass,
      affectedMethods: ['getLatLon', '_tryGps'],
      isProductionReady: false,
      restorationNotes: 'Remove GPS bypass logic and restore normal GPS service calls. Change Scotland centroid back to (55.8642, -4.2518).',
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  /// Create cache clearing modification
  factory DebuggingModification.cacheClearing({
    required DateTime createdAt,
    String? createdBy,
  }) {
    return DebuggingModification(
      modificationId: 'enhanced_cache_clearing',
      filePath: 'lib/main.dart',
      description: 'Enhanced cache clearing to remove all 5 SharedPreferences location keys while preserving test mode',
      type: ModificationType.cacheClearing,
      affectedMethods: ['_clearCachedLocation'],
      isProductionReady: false,
      restorationNotes: 'Revert cache clearing to production behavior. Remove enhanced debugging key clearing.',
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  /// Create coordinate validation modification
  factory DebuggingModification.coordinateValidation({
    required DateTime createdAt,
    String? createdBy,
  }) {
    return DebuggingModification(
      modificationId: 'coordinate_validation_debug',
      filePath: 'lib/utils/location_utils.dart',
      description: 'Enhanced coordinate validation and logging for debugging boundary calculations',
      type: ModificationType.coordinateValidation,
      affectedMethods: ['isInScotland', 'logRedact'],
      isProductionReady: true, // Safe for production
      restorationNotes: null, // No restoration needed
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  /// Create debug logging modification
  factory DebuggingModification.debugLogging({
    required DateTime createdAt,
    String? createdBy,
  }) {
    return DebuggingModification(
      modificationId: 'enhanced_debug_logging',
      filePath: 'lib/services/location_resolver_impl.dart',
      description: 'Enhanced debug logging for location resolution debugging session',
      type: ModificationType.debugLogging,
      affectedMethods: ['getLatLon', '_loadCachedLocation', '_tryGps'],
      isProductionReady: false,
      restorationNotes: 'Remove debug-specific log statements. Keep production logging levels.',
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}

/// Modification type enumeration
enum ModificationType {
  gpsBypass,
  cacheClearing,
  coordinateValidation,
  debugLogging
}

/// Debugging session tracker
class DebuggingSession {
  final String sessionId;
  final DateTime startTime;
  final List<DebuggingModification> modifications;
  final String description;
  final bool isActive;

  const DebuggingSession({
    required this.sessionId,
    required this.startTime,
    required this.modifications,
    required this.description,
    required this.isActive,
  });

  /// Get modifications that need restoration
  List<DebuggingModification> get modificationsNeedingRestoration {
    return modifications.where((mod) => mod.needsRestoration).toList();
  }

  /// Get production-ready modifications
  List<DebuggingModification> get productionReadyModifications {
    return modifications.where((mod) => mod.isProductionReady).toList();
  }

  /// Check if session is ready for production
  bool get isProductionReady {
    return modificationsNeedingRestoration.isEmpty;
  }

  /// Get session duration
  Duration get duration {
    return DateTime.now().difference(startTime);
  }

  /// Generate session summary
  String get summary {
    return '''
Debugging Session Summary:
  Session ID: $sessionId
  Started: ${startTime.toIso8601String()}
  Duration: ${duration.inDays} days, ${duration.inHours % 24} hours
  Status: ${isActive ? 'Active' : 'Completed'}
  Total Modifications: ${modifications.length}
  Production Ready: ${productionReadyModifications.length}
  Need Restoration: ${modificationsNeedingRestoration.length}
  Production Ready: $isProductionReady
''';
  }

  /// Create current debugging session
  factory DebuggingSession.current() {
    final now = DateTime.now();
    
    return DebuggingSession(
      sessionId: 'location_debugging_session_${now.millisecondsSinceEpoch}',
      startTime: now,
      description: 'Location services debugging session to validate GPS bypass and cache clearing functionality',
      isActive: true,
      modifications: [
        DebuggingModification.gpsBypass(createdAt: now, createdBy: 'debugging_session'),
        DebuggingModification.cacheClearing(createdAt: now, createdBy: 'debugging_session'),
        DebuggingModification.coordinateValidation(createdAt: now, createdBy: 'debugging_session'),
        DebuggingModification.debugLogging(createdAt: now, createdBy: 'debugging_session'),
      ],
    );
  }
}