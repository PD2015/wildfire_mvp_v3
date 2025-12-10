# Tasks: 022 – Onboarding & Legal Integration

**Generated**: 2025-12-10  
**Total Tasks**: 22  
**Estimated Effort**: 10-15 hours

---

## Phase 0: Foundation (P0)

### Task P0.1: Create ConsentRecord Model

**Priority**: P0  
**Depends On**: None  
**Effort**: 30 min

#### Files
- Create: `lib/models/consent_record.dart`
- Create: `test/unit/models/consent_record_test.dart`

#### Requirements
1. Equatable class with:
   - `termsVersion` (int) - which terms version was accepted
   - `acceptedAt` (DateTime) - UTC timestamp of acceptance
2. `isCurrentVersion` getter - compares to `OnboardingConfig.currentTermsVersion`
3. `formattedDate` getter - returns "10 Dec 2025 at 14:30 UTC" format

#### Acceptance Criteria
- [ ] `flutter analyze lib/models/consent_record.dart` passes
- [ ] `flutter test test/unit/models/consent_record_test.dart` passes
- [ ] Tests cover: equality, props, isCurrentVersion, formattedDate

#### Test Command
```bash
flutter test test/unit/models/consent_record_test.dart
```

---

### Task P0.2: Create OnboardingState Sealed Classes

**Priority**: P0  
**Depends On**: None  
**Effort**: 30 min

#### Files
- Create: `lib/features/onboarding/models/onboarding_state.dart`
- Create: `test/unit/models/onboarding_state_test.dart`

#### Requirements
1. Sealed class hierarchy:
   - `OnboardingState` (base)
   - `OnboardingLoading` - initial loading state
   - `OnboardingActive` - active flow with page tracking
   - `OnboardingComplete` - ready to navigate
   - `OnboardingMigration` - version upgrade needed
2. `OnboardingActive` properties:
   - `currentPage` (int, default 0)
   - `totalPages` (int, always 4)
   - `disclaimerChecked` (bool)
   - `termsChecked` (bool)
   - `selectedRadiusKm` (int, default 10)
   - `locationPermissionGranted` (bool)
   - `isRequestingLocation` (bool)
3. `OnboardingActive` getters:
   - `canProceed` - true for pages 0-2, requires both checkboxes for page 3
   - `canFinish` - true when on page 3 with both checkboxes checked
