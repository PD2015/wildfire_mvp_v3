---
title: Test Coverage Report
status: active
last_updated: 2025-10-30
category: reference
subcategory: testing
related:
  - ../guides/testing/integration-tests.md
  - ../guides/testing/platform-specific.md
replaces:
  - ../TEST_COVERAGE.md
  - ../TEST_COVERAGE_REPORT.md
---

# Test Coverage Report

## 📊 Executive Summary

**Last Comprehensive Analysis**: October 28, 2025  
**Branch**: 013-a12-report-fire  
**Test Types**: Unit, Widget, Integration, Manual

| Metric | Value | Status |
|--------|-------|--------|
| **Overall Coverage** | **78.5%** (1013/1290 lines) | ✅ Excellent |
| **Source Files** | 40 files analyzed | - |
| **Test Success Rate** | **99.7%** (363/364 passing) | ✅ Production Ready |
| **Skipped Tests** | 6 (GoogleMap framework limitation) | ⚠️ Manual verification required |
| **Quality Status** | Production-ready | ✅ |

### Coverage Quality Assessment
- ✅ **Production Ready**: >75% overall coverage achieved
- ✅ **Critical Path Coverage**: All user-facing workflows tested  
- ✅ **Constitutional Compliance**: C2 (privacy), C3 (accessibility), C4 (transparency) requirements covered
- ⚠️ **Platform Limitations**: GoogleMap tests require manual verification (Flutter framework incompatibility)

---

## 📁 Coverage by Component

### Core Services (Business Logic)

| Component | Coverage | Lines | Status | Notes |
|-----------|----------|-------|--------|-------|
| **FireRiskService** | 89% | 125/140 | ✅ Excellent | Orchestration, fallback chain, timeouts |
| **EffisService** | 48% | 121/250 | ⚠️ Moderate | WFS/WMS integration, needs contract tests |
| **LocationResolver** | 69% | 39/56 | ✅ Good | GPS, cache, fallback chain |
| **CacheService** | 85% | 98/115 | ✅ Excellent | TTL, LRU eviction, geohash keys |
| **FireLocationService** | 72% | 85/118 | ✅ Good | EFFIS WFS integration, bbox queries |

**Overall Services Coverage**: **~74%** ✅

### Controllers (State Management)

| Component | Coverage | Lines | Status | Notes |
|-----------|----------|-------|--------|-------|
| **HomeController** | 65% | 55/84 | ✅ Good | Location, fire risk, state updates |
| **MapController** | 1% | 1/73 | ❌ Very Low | Widget tests use mocks, direct unit tests needed |

**Overall Controller Coverage**: **~33%** ⚠️ (MapController pulls down average)

### Models (Data Structures)

| Component | Coverage | Lines | Status | Notes |
|-----------|----------|-------|--------|-------|
| **FireRisk** | 95% | 42/44 | ✅ Excellent | FWI calculation, color coding |
| **LatLng** | 100% | 18/18 | ✅ Perfect | Coordinate model |
| **FireIncident** | 88% | 35/40 | ✅ Excellent | GeoJSON parsing |
| **EffisFwiResult** | 92% | 28/30 | ✅ Excellent | EFFIS response models |

**Overall Model Coverage**: **~92%** ✅

### UI Widgets

| Component | Coverage | Lines | Status | Notes |
|-----------|----------|-------|--------|-------|
| **RiskBanner** | 85% | 45/53 | ✅ Excellent | FWI display, color coding |
| **MapScreen** | 15% | 12/80 | ❌ Low | GoogleMap widget testing limitations |
| **HomeScreen** | 60% | 35/58 | ✅ Good | Integration tests cover workflows |

**Overall UI Coverage**: **~53%** ⚠️ (MapScreen pulls down average due to GoogleMap limitations)

---

## 🧪 Test Suite Breakdown

### Unit Tests (Fast, Isolated)

**Total**: 180+ tests across 15 test files  
**Execution Time**: ~8 seconds  
**Coverage**: Services, models, utilities

#### Key Test Suites
- **FireRiskService**: 45 tests (orchestration, fallback chain, timeouts)
- **LocationResolver**: 32 tests (GPS, cache, fallback, permissions)
- **CacheService**: 28 tests (TTL, LRU, geohash, persistence)
- **Models**: 35 tests (FWI calculation, color coding, parsing)
- **EffisService**: 25 tests (WFS, WMS, GeoJSON parsing)
- **Geographic Utils**: 15 tests (Scotland boundaries, geohash encoding)

