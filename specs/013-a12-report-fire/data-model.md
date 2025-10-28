# Data Model: A12 – Report Fire Screen (MVP)

**Date**: 28 October 2025  
**Feature**: Report Fire Screen emergency contact data structures

## Core Entities

### EmergencyContact
**Purpose**: Represents official emergency service contact information for Scotland fire reporting

**Fields**:
- `serviceName`: String - Display name (e.g., "Fire Service", "Police Scotland")
- `phoneNumber`: String - Emergency contact number (e.g., "999", "101", "0800555111")
- `displayText`: String - Full button text (e.g., "Call 999 — Fire Service")
- `priority`: EmergencyPriority - UI styling and ordering priority
- `description`: String? - Optional descriptive text for accessibility

**Validation Rules**:
- `serviceName`: Required, non-empty, max 50 characters
- `phoneNumber`: Required, non-empty, digits and allowed characters only (0-9, +, spaces)
- `displayText`: Required, non-empty, max 100 characters for UI display
- `priority`: Required enum value
- `description`: Optional, max 200 characters if provided

**Relationships**: None (static data, no external dependencies)

### EmergencyPriority (Enum)
**Purpose**: Defines visual styling and ordering priority for emergency contacts

**Values**:
- `critical`: Highest priority, emergency styling (red/error colors) - for 999 Fire Service
- `important`: Standard priority, primary styling - for 101 Police Scotland  
- `standard`: Normal priority, secondary styling - for 0800 555 111 Crimestoppers

**Usage**: Determines button styling via Material 3 ColorScheme mapping

### CallResult (Enum)  
**Purpose**: Represents outcome of emergency call attempt for error handling

**Values**:
- `success`: Dialer opened successfully
- `unavailable`: tel: scheme not supported (emulator, web without phone capability)
- `error`: Unexpected platform exception during launch

**Usage**: Determines SnackBar notification content and user guidance

## Data Flow

### Static Data Initialization
```
EmergencyContacts.scottishFireReporting = [
  EmergencyContact(
    serviceName: "Fire Service",
    phoneNumber: "999", 
    displayText: "Call 999 — Fire Service",
    priority: EmergencyPriority.critical,
    description: "Emergency fire service for immediate fire incidents"
  ),
  EmergencyContact(
    serviceName: "Police Scotland", 
    phoneNumber: "101",
    displayText: "Call 101 — Police Scotland", 
    priority: EmergencyPriority.important,
    description: "Police Scotland non-emergency line for fire-related incidents"
  ),
  EmergencyContact(
    serviceName: "Crimestoppers",
    phoneNumber: "0800555111",
    displayText: "Call 0800 555 111 — Crimestoppers",
    priority: EmergencyPriority.standard, 
    description: "Anonymous reporting line for fire-related criminal activity"
  )
]
```

### Call Attempt Flow
```
User taps button → 
EmergencyContact.phoneNumber → 
url_launcher.launch("tel:${phoneNumber}") →
Success: Native dialer opens |
Failure: CallResult.unavailable/error → SnackBar with manual instructions
```

## State Management
**Approach**: StatelessWidget with const data  
**Rationale**: No dynamic state, no user input, no network data - emergency contacts are compile-time constants

## Serialization
**Not Required**: Static data never serialized/deserialized, no persistence layer, no API communication

## Testing Data
**Test Constants**:
```dart
static const testFireService = EmergencyContact(
  serviceName: "Test Fire Service",
  phoneNumber: "999", 
  displayText: "Call 999 — Test Fire Service",
  priority: EmergencyPriority.critical,
);

static const testPoliceScotland = EmergencyContact(
  serviceName: "Test Police",
  phoneNumber: "101",
  displayText: "Call 101 — Test Police", 
  priority: EmergencyPriority.important,
);
```

## Validation Strategy
- **Compile-time validation**: const constructors ensure required fields
- **Runtime validation**: Factory constructors with validation for dynamic creation (if needed in future)
- **Test validation**: Unit tests verify field constraints and enum mappings