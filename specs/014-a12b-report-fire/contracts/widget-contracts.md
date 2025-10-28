# Widget Interface Contracts: A12b – Report Fire Screen (Descriptive)

**Date**: 2025-10-28  
**Feature**: Enhanced emergency calling interface contracts

## ReportFireScreen Widget Contract
**Purpose**: Main screen widget interface for enhanced fire reporting

### Widget Behavior Contract
```dart
class ReportFireScreen extends StatelessWidget {
  const ReportFireScreen({super.key});
  
  // Returns Material Scaffold with enhanced emergency guidance
  @override
  Widget build(BuildContext context);
}
```

**Visual Contract**:
- AppBar with title "Report a Fire" and back navigation
- Warning banner: "See smoke, flames, or a campfire? Act fast — stay safe."
- Three guidance sections with step-by-step emergency progression
- Safety tips card with structured safety information
- Educational link to wildfire learning resources
- Proper Material 3 ColorScheme integration

**Accessibility Contract**:
- Screen reader navigation follows emergency priority order
- All buttons meet ≥48dp touch target requirement
- Semantic labels for all interactive elements
- Proper heading hierarchy for guidance sections
- AA contrast ratio compliance in light/dark themes

## GuidanceSection Widget Contract
**Purpose**: Individual step guidance with associated emergency contact

### Interface
```dart
class GuidanceSection extends StatelessWidget {
  final int stepNumber;              // 1, 2, 3
  final SafetyGuidance guidance;     // Content data
  final VoidCallback onEmergencyCall; // Button tap handler
  final bool showDivider;           // Visual separation
  
  const GuidanceSection({
    super.key,
    required this.stepNumber,
    required this.guidance,
    required this.onEmergencyCall,
    this.showDivider = true,
  });
}
```

**Behavior Contract**:
- Step number displayed as visual hierarchy indicator
- Guidance title renders as semantic heading (h2 equivalent)
- Description text maintains Year 7-8 reading level
- Examples list provides scannable bullet format
- Emergency button integrates with existing EmergencyButton component

**Visual Styling Contract**:
- Step 1: Error color scheme (urgent emergency)
- Step 2: Primary color scheme (important but non-emergency)  
- Step 3: Surface variant color scheme (standard reporting)
- Consistent 16dp spacing between elements
- Divider lines for visual section separation

## SafetyTipsCard Widget Contract
**Purpose**: Safety guidance and movement advice display

### Interface
```dart
class SafetyTipsCard extends StatelessWidget {
  final List<SafetyTip> tips;          // Safety instructions
  final String whatToReportGuidance;   // Location reporting guidance
  
  const SafetyTipsCard({
    super.key,
    required this.tips,
    required this.whatToReportGuidance,
  });
}
```

**Content Contract**:
- Card header: "Safety Tips" with info icon
- Maximum 4 safety tips for scannable layout
- Warning tips (fire fighting, movement) visually emphasized
- What3Words/GPS reporting guidance prominently displayed
- Rounded card styling consistent with app theme

**Accessibility Contract**:
- Card announced as single semantic unit
- Individual tips navigable by screen reader
- Warning tips include semantic emphasis
- Icon-text associations properly labeled

## EmergencyButton Enhancement Contract
**Purpose**: Extended styling for enhanced emergency contact buttons

### Enhanced Interface
```dart
class EmergencyButton extends StatelessWidget {
  final EmergencyContact contact;      // Existing contact data
  final VoidCallback onPressed;        // Existing tap handler
  final EmergencyButtonStyle style;    // New styling options
  
  const EmergencyButton({
    super.key,
    required this.contact,
    required this.onPressed,
    this.style = EmergencyButtonStyle.standard,
  });
}

enum EmergencyButtonStyle {
  urgent,     // Error color, bold styling for 999
  important,  // Primary color for 101
  standard,   // Surface variant for Crimestoppers
}
```

**Enhanced Behavior Contract**:
- Button text includes contact context: "Call 999 — Fire Service"
- Minimum touch target: 48dp x 48dp (exceeds 44dp requirement)
- Material 3 elevation and ripple effects
- Loading state during url_launcher call attempt
- Error state integration with SnackBar fallback

## Accessibility Testing Contract
**Purpose**: Comprehensive accessibility compliance verification

### Screen Reader Navigation Contract
```
Navigation Order:
1. AppBar title and back button
2. Warning banner (critical context)
3. Step 1 heading → guidance → 999 button
4. Step 2 heading → guidance → 101 button  
5. Step 3 heading → guidance → Crimestoppers button
6. Safety Tips card → individual tips
7. Educational link
```

**VoiceOver/TalkBack Announcements**:
- Buttons: "Call 999 Fire Service, button, Opens phone dialer for emergency call"
- Headings: "Step 1 Active Fire Emergency, heading level 2"
- Cards: "Safety Tips, card, 4 items"
- Links: "Learn how wildfires are reported, link"

### Touch Target Contract
```dart
// Minimum touch target verification
const double minTouchTarget = 48.0; // dp

bool verifyTouchTarget(Widget widget) {
  final RenderBox renderBox = widget.findRenderObject() as RenderBox;
  return renderBox.size.width >= minTouchTarget && 
         renderBox.size.height >= minTouchTarget;
}
```

### Color Contrast Contract
- AA compliance verification in light theme (contrast ratio ≥ 4.5:1)
- AA compliance verification in dark theme (contrast ratio ≥ 4.5:1)
- Error colors maintain contrast for urgent emergency buttons
- Surface colors provide sufficient differentiation between steps

## Integration Testing Contract
**Purpose**: End-to-end functionality verification

### Emergency Call Flow Contract
```dart
// Test emergency call initiation
testWidgets('emergency button opens dialer on capable devices', (tester) async {
  // Setup: Device with dialer capability
  // Action: Tap emergency button
  // Verify: url_launcher called with correct tel: URI
  // Verify: No SnackBar error shown
});

testWidgets('emergency button shows fallback on incapable devices', (tester) async {
  // Setup: Emulator or device without dialer
  // Action: Tap emergency button  
  // Verify: SnackBar shows manual dialing instructions
  // Verify: Manual number matches button contact
});
```

### Accessibility Integration Contract
```dart
// Test complete screen reader navigation
testWidgets('screen reader navigates emergency guidance correctly', (tester) async {
  // Setup: Enable screen reader simulation
  // Action: Navigate through all elements
  // Verify: Navigation order matches emergency priority
  // Verify: All elements have semantic labels
});
```

### Offline Functionality Contract
```dart
// Test offline capability
testWidgets('screen functions fully without network', (tester) async {
  // Setup: Disable network connectivity
  // Action: Load screen and interact with all elements
  // Verify: All content displays correctly
  // Verify: Emergency buttons function (attempt dialer)
  // Verify: No network error states shown
});
```