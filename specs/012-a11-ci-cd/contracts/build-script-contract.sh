# Build Script Contract: scripts/build_web_ci.sh

**Purpose**: Build Flutter web application with secure API key injection for CI/CD environments

**Last Updated**: 2025-10-27  
**Version**: 1.0

---

## Script Interface

### Input Contract
```bash
# Environment Variables (REQUIRED)
MAPS_API_KEY_WEB="AIza..."  # Google Maps API key (from GitHub Secrets)

# Environment Variables (OPTIONAL)
MAP_LIVE_DATA="false"       # Flutter build flag (default: false for CI)

# File System Preconditions
- web/index.html MUST exist
- web/index.html MUST contain %MAPS_API_KEY% placeholder
- flutter MUST be in PATH (Flutter SDK installed)
```

### Output Contract
```bash
# Exit Codes
0 = Success (build complete, API key injected, cleanup done)
1 = Error (missing API key, build failure, placeholder not found)

# File System Postconditions
- build/web/ directory MUST exist
- build/web/index.html MUST contain injected API key (not placeholder)
- web/index.html MUST contain placeholder (original restored, no key)
- web/index.html.bak MUST NOT exist (cleanup complete)

# Standard Output Format
🔑 Injecting API key into web/index.html...
🔨 Building Flutter web app...
[flutter build output]
✅ Web build complete!
📁 Build output: build/web/
🔒 API key injection cleaned up (original file restored)
```

---

## Implementation Contract

### Script Template
```bash
#!/bin/bash
# scripts/build_web_ci.sh
# CI-specific build script with API key injection from environment variables

set -e  # Exit on any error (C5 resilience)

echo "🌐 Building WildFire MVP v3 for Web (CI mode)..."

# PHASE 1: Validate Inputs (C5 error handling)
WEB_API_KEY="${MAPS_API_KEY_WEB:-}"

if [ -z "$WEB_API_KEY" ]; then
  echo "❌ Error: MAPS_API_KEY_WEB environment variable not set"
  echo "   Expected: GitHub Secrets → GOOGLE_MAPS_API_KEY_WEB_PREVIEW or GOOGLE_MAPS_API_KEY_WEB_PRODUCTION"
  exit 1
fi

# Validate placeholder exists in web/index.html
if ! grep -q "%MAPS_API_KEY%" web/index.html; then
  echo "❌ Error: %MAPS_API_KEY% placeholder not found in web/index.html"
  echo "   Expected: <script src=\"https://maps.googleapis.com/maps/api/js%MAPS_API_KEY%\"></script>"
  exit 1
fi

# PHASE 2: Inject API Key (C2 secret management)
echo "🔑 Injecting API key into web/index.html..."

# Create backup for rollback
cp web/index.html web/index.html.bak

# Replace placeholder with actual API key
# Pattern: %MAPS_API_KEY% → ?key=AIza...
sed -i.tmp 's|%MAPS_API_KEY%|?key='"$WEB_API_KEY"'|g' web/index.html
rm -f web/index.html.tmp  # Remove sed backup file

# Validate injection succeeded
if grep -q "%MAPS_API_KEY%" web/index.html; then
  echo "❌ Error: API key injection failed (placeholder still exists)"
  mv web/index.html.bak web/index.html  # Restore original
  exit 1
fi

echo "✅ API key injected successfully"

# PHASE 3: Build Flutter Web (C1 code quality)
echo "🔨 Building Flutter web app..."

# Set build flags
BUILD_FLAGS="--release --dart-define=MAP_LIVE_DATA=${MAP_LIVE_DATA:-false}"

# Run Flutter build
if ! flutter build web $BUILD_FLAGS; then
  echo "❌ Error: Flutter build failed"
  mv web/index.html.bak web/index.html  # Restore original
  exit 1
fi

echo "✅ Web build complete!"
echo "📁 Build output: build/web/"

# PHASE 4: Cleanup (C2 prevent key leaks)
echo "🔒 Cleaning up API key injection..."

# Restore original web/index.html (with placeholder)
mv web/index.html.bak web/index.html

# Validate cleanup
if ! grep -q "%MAPS_API_KEY%" web/index.html; then
  echo "⚠️  Warning: Original file restoration may have failed"
  echo "   web/index.html should contain placeholder, not API key"
  # Don't exit - build succeeded, this is just a warning
fi

# Validate build artifact exists
if [ ! -f "build/web/index.html" ]; then
  echo "❌ Error: Build artifact not found (build/web/index.html missing)"
  exit 1
fi

# Log API key masked value (C2 safe logging)
KEY_PREVIEW="${WEB_API_KEY:0:8}***"
echo "📊 Build Summary:"
echo "   - API Key: $KEY_PREVIEW (masked)"
echo "   - Build Mode: release"
echo "   - Live Data: ${MAP_LIVE_DATA:-false}"
echo "   - Output: build/web/"

echo "✅ CI build complete - ready for deployment!"
```