4. `copyWith` method for `OnboardingActive`

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/models/` passes
- [ ] `flutter test test/unit/models/onboarding_state_test.dart` passes
- [ ] Tests cover: all state classes, canProceed logic, canFinish logic, copyWith

#### Test Command
```bash
flutter test test/unit/models/onboarding_state_test.dart
```

---

### Task P0.3: Create OnboardingPrefsService Interface

**Priority**: P0  
**Depends On**: P0.1  
**Effort**: 20 min

#### Files
- Create: `lib/services/onboarding_prefs.dart`

#### Requirements
1. Abstract class `OnboardingPrefsService` with methods:
   - `Future<bool> isOnboardingRequired()`
   - `Future<bool> isMigrationRequired()`
   - `Future<int> getOnboardingVersion()`
   - `Future<ConsentRecord?> getConsentRecord()`
   - `Future<int> getNotificationRadiusKm()`
   - `Future<int> getPreviousVersion()`
   - `Future<void> completeOnboarding({required int radiusKm})`
   - `Future<void> updateNotificationRadius({required int radiusKm})`
2. `OnboardingConfig` class with constants:
   - `currentOnboardingVersion = 1`
   - `currentTermsVersion = 1`
   - `validRadiusOptions = [0, 5, 10, 25, 50]`
   - `defaultRadiusKm = 10`
   - SharedPreferences key constants

#### Acceptance Criteria
- [ ] `flutter analyze lib/services/onboarding_prefs.dart` passes
- [ ] Interface compiles with all method signatures

#### Test Command
```bash
flutter analyze lib/services/onboarding_prefs.dart
```

---

### Task P0.4: Implement OnboardingPrefsImpl

**Priority**: P0  
**Depends On**: P0.3  
**Effort**: 45 min

#### Files
- Create: `lib/services/onboarding_prefs_impl.dart`
- Create: `test/unit/services/onboarding_prefs_test.dart`

#### Requirements
1. Implement all `OnboardingPrefsService` methods
2. Use `SharedPreferences` for persistence
3. `isOnboardingRequired()`: version < currentOnboardingVersion
4. `isMigrationRequired()`: version > 0 AND version < current
5. `completeOnboarding()`: validate radiusKm, save all 4 keys atomically
6. `getConsentRecord()`: return null if missing keys
7. Throw `ArgumentError` for invalid radius values

#### Acceptance Criteria
- [ ] `flutter analyze lib/services/onboarding_prefs_impl.dart` passes
- [ ] `flutter test test/unit/services/onboarding_prefs_test.dart` passes
- [ ] Tests cover:
  - isOnboardingRequired (first launch, incomplete, complete)
  - isMigrationRequired (first launch vs upgrade)
  - completeOnboarding (saves all keys, validates radius)
  - getConsentRecord (missing, present)
  - getNotificationRadiusKm (default, custom)

#### Test Command
```bash
flutter test test/unit/services/onboarding_prefs_test.dart
```

---

## Phase 1: Legal Routes (P1)

### Task P1.1: Create LegalContent with Documents

**Priority**: P1  
**Depends On**: None  
**Effort**: 45 min

#### Files
- Create: `lib/content/legal_content.dart`

#### Requirements
1. `LegalDocument` class with:
   - `id` (String)
   - `title` (String)
   - `version` (String)
   - `effectiveDate` (DateTime)
   - `content` (String)
2. `LegalContent` class with static documents:
   - `termsOfService`
   - `privacyPolicy`
   - `emergencyDisclaimer`
   - `dataSources`
3. Copy content from `docs/onboarding_legal_draft.md`
4. Content version constant for migration tracking

#### Acceptance Criteria
- [ ] `flutter analyze lib/content/legal_content.dart` passes
- [ ] All 4 documents have non-empty content
- [ ] Effective dates are valid

#### Test Command
```bash
flutter analyze lib/content/legal_content.dart
```

---

### Task P1.2: Create LegalDocumentScreen

**Priority**: P1  
**Depends On**: P1.1  
**Effort**: 45 min

#### Files
- Create: `lib/screens/legal_document_screen.dart`
- Create: `test/widget/legal/legal_document_screen_test.dart`

#### Requirements
1. Accepts `LegalDocument` parameter
2. AppBar with document title
3. Scrollable body with document content
4. Back button returns to previous screen
5. Minimum 48dp touch targets

#### Acceptance Criteria
- [ ] `flutter analyze lib/screens/legal_document_screen.dart` passes
- [ ] `flutter test test/widget/legal/legal_document_screen_test.dart` passes
- [ ] Tests cover: title displayed, content displayed, back navigation

#### Test Command
```bash
flutter test test/widget/legal/legal_document_screen_test.dart
```

---

### Task P1.3: Create AboutScreen Hub

**Priority**: P1  
**Depends On**: P1.2  
**Effort**: 30 min

#### Files
- Create: `lib/screens/about_screen.dart`
- Create: `test/widget/legal/about_screen_test.dart`

#### Requirements
1. AppBar with "About" title
2. List tiles linking to:
   - Terms of Service (`/about/terms`)
   - Privacy Policy (`/about/privacy`)
   - Data Sources (`/about/data-sources`)
3. App version display at bottom
4. Minimum 48dp touch targets

#### Acceptance Criteria
- [ ] `flutter analyze lib/screens/about_screen.dart` passes
- [ ] `flutter test test/widget/legal/about_screen_test.dart` passes
- [ ] Tests cover: all links present, navigation works

#### Test Command
```bash
flutter test test/widget/legal/about_screen_test.dart
```

---

### Task P1.4: Add Legal Routes to Router

**Priority**: P1  
**Depends On**: P1.3  
**Effort**: 30 min

#### Files
- Modify: `lib/app.dart`

#### Requirements
1. Add `/about` route with `AboutScreen`
2. Add nested routes:
   - `/about/terms` → `LegalDocumentScreen(LegalContent.termsOfService)`
   - `/about/privacy` → `LegalDocumentScreen(LegalContent.privacyPolicy)`
   - `/about/data-sources` → `LegalDocumentScreen(LegalContent.dataSources)`
3. Routes should be outside ShellRoute (no bottom nav)
4. NO redirect logic yet (that's P3)

#### Acceptance Criteria
- [ ] `flutter analyze lib/app.dart` passes
- [ ] Can navigate to `/about` and sub-routes manually
- [ ] Back navigation works correctly

#### Test Command
```bash
flutter analyze lib/app.dart
```

---

## Phase 2: Onboarding UI (P2)

### Task P2.1: Create OnboardingCard Widget

**Priority**: P2  
**Depends On**: None  
**Effort**: 20 min

#### Files
- Create: `lib/features/onboarding/widgets/onboarding_card.dart`

#### Requirements
1. Reusable card with rounded corners
2. Accepts `child` widget
3. Consistent padding (24dp)
4. Slight elevation or border
5. Constrained max width (400dp) for tablets

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/widgets/onboarding_card.dart` passes
- [ ] Widget renders correctly in preview

