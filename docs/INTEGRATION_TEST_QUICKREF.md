# Integration Test Quick Reference

**TL;DR**: 16/24 tests passing. Map tests skipped (manual testing required).

---

## Quick Commands

```bash
# Run all integration tests (11 minutes)
flutter test integration_test/ -d emulator-5554

# Run home tests only (5 minutes) - 7/9 passing
flutter test integration_test/home_integration_test.dart -d emulator-5554

# Run app tests only (4 minutes) - 9/9 passing ✅
flutter test integration_test/app_integration_test.dart -d emulator-5554

# Manual map testing (interactive)
flutter run -d emulator-5554 --dart-define=MAP_LIVE_DATA=false
# Then follow: docs/MAP_MANUAL_TESTING.md
```

---

## Test Status at a Glance

| Suite | Status | Pass/Total |
|-------|--------|------------|
| Home | ⚠️ Partial | 7/9 (78%) |
| Map | ⏭️ Skipped | 0/8 (manual) |
| App | ✅ Pass | 9/9 (100%) |
| **Total** | 🟡 Good | **16/24** |

---

## Known Issues

### ❌ 2 Home Tests Failing (UI visibility)
- Timestamp not found in RiskBanner
- Source chip not visible
- **Fix needed**: Update RiskBanner widget or test selectors

### ⏭️ 8 Map Tests Skipped (framework limitation)
- GoogleMap incompatible with Flutter integration_test
- **Solution**: Manual testing required (see docs/MAP_MANUAL_TESTING.md)

---

## Documentation

| File | Purpose |
|------|---------|
| `INTEGRATION_TEST_FIXES.md` | Session 1: Fixed compilation errors |
| `INTEGRATION_TEST_PUMP_STRATEGY.md` | Session 2: Why pump() failed |
| `MAP_MANUAL_TESTING.md` | Comprehensive manual test guide |
| `INTEGRATION_TEST_SUMMARY.md` | Full session summary |
| `INTEGRATION_TEST_QUICKREF.md` | This file |

---

## Before Release Checklist

```
[ ] All automated tests passing (16/16 non-map)
[ ] Manual map testing complete (8/8 tests)
[ ] QA sign-off obtained
```

---

## Questions?

- **Why are map tests skipped?** → GoogleMap continuously renders frames, breaking test framework assumptions
- **Can we fix map tests?** → No, requires external E2E framework (Patrol, Maestro, Appium)
- **Is manual testing sufficient?** → Yes, map functionality fully testable manually
- **When to run manual tests?** → Before every release, when map code changes

---

**Last Updated**: 2025-10-20  
**Next Review**: When remaining 2 home UI tests are fixed
