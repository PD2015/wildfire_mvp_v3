# Quickstart: 022 – Onboarding & Legal Integration

**Generated**: 2025-12-10  
**Status**: Ready for Implementation

---

## Prerequisites

- [ ] Flutter 3.35.5 / Dart 3.9.2
- [ ] Working development environment
- [ ] Branch: `feature/agent-d/onboarding-disclaimers`

---

## 1. File Structure to Create

```
lib/
├── content/
│   └── legal_content.dart            # Legal document strings
│
├── features/
│   └── onboarding/
│       ├── models/
│       │   └── onboarding_state.dart # State classes
│       │
│       ├── controllers/
│       │   └── onboarding_controller.dart
│       │
│       ├── screens/
│       │   └── onboarding_screen.dart
│       │
│       └── widgets/
│           ├── welcome_page.dart
│           ├── safety_disclaimer_page.dart
│           ├── privacy_page.dart
│           ├── setup_consent_page.dart
│           ├── onboarding_card.dart
│           ├── hero_background.dart
│           ├── radius_selector.dart
│           └── page_indicator.dart
│
├── models/
│   └── consent_record.dart           # GDPR consent model
│
├── screens/
│   ├── about_screen.dart             # P1 About hub
│   └── legal_document_screen.dart    # P1 Legal viewer
│
└── services/
    ├── onboarding_prefs.dart         # Interface
    └── onboarding_prefs_impl.dart    # Implementation

test/
├── unit/
│   ├── models/
│   │   ├── consent_record_test.dart
│   │   └── onboarding_state_test.dart
│   │
│   └── services/
│       └── onboarding_prefs_test.dart
│
├── widget/
│   ├── onboarding/
│   │   ├── onboarding_screen_test.dart
│   │   ├── welcome_page_test.dart
│   │   ├── safety_disclaimer_page_test.dart
│   │   ├── privacy_page_test.dart
│   │   └── setup_consent_page_test.dart
│   │
│   └── legal/
│       ├── about_screen_test.dart
│       └── legal_document_screen_test.dart
│
└── integration/
    └── onboarding_flow_test.dart
```

---

## 2. Implementation Order

### Phase A: Foundation (P0)
1. `consent_record.dart` – Equatable model
2. `onboarding_state.dart` – Sealed state classes
3. `onboarding_prefs.dart` – Service interface
4. `onboarding_prefs_impl.dart` – SharedPreferences implementation
5. Unit tests for models and service

### Phase B: Legal Routes (P1)
1. `legal_content.dart` – Copy content from docs/onboarding_legal_draft.md
2. `legal_document_screen.dart` – Scrollable text with AppBar
3. `about_screen.dart` – Hub linking to legal documents
4. Add routes to `app.dart` (no redirect yet)
5. Widget tests for legal screens

### Phase C: Onboarding UI (P2)
1. `onboarding_card.dart` – Reusable card widget
2. `hero_background.dart` – Gradient (no image)
3. `page_indicator.dart` – 4 dots
4. `radius_selector.dart` – SegmentedButton 0-50km
5. Page widgets (welcome, safety, privacy, setup)
6. `onboarding_screen.dart` – PageView assembler
7. Widget tests for all components

### Phase D: Controller & Integration (P3)
1. `onboarding_controller.dart` – ChangeNotifier
2. Update `main.dart` – Pre-load SharedPreferences
3. Update `app.dart` – Add redirect logic
4. Integration test for full flow

### Phase E: Home Screen Footer (P4)
1. Add disclaimer footer to `home_screen.dart`
2. Widget test for footer

---

## 3. Key Code Snippets

