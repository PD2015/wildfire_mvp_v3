# Platform Interface Contracts: A12 – Report Fire Screen

**Date**: 28 October 2025  
**Feature**: Emergency calling platform integration contracts

## url_launcher Platform Contract

### launchEmergencyCall()
**Purpose**: Launch native dialer with emergency contact number

**Interface**:
```dart
Future<CallResult> launchEmergencyCall(String phoneNumber)
```

**Input Contract**:
- `phoneNumber`: Non-null String, format: digits with optional spaces/+ prefix
- Examples: "999", "101", "0800 555 111", "+44999"

**Output Contract**:
- Returns `Future<CallResult>` 
- `CallResult.success`: Platform dialer opened with number pre-filled
- `CallResult.unavailable`: tel: scheme not supported on current platform
- `CallResult.error`: Unexpected platform exception occurred

**Platform Behavior**:
- **iOS**: Opens Phone app with number dialed, requires user confirmation
- **Android**: Opens default dialer app with number entered, user initiates call
- **Web**: Attempts tel: link, may show browser notification if no phone capability
- **macOS (desktop)**: May fail gracefully if no phone app available
- **Emulator**: Always returns `CallResult.unavailable`

**Error Handling Contract**:
- Never throws exceptions - all failures converted to CallResult enum
- PlatformException caught and converted to CallResult.error
- Unsupported platform detected as CallResult.unavailable

### canLaunchEmergencyCall() [Optional Future Enhancement]
**Purpose**: Pre-check platform dialer capability (not implemented in MVP)

**Interface**:
```dart
Future<bool> canLaunchEmergencyCall()
```

**Contract**: Returns platform capability for tel: scheme handling
**MVP Decision**: Not implemented - direct launch with error handling preferred

## Widget Testing Contracts

### EmergencyButton Widget Contract
**Purpose**: Testable interface for emergency contact button component

**Widget Properties Contract**:
```dart
EmergencyButton({
  required EmergencyContact contact,
  required VoidCallback onPressed,
  Key? key,
})
```

**Input Contract**:
- `contact`: Non-null EmergencyContact with valid fields
- `onPressed`: Non-null callback function for tap handling  
- `key`: Optional widget key for testing identification

**Rendering Contract**:
- Button text matches `contact.displayText` exactly
- Touch target area ≥44dp × 44dp (accessibility requirement)
- Semantic label includes contact description if provided
- Visual styling matches contact priority level

**Accessibility Contract**:
- Semantics(label: contact.description) wrapper if description exists
- Semantics(button: true) role identification
- excludeSemantics: false to ensure screen reader access
- Minimum contrast ratio 4.5:1 (WCAG AA compliance)

### ReportFireScreen Widget Contract  
**Purpose**: Full screen integration testing interface

**Screen Behavior Contract**:
- Displays exactly 3 emergency contact buttons
- Buttons ordered by priority: critical, important, standard
- Screen title displays "Report a Fire" 
- AppBar includes back navigation capability
- No loading states (static content)
- No network indicators (offline capable)

**Navigation Contract**:
- Route path: "/report"
- Accessible via go_router navigation
- Can be navigated to from any screen in app
- Back navigation returns to previous route

**Error Display Contract**:
- SnackBar shown on CallResult.unavailable or CallResult.error
- SnackBar content includes manual dialing instructions
- SnackBar dismissed automatically after 5 seconds
- Error state doesn't prevent subsequent button taps

## Integration Test Contracts

### Platform Integration Contract
**Test Scope**: Real device testing for actual dialer integration

**Success Criteria**:
- On physical device: Native dialer opens with correct number
- On emulator: SnackBar appears with fallback instructions
- Multiple button taps handled gracefully
- Screen orientation changes preserve functionality

**Performance Contract**:
- Button tap response < 100ms
- Screen load time < 200ms  
- No memory leaks on repeated navigation
- Smooth animations at 60fps

## Accessibility Testing Contract

### Screen Reader Contract**:
- All buttons announced with service name and phone number
- Semantic ordering follows visual priority (999, 101, 0800)
- Focus navigation works correctly with external keyboard/switch control
- Voice control commands work for button activation

### Visual Accessibility Contract**:
- High contrast mode support maintained
- Large text scaling preserves button layout
- Color blind users can distinguish button priorities
- Dark theme maintains all accessibility features