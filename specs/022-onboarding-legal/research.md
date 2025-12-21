# Research: 022 – Onboarding & Legal Integration

**Generated**: 2025-12-10  
**Status**: Complete

---

## 1. Technical Context Resolution

### Language/Framework
- **Decision**: Dart 3.9.2 / Flutter 3.35.5 stable
- **Rationale**: Matches existing project setup
- **Alternatives**: N/A (existing project)

### Dependencies Required
- **Decision**: No new dependencies needed
- **Rationale**: 
  - `shared_preferences` - already in project for settings persistence
  - `go_router` - already configured for navigation
  - `geolocator` / `permission_handler` - already used by LocationResolver
- **Alternatives**: None needed

### Storage Approach
- **Decision**: SharedPreferences for consent tracking
- **Rationale**: 
  - Lightweight key-value storage sufficient for 4 preference keys
  - Already used throughout app (location cache, fire incident cache)
  - GDPR requires local persistence only (no server-side tracking)
- **Alternatives Rejected**:
  - SQLite: Overkill for 4 simple keys
  - Secure storage: Not needed for non-sensitive preference data

---

## 2. Existing Code Patterns

### Router Configuration (lib/app.dart)
```dart
// Current pattern: GoRouter with ShellRoute for bottom nav
late final GoRouter _router = GoRouter(
  routes: [
    // Full-screen routes (no bottom nav)
    GoRoute(path: '/location-picker', ...),
    
    // ShellRoute with bottom nav
    ShellRoute(
      builder: (context, state, child) => Scaffold(
        body: child,
        bottomNavigationBar: AppBottomNav(...),
      ),
      routes: [
        GoRoute(path: '/', name: 'fire-risk', ...),
        GoRoute(path: '/map', name: 'map', ...),
        GoRoute(path: '/report', name: 'report', ...),
      ],
    ),
  ],
);
```

**Implication**: 
- `/onboarding` should be a full-screen route (outside ShellRoute)
- `/about/*` legal routes should also be full-screen (no bottom nav during onboarding)

### SharedPreferences Pattern (lib/main.dart)
```dart
// Current pattern: Pre-load in main, pass to services
final prefs = await SharedPreferences.getInstance();
final FireIncidentCache fireIncidentCache = FireIncidentCacheImpl(prefs: prefs);
```

**Implication**: Can pass prefs to WildFireApp for onboarding check

### Location Permission (lib/services/location_resolver_impl.dart)
```dart
// Current pattern: Full permission flow in _tryGps()
if (permission == LocationPermission.denied) {
  permission = await _geolocatorService.requestPermission();
}
```

**Implication**: Call `locationResolver.getLatLon()` to trigger permission dialog

---

## 3. Asset Investigation

### Existing Assets
```
assets/icons/
├── app_icon.png          # Main app icon (use for onboarding logo)
├── app_icon_ios.png      # iOS variant
├── app_icon_v1.png       # Legacy version
├── splash_icon.png       # Splash screen icon
└── splash_icon_v2_bg.png # Splash with background
```

### New Assets Required
| Asset | Purpose | Spec |
|-------|---------|------|
| `onboarding_hero.png` | Page 1 hero image | Scottish landscape, 1080x600px, forest/hills theme |
| `onboarding_hero_dark.png` | Dark mode variant | Same scene, darker tones |

**Alternative**: Use gradient background with app icon instead of hero image (simpler, no asset dependency)

---

## 4. Legal Content Location

### Current State
- Legal document content exists in `docs/onboarding_legal_draft.md`
- Terms of Service (~150 lines)
- Privacy Policy (~120 lines)
- Emergency Disclaimer (~50 lines)
- Data Sources (~80 lines)

### Implementation Decision
- **Decision**: Embed content as Dart string constants in `lib/content/legal_content.dart`
- **Rationale**: 
  - Offline access guaranteed
  - No network dependency for legal viewing
  - Easy to version (increment constant when content changes)
  - Follows existing pattern (`lib/content/scotland_risk_guidance.dart`)
- **Alternatives Rejected**:
  - External URL: Requires network, breaks offline
  - Markdown assets: Requires markdown renderer dependency

---

## 5. UI Component Patterns

### Existing Card Pattern (RiskGuidanceCard)
```dart
Card(
  margin: EdgeInsets.zero,
  color: cardBackground,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: cardBorderColor, width: 2),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(...),
  ),
)
```

### Existing Button Patterns
- Primary: `FilledButton` or `FilledButton.tonal`
- Secondary: `TextButton`
- Touch targets: ≥44dp (constitutional requirement C3)

### Segmented Button Pattern (Material 3)
```dart
SegmentedButton<int>(
  segments: [
    ButtonSegment(value: 0, label: Text('Off')),
    ButtonSegment(value: 5, label: Text('5 km')),
    // ...
  ],
  selected: {selectedValue},
  onSelectionChanged: (Set<int> newSelection) {
    setState(() => selectedValue = newSelection.first);
  },
)
```

---

## 6. Testing Patterns

### Widget Test Pattern (existing)
```dart
testWidgets('description', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: WidgetUnderTest()),
  ));
  
  expect(find.text('Expected'), findsOneWidget);
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
});
```

### Integration Test Pattern (existing)
```dart
// integration_test/app_integration_test.dart
testWidgets('full flow', (tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const WildFireApp(...));
  await tester.pumpAndSettle();
  // assertions
});
```

---

## 7. Constitution Compliance Checklist

| Gate | Requirement | How Addressed |
|------|-------------|---------------|
| C1 | flutter analyze, tests | All new code will pass analyze; widget tests for each component |
| C2 | No secrets, safe logging | No secrets needed; use `LocationUtils.logRedact()` for any coordinate logs |
| C3 | ≥44dp touch targets, semantic labels | All buttons ≥44dp; `Semantics` widgets on interactive elements |
| C4 | Official colors, timestamps | Use `BrandPalette`/`RiskPalette`; consent timestamp displayed in legal info |
| C5 | Error handling, fallbacks | Location permission gracefully falls back; prefs errors handled |

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Hero image delays implementation | Medium | Low | Use gradient background fallback |
| Legal content too long for screens | Low | Medium | Add ScrollView to legal screens |
| Permission dialog timing issues | Low | Medium | Test on real devices, not just simulator |
| Router redirect race condition | Low | High | Pre-load prefs before router init |

---

## Summary

All technical unknowns resolved. Ready for Phase 1 design.

**Key Decisions**:
1. No new dependencies required
2. Legal content as embedded Dart constants
3. Gradient background fallback for hero image
4. Pre-load prefs pattern for router redirect
5. Use existing LocationResolver for permission flow