#### Test Command
```bash
flutter analyze lib/features/onboarding/widgets/onboarding_card.dart
```

---

### Task P2.2: Create HeroBackground Widget

**Priority**: P2  
**Depends On**: None  
**Effort**: 20 min

#### Files
- Create: `lib/features/onboarding/widgets/hero_background.dart`

#### Requirements
1. Gradient background (fire-themed warm colors)
2. Accepts `child` widget
3. Falls back gracefully if rendering fails
4. SafeArea compatible

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/widgets/hero_background.dart` passes
- [ ] Gradient renders on all platforms

#### Test Command
```bash
flutter analyze lib/features/onboarding/widgets/hero_background.dart
```

---

### Task P2.3: Create PageIndicator Widget

**Priority**: P2  
**Depends On**: None  
**Effort**: 15 min

#### Files
- Create: `lib/features/onboarding/widgets/page_indicator.dart`

#### Requirements
1. Shows 4 dots for pages
2. Current page dot highlighted (larger/different color)
3. Accepts `currentPage` and `totalPages` parameters
4. Accessible (announces "Page X of Y")

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/widgets/page_indicator.dart` passes
- [ ] Correct dot highlighted for each page

#### Test Command
```bash
flutter analyze lib/features/onboarding/widgets/page_indicator.dart
```

---

### Task P2.4: Create RadiusSelector Widget

**Priority**: P2  
**Depends On**: None  
**Effort**: 30 min

#### Files
- Create: `lib/features/onboarding/widgets/radius_selector.dart`

#### Requirements
1. SegmentedButton with options: Off, 5km, 10km, 25km, 50km
2. Accepts `selectedRadius` and `onChanged` callback
3. Minimum 48dp touch targets
4. Accessible labels for each option

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/widgets/radius_selector.dart` passes
- [ ] Selection changes correctly
- [ ] Touch targets ≥48dp

#### Test Command
```bash
flutter analyze lib/features/onboarding/widgets/radius_selector.dart
```

---

### Task P2.5: Create WelcomePage

**Priority**: P2  
**Depends On**: P2.1, P2.2  
**Effort**: 30 min

#### Files
- Create: `lib/features/onboarding/widgets/welcome_page.dart`
- Create: `test/widget/onboarding/welcome_page_test.dart`

#### Requirements
1. HeroBackground with gradient
2. App logo from `assets/icons/app_icon.png`
3. OnboardingCard with:
   - "Welcome to WildFire" title
   - App description
   - Key features bullet list
4. "Continue" button at bottom
5. Button callback: `onContinue`

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/widgets/welcome_page.dart` passes
- [ ] `flutter test test/widget/onboarding/welcome_page_test.dart` passes
- [ ] Tests cover: renders correctly, continue button works

#### Test Command
```bash
flutter test test/widget/onboarding/welcome_page_test.dart
```

---

### Task P2.6: Create SafetyDisclaimerPage

**Priority**: P2  
**Depends On**: P2.1  
**Effort**: 30 min

#### Files
- Create: `lib/features/onboarding/widgets/safety_disclaimer_page.dart`
- Create: `test/widget/onboarding/safety_disclaimer_page_test.dart`

#### Requirements
1. Warning icon (`Icons.warning_amber`)
2. OnboardingCard with:
   - "Safety First" title
   - Disclaimer text with 999/101 emphasized
   - "View full disclaimer" link → push `/about/terms`
