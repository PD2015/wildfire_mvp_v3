# Feature Specification: A12 – Report Fire Screen (MVP)

**Feature Branch**: `013-a12-report-fire`  
**Created**: 27 October 2025  
**Status**: Draft  
**Input**: User description: "Add a minimal, accessible screen that instructs users how to report a fire in Scotland and provides one-tap call actions for 999 (Fire Service), 101 (Police Scotland), and 0800 555 111 (Crimestoppers). No user data collection; privacy-safe; works offline with a dialer fallback notice."

## Execution Flow (main)
```
1. Parse user description from Input ✓
   → Feature clear: Emergency reporting screen for fire incidents in Scotland
2. Extract key concepts from description ✓
   → Actors: walkers/visitors, local residents
   → Actions: report fires via official emergency channels
   → Data: no collection, privacy-safe
   → Constraints: offline capability, accessibility compliance
3. For each unclear aspect: ✓
   → All aspects well-defined in provided scope
4. Fill User Scenarios & Testing section ✓
   → Clear user flow: spot fire → access screen → call appropriate service
5. Generate Functional Requirements ✓
   → Each requirement testable and measurable
6. Identify Key Entities ✓
   → Minimal data entities (emergency contacts only)
7. Run Review Checklist ✓
   → No technical implementation details
   → All requirements testable
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing

### Primary User Story
As a person in Scotland who spots a fire or fire-related emergency, I need quick access to the correct emergency contact numbers with clear instructions, so I can report the incident immediately through official channels without confusion or delay.

### Acceptance Scenarios
1. **Given** I am using the WildFire app and need to report a fire emergency, **When** I navigate to the Report Fire screen, **Then** I see three clearly labeled call-to-action buttons for 999 (Fire Service), 101 (Police Scotland), and 0800 555 111 (Crimestoppers) with appropriate emergency styling
2. **Given** I am on the Report Fire screen on a device with calling capability, **When** I tap any of the three emergency contact buttons, **Then** my device's dialer opens with the correct number pre-filled and ready to call
3. **Given** I am on the Report Fire screen on a device without calling capability (emulator/web), **When** I tap any emergency contact button, **Then** I see a clear notification explaining that the dialer cannot open and suggesting manual dialing
4. **Given** I am a user with accessibility needs, **When** I navigate the Report Fire screen using screen reader or voice control, **Then** each button has clear semantic labels and meets minimum touch target size requirements
5. **Given** I am using the app in poor network conditions or offline, **When** I access the Report Fire screen, **Then** all content loads immediately as it requires no network connectivity

### Edge Cases
- What happens when device has no phone app installed? System shows fallback notification with number to manually dial
- How does system handle different device types? Responsive design ensures buttons remain accessible on all screen sizes
- What if user accidentally taps a button? Standard system dialer confirmation prevents accidental calls

## Requirements

### Functional Requirements
- **FR-001**: System MUST provide a dedicated "Report a Fire" screen accessible via navigation route "/report"
- **FR-002**: Screen MUST display three emergency contact buttons: "Call 999 — Fire Service" (primary emergency styling), "Call 101 — Police Scotland", and "Call 0800 555 111 — Crimestoppers"
- **FR-003**: Each button MUST attempt to open the device's native dialer with the corresponding emergency number pre-filled when tapped
- **FR-004**: System MUST display instructional copy specific to Scotland fire reporting procedures that is concise and action-oriented
- **FR-005**: System MUST show a clear notification when dialer cannot open (offline/emulator scenarios) directing users to manually dial the number
- **FR-006**: All call-to-action buttons MUST meet minimum touch target size of 44dp for accessibility compliance
- **FR-007**: Screen MUST provide semantic labels for all interactive elements to support screen readers and assistive technologies
- **FR-008**: Screen MUST maintain WCAG AA contrast ratios in both light and dark themes
- **FR-009**: Screen MUST function entirely offline with no network dependencies or data transmission
- **FR-010**: System MUST NOT collect, store, or transmit any user location data or personally identifiable information from this screen

### Key Entities
- **Emergency Contact**: Represents official emergency service contact information including service name, phone number, and display priority
- **Call Action**: Represents user interaction to initiate emergency call with fallback behavior for unsupported devices

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---