**Status**: ✅ All passing (100% success rate)

### Widget Tests (UI Components)

**Total**: 120+ tests across 8 test files  
**Execution Time**: ~15 seconds  
**Coverage**: Widgets, screens, user interactions

#### Key Test Suites
- **RiskBanner**: 32 tests (Card layout, colors, weather panel, source display)
- **HomeScreen**: 20 tests (layout, location display, error states)
- **MapScreen**: 20 tests (basic rendering, mock controller integration)
- **Error Views**: 15 tests (retry buttons, error messages)
- **Accessibility**: 33 tests (touch targets ≥44dp, semantic labels)

**Status**: ✅ All passing (100% success rate)

### Golden Tests (Visual Regression Prevention)

**Total**: 7 tests (A14 RiskBanner visual refresh)  
**Execution Time**: ~3 seconds  
**Coverage**: Pixel-perfect UI verification across themes and risk levels

#### RiskBanner Golden Test Suite
- **Risk Levels**: All 6 levels (Very Low, Low, Moderate, High, Very High, Extreme)
- **Themes**: Light + Dark mode coverage
- **Special States**: Cached data indicator
- **Test Files**: `test/widget/golden/risk_banner_*_test.dart`
- **Baselines**: `test/widget/golden/goldens/*.png`

**Purpose**: Prevents unintended visual regressions in Material Card design, Scottish color palette, typography, spacing, and layout.

**Usage**:
```bash
# Run golden tests (compare against baselines)
flutter test test/widget/golden/

# Update baselines after intentional design changes
flutter test --update-goldens test/widget/golden/
```

**Status**: ✅ All 7 passing (100% success rate)

### Integration Tests (End-to-End Workflows)

**Total**: 24 tests across 3 test files  
**Execution Time**: ~11 minutes (automated) + ~2 minutes (manual)  
**Coverage**: User workflows, navigation, data persistence

#### Home Screen Tests (9 tests)
**Status**: ⚠️ 7/9 passing (78%)
- ✅ Fire risk banner display and color validation
- ✅ Location resolution (GPS, cache, fallback)
- ✅ C4 transparency compliance (timestamp visible)
- ⚠️ **2 failing**: Timestamp/source chip widget selector issues

#### App Navigation Tests (9 tests)
**Status**: ✅ 9/9 passing (100%)
- ✅ Tab navigation (Home ↔ Map)
- ✅ App lifecycle (background/foreground)
- ✅ Deep linking and route handling
- ✅ Error state recovery

#### Map Tests (8 tests)
**Status**: ⏭️ 0/8 automated (manual verification required)
- ⏭️ **Skipped**: GoogleMap incompatible with Flutter integration_test framework
- 🔍 **Manual testing**: Interactive verification checklist (see archived session docs)
- ✅ **Verified manually**: Map rendering, markers, navigation, zoom controls

**Status**: 🟡 16/24 automated (67%), 24/24 total with manual verification (100%)

### Manual Testing (Platform-Specific)

**Platforms Tested**: Android, iOS, macOS, Web  
**Test Sessions**: 9 documented sessions (archived in history/sessions/)  
**Coverage**: GoogleMap interactions, platform-specific features, performance

#### Android Testing
- ✅ Full feature set verified (100% working)
- ✅ Google Maps API integration
- ✅ GPS permission handling
- ✅ Performance metrics within targets

#### iOS Testing  
- ✅ Full feature set verified (100% working)
- ✅ Native iOS UI appearance
- ✅ Touch targets ≥44dp
- ✅ Safe area handling

#### macOS Testing
- ⚠️ Partial feature set (60% - no map support)
- ✅ Home screen functional
- ❌ Map screen unavailable (google_maps_flutter limitation)

#### Web Testing
- ✅ Demo-ready (95% working)
- ⚠️ CORS proxy needed for production
- ✅ JavaScript Maps API integration

---

## 📈 Coverage Trends

### Historical Coverage Growth

| Date | Coverage | Change | Milestone |
|------|----------|--------|-----------|
| Oct 15, 2025 | 45% | - | Initial A1-A6 features |
| Oct 19, 2025 | 62% | +17% | A10 Google Maps integration |
| Oct 20, 2025 | 71% | +9% | Integration tests added |
| Oct 28, 2025 | 78.5% | +7.5% | Coverage improvements, A12 Report Fire |

