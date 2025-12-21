# Feature Plan: 023 — Settings & Help/Info Hubs

**Branch:** `feature/agent-d/settings-help-hubs`  
**Created:** 21 December 2025  
**Status:** Planning

---

## Overview

Add two secondary navigation hubs accessible via AppBar icons on all primary screens:
- ⚙️ **Settings** — User preferences and configuration
- ℹ️ **Help & Info** — Guidance, education, and support content

These complement (not replace) the existing bottom navigation for primary tasks.

---

## Decisions Made

| Question | Decision |
|----------|----------|
| AppBar action placement | Two icon buttons (⚙️ ℹ️) - most discoverable for infrequent users |
| About section handling | Keep `/about`, move legal to Settings hub, move app info to Help hub |
| Notifications UI | Show as disabled/greyed with "Coming soon" label |
| Location mode setting | Not implementing - use existing LocationResolver behavior |
| Help content format | Reuse `LegalDocumentScreen` pattern with new content files |

---

## Information Architecture

### Primary Navigation (unchanged)
```
Bottom Nav:
├── Fire Risk (/)
├── Map (/map)
└── Report Fire (/report)
```

### Secondary Navigation (new)
```
AppBar Icons → Settings (/settings) | Help & Info (/help)
```

---

## Route Structure

### Settings Hub (`/settings`)
```
/settings                    → SettingsScreen (hub)
├── /settings/notifications  → NotificationsSettingsScreen
├── /settings/about          → AboutSettingsScreen (legal links)
│   ├── /settings/about/terms
│   ├── /settings/about/privacy
│   ├── /settings/about/disclaimer
│   └── /settings/about/data-sources
└── /settings/advanced       → AdvancedSettingsScreen (dev options, gated)
```

### Help & Info Hub (`/help`)
```
/help                        → HelpInfoScreen (hub)
├── /help/getting-started
│   ├── /help/getting-started/how-to-use
│   ├── /help/getting-started/risk-levels
│   └── /help/getting-started/when-to-use
├── /help/wildfire-education
│   ├── /help/wildfire-education/understanding-risk
│   ├── /help/wildfire-education/weather-fuel-fire
│   └── /help/wildfire-education/seasonal-guidance
├── /help/using-the-map
│   ├── /help/using-the-map/hotspots
│   ├── /help/using-the-map/data-sources
│   └── /help/using-the-map/update-frequency
├── /help/safety
│   ├── /help/safety/see-fire
│   ├── /help/safety/limitations
│   └── /help/safety/emergency-guidance
└── /help/about              → AboutHelpScreen (app info, data sources)
```

---

## Implementation Tasks

### Phase 1: Foundation (Routes & Shells) ✅
- [x] **T1.1** Create shared `AppBarActions` widget for Settings/Help icons
- [x] **T1.2** Add AppBar actions to `HomeScreen`
- [x] **T1.3** Add AppBar actions to `MapScreen`
- [x] **T1.4** Add AppBar actions to `ReportFireScreen`
- [x] **T1.5** Create `SettingsScreen` hub (scaffold with sections)
- [x] **T1.6** Create `HelpInfoScreen` hub (scaffold with sections)
- [x] **T1.7** Add `/settings` and `/help` routes to `app.dart`

### Phase 2: Settings Hub Implementation
- [ ] **T2.1** Create `SettingsPrefs` service for persistence
- [ ] **T2.2** Create `NotificationsSettingsScreen` with disabled toggles + "Coming soon"
- [ ] **T2.3** Create `AboutSettingsScreen` (legal docs section)
- [ ] **T2.4** Add nested legal routes under `/settings/about/*`
- [ ] **T2.5** Create `AdvancedSettingsScreen` with dev options
- [ ] **T2.6** Implement dev options gating (kDebugMode + tap-to-unlock in prod)

### Phase 3: Help & Info Hub Implementation
- [ ] **T3.1** Create `HelpContent` class (like `LegalContent`) with help documents
- [ ] **T3.2** Create help content: Getting Started section
- [ ] **T3.3** Create help content: Wildfire Education section (stub content)
- [ ] **T3.4** Create help content: Using the Map section (stub content)
- [ ] **T3.5** Create help content: Safety & Responsibility section
- [ ] **T3.6** Create `AboutHelpScreen` (app info + version + data sources link)
- [ ] **T3.7** Add all Help routes to `app.dart`

