# Spec: 022 – Onboarding & Legal Integration

**Status:** Ready for Implementation  
**Created:** 2025-12-09  
**Last Updated:** 2025-12-10

---

## Goal

Add a first-launch onboarding flow to the WildFire app that:

- Introduces what the app is and is not
- Shows a short emergency disclaimer and links to full legal docs
- Lets the user choose a preferred notification distance from fires (stored for future use; also to be used for calculating number of active fires in risk banner — see Future Work)
- Requires explicit consent to terms before proceeding
- Marks onboarding as complete so it's skipped on subsequent launches
- Supports version migration when legal terms are updated

**Style**: Use the existing WildFire theme (Material 3) with "Option B" flavour (see Appendix) – full-bleed background colour/illustration and a central card for content.

---

## Prerequisites

Before implementing 022, the following must be completed:

### P1: Legal Routes (separate task)
Create in-app legal screens:
- `/about` → Legal & About hub
- `/about/terms` → Terms of Service
- `/about/privacy` → Privacy Policy  
- `/about/data-sources` → Data sources & attribution

These routes do not currently exist in the codebase.

---

## 1. New Persistent Settings

Implement via SharedPreferences:

### `onboarding_version`: int
- Default: `0` (absent = never completed)
- Current version: `1`
- Set to current version after user completes onboarding with required checkboxes
- Used for version migration (see Section 9)

### `terms_accepted_version`: int
- Default: `0` (not accepted)
- Current version: `1`
- Records which version of terms the user accepted
- **GDPR audit requirement**: Must be persisted for compliance

### `terms_accepted_timestamp`: int (milliseconds since epoch)
- Default: `0`
- Records when terms were accepted (UTC)
- **GDPR audit requirement**: Must be persisted for compliance

### `notification_radius_km`: int
- Default: `10` (safe baseline)
- Values allowed: `0` (off), `5`, `10`, `25`, `50`
- `0` means notifications disabled

---

## 2. Routing & Navigation

### New routes

```dart
GoRoute(
  path: '/onboarding',
  name: 'onboarding',
  builder: (context, state) => const OnboardingScreen(),
),
```

### Redirect logic

In root router (lib/app.dart):

```dart
// In router redirect logic:
final prefs = await SharedPreferences.getInstance();
final onboardingVersion = prefs.getInt('onboarding_version') ?? 0;
const currentVersion = 1;

if (onboardingVersion < currentVersion && state.uri.path != '/onboarding') {
  return '/onboarding';
}
```

On finishing onboarding:

```dart
final now = DateTime.now().toUtc().millisecondsSinceEpoch;
await prefs.setInt('onboarding_version', 1);
await prefs.setInt('terms_accepted_version', 1);
await prefs.setInt('terms_accepted_timestamp', now);
await prefs.setInt('notification_radius_km', selectedRadiusKm);
context.go('/');
```

---

## 3. Onboarding Flow – Layout & Styling

Implement as one `OnboardingScreen` with 4 pages inside a `PageView`.

### 3.1 Layout (Option B flavour)

**Structure:**
- **Background**: Scaffold with `BrandPalette.forest900` or `colorScheme.surface`
- **Top**: App logo / pin icon and "WildFire Tracker" title
- **Middle**: Card with rounded corners (12-24px), elevation or soft shadow
- **Bottom**:
  - Primary button ("Continue" / "Get started")
  - Page indicator dots (4 steps)

**Styling:**
- Use Material 3 `FilledButton` for primary actions
- Use `TextButton` for links
- Respect existing typography (`Theme.of(context).textTheme.*`)

**Accessibility:**
- All buttons ≥44dp height
- Semantics labels per page: "Continue onboarding, step 1 of 4"

---

## 4. Onboarding Content (Per Page)

### Page 1 – Welcome

**Purpose**: Friendly intro + scope

**Content:**
- **Title**: "Welcome to the Wildfire Tracker"
- **Body**:
  - "This app helps you stay aware of wildfire risk and recent fire activity across Scotland."
  - "Data is based on environmental models and satellite detections and may be delayed or incomplete."
- **Bullet list**:
  - "Check today's wildfire risk where you are."
  - "Explore satellite-detected hotspots."
  - "Plan ahead for days with higher risk."
  - "Pick a location with accurate coordinates to help reporting."
  - "Learn about Wildfires and their prevention"

**Buttons:**
- Primary: "Continue"

**Skip behaviour**: Pages 1-3 can be skipped via swipe or "Continue" – but Page 4 checkboxes are mandatory.

