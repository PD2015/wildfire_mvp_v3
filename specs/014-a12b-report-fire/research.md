# Research: A12b – Report Fire Screen (Descriptive)

**Date**: 2025-10-28  
**Feature**: Enhanced Report Fire Screen with Scotland-specific guidance

## Research Findings

### Content Structure and Readability
**Decision**: Multi-section layout with step-by-step emergency guidance  
**Rationale**: 
- Users need clear prioritization during emergency situations
- Step 1 (active fires) → Step 2 (non-emergency) → Step 3 (anonymous) flow matches cognitive processing under stress
- Year 7-8 reading level requirement necessitates short paragraphs and scannable format
- Research shows emergency users scan rather than read, requiring visual hierarchy
**Alternatives considered**:
- Single-column text block: Too overwhelming for emergency situations
- Tab-based interface: Adds cognitive load when users need immediate action
- Accordion-style collapsible sections: Hides critical information behind interactions

### Safety Guidance Integration
**Decision**: Dedicated safety tips card with "What to Report" examples and movement guidance  
**Rationale**:
- Scotland Fire and Rescue Service guidance emphasizes location details (What3Words/GPS coordinates)
- "Move uphill/upwind" and "don't fight fires" are critical safety messages for wildfire scenarios
- Structured format allows screen readers to navigate safety information separately from action buttons
- Examples reduce cognitive load by providing concrete templates for emergency calls
**Alternatives considered**:
- Inline safety tips within button sections: Creates visual clutter and reduces scanability
- External links to safety resources: Requires network connectivity, violates offline requirement
- Modal popup safety guidance: Adds interaction friction during emergency situations

### Enhanced Emergency Button Styling
**Decision**: Preserve existing EmergencyButton component with enhanced visual hierarchy  
**Rationale**:
- A12 MVP implementation already provides accessibility-compliant button architecture
- Material 3 ColorScheme provides appropriate semantic colors (error for 999, primary for 101, surfaceVariant for Crimestoppers)
- Existing ≥44dp touch targets meet accessibility requirements; A12b increases to ≥48dp for improved usability
- Screen reader compatibility already established in A12 implementation
**Alternatives considered**:
- Complete button redesign: Would break existing accessibility testing and user familiarity
- Icon-based buttons: Could confuse users in emergency situations who need clear text labels
- Floating action buttons: Don't provide enough space for descriptive contact information

### Offline Capability and Error Handling
**Decision**: Extend existing SnackBar fallback system with enhanced offline detection  
**Rationale**:
- A12 MVP already handles url_launcher failures gracefully with manual dialing instructions
- Offline banner can be shown persistently when tel: scheme support is unavailable
- No network dependencies required - all content is static and embedded in app
- Error states must be visible rather than silent (constitutional principle compliance)
**Alternatives considered**:
- Network connectivity checks: Adds unnecessary complexity for static content feature
- Cached content systems: Not needed since all guidance content is built into the app
- Progressive web app offline service worker: Overengineered for simple static content

### Accessibility and Screen Reader Support
**Decision**: Semantic HTML-like structure with proper heading hierarchy and label associations  
**Rationale**:
- VoiceOver and TalkBack require logical navigation order: header → guidance → buttons → safety tips
- Emergency contact buttons need clear semantic labels that include both number and service name
- Step-by-step guidance sections need proper header tags (h2/h3 equivalent) for navigation landmarks
- Color cannot be the only differentiator for emergency vs non-emergency contacts (WCAG AA compliance)
**Alternatives considered**:
- Flat widget tree without semantic structure: Would fail accessibility testing
- Audio descriptions or TTS integration: Beyond scope for MVP, adds complex dependencies
- High contrast theme override: Existing Material 3 ColorScheme already provides AA compliance

### Performance and Loading Strategy
**Decision**: StatelessWidget with const constructors for all static content  
**Rationale**:
- Emergency situations require instant screen availability (<100ms load time)
- All guidance content is static text and doesn't require state management
- Const constructors reduce widget rebuilds and improve performance
- No asynchronous loading states needed since content is built into the app
**Alternatives considered**:
- StatefulWidget with loading states: Adds unnecessary complexity for static content
- External content management system: Would require network connectivity and violate offline requirements
- Dynamic content based on user location: Beyond scope and would require location permissions

### Testing and Quality Assurance Strategy
**Decision**: Widget tests for accessibility compliance + integration tests for offline scenarios  
**Rationale**:
- Emergency calling functionality already tested in A12 MVP implementation
- New focus on accessibility testing with VoiceOver/TalkBack simulation
- Integration tests must cover offline/emulator scenarios where tel: URLs fail
- Screen reader navigation order testing critical for emergency use cases
**Alternatives considered**:
- Manual testing only: Insufficient for accessibility compliance verification
- Unit tests for static content: Limited value since content is embedded constants
- Automated accessibility scanning tools: Helpful but insufficient for emergency use case validation

### Content Hierarchy and Information Architecture
**Decision**: Warning banner → Emergency steps → Safety tips → Educational link structure  
**Rationale**:
- "Act fast — stay safe" banner immediately establishes tone and urgency
- Three-step progression matches emergency response priority: active threats → non-emergency → anonymous reporting
- Safety tips card positioned after action buttons to avoid delaying emergency calls
- Educational link at bottom for users who want deeper wildfire knowledge
**Alternatives considered**:
- Safety tips first: Could delay emergency calls during active fire situations
- Single emergency contact: Doesn't address non-emergency or anonymous reporting needs
- Tabbed interface separating emergency vs non-emergency: Adds cognitive load during stress
