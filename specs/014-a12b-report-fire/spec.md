# Feature Specification: A12b – Report Fire Screen (Descriptive)

**Feature Branch**: `014-a12b-report-fire`  
**Created**: 28 October 2025  
**Status**: Draft  
**Input**: User description: "Replace/extend the MVP 'Report a Fire' screen with more descriptive, Scotland-specific guidance while preserving one-tap calling for 999 (Fire Service), 101 (Police Scotland), and 0800 555 111 (Crimestoppers). Copy should be concise but richer: include examples of what to say, safety posture (don't fight fires), and movement advice (uphill/upwind)."

## Execution Flow (main)
```
1. Parse user description from Input
   → Feature description provided: enhanced Report Fire screen with Scotland-specific guidance
2. Extract key concepts from description
   → Actors: Scottish residents, visitors, emergency responders
   → Actions: reporting fires, emergency calling, safety guidance
   → Data: Scotland-specific emergency contacts, safety instructions
   → Constraints: accessibility requirements, privacy preservation
3. For each unclear aspect:
   → All aspects clearly specified in scope
4. Fill User Scenarios & Testing section
   → Clear user flows for different emergency scenarios identified
5. Generate Functional Requirements
   → Each requirement is testable and measurable
6. Identify Key Entities (if data involved)
   → Emergency contacts, safety guidance content
7. Run Review Checklist
   → No implementation details included, focused on user value
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a person in Scotland who spots a potential wildfire, I need clear, actionable guidance on what to report and who to call, so I can respond appropriately to different emergency situations while staying safe.

### Acceptance Scenarios
1. **Given** I spot active flames spreading rapidly, **When** I access the Report Fire screen, **Then** I see clear emergency guidance with examples of what to report and a prominent 999 Fire Service button
2. **Given** I notice an illegal campfire but no active spreading, **When** I view the non-emergency section, **Then** I see concise guidance and can easily call 101 Police Scotland
3. **Given** I want to report suspected arson anonymously, **When** I look for anonymous reporting options, **Then** I find Crimestoppers contact with clear explanation of when to use it
4. **Given** I'm using a screen reader, **When** I navigate the Report Fire screen, **Then** all emergency buttons and guidance sections are properly announced with semantic labels
5. **Given** I'm on a device without cellular service, **When** I try to make an emergency call, **Then** I see a helpful offline notification explaining the limitation

### Edge Cases
- What happens when the device cannot make phone calls (tablet/simulator)?
- How does the system handle users who are colorblind or have low vision?
- What if a user needs guidance in multiple emergency scenarios simultaneously?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: Screen MUST display at route "/report" with title "Report a Fire"
- **FR-002**: Screen MUST include a warning banner with tone: "See smoke, flames, or a campfire? Act fast — stay safe."
- **FR-003**: Screen MUST provide Step 1 emergency guidance with examples of what to report (location, terrain, spread, access)
- **FR-004**: Screen MUST include one-tap Call 999 Fire Service button for active emergencies
- **FR-005**: Screen MUST provide Step 2 guidance for non-spreading fires with Call 101 Police Scotland button
- **FR-006**: Screen MUST provide Step 3 anonymous reporting option with Call 0800 555 111 Crimestoppers button
- **FR-007**: Screen MUST display safety tips card including What3Words/GPS guidance, "don't fight fires" warning, and "move uphill/upwind" advice
- **FR-008**: System MUST open device dialer when emergency buttons are pressed on capable devices
- **FR-009**: System MUST show SnackBar fallback message when dialer cannot be opened (simulator/offline/tablet)
- **FR-010**: Screen MUST include "Learn how wildfires are reported" link to internal education content
- **FR-011**: Screen MUST display optional offline banner when device is offline or tel: URLs cannot open
- **FR-012**: All interactive elements MUST meet ≥48dp minimum touch target size for accessibility
- **FR-013**: All content MUST use semantic labels and proper heading hierarchy for screen readers
- **FR-014**: Color scheme MUST provide AA contrast ratio in both light and dark themes
- **FR-015**: Text content MUST maintain Year 7-8 reading level with scannable 2-3 line paragraphs
- **FR-016**: Emergency buttons MUST use appropriate color emphasis (error/primary/surfaceVariant from app theme)
- **FR-017**: Screen MUST work fully offline without requiring network connectivity
- **FR-018**: System MUST NOT collect, store, or transmit user location or usage telemetry

### Key Entities *(include if feature involves data)*
- **Emergency Contact**: Scotland-specific emergency service with phone number, display name, and usage context (active emergency vs non-emergency vs anonymous)
- **Safety Guidance Content**: Structured safety instructions including what to report, safety posture, and movement advice
- **Offline State**: System capability to detect and respond to offline conditions or dialer limitations

---

## Success Criteria
- CTAs successfully open device dialer on phones; show appropriate SnackBar fallback on simulator/tablet
- Copy achieves Year 7-8 reading level and remains scannable with 2-3 short lines per paragraph
- All accessibility tests pass including VoiceOver/TalkBack compatibility
- AA contrast ratio verified in both light and dark themes
- Screen functions fully without network connectivity
- Zero telemetry or location data collection/transmission

## Out of Scope
- Collecting incident reports or media uploads
- GPS/location sharing or What3Words integration (reserved for future enhancement)
- Push notifications or real-time updates
- Multi-language support (English only for Scotland market)
- Integration with emergency service dispatch systems

## Dependencies
- Existing url_launcher package (^6.3.0) for dialer integration
- Current app theme system and ColorScheme implementation
- Existing routing infrastructure pointing to "/report" route

## Guardrails
- Must comply with constitutional requirements C1-C5 per project constitution
- Must preserve existing emergency calling functionality
- Must maintain privacy-first approach with no data collection
- Must ensure accessibility compliance for all users

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

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
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (none found)
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---