---

### Page 2 – Safety & Emergency Disclaimer

**Content:**

> WildFire Tracker provides general wildfire-risk information and satellite-detected hotspots.
> This app is not a real-time emergency alert system.
> If you see fire or believe life or property is at risk, call 999 immediately.
> For non-emergency fire concerns, call 101.

**Layout:**
- Warning icon (amber from theme palette)
- Bold emphasis on 999 and 101
- Link: "View full Terms & Privacy" → `context.push('/about')`

**Buttons:**
- Primary: "Continue"
- Secondary text link: "View full Terms & Privacy"

---

### Page 3 – Data & Privacy Snapshot

**Content (bullet points):**
- "We don't collect names, emails, or account data."
- "We don't store your exact GPS location. Logged locations are privacy-safe and approximate."
- "We don't use tracking or advertising SDKs."
- "You can turn location off in your device settings at any time."

**Link:** "Read the full Privacy Policy" → `context.push('/about/privacy')`

**Buttons:**
- Primary: "Continue"

---

### Page 4 – Setup & Consent

**Title**: "Set Up Your App"

#### Section A: Location Access
- **Button**: "Allow Location Access" / "Deny"
- Triggers system permission dialog via existing `LocationResolver`
- User can proceed regardless of choice

#### Section B: Notification Radius
- **Label**: "Notify me about active fires within:"
- **UI**: Material 3 segmented buttons
- **Options**: `Off`, `5 km`, `10 km`, `25 km`, `50 km`
- **Default**: `10 km` pre-selected

#### Section C: Legal Checkboxes (MANDATORY)

Both checkboxes **must** be checked before "Get started" is enabled:

```
☐ I understand this app is informational only and is not an emergency alert system.
☐ I agree to the Terms of Service and Privacy Policy.
```

- Link under checkboxes: "View full disclaimer →" → `context.push('/about/terms')`
- "Get started" button disabled (greyed out) until both checked
- Show helper text: "Please accept both to continue"

#### Section D: CTA

**Buttons:**
- Primary: "Get started" (disabled until checkboxes checked)
  - Saves all preferences (see Section 2)
  - Navigates to `/`

**No skip option on Page 4** – legal consent is mandatory.

---

## 5. GDPR Consent Tracking (Best Practice)

For UK GDPR compliance, consent must be:
- **Freely given**: User can deny location, choose "Off" for notifications
- **Specific**: Separate checkboxes for understanding disclaimer vs accepting terms
- **Informed**: Links to full legal documents available
- **Unambiguous**: Explicit checkbox action required
- **Recorded**: Timestamp and version stored locally

### Stored consent record:

```dart
// SharedPreferences keys
'terms_accepted_version': 1,        // Which version was accepted
'terms_accepted_timestamp': 1733756400000,  // When (UTC millis)
'onboarding_version': 1,            // Completion marker
```

### Future audit retrieval:

```dart
Future<ConsentRecord?> getConsentRecord() async {
  final prefs = await SharedPreferences.getInstance();
  final version = prefs.getInt('terms_accepted_version');
  final timestamp = prefs.getInt('terms_accepted_timestamp');
  
  if (version == null || timestamp == null) return null;
  
  return ConsentRecord(
    termsVersion: version,
    acceptedAt: DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
  );
}
```

---

## 6. Existing Disclaimers Review

### Home Screen Footer
**Current state**: No disclaimer text exists on home screen.  
**Action required**: Add footer disclaimer under risk banner.

**Text to add:**
> Not for emergency use. Data from EFFIS/SEPA. Call 999 in an emergency.

**Implementation:**
- Add below `RiskGuidanceCard` in `lib/screens/home_screen.dart`
- Use `Theme.of(context).textTheme.bodySmall` with reduced opacity
- Wrap in `Semantics` with full label including "call 999"

### Map Fire Marker Bottom Sheet  
**Current state**: Already has disclaimer text ✅

**Existing text** (line ~351 in `fire_details_bottom_sheet.dart`):
> "These details come from satellite detections and may lag behind real-world conditions. If you are in immediate danger, call 999 without delay."

**Action required**: None – existing text is sufficient.

---

## 7. Files to Create/Modify

### New files

| File | Purpose |
|------|---------|
| `lib/features/onboarding/onboarding_screen.dart` | Main 4-page PageView with all content |
| `lib/features/onboarding/widgets/onboarding_page.dart` | Reusable page template (card layout) |
| `lib/features/onboarding/widgets/consent_checkboxes.dart` | Checkbox group with validation |
| `lib/features/onboarding/widgets/radius_selector.dart` | Segmented button for km selection |
| `lib/services/onboarding_prefs.dart` | Preference helpers |

