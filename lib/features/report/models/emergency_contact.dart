import 'package:equatable/equatable.dart';

/// Emergency priority levels for Scottish fire reporting
enum EmergencyPriority {
  /// Life-threatening emergencies requiring immediate response (999)
  urgent,

  /// Non-emergency incidents requiring police response (101)
  nonEmergency,

  /// Anonymous reporting for suspicious activities (Crimestoppers)
  anonymous,
}

/// Call result status for emergency contact attempts
enum CallResult {
  /// Call was successfully initiated
  success,

  /// Call failed due to technical issues
  failed,

  /// Call was cancelled by user
  cancelled,

  /// Platform does not support calling (e.g., web emulator)
  unsupported,
}

/// Emergency contact information for Scottish fire reporting services
///
/// Represents the three primary emergency contacts available in Scotland
/// for fire-related incidents, with priority levels and contact details.
class EmergencyContact extends Equatable {
  /// Display name for the emergency service
  final String name;

  /// Phone number in standard UK format
  final String phoneNumber;

  /// Emergency priority level
  final EmergencyPriority priority;

  /// Optional description of when to use this contact
  final String? description;

  const EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.priority,
    this.description,
  });

  /// Creates EmergencyContact with validation
  factory EmergencyContact.validated({
    required String name,
    required String phoneNumber,
    required EmergencyPriority priority,
    String? description,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }

    // Basic UK phone number validation
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length < 3) {
      throw ArgumentError('Invalid phone number format');
    }

    return EmergencyContact(
      name: name,
      phoneNumber: phoneNumber,
      priority: priority,
      description: description,
    );
  }

  /// Creates a copy with modified properties
  EmergencyContact copyWith({
    String? name,
    String? phoneNumber,
    EmergencyPriority? priority,
    String? description,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      priority: priority ?? this.priority,
      description: description ?? this.description,
    );
  }

  /// Returns phone number formatted for tel: URI scheme
  String get telUri => 'tel:${phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}';

  /// Returns display text for UI buttons
  String get displayText {
    // Shortened format for button width constraints
    // Icon conveys "call" action, text shows who to call
    if (this == crimestoppers) {
      return name; // "Crimestoppers"
    }
    // Format: "999 Fire Service" or "101 Police"
    return '$phoneNumber ${name.replaceAll(' Scotland', '')}';
  }

  /// Returns whether this is an urgent emergency contact
  bool get isUrgent => priority == EmergencyPriority.urgent;

  @override
  List<Object?> get props => [name, phoneNumber, priority, description];

  @override
  String toString() {
    return 'EmergencyContact(name: $name, phoneNumber: $phoneNumber, priority: $priority)';
  }

  /// Scottish Fire and Rescue Service - 999 Emergency
  ///
  /// For immediate life-threatening fire emergencies requiring
  /// immediate response from Scottish Fire and Rescue Service.
  static const fireService = EmergencyContact(
    name: 'Fire Service',
    phoneNumber: '999',
    priority: EmergencyPriority.urgent,
    description: 'Life-threatening fire emergencies',
  );

  /// Police Scotland - 101 Non-Emergency
  ///
  /// For non-emergency fire incidents that may require police
  /// response or investigation, such as suspicious fires.
  static const policeScotland = EmergencyContact(
    name: 'Police Scotland',
    phoneNumber: '101',
    priority: EmergencyPriority.nonEmergency,
    description: 'Non-emergency incidents requiring police response',
  );

  /// Crimestoppers - 0800 555 111 Anonymous Reporting
  ///
  /// For anonymous reporting of suspicious fire-related activities
  /// or arson incidents. Calls are free and completely anonymous.
  static const crimestoppers = EmergencyContact(
    name: 'Crimestoppers',
    phoneNumber: '0800 555 111',
    priority: EmergencyPriority.anonymous,
    description: 'Anonymous reporting of suspicious activities',
  );

  /// All available Scottish emergency contacts for fire reporting
  static const List<EmergencyContact> scottishFireContacts = [
    fireService,
    policeScotland,
    crimestoppers,
  ];
}
