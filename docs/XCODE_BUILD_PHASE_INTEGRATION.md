# Xcode Build Phase Integration Instructions

## Overview

This document provides step-by-step instructions for integrating our iOS API key injection into the standard Xcode build system, following Flutter community best practices.

## Prerequisites

- ✅ Existing `ios/ios_prebuild.sh` script (our proven solution)
- ✅ Existing `ios/xcode_build_phase_script.sh` (Xcode integration wrapper)
- ✅ Xcode installed and iOS project accessible

## Step-by-Step Integration

### 1. Open Xcode Project

```bash
cd /path/to/wildfire_mvp_v3
open ios/Runner.xcworkspace
```

### 2. Navigate to Build Phases

1. In Xcode, select the **Runner** target in the project navigator
2. Click on the **"Build Phases"** tab at the top
3. You should see existing phases like:
   - Target Dependencies
   - [CP] Check Pods Manifest.lock
   - Compile Sources
   - Bundle Framework
   - [CP] Embed Pods Frameworks
   - etc.

### 3. Add New Run Script Phase

1. Click the **"+"** button in the top-left of the Build Phases section
2. Select **"New Run Script Phase"**
3. A new "Run Script" phase will appear at the bottom

### 4. Configure the Run Script Phase

#### 4.1 Rename the Phase
1. Double-click on "Run Script" to rename it
2. Change the name to: **"Process DART_DEFINES (API Keys)"**

#### 4.2 Position the Phase
1. **Drag** the new phase to position it **BEFORE** "Compile Sources"
2. The correct order should be:
   - Target Dependencies
   - [CP] Check Pods Manifest.lock
   - **Process DART_DEFINES (API Keys)** ← Your new phase
   - Compile Sources
   - Bundle Framework
   - etc.

#### 4.3 Configure Script Settings

In the script configuration area:

**Shell:** `/bin/sh` (default - leave unchanged)

**Script Content:** Paste this exactly:
```bash
# Flutter DART_DEFINES API Key Injection
# Automatically processes environment variables from --dart-define-from-file
# and injects API keys into Info.plist

if [ -f "${SRCROOT}/ios/xcode_build_phase_script.sh" ]; then
    echo "🔧 Running DART_DEFINES processor..."
    bash "${SRCROOT}/ios/xcode_build_phase_script.sh"
else
    echo "⚠️  Xcode build phase script not found - skipping API key injection"
    echo "Expected: ${SRCROOT}/ios/xcode_build_phase_script.sh"
fi
```

#### 4.4 Input/Output Files (Optional but Recommended)

**Input Files:**
```
$(SRCROOT)/Flutter/Generated.xcconfig
$(SRCROOT)/Runner/Info.plist
$(SRCROOT)/ios/ios_prebuild.sh
```

**Output Files:**
```
$(SRCROOT)/Runner/Info.plist
```

This helps Xcode's incremental build system understand dependencies.

### 5. Test the Integration

#### 5.1 Clean Build Test
1. In Xcode: Product → Clean Build Folder (⌘⇧K)
2. Run a Flutter command that generates DART_DEFINES:
   ```bash
   flutter build ios --dart-define-from-file=env/dev.env.json --no-codesign
   ```
3. Check the build output for our script messages

#### 5.2 Xcode GUI Build Test
1. In Xcode: Product → Build (⌘B)
2. Look for our script output in the build log:
   ```
   🔧 Running DART_DEFINES processor...
   🔧 Xcode Build Phase: Processing environment variables...
   ✅ Found DART_DEFINES and prebuild script - processing API keys...
   ✅ Xcode Build Phase: API key injection completed successfully
   ```

#### 5.3 Standard Flutter Commands Test
```bash
# Should work automatically now:
flutter run -d ios --dart-define-from-file=env/dev.env.json

# Should also work:
flutter build ipa --dart-define-from-file=env/dev.env.json
```

## Verification Steps

### Check Info.plist After Build
```bash
grep -A 1 "GMSApiKey" ios/Runner/Info.plist
```

Expected output:
```xml
<key>GMSApiKey</key>
<string>AIzaSyBBbL552AGWKqEQKhNCxkX0xHjncwpZumA</string>
```

### Test App Launch
1. Run the app on iOS simulator
2. Navigate to Maps tab
3. Verify no Google Maps crashes occur
4. Confirm maps load correctly

## Troubleshooting

### Build Phase Not Running
- **Check position**: Must be BEFORE "Compile Sources"
- **Check script path**: Verify `ios/xcode_build_phase_script.sh` exists
- **Check permissions**: Run `chmod +x ios/xcode_build_phase_script.sh`

### API Key Not Injected
- **Check DART_DEFINES**: Run `flutter build ios` first to generate `Generated.xcconfig`
- **Check API key**: Verify `GOOGLE_MAPS_API_KEY_IOS` is in `env/dev.env.json`
- **Check script output**: Look for error messages in Xcode build log

### Build Failures
- **Check script syntax**: Ensure no copy-paste errors in the script content
- **Check file permissions**: All `.sh` files should be executable
- **Check paths**: Verify all referenced files exist

## Rollback Plan

If the integration causes issues:

1. **Disable Build Phase**: In Xcode Build Phases, uncheck the "Process DART_DEFINES" phase
2. **Use Manual Method**: Continue using `./scripts/run_ios_safe.sh`
3. **Remove Build Phase**: Delete the "Process DART_DEFINES" phase entirely

## Benefits After Integration

### For Developers
```bash
# Before (Manual)
./scripts/run_ios_safe.sh

# After (Automatic)  
flutter run -d ios --dart-define-from-file=env/dev.env.json
```

### For CI/CD
```bash
# Standard Flutter commands work automatically
flutter build ipa --dart-define-from-file=env/prod.env.json
```

### For Team Workflow
- ✅ No manual prebuild steps required
- ✅ Works with standard Flutter commands
- ✅ Transparent to new team members
- ✅ Compatible with Xcode GUI builds
- ✅ Proper incremental build support

## Next Steps After Integration

1. **Update README.md** - Remove manual prebuild instructions
2. **Update Documentation** - Document standard Flutter workflow
3. **Train Team** - Show new simplified workflow
4. **Optional Cleanup** - Remove manual wrapper scripts after verification

## Advanced: CI/CD Integration

The build phase works automatically in CI environments:

```yaml
# GitHub Actions example
- name: Build iOS
  run: |
    flutter build ipa \
      --dart-define-from-file=env/prod.env.json \
      --export-method=app-store
```

No additional CI configuration needed - the API key injection happens automatically during the Xcode build process.

## Conclusion

This integration makes our iOS API key injection follow Flutter community best practices while preserving all our proven logic. The solution becomes transparent to developers and works seamlessly with all Flutter commands and CI/CD systems.