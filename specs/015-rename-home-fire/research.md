# Research: Rename Home → Fire Risk Screen and Update Navigation Icon

**Feature**: 015-rename-home-fire  
**Date**: 2025-11-01  
**Status**: Complete

## Research Tasks

### Icon Selection and Accessibility Research
**Task**: Validate Material Icons for warning/hazard display across platforms  
**Decision**: Use Icons.warning_amber as primary, Icons.report_outlined as fallback  
**Rationale**: 
- Icons.warning_amber: Standard Material Design warning triangle with exclamation
- Universally supported across Android/iOS/Web/Desktop
- Built into Flutter SDK (no external dependencies)
- Accessible with proper semantic meaning for hazard communication
- Fallback to Icons.report_outlined if design prefers outlined style
**Alternatives considered**:
- Custom SVG icons (rejected: adds build complexity, maintenance overhead)
- FontAwesome icons (rejected: external dependency increases bundle size)
- Icons.warning (rejected: filled triangle may not provide enough visual distinction)

### Go Router Navigation Research
**Task**: Analyze route alias implementation to avoid breaking existing navigation  
**Decision**: Add '/fire-risk' as new route, keep '/' as primary with FireRiskScreen destination  
**Rationale**:
- go_router supports multiple paths to same screen via route aliases
- Maintains backward compatibility for existing bookmarks and deep links
- '/' remains primary start route, '/fire-risk' added as semantic alias
- No breaking changes to navigation state or URL structure
**Alternatives considered**:
- Replace '/' with '/fire-risk' only (rejected: breaks existing user bookmarks)
- Redirect '/' to '/fire-risk' (rejected: changes URL in browser, confusing UX)
- Keep both '/' and '/home' (rejected: 'home' misleading for fire risk app)

### Accessibility and Semantic Labels Research
**Task**: Define proper screen reader descriptions for fire risk context  
**Decision**: Implement semantic format: "Current wildfire risk is {LEVEL}, updated {RELATIVE_TIME}. Source: {SOURCE}."  
**Rationale**:
- Provides complete context for screen reader users
- Includes risk level, recency, and data source for informed decision-making
- Follows WCAG guidelines for informative content description
- Integrates with existing RiskBanner and timestamp display logic
**Alternatives considered**:
- Simple "Fire Risk" label only (rejected: insufficient context for blind users)
- Technical format with coordinates (rejected: violates C2 gate, contains PII)
- Generic "Wildfire information" (rejected: doesn't specify risk level importance)

### Touch Target and Contrast Research
**Task**: Verify Material Design compliance for warning icon in bottom navigation  
**Decision**: Maintain ≥44dp touch target, validate contrast ratios for Icons.warning_amber  
**Rationale**:
- Icons.warning_amber inherits size from bottom navigation configuration
- Material Design ensures adequate contrast in both light and dark themes
- Existing bottom navigation already meets 44dp minimum touch target requirement
- Warning triangle provides better visual distinction than home icon
**Alternatives considered**:
- Custom sizing for warning icon (rejected: inconsistent with navigation bar design)
- Color customization for icon (rejected: may violate accessibility contrast ratios)

### Migration Strategy Research
**Task**: Plan phased approach to minimize disruption and enable rollback  
**Decision**: Two-phase migration - Phase 1: UI/routes, Phase 2: optional class renaming  
**Rationale**:
- Phase 1 delivers immediate user value with minimal code changes
- Preserves existing class names (HomeScreen, HomeController) to reduce refactoring scope
- Phase 2 can be implemented later as mechanical refactor if desired
- Enables easy rollback by reverting UI strings and route configuration only
**Alternatives considered**:
- Full rename in single PR (rejected: large change surface, harder to review/rollback)
- UI changes only, never rename classes (rejected: creates technical debt and confusion)
- Class renames first, then UI (rejected: wrong priority order, no user value initially)

## Technical Decisions Summary

| Component | Current | Target | Risk Level |
|-----------|---------|--------|------------|
| Bottom Nav Icon | Icons.home | Icons.warning_amber | Low (Material icon) |
| Bottom Nav Label | "Home" | "Fire Risk" | Low (string constant) |
| AppBar Title | "Home" | "Wildfire Risk" | Low (string constant) |
| Primary Route | '/' → HomeScreen | '/' → FireRiskScreen | Medium (routing change) |
| Route Alias | None | '/fire-risk' → FireRiskScreen | Low (additive change) |
| Semantic Labels | "Home tab" | "Current wildfire risk..." | Low (accessibility improvement) |

## Dependencies Validated

**Required (already present)**:
- Flutter SDK 3.35.5+ (Icons.warning_amber support)
- go_router (route alias capability)
- Material Design (icon theming and contrast)

**Testing Dependencies**:
- flutter_test (widget testing for navigation)
- integration_test (route navigation flows)  
- golden test capability (optional UI verification)

## Risk Mitigation Strategies

**Deep Link Compatibility**:
- Test existing bookmarks and saved navigation state
- Verify go_router handles route changes gracefully
- Document any breaking changes in migration notes

**Icon Readability**:
- Validate Icons.warning_amber contrast in light/dark themes
- Test icon visibility at standard and accessibility font sizes
- Provide fallback to Icons.report_outlined if design team prefers

**Rollback Preparation**:
- Document original values for all changed strings/icons
- Test rollback scenario during development
- Ensure rollback can be accomplished with single revert commit

## Constitutional Compliance Validation

**C1 (Code Quality)**: Standard Flutter patterns, lint-clean implementation  
**C2 (Secrets/Logging)**: No new secrets or PII, existing logging unchanged  
**C3 (Accessibility)**: Enhanced semantic labels, maintained touch targets  
**C4 (Trust/Transparency)**: No color changes, existing timestamp/source preservation  
**C5 (Resilience)**: No service changes, existing error handling unchanged

## Performance Impact Assessment

**Negligible Performance Impact**:
- Icon rendering: Icons.warning_amber vs Icons.home (same rendering cost)
- String changes: Static text rendering (no dynamic computation)
- Route resolution: go_router alias lookup (microsecond overhead)
- Memory usage: No new dependencies or significant data structures
- Build size: Material icons already included in Flutter SDK

**No Negative Impact Expected**: Navigation performance, app startup time, or memory consumption should remain unchanged.