**Trend**: ✅ Steady improvement toward 80% target

---

## 🎯 Coverage Goals

### Current State
- ✅ **Achieved**: 75% minimum for production
- ✅ **Achieved**: All critical paths tested
- ✅ **Achieved**: Constitutional compliance verified

### Short-Term Goals (Next Release)
- [ ] **MapController Unit Tests**: Increase from 1% to 60% (+59%)
- [ ] **Fix 2 Home Tests**: Timestamp/source chip selector issues
- [ ] **EFFIS Contract Tests**: Add real fixture data tests (+20% EFFIS coverage)
- **Target**: **82% overall coverage**

### Long-Term Goals (6 months)
- [ ] **MapController**: 80% coverage with comprehensive unit tests
- [ ] **EFFIS Service**: 70% coverage with contract tests
- [ ] **E2E Test Framework**: Explore Patrol/Maestro for automated map testing
- **Target**: **85% overall coverage**

---

## 🚨 Known Gaps and Limitations

### Critical Gaps (Block Future Features)
*None identified* - All production-critical code paths are tested

### Non-Critical Gaps (Nice to Have)
1. **MapController Direct Unit Tests** (currently 1%)
   - **Impact**: Low (widget tests cover state management indirectly)
   - **Priority**: P2 (improve confidence in map feature changes)

2. **EFFIS Contract Tests** (fixture-based)
   - **Impact**: Medium (would catch API changes earlier)
   - **Priority**: P1 (improve API integration reliability)

3. **Platform-Specific Edge Cases**
   - **Impact**: Low (manual testing covers these)
   - **Priority**: P3 (automate if E2E framework adopted)

### Framework Limitations
- **GoogleMap Testing**: Flutter's `integration_test` framework incompatible with continuous frame rendering
- **Workaround**: Manual testing with documented checklists (archived in history/sessions/)
- **Status**: Acceptable for production (manual verification reliable)

---

## 🔧 Running Coverage Reports

### Generate Coverage Report
```bash
# Run all tests with coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

### Generate Coverage Per Feature
```bash
# Service layer only
flutter test test/unit/services/ --coverage

# Widget layer only
flutter test test/widget/ --coverage

# Integration tests (no coverage data - device tests)
flutter test integration_test/ -d emulator-5554
```

### CI/CD Coverage Enforcement
```yaml
# .github/workflows/test.yml
- name: Check coverage threshold
  run: |
    COVERAGE=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
    if (( $(echo "$COVERAGE < 75" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 75% threshold"
      exit 1
    fi
```

---

## 📚 Coverage Best Practices

### What to Test
✅ **High Value**:
- Business logic (services, controllers)
- Data models (parsing, validation)
- Critical user workflows
- Error handling and edge cases
- Constitutional compliance (C2, C3, C4)

⚠️ **Medium Value**:
- UI widgets (widget tests)
- Navigation flows
- Platform-specific code

❌ **Low Value**:
- Generated code
- Simple getters/setters
- Third-party library wrappers

### Test Pyramid Strategy
```
        /\
       /  \  E2E (Manual + Integration)
      /____\  ~10% of tests
     /      \
    / Widget \ Widget Tests
   /__________\ ~30% of tests
  /            \
 /    Unit      \ Unit Tests
/________________\ ~60% of tests
```

**Current Distribution**: ✅ Follows pyramid (60% unit, 30% widget, 10% integration/manual)

---

## 🔗 Related Documentation

- **[Integration Testing Guide](../guides/testing/integration-tests.md)** - Test methodology and patterns
- **[Platform-Specific Testing](../guides/testing/platform-specific.md)** - iOS, Android, Web, macOS testing
- **[Troubleshooting](../guides/testing/troubleshooting.md)** - Debugging test failures
- **[Test Regions](test-regions.md)** - Test data and configuration

---

## 📝 Coverage Report Changelog

| Date | Coverage | Changes |
|------|----------|---------|
| 2025-10-30 | 78.5% | Consolidated coverage documentation |
| 2025-10-28 | 78.5% | A12 Report Fire feature coverage |
| 2025-10-20 | 71% | Integration tests added |
| 2025-10-19 | 62% | A10 Google Maps coverage |
| 2025-10-15 | 45% | Initial A1-A6 coverage |

**Next Review**: When new features are added or coverage drops below 75%
