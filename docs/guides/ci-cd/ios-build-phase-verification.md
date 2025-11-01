---
title: iOS Xcode Build Phase CI/CD Verification
status: active
last_updated: 2025-11-01
category: guides
subcategory: ci-cd
related:
  - ../../IOS_GOOGLE_MAPS_INTEGRATION.md
  - ../setup/google-maps.md
  - ../../CI_CD_WORKFLOW_GUIDE.md
---

# iOS Xcode Build Phase CI/CD Verification

## Overview

This guide documents the automated CI/CD verification job that ensures the iOS Xcode build phase (for Google Maps API key injection) works correctly in automation environments.

**Job Name**: `verify-ios-build-phase`  
**Trigger**: On all pushes and pull requests (runs after `build` job)  
**Runner**: `macos-latest` (required for Xcode tools)  
**Timeout**: 20 minutes

## Purpose

The CI/CD job verifies that:
1. iOS prebuild scripts exist and are executable
2. Info.plist contains placeholder (no hardcoded secrets)
3. Flutter generates correct DART_DEFINES in Generated.xcconfig
4. Prebuild script successfully extracts and injects API key
5. Full iOS build configuration works with the build phase
6. AppDelegate correctly reads API key from Info.plist

## Architecture

```
CI Environment
  ↓
Create env/ci.env.json (with CI secrets)
  ↓
flutter build ios --config-only --dart-define-from-file
  ↓
Generates ios/Flutter/Generated.xcconfig (DART_DEFINES)
  ↓
Run ios_prebuild.sh manually (SRCROOT set)
  ↓
Extract API key from DART_DEFINES (base64 decode)
  ↓
Inject into ios/Runner/Info.plist (PlistBuddy)
  ↓
Verify injection successful
  ↓
Restore Info.plist backup (no dirty state)
```

## Verification Steps

### 1. Script Existence Check
```bash
# Verifies prebuild scripts exist
- ios/ios_prebuild.sh
- ios/xcode_build_phase_script.sh

# Ensures executable permissions
chmod +x ios/*.sh
```

### 2. Placeholder Validation
```bash
# Check Info.plist has placeholder (no hardcoded key)
grep "\${GOOGLE_MAPS_API_KEY_IOS}" ios/Runner/Info.plist
```
✅ **Expected**: Placeholder found (security compliance)  
❌ **Failure**: Hardcoded API key detected (security risk)

### 3. Generated.xcconfig Creation
```bash
# Generate Flutter build config
flutter build ios --config-only --dart-define-from-file=env/ci.env.json

# Verify DART_DEFINES present
grep "DART_DEFINES=" ios/Flutter/Generated.xcconfig
```
✅ **Expected**: DART_DEFINES line with base64-encoded values  
❌ **Failure**: Missing Generated.xcconfig or DART_DEFINES

### 4. Manual Script Test
```bash
# Set required environment variables
export SRCROOT="$(pwd)/ios"

# Backup Info.plist
cp ios/Runner/Info.plist ios/Runner/Info.plist.backup

# Run prebuild script
cd ios && ./ios_prebuild.sh
```
✅ **Expected**: Script exits 0, logs show "API key injected"  
❌ **Failure**: Script error, missing dependencies, or parse failure

### 5. Injection Verification
```bash
# Check API key was injected (no longer placeholder)
/usr/libexec/PlistBuddy -c "Print :GMSApiKey" ios/Runner/Info.plist

# Verify format (should start with AIzaSy)
```
✅ **Expected**: Real API key present (starts with `AIzaSy`)  
❌ **Failure**: Still placeholder, or malformed key

### 6. Full Build Test
```bash
# Test complete iOS build configuration
flutter build ios \
  --dart-define-from-file=env/ci.env.json \
  --no-codesign \
  --debug \
  --config-only
```
✅ **Expected**: Build succeeds without errors  
❌ **Failure**: Build errors, missing dependencies, or config issues

### 7. AppDelegate Pattern Check
```bash
# Verify AppDelegate reads from Info.plist correctly
grep "Bundle.main.object(forInfoDictionaryKey: \"GMSApiKey\")" ios/Runner/AppDelegate.swift
```
✅ **Expected**: Correct Info.plist reading pattern found  
❌ **Failure**: Hardcoded key or incorrect reading pattern

## GitHub Secrets Required

The job uses optional secrets (fallback to test key if not set):

| Secret Name | Purpose | Required? |
|-------------|---------|-----------|
| `GOOGLE_MAPS_API_KEY_IOS_CI` | iOS API key for CI builds | Optional* |

*If not set, uses default test key: `AIzaSyDEFAULT_CI_KEY_FOR_BUILD_TEST_ONLY`