---

## Contract Validation Tests

### Test 1: Missing API Key
**Input**:
```bash
unset MAPS_API_KEY_WEB
./scripts/build_web_ci.sh
```

**Expected Output**:
```
🌐 Building WildFire MVP v3 for Web (CI mode)...
❌ Error: MAPS_API_KEY_WEB environment variable not set
   Expected: GitHub Secrets → GOOGLE_MAPS_API_KEY_WEB_PREVIEW or GOOGLE_MAPS_API_KEY_WEB_PRODUCTION
```

**Expected Exit Code**: `1`

**Validation**:
- ✅ Script exits immediately (no build attempted)
- ✅ Error message clear and actionable
- ✅ web/index.html unchanged (still has placeholder)

---

### Test 2: Missing Placeholder
**Input**:
```bash
# Modify web/index.html to remove placeholder
sed -i.bak 's|%MAPS_API_KEY%||g' web/index.html

export MAPS_API_KEY_WEB="test_key_12345"
./scripts/build_web_ci.sh
```

**Expected Output**:
```
🌐 Building WildFire MVP v3 for Web (CI mode)...
❌ Error: %MAPS_API_KEY% placeholder not found in web/index.html
   Expected: <script src="https://maps.googleapis.com/maps/api/js%MAPS_API_KEY%"></script>
```

**Expected Exit Code**: `1`

**Validation**:
- ✅ Script exits immediately (no injection attempted)
- ✅ Error message includes expected placeholder format
- ✅ Restore web/index.html.bak after test

---

### Test 3: Successful Build with API Key
**Input**:
```bash
export MAPS_API_KEY_WEB="AIzaSyTest1234567890abcdefghij"
./scripts/build_web_ci.sh
```

**Expected Output**:
```
🌐 Building WildFire MVP v3 for Web (CI mode)...
🔑 Injecting API key into web/index.html...
✅ API key injected successfully
🔨 Building Flutter web app...
[Flutter build output...]
✅ Web build complete!
📁 Build output: build/web/
🔒 Cleaning up API key injection...
📊 Build Summary:
   - API Key: AIzaSyTe*** (masked)
   - Build Mode: release
   - Live Data: false
   - Output: build/web/
✅ CI build complete - ready for deployment!
```

**Expected Exit Code**: `0`

**Validation**:
- ✅ build/web/index.html contains API key (not placeholder)
- ✅ web/index.html contains placeholder (not API key)
- ✅ web/index.html.bak does not exist (cleanup complete)
- ✅ API key logged as masked value (first 8 chars + ***)

---

### Test 4: Build Failure Rollback
**Input**:
```bash
# Introduce syntax error in main.dart to cause build failure
echo "syntax error" >> lib/main.dart

export MAPS_API_KEY_WEB="test_key_12345"
./scripts/build_web_ci.sh
```

**Expected Output**:
```
🌐 Building WildFire MVP v3 for Web (CI mode)...
🔑 Injecting API key into web/index.html...
✅ API key injected successfully
🔨 Building Flutter web app...
[Flutter error output...]
❌ Error: Flutter build failed
```