3. "Continue" button
4. Button callback: `onContinue`, `onViewTerms`

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/widgets/safety_disclaimer_page.dart` passes
- [ ] `flutter test test/widget/onboarding/safety_disclaimer_page_test.dart` passes
- [ ] Tests cover: renders correctly, links work, continue button works

#### Test Command
```bash
flutter test test/widget/onboarding/safety_disclaimer_page_test.dart
```

---

### Task P2.7: Create PrivacyPage

**Priority**: P2  
**Depends On**: P2.1  
**Effort**: 30 min

#### Files
- Create: `lib/features/onboarding/widgets/privacy_page.dart`
- Create: `test/widget/onboarding/privacy_page_test.dart`

#### Requirements
1. OnboardingCard with:
   - "Your Privacy" title
   - Privacy bullet points (no accounts, local storage, etc.)
   - "View privacy policy" link → push `/about/privacy`
2. "Continue" button
3. Button callbacks: `onContinue`, `onViewPrivacy`

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/widgets/privacy_page.dart` passes
- [ ] `flutter test test/widget/onboarding/privacy_page_test.dart` passes
- [ ] Tests cover: renders correctly, link works, continue button works

#### Test Command
```bash
flutter test test/widget/onboarding/privacy_page_test.dart
```

---

### Task P2.8: Create SetupConsentPage

**Priority**: P2  
**Depends On**: P2.1, P2.4  
**Effort**: 45 min

#### Files
- Create: `lib/features/onboarding/widgets/setup_consent_page.dart`
- Create: `test/widget/onboarding/setup_consent_page_test.dart`

#### Requirements
1. OnboardingCard with sections:
   - **Location**: "Allow Location Access" button (uses existing LocationResolver)
   - **Notifications**: RadiusSelector for distance preference
   - **Consent**: Two checkboxes (disclaimer acknowledged, terms accepted)
2. "View full disclaimer" link
3. "Get Started" button - disabled until both checkboxes checked
4. Callbacks:
   - `onRequestLocation`
   - `onRadiusChanged(int)`
   - `onDisclaimerChecked(bool)`
   - `onTermsChecked(bool)`
   - `onGetStarted`
5. All touch targets ≥48dp

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/widgets/setup_consent_page.dart` passes
- [ ] `flutter test test/widget/onboarding/setup_consent_page_test.dart` passes
- [ ] Tests cover:
  - Button disabled when checkboxes unchecked
  - Button enabled when both checked
  - Checkbox state changes correctly
  - Radius selection works

#### Test Command
```bash
flutter test test/widget/onboarding/setup_consent_page_test.dart
```

---

### Task P2.9: Create OnboardingScreen with PageView

**Priority**: P2  
**Depends On**: P2.3, P2.5, P2.6, P2.7, P2.8  
**Effort**: 45 min

#### Files
- Create: `lib/features/onboarding/screens/onboarding_screen.dart`
- Create: `test/widget/onboarding/onboarding_screen_test.dart`

#### Requirements
1. Scaffold with SafeArea
2. PageView with 4 pages (NeverScrollableScrollPhysics - no swipe)
3. PageController for programmatic navigation
4. PageIndicator at bottom
5. Handle all page callbacks to advance/complete
6. State: currentPage, disclaimerChecked, termsChecked, selectedRadius
7. No controller yet - just local state

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/screens/onboarding_screen.dart` passes
- [ ] `flutter test test/widget/onboarding/onboarding_screen_test.dart` passes
- [ ] Tests cover:
  - Starts on page 0
  - Continue advances to next page
  - Page indicator updates
  - Cannot swipe between pages
  - Get Started requires both checkboxes

#### Test Command
```bash
flutter test test/widget/onboarding/onboarding_screen_test.dart
```

---

## Phase 3: Controller & Router (P3)

### Task P3.1: Create OnboardingController

**Priority**: P3  
**Depends On**: P0, P2.9  
**Effort**: 45 min

#### Files
- Create: `lib/features/onboarding/controllers/onboarding_controller.dart`

#### Requirements
1. ChangeNotifier extending controller pattern
2. Inject `OnboardingPrefsService` and `LocationResolver`
3. State management for all OnboardingState variants
4. Methods:
   - `initialize()` - check if migration needed
   - `nextPage()`
   - `setDisclaimerChecked(bool)`
   - `setTermsChecked(bool)`
   - `setRadius(int)`
   - `requestLocation()` - uses LocationResolver.getLatLon()
   - `completeOnboarding()` - saves prefs, transitions to complete state

#### Acceptance Criteria
- [ ] `flutter analyze lib/features/onboarding/controllers/onboarding_controller.dart` passes
- [ ] Controller compiles and integrates with OnboardingScreen

#### Test Command
```bash
flutter analyze lib/features/onboarding/controllers/
```

---

### Task P3.2: Update main.dart for Prefs Pre-loading

**Priority**: P3  
**Depends On**: None  
**Effort**: 15 min

#### Files
- Modify: `lib/main.dart`

