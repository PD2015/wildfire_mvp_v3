# Implementation Plan: 022 – Onboarding & Legal Integration

**Feature**: A16 Onboarding & Legal Integration  
**Branch**: `feature/agent-d/onboarding-disclaimers`  
**Created**: 2025-12-10  
**Status**: Ready for Task Generation

---

## Technical Context

### Environment
- **Flutter**: 3.35.5 stable
- **Dart**: 3.9.2
- **Target Platforms**: iOS, Android, Web
- **Dependencies**: shared_preferences, go_router, equatable (all existing)

### Key Patterns
- **State Management**: ChangeNotifier (existing pattern)
- **Navigation**: go_router with ShellRoute, redirect callback
- **Persistence**: SharedPreferences (pre-loaded in main.dart)
- **Error Handling**: Either<L,R> for services, plain states for UI

### Relevant Existing Files
| File | Purpose | Changes Required |
|------|---------|------------------|
| `lib/main.dart` | Entry point | Pre-load SharedPreferences, pass to app |
| `lib/app.dart` | Router config | Add redirect logic, new routes |
| `lib/screens/home_screen.dart` | Home page | Add disclaimer footer |

---

## Constitution Check

| Gate | Status | Notes |
|------|--------|-------|
| C1: Code Quality | ⬜ | `flutter analyze` must pass |
| C2: No Secrets | ✅ | Legal content as Dart strings, no API keys |
| C3: Accessibility | ⬜ | All touch targets ≥48dp, screen reader tested |
| C4: Transparency | ✅ | Data source attribution included |
| C5: Resilience | ⬜ | Graceful fallback if prefs fail |

---

## Project Structure

### New Files (18 files)

```
lib/
├── content/
│   └── legal_content.dart              # [P1] Legal document strings
│
├── features/
│   └── onboarding/
│       ├── models/
│       │   └── onboarding_state.dart   # [P0] Sealed state classes
│       │
│       ├── controllers/
│       │   └── onboarding_controller.dart  # [P3]
│       │
│       ├── screens/
│       │   └── onboarding_screen.dart  # [P2]
│       │
│       └── widgets/
│           ├── welcome_page.dart       # [P2]
│           ├── safety_disclaimer_page.dart  # [P2]
│           ├── privacy_page.dart       # [P2]
│           ├── setup_consent_page.dart # [P2]
│           ├── onboarding_card.dart    # [P2]
│           ├── hero_background.dart    # [P2]
│           ├── radius_selector.dart    # [P2]
│           └── page_indicator.dart     # [P2]
│
├── models/
│   └── consent_record.dart             # [P0] GDPR consent model
│
├── screens/
│   ├── about_screen.dart               # [P1] About hub
│   └── legal_document_screen.dart      # [P1] Legal viewer
│
└── services/
    ├── onboarding_prefs.dart           # [P0] Interface
    └── onboarding_prefs_impl.dart      # [P0] Implementation
```

### Modified Files (3 files)

```
lib/
├── main.dart           # [P3] Pre-load prefs
├── app.dart            # [P3] Router redirect + new routes
└── screens/
    └── home_screen.dart  # [P4] Footer disclaimer
```

### Test Files (11 files)

```
test/
├── unit/
│   ├── models/
│   │   ├── consent_record_test.dart          # [P0]
│   │   └── onboarding_state_test.dart        # [P0]
│   └── services/
│       └── onboarding_prefs_test.dart        # [P0]
│
├── widget/
│   ├── onboarding/
│   │   ├── onboarding_screen_test.dart       # [P2]
│   │   ├── welcome_page_test.dart            # [P2]
│   │   ├── safety_disclaimer_page_test.dart  # [P2]
│   │   ├── privacy_page_test.dart            # [P2]
│   │   └── setup_consent_page_test.dart      # [P2]
│   └── legal/
│       ├── about_screen_test.dart            # [P1]
│       └── legal_document_screen_test.dart   # [P1]
│
└── integration/
    └── onboarding_flow_test.dart             # [P3]
```

---

## Implementation Phases

### Phase 0: Foundation (P0) – 4 tasks
Data models and service interface. No UI.

| # | Task | Files | Tests | Depends |
|---|------|-------|-------|---------|
| 0.1 | Create ConsentRecord model | `consent_record.dart` | `consent_record_test.dart` | - |
| 0.2 | Create OnboardingState sealed classes | `onboarding_state.dart` | `onboarding_state_test.dart` | - |
| 0.3 | Create OnboardingPrefsService interface | `onboarding_prefs.dart` | - | 0.1 |
| 0.4 | Implement OnboardingPrefsImpl | `onboarding_prefs_impl.dart` | `onboarding_prefs_test.dart` | 0.3 |

**Exit Criteria**: `flutter test test/unit/` passes

---

### Phase 1: Legal Routes (P1) – 4 tasks
Legal document viewing without onboarding gate.