**Expected Exit Code**: `1`

**Validation**:
- ✅ Script exits after build failure
- ✅ web/index.html restored to original (contains placeholder, not API key)
- ✅ build/web/ directory may not exist or be incomplete
- ✅ Git status shows no changes to web/index.html

---

### Test 5: Cleanup Validation
**Input**:
```bash
export MAPS_API_KEY_WEB="test_key_12345"
./scripts/build_web_ci.sh

# After script completes, check file contents
grep "%MAPS_API_KEY%" web/index.html  # Should find placeholder
grep "test_key_12345" web/index.html  # Should NOT find key
grep "test_key_12345" build/web/index.html  # Should find key
```

**Expected Results**:
```bash
# web/index.html (original)
<script src="https://maps.googleapis.com/maps/api/js%MAPS_API_KEY%"></script>

# build/web/index.html (build artifact)
<script src="https://maps.googleapis.com/maps/api/js?key=test_key_12345"></script>
```

**Validation**:
- ✅ Original file restored with placeholder
- ✅ Build artifact contains injected key
- ✅ No backup files (.bak, .tmp) left behind

---

## Integration with GitHub Actions

### Workflow Usage
```yaml
- name: Build web with API key injection
  env:
    MAPS_API_KEY_WEB: ${{ secrets.GOOGLE_MAPS_API_KEY_WEB_PREVIEW }}
    MAP_LIVE_DATA: 'false'
  run: |
    chmod +x ./scripts/build_web_ci.sh
    ./scripts/build_web_ci.sh
```

**Requirements**:
- Script MUST be executable: `chmod +x ./scripts/build_web_ci.sh`
- Environment variable MUST be set from GitHub Secrets
- Script MUST be run from repository root (relative paths)

### Error Handling Contract (C5)
| Failure Scenario | Expected Behavior | Recovery |
|------------------|-------------------|----------|
| Missing API key | Exit 1, clear error message | Add secret to GitHub repo |
| Missing placeholder | Exit 1, validation error | Fix web/index.html |
| Build failure | Exit 1, restore original file | Fix code, rerun |
| Cleanup failure | Warning logged, build succeeds | Manual verification, non-blocking |
| Missing build artifact | Exit 1, critical error | Investigate Flutter build logs |

---

## Security Contract (C2 Compliance)

### Secret Handling
- ✅ API keys MUST NEVER be logged in full (only first 8 chars + ***)
- ✅ API keys MUST NEVER be committed to repository (cleanup enforced)
- ✅ API keys MUST be injected from environment variables (not files)
- ✅ Backup files (.bak) MUST be removed (prevent key leaks)

### Logging Safety
```bash
# CORRECT: Masked logging (C2 compliant)
KEY_PREVIEW="${WEB_API_KEY:0:8}***"
echo "📊 Build Summary:"
echo "   - API Key: $KEY_PREVIEW (masked)"

# WRONG: Full key logging (C2 violation)
echo "Using API key: $WEB_API_KEY"  # ❌ Exposes full key in logs
```

---

## Performance Contract (M1 Compliance)

### Build Time Requirements
- Flutter build MUST complete in <2 minutes (typical: 1-1.5 minutes)
- Script overhead MUST be <5 seconds (validation, injection, cleanup)
- Total build job time: <2.5 minutes (acceptable for M1: <5 min total)

### Optimization Opportunities
- Use Flutter web caching in CI (caches build artifacts between runs)
- Skip unnecessary dependencies (flutter pub get runs before script)
- Parallel builds not needed (single web target)

---

## Change Log

**Version 1.0 (2025-10-27)**:
- Initial build script contract
- Defined input/output contracts
- Specified 5 validation tests
- Documented GitHub Actions integration
- Defined security contract (C2 compliance)
- Defined performance contract (M1 compliance)

**Next Version** (future):
- Add support for staging API key (MAPS_API_KEY_WEB_STAGING)
- Add support for custom build flags (optimize for size, etc.)
- Add pre-build validation (flutter doctor checks)