#### Requirements
1. Add `WidgetsFlutterBinding.ensureInitialized()` if not present
2. `await SharedPreferences.getInstance()` before runApp
3. Pass prefs to `WildFireApp` constructor

#### Acceptance Criteria
- [ ] `flutter analyze lib/main.dart` passes
- [ ] App starts successfully with pre-loaded prefs

#### Test Command
```bash
flutter analyze lib/main.dart
```

---

### Task P3.3: Update app.dart with Router Redirect

**Priority**: P3  
**Depends On**: P3.2, P1.4  
**Effort**: 30 min

#### Files
- Modify: `lib/app.dart`

#### Requirements
1. Accept `SharedPreferences prefs` in WildFireApp constructor
2. Add `/onboarding` route (outside ShellRoute)
3. Implement redirect logic:
   - If onboarding incomplete AND not on `/onboarding` or `/about/*` → redirect `/onboarding`
   - If onboarding complete AND on `/onboarding` → redirect `/`
   - Otherwise no redirect
4. Use synchronous `prefs.getInt()` in redirect

#### Acceptance Criteria
- [ ] `flutter analyze lib/app.dart` passes
- [ ] Fresh install redirects to `/onboarding`
- [ ] Completed onboarding allows access to `/`
- [ ] Legal routes accessible during onboarding

#### Test Command
```bash
flutter analyze lib/app.dart
```

---

### Task P3.4: Create Integration Test

**Priority**: P3  
**Depends On**: P3.1, P3.3  
**Effort**: 45 min

#### Files
- Create: `test/integration/onboarding_flow_test.dart`

#### Requirements
1. Test complete onboarding flow:
   - Fresh install shows onboarding
   - Navigate through all 4 pages
   - Check both consent boxes
   - Complete onboarding
   - Verify navigation to home
2. Test persistence:
   - Complete onboarding
   - Recreate app
   - Verify skips onboarding
3. Test legal route access during onboarding:
   - On page 2, tap "View Terms"
   - Verify terms screen shown
   - Back returns to onboarding

#### Acceptance Criteria
- [ ] `flutter test test/integration/onboarding_flow_test.dart` passes
- [ ] All 3 test scenarios pass

#### Test Command
```bash
flutter test test/integration/onboarding_flow_test.dart
```

---

## Phase 4: Home Footer (P4)

### Task P4.1: Add Disclaimer Footer to HomeScreen

**Priority**: P4  
**Depends On**: P3  
**Effort**: 30 min

#### Files
- Modify: `lib/screens/home_screen.dart`
- Modify: `test/widget/home_screen_test.dart` (add test)

#### Requirements
1. Add footer text at bottom of home screen:
   - "For information only. Dial 999 in an emergency."
2. Style: muted color, smaller text, centered
3. Link "About this app" → navigate to `/about`
4. Footer should not scroll with content

#### Acceptance Criteria
- [ ] `flutter analyze lib/screens/home_screen.dart` passes
- [ ] `flutter test test/widget/home_screen_test.dart` passes
- [ ] Footer visible on home screen
- [ ] About link navigates correctly

#### Test Command
```bash
flutter test test/widget/home_screen_test.dart
```

---

## Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| P0: Foundation | 4 | ⬜ |
| P1: Legal Routes | 4 | ⬜ |
| P2: Onboarding UI | 9 | ⬜ |
| P3: Controller & Router | 4 | ⬜ |
| P4: Home Footer | 1 | ⬜ |
| **Total** | **22** | **0/22** |

---

## Execution Order

```
P0.1 ──┬── P0.2
       │
       ▼
     P0.3
       │
       ▼
     P0.4
       │
       ├───────────────────────────────┐
       │                               │
       ▼                               ▼
     P1.1                            P2.1 ── P2.2 ── P2.3 ── P2.4
       │                               │
       ▼                               ▼
     P1.2                      P2.5 ── P2.6 ── P2.7 ── P2.8
       │                               │
       ▼                               ▼
     P1.3                            P2.9
       │                               │
       ▼                               │
     P1.4 ─────────────────────────────┤
                                       │
                                       ▼
                              P3.1 ── P3.2 ── P3.3 ── P3.4
                                       │
                                       ▼
                                     P4.1
```

---

## Quick Start

Begin with:
```bash
# Start P0.1
touch lib/models/consent_record.dart
touch test/unit/models/consent_record_test.dart
```

After each task:
```bash
flutter analyze
flutter test <test_file>
```
