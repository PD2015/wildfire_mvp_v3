# Quickstart: A12b – Report Fire Screen (Descriptive)

**Date**: 2025-10-28  
**Feature**: Enhanced fire reporting with Scotland-specific guidance  
**Prerequisites**: Existing A12 Report Fire MVP implementation

## Quick Integration (10 minutes)

### 1. Verify Base Dependencies
```bash
# Check existing A12 implementation
flutter pub deps | grep url_launcher  # Should show ^6.3.0
ls lib/features/report/screens/        # Should show report_fire_screen.dart
ls lib/utils/                          # Should show url_launcher_utils.dart
```

### 2. Test Existing Emergency Calling
```bash
# Run existing tests to verify A12 base functionality
flutter test test/features/report/screens/report_fire_screen_test.dart
flutter test test/utils/url_launcher_utils_test.dart
```

### 3. Create Enhanced Widget Components
```bash
# Create new guidance widgets (builds on existing EmergencyButton)
touch lib/features/report/widgets/guidance_section.dart
touch lib/features/report/widgets/safety_tips_card.dart
touch lib/features/report/models/safety_guidance.dart
```

### 4. Enhance Existing Screen
```dart
// Replace existing ReportFireScreen content while preserving:
// - AppBar structure and navigation
// - Emergency contact button functionality  
// - SnackBar error handling
// - Accessibility touch targets and semantic labels

class ReportFireScreen extends StatelessWidget {
  const ReportFireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Fire'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Enhanced warning banner
              _buildWarningBanner(),
              const SizedBox(height: 24.0),
              
              // Step-by-step guidance sections
              ...ScotlandFireGuidance.steps.map((guidance) =>
                GuidanceSection(
                  guidance: guidance,
                  onEmergencyCall: () => _handleEmergencyCall(context, guidance.contact),
                ),
              ),
              
              const SizedBox(height: 32.0),
              
              // Safety tips card
              const SafetyTipsCard(),
              
              const SizedBox(height: 24.0),
              
              // Educational link
              _buildEducationalLink(context),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 5. Quick Accessibility Test
```bash
# Test enhanced screen with accessibility
flutter test --tags=accessibility
# Manual test: Enable VoiceOver/TalkBack and navigate screen
```

## Complete User Stories Validation

### Story 1: Active Fire Emergency (999)
**Test Steps**:
1. User sees active flames spreading on hillside
2. Opens Report Fire screen from navigation
3. Reads Step 1 guidance: "Call 999 immediately if you see flames spreading"
4. Sees examples: location, size, terrain, access details
5. Taps "Call 999 — Fire Service" button

**Expected Result**: Device dialer opens with 999 pre-filled, or SnackBar shows manual dialing fallback
**Verification**: Emergency contact reached quickly with relevant information ready

### Story 2: Illegal Campfire (101) 
**Test Steps**:
1. User notices unattended campfire in restricted area
2. Sees fire is contained but potentially illegal
3. Reads Step 2 guidance for non-emergency reporting
4. Understands this is Police Scotland jurisdiction
5. Taps "Call 101 — Police Scotland" button

**Expected Result**: Non-emergency dialer opens, user reports illegal fire activity
**Verification**: Appropriate service contacted for enforcement rather than emergency response

### Story 3: Suspected Arson (Crimestoppers)
**Test Steps**:
1. User witnesses suspicious fire-starting activity
2. Wants to report anonymously due to safety concerns
3. Reads Step 3 guidance for anonymous reporting
4. Understands Crimestoppers process
5. Taps "Call 0800 555 111 — Crimestoppers" button

**Expected Result**: Anonymous reporting line opens, user can report without identification
**Verification**: Suspected crime reported through appropriate anonymous channel

### Story 4: Screen Reader Navigation
**Test Steps**:
1. Screen reader user opens Report Fire screen
2. Warning banner announced first (alert role)
3. Navigates through Step 1 heading → guidance → examples → button
4. Continues through Steps 2-3 in logical order
5. Reaches Safety Tips card as supplementary information

**Expected Result**: Complete navigation without missing critical information
**Verification**: All emergency options accessible to users with visual impairments

### Story 5: Device Without Dialer (Tablet/Emulator)
**Test Steps**:
1. User on tablet or emulator accesses screen
2. Reads appropriate guidance for their situation
3. Attempts to call emergency service
4. Receives clear fallback notification
5. Uses manual dialing information to call from another device

**Expected Result**: Clear error handling with actionable alternative
**Verification**: Users not blocked from reporting fires due to device limitations

## Integration Checklist

### Content Integration
- [ ] Warning banner displays with appropriate urgency styling
- [ ] Three guidance steps show in emergency priority order
- [ ] Each step includes concrete "what to report" examples
- [ ] Safety tips card appears after action buttons
- [ ] Educational link provides optional additional learning

### Emergency Calling Integration
- [ ] All three emergency contacts (999, 101, 0800 555 111) function correctly
- [ ] Button styling reflects emergency priority (error > primary > surface)
- [ ] SnackBar fallback shows manual dialing instructions when needed
- [ ] No network connectivity required for any functionality

### Accessibility Integration
- [ ] Screen reader announces content in logical emergency order
- [ ] All buttons meet ≥48dp touch target requirement
- [ ] Semantic labels provide context for all interactive elements
- [ ] Color scheme maintains AA contrast in light and dark themes
- [ ] Content scales properly with large text settings

### Testing Coverage
- [ ] Widget tests for all new guidance components
- [ ] Integration tests for emergency call flows
- [ ] Accessibility tests for screen reader compatibility
- [ ] Performance tests for instant screen loading

### Constitutional Compliance
- [ ] C1: flutter analyze passes, comprehensive tests included
- [ ] C2: No data collection, no secrets, safe logging (emergency use only)
- [ ] C3: Enhanced accessibility with ≥48dp targets and semantic labels
- [ ] C4: Official Scotland emergency service colors and contact information
- [ ] C5: Clear error handling, offline capability, no silent failures

## Performance Validation

### Loading Performance
- [ ] Screen displays instantly (<100ms from navigation)
- [ ] No loading states required (static content)
- [ ] Smooth scrolling with multiple guidance sections
- [ ] No memory leaks on repeated navigation

### Interaction Performance  
- [ ] Emergency buttons respond immediately (<50ms touch feedback)
- [ ] SnackBar appears within 100ms of dialer failure
- [ ] Smooth animations for all state transitions
- [ ] Consistent 60fps performance on target devices

## Troubleshooting

### Common Issues

**"Enhanced content too wordy"**:
- Verify each paragraph ≤50 words and ≤3 sentences
- Use Flesch-Kincaid Grade Level 7-8 target
- Test with real users unfamiliar with wildfire reporting

**"Screen reader navigation confusing"**:
- Verify semantic heading hierarchy (h1 → h2 → h3 equivalent)
- Test actual VoiceOver/TalkBack navigation order
- Ensure alert banner announced first for critical context

**"Emergency buttons not visually distinct"**:
- Verify error color scheme for 999 Fire Service
- Confirm primary color for 101 Police Scotland
- Check surface variant color for Crimestoppers
- Test in both light and dark themes

### Performance Issues

**"Screen loads slowly"**:
- Check for non-const widget constructors
- Verify all guidance content is static (no async loading)
- Profile with Flutter Inspector for rebuild patterns

**"Guidance sections cause overflow"**:
- Ensure SingleChildScrollView wrapper around content
- Verify responsive layout at different screen sizes
- Test with large text accessibility settings enabled

## Content Validation

### Scotland Emergency Services Verification
- [ ] 999 connects to Scottish Fire and Rescue Service
- [ ] 101 connects to Police Scotland non-emergency line
- [ ] 0800 555 111 connects to Crimestoppers anonymous reporting
- [ ] All service names use official Scottish terminology

### Safety Guidance Accuracy
- [ ] "Move uphill/upwind" aligns with Scottish Fire and Rescue guidance
- [ ] "Don't fight fires yourself" messaging matches official safety advice
- [ ] What3Words prominence reflects Scotland emergency service adoption
- [ ] Terrain and access examples relevant to Scottish geography

### Reading Level Verification
```bash
# Use readability tools to verify content
echo "Call 999 immediately if you see flames spreading or people in danger." | readability-cli
# Target: Grade 7-8, Flesch Reading Ease 60-70
```

### Accessibility Audit
```bash
# Run accessibility testing
flutter test --tags=a11y
# Manual verification with screen reader
# Contrast ratio testing with accessibility tools
```

## Deployment Checklist

### Pre-Release Validation
- [ ] All emergency numbers verified current for Scotland
- [ ] Content reviewed for Year 7-8 reading level
- [ ] Accessibility testing passed with assistive technologies
- [ ] Performance benchmarks met on target devices
- [ ] Offline functionality verified (no network dependencies)

### Post-Release Monitoring
- [ ] Emergency call success rates (where measurable)
- [ ] Screen reader usage analytics (if available)
- [ ] User feedback on guidance clarity and usefulness
- [ ] Performance metrics for screen loading and interaction