### Modified files

| File | Change |
|------|--------|
| `lib/app.dart` | Add `/onboarding` route and redirect logic |
| `lib/screens/home_screen.dart` | Add footer disclaimer text |

---

## 8. Non-Goals / Constraints

- **Do not** implement real notifications – just capture the distance preference
- **Do not** add analytics/trackers – maintain "no tracking" stance
- **Do not** allow skipping legal checkboxes on Page 4
- Respect existing privacy rules (use `LocationUtils.logRedact()` for debug logs)

### Future Work (out of scope for 022)
- Use `notification_radius_km` to calculate and display "X active fires within Y km" in risk banner
- Push notifications when new fires detected within radius
- "Learn about Wildfires" educational content section

---

## 9. Version Migration

When legal terms are updated in a future release:

1. Increment `currentVersion` constant (e.g., `1` → `2`)
2. Update legal document content
3. App redirect logic will catch `onboarding_version < currentVersion`
4. User sees onboarding again with explanation:

**Migration screen header:**
> "We've updated our terms"
> 
> "Please review the changes and confirm to continue using the app."

5. User must re-check consent boxes
6. New version and timestamp saved

---

## 10. Acceptance Criteria

### Functional
- [ ] Onboarding shown on first launch only
- [ ] All 4 pages accessible via swipe and "Continue" button
- [ ] Page indicator dots show current position
- [ ] Legal checkboxes required before "Get started" enabled
- [ ] Preferences persisted correctly (`onboarding_version`, `terms_accepted_*`, `notification_radius_km`)
- [ ] Legal links navigate to `/about/*` routes and return correctly
- [ ] Home screen footer disclaimer visible after onboarding
- [ ] Existing bottom sheet disclaimer unchanged

### Accessibility (C3)
- [ ] All touch targets ≥44dp
- [ ] Semantic labels on all interactive elements
- [ ] VoiceOver (iOS) tested
- [ ] TalkBack (Android) tested
- [ ] High contrast mode supported

### Version Migration
- [ ] Incrementing version triggers re-onboarding
- [ ] Previous consent timestamp preserved for audit
- [ ] New consent recorded with new timestamp

---

## 11. Testing Requirements

### Unit Tests
- [ ] `onboarding_prefs.dart` – get/set all preferences
- [ ] Consent record serialization/deserialization
- [ ] Version comparison logic

### Widget Tests
- [ ] Each onboarding page renders correctly
- [ ] Page navigation (swipe, button)
- [ ] Checkbox state management
- [ ] "Get started" disabled until both checkboxes checked
- [ ] Radius selector state changes
- [ ] Legal links trigger navigation

### Integration Tests
- [ ] Full onboarding flow end-to-end
- [ ] Redirect from `/` to `/onboarding` on first launch
- [ ] No redirect after completion
- [ ] Version migration triggers re-onboarding
- [ ] Preferences persist across app restart

### Accessibility Audit
- [ ] Screen reader announces page content correctly
- [ ] Focus order logical
- [ ] Checkbox state announced
- [ ] Button disabled state announced

---

## Appendix: Legal Document Content

Full legal document text is available in:  
`docs/onboarding_legal_draft.md`

Includes:
- Terms of Service
- Privacy Policy
- Emergency & Accuracy Disclaimer
- Data Sources & Attribution

---

## Appendix: Option B Style Reference

**Option B — 5-Screen Guided Story + Interaction**

A more "designed" experience suitable for app-store wow factor.

### Screen 1 — Why this app exists
- Hero image of Scottish hills
- "Scotland's wildfire seasons are becoming more unpredictable…"
- Sets emotional context, purpose

### Screen 2 — What the app gives you
Icons for:
- Today's risk level
- Active fires nearby
- Map tools
- Offline/cached fallback

### Screen 3 — How the data works
- Simple animation or visual sequence of fallback chain
- A map blur showing radius of location rounding

### Screen 4 — Your role
- "You help by using this responsibly."
- Not a reporting tool for emergencies (but can help you gather coordinates)

### Screen 5 — Permissions + Legal
- Location permission
- Notifications preference
- Legal disclaimer acknowledgment
- "Get Started" button

**Pros:**
- Premium feel
- Builds trust
- Helps avoid future user misunderstanding

**Cons:**
- More design overhead
- Slightly more friction for the user