### main.dart Update

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-load SharedPreferences for sync router redirect
  final prefs = await SharedPreferences.getInstance();
  
  runApp(WildFireApp(prefs: prefs));
}
```

### app.dart Router Update

```dart
class WildFireApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const WildFireApp({required this.prefs, super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _createRouter(),
      // ...
    );
  }
  
  GoRouter _createRouter() {
    return GoRouter(
      redirect: (context, state) {
        final version = prefs.getInt('onboarding_version') ?? 0;
        final isComplete = version >= 1;
        final path = state.uri.path;
        
        // Allow legal routes always
        if (path.startsWith('/about')) return null;
        
        // Redirect to onboarding if not complete
        if (!isComplete && path != '/onboarding') {
          return '/onboarding';
        }
        
        // Redirect away from onboarding if complete
        if (isComplete && path == '/onboarding') {
          return '/';
        }
        
        return null;
      },
      routes: [
        // ... existing routes ...
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (_, __) => const AboutScreen(),
          routes: [
            GoRoute(path: 'terms', builder: (_, __) => LegalDocumentScreen(document: LegalContent.termsOfService)),
            GoRoute(path: 'privacy', builder: (_, __) => LegalDocumentScreen(document: LegalContent.privacyPolicy)),
            GoRoute(path: 'data-sources', builder: (_, __) => LegalDocumentScreen(document: LegalContent.dataSources)),
          ],
        ),
      ],
    );
  }
}
```

### OnboardingScreen PageView

```dart
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(), // Swipe disabled
                children: const [
                  WelcomePage(),
                  SafetyDisclaimerPage(),
                  PrivacyPage(),
                  SetupConsentPage(),
                ],
              ),
            ),
            PageIndicator(currentPage: _currentPage, totalPages: 4),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. Constitution Compliance Checklist

| Gate | Requirement | Implementation |
|------|-------------|----------------|
| C1 | No errors | `flutter analyze` passes |
| C2 | No secrets | Legal content as Dart strings |
| C3 | Accessibility ≥44dp | All buttons/checkboxes ≥48dp |
| C4 | Transparency | Data source attribution on Page 1 |
| C5 | Resilience | Graceful fallback if prefs fail |

---

## 5. Test Commands

```bash
# Run all tests
flutter test

# Run onboarding tests only
flutter test test/unit/services/onboarding_prefs_test.dart
flutter test test/widget/onboarding/

# Run integration test
flutter test integration_test/onboarding_flow_test.dart

# Analyze for errors
flutter analyze

# Check accessibility (manual)
# - Enable TalkBack/VoiceOver
# - Navigate through onboarding
# - Verify all elements announced
```

---

## 6. Validation Steps

After implementation:

1. [ ] `flutter analyze` shows 0 errors
2. [ ] All unit tests pass
3. [ ] All widget tests pass
4. [ ] Integration test passes
5. [ ] Fresh install shows onboarding
6. [ ] Completing onboarding navigates to home
7. [ ] Reopening app skips onboarding
8. [ ] Legal routes accessible from onboarding
9. [ ] Back from legal returns to onboarding
10. [ ] Home screen shows disclaimer footer
11. [ ] All touch targets ≥44dp (measured)
12. [ ] VoiceOver/TalkBack navigates successfully

---

## 7. Dependencies

No new dependencies required. Uses existing:

- `shared_preferences` (already in pubspec.yaml)
- `go_router` (already in pubspec.yaml)
- `equatable` (already in pubspec.yaml)

---

## 8. Assets

| Asset | Source | Status |
|-------|--------|--------|
| App logo | `assets/icons/app_icon.png` | ✅ Exists |
| Hero image | N/A (gradient only) | N/A |
| Warning icon | `Icons.warning_amber` | ✅ Built-in |
| GPS icon | `Icons.gps_fixed` | ✅ Built-in |

---

## 9. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Router redirect loops | Comprehensive test coverage |
| Prefs load failure | Graceful fallback to show onboarding |
| Legal content changes | Version constant for migration |
| Accessibility failures | 48dp minimum touch targets |

---

## Ready to Implement

This spec is complete and ready for task generation. The implementation order ensures dependencies are satisfied and testing is possible at each phase.