### Phase 4: Cleanup & Polish
- [ ] **T4.1** Update onboarding legal links to new `/settings/about/*` paths
- [ ] **T4.2** Redirect or remove old `/about` route
- [ ] **T4.3** Verify back navigation returns to correct primary screen
- [ ] **T4.4** Accessibility audit (touch targets, semantics, screen reader)
- [ ] **T4.5** Test all deep links work correctly

---

## File Structure (New Files)

```
lib/
├── features/
│   ├── settings/
│   │   ├── screens/
│   │   │   ├── settings_screen.dart           # Hub landing page
│   │   │   ├── notifications_settings_screen.dart
│   │   │   ├── about_settings_screen.dart     # Legal links
│   │   │   └── advanced_settings_screen.dart  # Dev options
│   │   ├── services/
│   │   │   └── settings_prefs.dart            # SharedPreferences wrapper
│   │   └── widgets/
│   │       └── settings_section.dart          # Reusable section header
│   │
│   └── help/
│       ├── screens/
│       │   ├── help_info_screen.dart          # Hub landing page
│       │   └── about_help_screen.dart         # App info section
│       └── content/
│           └── help_content.dart              # All help text (markdown strings)
│
├── widgets/
│   └── app_bar_actions.dart                   # Shared Settings/Help icons
```

---

## Settings Persistence Schema

```dart
/// SharedPreferences keys for settings
class SettingsPrefs {
  // Notifications (UI only for now - actual implementation later)
  static const String keyAlertsEnabled = 'settings_alerts_enabled';      // bool
  static const String keyAlertDistanceKm = 'settings_alert_distance_km'; // double
  
  // Advanced / Developer
  static const String keyDevOptionsUnlocked = 'settings_dev_unlocked';   // bool
}
```

---

## UI Specifications

### AppBar Actions (all primary screens)
```
┌─────────────────────────────────────────┐
│ ← Wildfire Risk              ⚙️  ℹ️    │
├─────────────────────────────────────────┤
│            [Screen Content]             │
└─────────────────────────────────────────┘

Icons:
- Settings: Icons.settings_outlined (filled when on /settings/*)
- Help: Icons.help_outline (filled when on /help/*)
- Touch target: 48dp minimum
- Semantic labels: "Settings" / "Help and information"
```

### Settings Hub Layout
```
┌─────────────────────────────────────────┐
│ ← Settings                              │
├─────────────────────────────────────────┤
│                                         │
│ NOTIFICATIONS                           │
│ ┌─────────────────────────────────────┐ │
│ │ 🔔 Alert Settings              >    │ │
│ │    Coming soon                      │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ABOUT                                   │
│ ┌─────────────────────────────────────┐ │
│ │ 📄 Terms of Service            >    │ │
│ │ 🔒 Privacy Policy              >    │ │
│ │ ⚠️ Emergency Disclaimer        >    │ │
│ │ 📊 Data Sources                >    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [ADVANCED - visible only when unlocked] │
│ ┌─────────────────────────────────────┐ │
│ │ 🔧 Developer Options           >    │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### Help & Info Hub Layout
```
┌─────────────────────────────────────────┐
│ ← Help & Info                           │
├─────────────────────────────────────────┤
│                                         │
│ GETTING STARTED                         │
│ ┌─────────────────────────────────────┐ │
│ │ 📖 How to use WildFire         >    │ │
│ │ 🎯 What the risk levels mean   >    │ │
│ │ ⏰ When to use this app        >    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ WILDFIRE EDUCATION                      │
│ ┌─────────────────────────────────────┐ │
│ │ 🔥 Understanding wildfire risk >    │ │
│ │ 🌡️ Weather, fuel, and fire    >    │ │
│ │ 📅 Seasonal guidance           >    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ USING THE MAP                           │
│ ┌─────────────────────────────────────┐ │
│ │ 📍 What hotspots show          >    │ │
│ │ 📊 Data sources explained      >    │ │
│ │ ⏱️ Update frequency & limits   >    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ SAFETY & RESPONSIBILITY                 │
│ ┌─────────────────────────────────────┐ │
│ │ 🚨 What to do if you see fire  >    │ │
│ │ ⚠️ Important limitations       >    │ │
│ │ 📞 Emergency guidance          >    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ABOUT                                   │
│ ┌─────────────────────────────────────┐ │
│ │ ℹ️ About WildFire              >    │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## Developer Options Gating

