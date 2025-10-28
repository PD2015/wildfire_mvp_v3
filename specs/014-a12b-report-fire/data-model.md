# Data Model: A12b – Report Fire Screen (Descriptive)

**Date**: 2025-10-28  
**Feature**: Enhanced Report Fire Screen with structured guidance content

## Entity Definitions

### SafetyGuidance
**Purpose**: Structured container for step-by-step emergency guidance content
**Source**: Feature requirements FR-003, FR-005, FR-007

```dart
class SafetyGuidance extends Equatable {
  final String stepTitle;           // e.g., "Step 1: Active Fire Emergency"
  final String description;         // Short guidance paragraph
  final List<String> examples;     // What to report examples
  final EmergencyContact? contact; // Associated emergency service
  final bool isUrgent;            // Visual priority indicator
}
```

**Validation Rules**:
- `stepTitle`: Non-empty, max 50 characters for scannable headers
- `description`: Max 200 characters to maintain Year 7-8 reading level
- `examples`: 2-4 concrete examples, each max 100 characters
- Contact association must match emergency service availability

**State Transitions**: Static content - no state changes required

### SafetyTipsCard (Value Object)
**Purpose**: Container for safety posture and movement advice content
**Source**: Feature requirement FR-007

```dart
class SafetyTipsCard extends Equatable {
  final String title;                    // "Safety Tips"
  final List<SafetyTip> tips;           // Individual safety instructions
  final String whatToReportGuidance;    // What3Words/GPS guidance
}

class SafetyTip extends Equatable {
  final IconData icon;        // Visual indicator
  final String title;         // Short tip headline
  final String description;   // Actionable instruction
  final bool isWarning;       // Critical safety warning flag
}
```

**Validation Rules**:
- Maximum 4 tips to maintain scannable layout
- Each tip description max 150 characters
- Warning tips (e.g., "don't fight fires") must be visually distinct

### EmergencyContact (Existing - Extended)
**Purpose**: Scotland emergency service contact with enhanced context
**Source**: Existing A12 model, extended for A12b descriptive content

```dart
// Extends existing model with additional context fields
class EmergencyContact extends Equatable {
  // Existing fields from A12
  final String name;           // "Fire Service"
  final String phoneNumber;    // "999"
  final EmergencyPriority priority;
  final String description;

  // New fields for A12b enhanced guidance
  final String whenToUse;      // "For active fires spreading rapidly"
  final String guidanceText;   // Expanded guidance paragraph
  final Color buttonColor;     // Theme-aware button color
}
```

**Enhanced Emergency Contacts**:
- **Fire Service (999)**: `priority: urgent`, `whenToUse: "Active fires spreading rapidly"`, `buttonColor: ColorScheme.error`
- **Police Scotland (101)**: `priority: important`, `whenToUse: "Illegal campfires, no spreading"`, `buttonColor: ColorScheme.primary` 
- **Crimestoppers (0800 555 111)**: `priority: standard`, `whenToUse: "Anonymous suspected arson reports"`, `buttonColor: ColorScheme.surfaceVariant`

### GuidanceSection (Widget Data)
**Purpose**: Structured data for each guidance step section
**Source**: Feature requirements FR-003, FR-005, FR-006

```dart
class GuidanceSection extends Equatable {
  final int stepNumber;              // 1, 2, 3
  final SafetyGuidance guidance;     // Step content
  final Widget actionButton;         // Emergency contact CTA
  final bool showDivider;           // Visual separation
}
```

**Display Rules**:
- Step 1: Emergency red styling with prominent visual treatment
- Step 2: Standard primary styling 
- Step 3: Subtle surface styling
- Dividers between sections for visual hierarchy

## Data Flow

### Static Content Loading
```
App Launch →
SafetyGuidanceFactory.createScotlandGuidance() →
List<GuidanceSection> →
ReportFireScreen widget build
```

### Emergency Call Flow
```
User taps emergency button →
EmergencyContact.telUri →
UrlLauncherUtils.handleEmergencyCall() →
Success: Native dialer opens |
Failure: SnackBar with EmergencyContact.phoneNumber for manual dialing
```

### Accessibility Navigation Flow
```
Screen reader focus →
Warning banner (semanticLabel) →
Step 1 heading (header semantics) →
Step 1 guidance (paragraph semantics) →
999 Fire Service button (button semantics + hint) →
Step 2 heading → ... →
Safety Tips card (card semantics) →
Learn more link (link semantics)
```

## Content Constants

### Scotland Emergency Guidance
**Source**: Feature specification functional requirements

```dart
static const scotlandFireGuidance = [
  SafetyGuidance(
    stepTitle: "Step 1: Active Fire Emergency",
    description: "Call 999 immediately if you see flames spreading or people in danger.",
    examples: [
      "Location: What3Words or GPS coordinates",
      "Size: 'Small campfire' or 'spreading across hillside'",
      "Terrain: 'Steep slope' or 'near buildings'",
      "Access: 'Off A82 road' or 'footpath only'"
    ],
    contact: EmergencyContact.fireService,
    isUrgent: true,
  ),
  // Additional steps...
];
```

### Safety Tips Content
```dart
static const safetyTips = [
  SafetyTip(
    icon: Icons.location_on,
    title: "Share precise location",
    description: "Use What3Words app or GPS coordinates for exact location",
    isWarning: false,
  ),
  SafetyTip(
    icon: Icons.warning,
    title: "Don't fight fires yourself",
    description: "Never attempt to extinguish wildfires - leave immediately",
    isWarning: true,
  ),
  SafetyTip(
    icon: Icons.trending_up,
    title: "Move uphill and upwind",
    description: "Fire spreads fastest uphill and downwind - move to safety",
    isWarning: true,
  ),
];
```

## Accessibility Data Structure

### Semantic Labels
Each interactive element requires structured semantic information:

```dart
class EmergencyButtonSemantics {
  final String label;        // "Call 999 Fire Service"
  final String hint;         // "Opens phone dialer for emergency call"
  final String value;        // "999"
  final bool isButton;       // true
  final bool isFocusable;    // true
  final Rect touchArea;      // Minimum 48dp x 48dp
}
```

### Navigation Order
Screen reader navigation follows logical emergency priority:
1. Warning banner (immediate context)
2. Emergency guidance sections (priority order)
3. Emergency action buttons (with clear labels)
4. Safety information (supplementary)
5. Educational resources (optional)

**Validation**: All navigation elements must pass VoiceOver/TalkBack compatibility testing