| # | Task | Files | Tests | Depends |
|---|------|-------|-------|---------|
| 1.1 | Create LegalContent with all documents | `legal_content.dart` | - | - |
| 1.2 | Create LegalDocumentScreen | `legal_document_screen.dart` | `legal_document_screen_test.dart` | 1.1 |
| 1.3 | Create AboutScreen hub | `about_screen.dart` | `about_screen_test.dart` | 1.2 |
| 1.4 | Add /about routes to app.dart (no redirect) | `app.dart` | - | 1.3 |

**Exit Criteria**: Can navigate to `/about/terms` and view content

---

### Phase 2: Onboarding UI (P2) – 9 tasks
All onboarding widgets without controller.

| # | Task | Files | Tests | Depends |
|---|------|-------|-------|---------|
| 2.1 | Create OnboardingCard widget | `onboarding_card.dart` | - | - |
| 2.2 | Create HeroBackground widget | `hero_background.dart` | - | - |
| 2.3 | Create PageIndicator widget | `page_indicator.dart` | - | - |
| 2.4 | Create RadiusSelector widget | `radius_selector.dart` | - | - |
| 2.5 | Create WelcomePage | `welcome_page.dart` | `welcome_page_test.dart` | 2.1, 2.2 |
| 2.6 | Create SafetyDisclaimerPage | `safety_disclaimer_page.dart` | `safety_disclaimer_page_test.dart` | 2.1 |
| 2.7 | Create PrivacyPage | `privacy_page.dart` | `privacy_page_test.dart` | 2.1 |
| 2.8 | Create SetupConsentPage | `setup_consent_page.dart` | `setup_consent_page_test.dart` | 2.1, 2.4 |
| 2.9 | Create OnboardingScreen with PageView | `onboarding_screen.dart` | `onboarding_screen_test.dart` | 2.3, 2.5-2.8 |

**Exit Criteria**: Can view all 4 pages, navigate between them

---

### Phase 3: Controller & Router (P3) – 4 tasks
Wire up controller and router redirect.

| # | Task | Files | Tests | Depends |
|---|------|-------|-------|---------|
| 3.1 | Create OnboardingController | `onboarding_controller.dart` | - | P0, P2 |
| 3.2 | Update main.dart to pre-load prefs | `main.dart` | - | - |
| 3.3 | Update app.dart with redirect logic | `app.dart` | - | 3.2 |
| 3.4 | Create integration test | `onboarding_flow_test.dart` | - | 3.1-3.3 |

**Exit Criteria**: Fresh install shows onboarding, completion navigates to home

---

### Phase 4: Home Footer (P4) – 1 task
Add disclaimer footer to home screen.

| # | Task | Files | Tests | Depends |
|---|------|-------|-------|---------|
| 4.1 | Add disclaimer footer to HomeScreen | `home_screen.dart` | (existing test update) | P3 |

**Exit Criteria**: Home screen shows "For information only. Dial 999 for emergencies."

---

## Estimated Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| P0: Foundation | 4 | 1-2 hours |
| P1: Legal Routes | 4 | 2-3 hours |
| P2: Onboarding UI | 9 | 4-6 hours |
| P3: Controller & Router | 4 | 2-3 hours |
| P4: Home Footer | 1 | 30 min |
| **Total** | **22** | **10-15 hours** |

---

## Dependencies Graph

```
P0: Foundation
    │
    ├─────────────────┐
    │                 │
    ▼                 ▼
P1: Legal Routes    P2: Onboarding UI
    │                 │
    └────────┬────────┘
             │
             ▼
      P3: Controller & Router
             │
             ▼
      P4: Home Footer
```

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Router redirect loops | High | Comprehensive test coverage in 3.4 |
| SharedPreferences load failure | Medium | Graceful fallback in 3.3 |
| Accessibility failures | Medium | Manual testing after P2 |
| Legal content changes post-launch | Low | Version migration mechanism |

---

## Progress Tracking

| Phase | Status | Completion |
|-------|--------|------------|
| P0: Foundation | ⬜ Not Started | 0/4 |
| P1: Legal Routes | ⬜ Not Started | 0/4 |
| P2: Onboarding UI | ⬜ Not Started | 0/9 |
| P3: Controller & Router | ⬜ Not Started | 0/4 |
| P4: Home Footer | ⬜ Not Started | 0/1 |

---

## Next Steps

1. **Generate tasks.md** – Create detailed task specifications with acceptance criteria
2. **Start P0** – Implement foundation models and service
3. **Validate P0** – Run unit tests before proceeding
4. **Continue P1-P4** – Follow dependency order

---

## References

- [Spec Document](./spec.md)
- [Research Notes](./research.md)
- [Data Model](./data-model.md)
- [API Contracts](./contracts/)
- [Quickstart Guide](./quickstart.md)
- [Legal Content Draft](../../docs/onboarding_legal_draft.md)