### Unlock Mechanism
1. **Debug builds (`kDebugMode`):** Advanced section always visible
2. **Release builds:** Hidden by default
3. **Unlock gesture:** Tap "Version 1.0.0" in Help > About WildFire 7 times
4. **Persistence:** Once unlocked, stays unlocked via SharedPreferences
5. **Feedback:** Show snackbar "Developer options unlocked" on successful unlock

### Dev Options Content (migrated from existing AboutScreen)
- Reset Onboarding
- Clear Location Cache
- [Future: Feature flag toggles]

---

## Accessibility Requirements

| Requirement | Implementation |
|-------------|----------------|
| Touch targets | All buttons/tiles ≥ 48dp |
| Semantic labels | Icons have `semanticLabel` property set |
| Section headers | Use `Semantics(header: true)` for screen readers |
| Disabled states | "Coming soon" announced for notifications toggles |
| Feedback | Settings changes show snackbar confirmation |
| Non-emergency | Help content avoids implying emergency capability |

---

## Dependencies

| Dependency | Purpose | Status |
|------------|---------|--------|
| `go_router` | Routing | ✅ Already in use |
| `shared_preferences` | Settings persistence | ✅ Already in use |
| `flutter_markdown` | Help content rendering | ✅ Already added |

No new dependencies required.

---

## Testing Plan

### Unit Tests
- [ ] `SettingsPrefs` read/write operations
- [ ] Dev options unlock state persistence
- [ ] Default values when no prefs exist

### Widget Tests  
- [ ] `SettingsScreen` renders all sections correctly
- [ ] `HelpInfoScreen` renders all sections correctly
- [ ] `AppBarActions` navigates to correct routes
- [ ] Disabled notification toggles show "Coming soon" text
- [ ] Dev options hidden when not unlocked (release mode simulation)

### Integration Tests
- [ ] Full navigation: Home → Settings → Notifications → back → back → Home
- [ ] Full navigation: Map → Help → Getting Started → How to Use → back to Map
- [ ] Deep link `/settings/about/privacy` loads correct screen
- [ ] Deep link `/help/safety/see-fire` loads correct screen
- [ ] Dev options unlock gesture works (7 taps on version)

---

## Migration Notes

### Routes to Update
| Old Route | New Route | Action |
|-----------|-----------|--------|
| `/about` | `/help/about` | Redirect or keep as alias |
| `/about/terms` | `/settings/about/terms` | Update onboarding links |
| `/about/privacy` | `/settings/about/privacy` | Update onboarding links |
| `/about/disclaimer` | `/settings/about/disclaimer` | Update onboarding links |
| `/about/data-sources` | `/settings/about/data-sources` | Update help links |

### Files to Modify
- `lib/app.dart` — Add new routes, update redirects
- `lib/screens/home_screen.dart` — Add AppBar actions
- `lib/features/map/screens/map_screen.dart` — Add AppBar actions
- `lib/features/report/screens/report_fire_screen.dart` — Add AppBar actions
- `lib/features/onboarding/pages/*.dart` — Update legal links
- `lib/screens/about_screen.dart` — May deprecate or redirect

---

## Out of Scope

- ❌ Actual push notifications implementation (only settings UI)
- ❌ Backend CMS for help content
- ❌ Authentication or user accounts
- ❌ Redesign of bottom navigation
- ❌ Location mode setting in Settings (use existing behavior)

---

## Progress Log

| Date | Task | Status | Notes |
|------|------|--------|-------|
| 21 Dec 2025 | Branch created | ✅ | `feature/agent-d/settings-help-hubs` |
| 21 Dec 2025 | Planning document | ✅ | This file |
| 21 Dec 2025 | Phase 1 complete | ✅ | T1.1-T1.7 — Routes, hubs, AppBarActions |
| | | | |

---

## Ready to Start?

Begin with **Phase 1: Foundation** — creating the shared AppBar widget and hub screens, then adding routes. This establishes the navigation structure before filling in content.

**First task:** T1.1 - Create `AppBarActions` widget
