# Content Structure Contracts: A12b – Report Fire Screen (Descriptive)

**Date**: 2025-10-28  
**Feature**: Scotland-specific emergency guidance content contracts

## Content Hierarchy Contract
**Purpose**: Define information architecture and reading flow

### Visual Hierarchy Contract
```
1. Warning Banner (Critical Alert)
   ├── Tone: "Act fast — stay safe"
   ├── Style: Alert banner with warning color
   └── Semantic: Alert role for screen readers

2. Emergency Guidance Steps (Priority Order)
   ├── Step 1: Active Fire Emergency (Urgent)
   │   ├── Header: "Step 1: Active Fire Emergency" 
   │   ├── Guidance: Brief action-oriented paragraph
   │   ├── Examples: 4 concrete "What to Report" items
   │   └── CTA: "Call 999 — Fire Service" (Error styling)
   │
   ├── Step 2: Non-Emergency Fires (Important)  
   │   ├── Header: "Step 2: Non-Emergency Reporting"
   │   ├── Guidance: Illegal campfire and containment scenarios
   │   ├── Examples: 3 non-spreading fire situations
   │   └── CTA: "Call 101 — Police Scotland" (Primary styling)
   │
   └── Step 3: Anonymous Reporting (Standard)
       ├── Header: "Step 3: Anonymous Reporting"
       ├── Guidance: Suspected arson reporting guidance
       ├── Examples: 2 suspicious activity indicators  
       └── CTA: "Call 0800 555 111 — Crimestoppers" (Surface styling)

3. Safety Tips Card (Supplementary Information)
   ├── Header: "Safety Tips"
   ├── What to Report: Location guidance (What3Words/GPS)
   ├── Safety Posture: "Don't fight fires yourself"
   └── Movement: "Move uphill and upwind"

4. Educational Link (Optional Learning)
   └── "Learn how wildfires are reported" → Internal content
```

## Reading Level Contract
**Purpose**: Ensure Year 7-8 comprehension level per FR-015

### Text Complexity Requirements
- **Average sentence length**: 12-15 words maximum
- **Paragraph length**: 2-3 sentences, maximum 50 words
- **Vocabulary**: Common emergency terminology, avoid technical jargon
- **Sentence structure**: Simple subject-verb-object construction preferred

### Readability Validation
```
Flesch-Kincaid Grade Level: 7.0-8.0 target
Flesch Reading Ease: 60-70 (Standard readability)
Gunning Fog Index: <10 (Accessible complexity)
```

**Content Examples**:
```
✅ GOOD: "Call 999 immediately if you see flames spreading or people in danger."
❌ POOR: "Emergency services should be contacted via the 999 emergency number in situations involving active conflagration with potential for rapid propagation or immediate threat to human safety."

✅ GOOD: "Share your exact location using What3Words or GPS coordinates."  
❌ POOR: "Provide precise geographical coordinates utilizing satellite-based positioning systems or three-word location identification protocols."
```

## Scotland-Specific Content Contract
**Purpose**: Ensure content relevance for Scottish emergency services

### Emergency Service Context
- **Fire Service (999)**: Scottish Fire and Rescue Service authority
- **Police Scotland (101)**: Non-emergency reporting for illegal fires
- **Crimestoppers (0800 555 111)**: Anonymous crime reporting service

### Geographic Context Requirements
- Reference Scottish terrain challenges (hills, remote areas, limited access)
- Include What3Words prominence (widely used in Scotland emergency services)
- Acknowledge seasonal fire risks (spring/summer dry periods)
- Consider rural vs urban fire reporting differences

### Cultural Sensitivity Contract
```
Language Requirements:
- Use "wildfire" rather than "bushfire" (Australian term) or "forest fire" (too limiting)
- Reference "campfire" and "controlled burn" scenarios familiar to Scottish outdoor culture
- Include "illegal fire" terminology consistent with Scottish law
- Use "emergency services" rather than "first responders" (American terminology)
```

## Accessibility Content Contract
**Purpose**: Screen reader and assistive technology compatibility

### Semantic Structure Requirements
```html
<!-- Equivalent semantic structure for Flutter -->
<main role="main">
  <section aria-labelledby="warning-banner" role="alert">
    <h1 id="warning-banner">Emergency Fire Reporting</h1>
    <p>See smoke, flames, or a campfire? Act fast — stay safe.</p>
  </section>
  
  <section aria-labelledby="step-1">
    <h2 id="step-1">Step 1: Active Fire Emergency</h2>
    <p>Call 999 immediately if you see flames spreading or people in danger.</p>
    <ul>
      <li>Location: What3Words or GPS coordinates</li>
      <li>Size: 'Small campfire' or 'spreading across hillside'</li>
    </ul>
    <button type="button" aria-describedby="step-1">Call 999 — Fire Service</button>
  </section>
</main>
```

### Screen Reader Announcement Contract
```
Expected Announcements:
- Alert banner: "Emergency Fire Reporting, alert"
- Section headers: "Step 1 Active Fire Emergency, heading level 2"  
- Button context: "Call 999 Fire Service, button. Opens phone dialer for emergency call"
- Lists: "4 items. Location What3Words or GPS coordinates, list item 1 of 4"
```

### Visual Accessibility Contract
- **Color independence**: Information must be understandable without color perception
- **High contrast mode**: All text maintains AA contrast ratio (4.5:1 minimum)
- **Large text scaling**: Layout remains functional at 200% text size
- **Focus indicators**: All interactive elements show clear focus state

## Content Maintenance Contract
**Purpose**: Ensure content accuracy and currency

### Validation Requirements
- **Emergency numbers**: Verify 999, 101, 0800 555 111 remain current for Scotland
- **Service names**: "Scottish Fire and Rescue Service", "Police Scotland" official naming
- **Safety guidance**: Align with current Scottish Fire and Rescue Service wildfire guidance
- **Legal references**: Ensure "illegal fire" terminology matches Scottish law

### Review Schedule
- **Annual review**: Verify emergency service contact information
- **Seasonal update**: Adjust wildfire risk messaging for fire season
- **Incident-based**: Update guidance based on major wildfire incidents
- **Accessibility audit**: Annual screen reader compatibility verification

### Localization Contract (Future Enhancement)
```
Reserved for future implementation:
- Gaelic language support (if required by Scottish Government)
- Tourist-specific guidance (if app expands beyond residents)
- Regional fire service variations (if Scotland regionalizes further)
```

## Error Content Contract
**Purpose**: Clear messaging when emergency calling fails

### SnackBar Fallback Content
```
Title: "Dialer unavailable"
Message: "Your device cannot make calls right now."
Manual instruction: "Dial manually: [phone_number]"
Action: "OK" button to dismiss
```

### Offline Detection Content
```
Banner text: "This device cannot make phone calls"
Explanation: "Use another phone to call emergency services"
Persistent display: Shown until capability is restored
```

### Content Tone Requirements
- **Calm and clear**: Avoid panic-inducing language during errors
- **Actionable**: Always provide alternative action (manual dialing)
- **Accessible**: Error messages must be announced by screen readers
- **Brief**: Error content under 20 words for quick comprehension