**To add secret**:
1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GOOGLE_MAPS_API_KEY_IOS_CI`
4. Value: Your iOS-restricted Google Maps API key
5. Save

## Local Testing

Test the verification steps locally before pushing:

```bash
# 1. Create test environment file
cat > env/ci.env.json << EOF
{
  "GOOGLE_MAPS_API_KEY_IOS": "YOUR_IOS_API_KEY",
  "GOOGLE_MAPS_API_KEY_ANDROID": "YOUR_ANDROID_KEY",
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_WEB_KEY",
  "MAP_LIVE_DATA": "false",
  "EFFIS_BASE_URL": "https://ies-ows.jrc.ec.europa.eu/"
}
EOF

# 2. Generate Flutter config
flutter build ios --config-only --dart-define-from-file=env/ci.env.json --no-codesign

# 3. Verify Generated.xcconfig
grep "DART_DEFINES=" ios/Flutter/Generated.xcconfig

# 4. Test prebuild script
export SRCROOT="$(pwd)/ios"
cp ios/Runner/Info.plist ios/Runner/Info.plist.backup
cd ios && ./ios_prebuild.sh

# 5. Verify injection
/usr/libexec/PlistBuddy -c "Print :GMSApiKey" ios/Runner/Info.plist

# 6. Restore backup
mv ios/Runner/Info.plist.backup ios/Runner/Info.plist

# Cleanup
rm env/ci.env.json
```

## Troubleshooting

### Issue: "Generated.xcconfig not found"
**Cause**: Flutter build not run or failed  
**Solution**: 
```bash
flutter clean
flutter pub get
flutter build ios --config-only --dart-define-from-file=env/ci.env.json
```

### Issue: "DART_DEFINES not found in Generated.xcconfig"
**Cause**: Missing `--dart-define-from-file` flag  
**Solution**: Always use `--dart-define-from-file=env/ci.env.json` with build command

### Issue: "GOOGLE_MAPS_API_KEY_IOS not found in DART_DEFINES"
**Cause**: Key missing from env file or incorrect name  
**Solution**: 
- Check `env/ci.env.json` has exact key name: `GOOGLE_MAPS_API_KEY_IOS`
- Verify JSON syntax is valid (no trailing commas)

### Issue: "PlistBuddy failed to update GMSApiKey"
**Cause**: Info.plist doesn't have GMSApiKey entry  
**Solution**:
```bash
# Add GMSApiKey entry to Info.plist
/usr/libexec/PlistBuddy -c "Add :GMSApiKey string \${GOOGLE_MAPS_API_KEY_IOS}" ios/Runner/Info.plist
```

### Issue: "Permission denied: ios_prebuild.sh"
**Cause**: Script not executable  
**Solution**:
```bash
chmod +x ios/ios_prebuild.sh
chmod +x ios/xcode_build_phase_script.sh
git add ios/*.sh
git commit -m "chore: make prebuild scripts executable"
```

### Issue: CI job fails but local test works
**Cause**: Environment differences between local and CI  
**Solution**:
- Check `macos-latest` runner version matches your local macOS
- Verify all dependencies available in CI (Flutter, Xcode tools)
- Check GitHub Secrets are set correctly

## Success Criteria

The job passes when all steps complete successfully:

```
✅ Prebuild scripts exist and are executable
✅ Info.plist has placeholder (no hardcoded secrets)
✅ Generated.xcconfig contains DART_DEFINES
✅ Prebuild script successfully extracts and injects API key
✅ API key injection verified in Info.plist
✅ Full iOS build configuration successful
✅ AppDelegate reads API key correctly

🎉 All iOS Xcode build phase checks passed!
```

## Integration with PR Workflow

The job runs automatically on:
- All pull requests to `main`, `develop`, or `staging`
- All pushes to feature branches (`feature/*`, `**-a*-**`)

**PR Checklist**:
- [ ] `build` job passes (tests, analyze, format)
- [ ] `verify-ios-build-phase` job passes ← **New check**
- [ ] `constitutional-compliance` passes
- [ ] Code review approved

## Related Documentation

- **[iOS Google Maps Integration](../../IOS_GOOGLE_MAPS_INTEGRATION.md)** - Setup guide
- **[CI/CD Workflow Guide](../../CI_CD_WORKFLOW_GUIDE.md)** - Complete CI/CD overview
- **[API Key Management](../security/api-key-management.md)** - Security best practices

## Maintenance

**Update frequency**: Review quarterly or when:
- iOS build process changes
- Google Maps SDK updated
- New API key management requirements
- CI runner environment updated

**Last verified**: 2025-11-01  
**Next review**: 2026-02-01
