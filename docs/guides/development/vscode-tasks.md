---
title: VS Code Tasks Reference
status: active
last_updated: 2026-01-19
category: guides
subcategory: development
related:
  - ../setup/google-maps.md
  - ../../CI_CD_WORKFLOW_GUIDE.md
  - ../../DEPLOYMENT_WORKFLOW.md
---

# VS Code Tasks Reference

This guide documents the VS Code tasks configured in `.vscode/tasks.json` for the WildFire MVP project. Tasks provide quick access to common development workflows through the VS Code command palette or keyboard shortcuts.

## Quick Start

**Access Tasks:**
- `Cmd+Shift+B` → Run default build task (Pre-commit Full Check)
- `Cmd+Shift+P` → "Tasks: Run Task" → Select from menu
- `Cmd+Shift+P` → "Tasks: Run Build Task" → Quick build tasks

**AI Integration:**
- AI assistants (Copilot, etc.) can invoke tasks by name
- Say "run pre-commit checks" → Executes `🧪 Pre-commit: Full Check`
- Say "test on web platform" → Executes `🌐 Test: Web Platform`

---

## Task Categories

### 1. Pre-Commit & Quality Checks

#### 🧪 Pre-commit: Full Check ⭐ (Default)
**Command:** `dart format . && flutter analyze && flutter test`  
**Keyboard:** `Cmd+Shift+B` (default build task)  
**Purpose:** Standard pre-commit workflow - format, analyze, test all in sequence  
**When to use:** Before every commit, after making changes  

```bash
# Equivalent manual commands:
dart format .
flutter analyze
flutter test
```

#### 🏛️ Constitutional Gates (C1-C5)
**Command:** `./scripts/constitution-gates.sh`  
**Purpose:** Comprehensive compliance check (C1-C5 gates from project constitution)  
**When to use:** Before PR creation, for final validation  

**Checks:**
- C1: Code quality (format, analyze, tests)
- C2: Privacy compliance (coordinate logging)
- C3: Accessibility (semantic labels, contrast)
- C4: Security (API key patterns, gitleaks)
- C5: Documentation (health checks)

#### 🔍 Format Check Only
**Command:** `dart format --output=none --set-exit-if-changed .`  
**Purpose:** Check if code is formatted without applying changes  
**When to use:** In CI, to verify format compliance  

#### ✨ Format Code (Apply)
**Command:** `dart format lib/ test/`  
**Purpose:** Auto-format all Dart code  
**When to use:** After writing code, before committing  

#### 🔬 Analyze Only
**Command:** `flutter analyze --no-fatal-infos`  
**Purpose:** Run static analysis without tests  
**When to use:** Quick syntax/lint checks during development  

---

### 2. Testing Workflows

#### 🧪 Test: All
**Command:** `flutter test --reporter expanded`  
**Purpose:** Run all tests (unit + integration + widget) with expanded output  
**When to use:** Full test suite validation  

#### 🧪 Test: Unit Only
**Command:** `flutter test test/unit/ --reporter expanded`  
**Purpose:** Run only unit tests (fastest subset)  
**When to use:** Testing business logic, services, utilities  

**Example test files:**
- `test/unit/services/fire_risk_service_test.dart`
- `test/unit/controllers/home_controller_test.dart`
- `test/unit/utils/location_utils_test.dart`

#### 🧪 Test: Integration Only
**Command:** `flutter test test/integration/ --reporter expanded`  
**Purpose:** Run integration tests (service orchestration, flows)  
**When to use:** Testing multi-component interactions  

**Example test files:**
- `test/integration/home_flow_test.dart`
- `test/integration/map/fire_incident_integration_test.dart`

#### 🧪 Test: Widget Only
**Command:** `flutter test test/widget/ --reporter expanded`  
**Purpose:** Run widget tests (UI components)  
**When to use:** Testing UI behavior, accessibility  

**Example test files:**
- `test/widget/risk_banner_test.dart`
- `test/widget/location_chip_test.dart`

#### 🌐 Test: Web Platform
**Command:** `flutter test test/unit/ --platform=chrome && flutter test test/integration/ --platform=chrome`  
**Purpose:** Run tests specifically on Chrome/web platform  
**When to use:** Validating web compatibility (google_maps_flutter_web, etc.)  

**Note:** Some tests skip on web (GPS, platform-specific features)

#### 📊 Test: With Coverage
**Command:** `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`  
**Purpose:** Generate test coverage report  
**Output:** `coverage/html/index.html` (open in browser)  
**When to use:** Before releases, to identify untested code  

---

### 3. Platform Runs (Development)

#### 🌐 Run: Web (with API keys) ⭐
**Command:** `./scripts/run_web.sh`  
**Purpose:** Run app in Chrome with API key injection from `env/dev.env.json`  
**When to use:** Primary development platform (supports Google Maps)  

**Features:**
- Auto-injects `GOOGLE_MAPS_API_KEY_WEB` from env file
- Removes watermark ("for development purposes only")
- Restores original `web/index.html` on exit

#### 🍎 Run: macOS (with API keys)
**Command:** `flutter run -d macos --dart-define-from-file=env/dev.env.json`  
**Purpose:** Run native macOS desktop app  
**When to use:** Testing macOS-specific features  

**Limitations:**
- Does NOT support Google Maps (no `google_maps_flutter` on macOS desktop)
- Use for A1-A9 features (EFFIS, FireRisk, Location, Cache)

#### 📱 Run: iOS Simulator (with API keys)
**Command:** `./scripts/run_ios.sh`  
**Purpose:** Run on iOS simulator with Xcode build phase API key injection  
**When to use:** Testing iOS-specific features, Google Maps on mobile  

**Prerequisites:**
- Xcode installed
- iOS simulator available
- Run `./scripts/setup_xcode_build_phase.sh` once

#### 🤖 Run: Android Emulator
**Command:** `./scripts/run_android.sh`  
**Purpose:** Run on Android emulator  
**When to use:** Testing Android-specific features  

**Prerequisites:**
- Android Studio installed
- Emulator created and running

---

### 4. Build Tasks

#### 🔨 Build: Web (CI mode with API key)
**Command:** `export MAPS_API_KEY_WEB=$(jq -r .GOOGLE_MAPS_API_KEY_WEB env/dev.env.json) && ./scripts/build_web_ci.sh`  
**Purpose:** Build web app with API key injection (production-ready)  
**Output:** `build/web/` directory  
**When to use:** Testing CI build process locally, before deployment  

**Process:**
1. Extracts API key from `env/dev.env.json`
2. Injects into `web/index.html` placeholder `%MAPS_API_KEY%`
3. Runs `flutter build web --release`
4. Restores original `web/index.html`

#### 🔨 Build: Web (Release)
**Command:** `flutter build web --release --dart-define-from-file=env/dev.env.json`  
**Purpose:** Standard web release build  
**When to use:** Manual builds without CI script  

#### 🔨 Build: iOS
**Command:** `flutter build ios --release --dart-define-from-file=env/dev.env.json`  
**Purpose:** Build iOS release (requires macOS + Xcode)  

#### 🔨 Build: Android APK
**Command:** `flutter build apk --release --dart-define-from-file=env/dev.env.json`  
**Purpose:** Build Android APK for distribution  

---

### 5. Git & Deployment Workflows

#### 🚀 CI: Check Latest Run
**Command:** `gh run list --limit 5 --json databaseId,status,conclusion,headBranch,event,displayTitle`  
**Purpose:** Show last 5 GitHub Actions workflow runs  
**Output:** JSON with run status, branch, conclusion  
**When to use:** After pushing, to check CI status  

**Example output:**
```json
[
  {
    "conclusion": "success",
    "databaseId": 21031352735,
    "displayTitle": "fix(ci): reduce staging deploy expires",
    "headBranch": "023-compact-location-ui",
    "status": "completed"
  }
]
```

#### 🚀 CI: Watch Current Run
**Command:** `gh run watch`  
**Purpose:** Real-time monitoring of current workflow run  
**When to use:** After creating PR, during deployment  

**Features:**
- Live updates every few seconds
- Shows job progress
- Exits when run completes

#### 🚀 Deploy: Check Staging Status
**Command:** `gh run list --branch=staging --limit 1 && echo '\n🔗 Staging URL: https://wildfire-app-e11f8-staging.web.app'`  
**Purpose:** Check staging deployment status and get URL  
**When to use:** After merging PR to staging  

#### 📦 PR: Create to Staging
**Command:** `gh pr create --base staging --title '${input:prTitle}' --body '${input:prBody}'`  
**Purpose:** Create pull request to staging branch (interactive)  
**Prompts:** PR title, PR description  
**When to use:** After feature development complete  

#### 📦 PR: View Current
**Command:** `gh pr view --web`  
**Purpose:** Open current PR in browser  
**When to use:** Quick access to PR for review  

---

### 6. Security & API Key Checks

#### 🔒 Security: Check for Leaked Keys
**Command:** `grep -rE 'AIza[A-Za-z0-9_-]{35}' --exclude-dir=node_modules --exclude-dir=build . || echo '✅ No API keys found in code'`  
**Purpose:** Search for Google Maps API keys in source code  
**Pattern:** `AIza` followed by 35 characters (Google Maps API key format)  
**When to use:** Before committing, in pre-commit hooks  

**Safe locations for keys:**
- `env/dev.env.json` (gitignored)
- `env/prod.env.json` (gitignored)

**Unsafe locations:**
- Any file in `lib/`, `test/`, `web/`, etc.

#### 🔒 Security: Run Gitleaks
**Command:** `docker run --rm -v ${workspaceFolder}:/repo zricethezav/gitleaks:latest detect --source=/repo --verbose --no-git`  
**Purpose:** Comprehensive secret scanning with Gitleaks  
**Prerequisites:** Docker installed  
**When to use:** Weekly security audits, before releases  

**Detects:**
- API keys (Google, AWS, GitHub, etc.)
- Private keys, tokens
- Passwords, connection strings

#### 🔑 Verify: Environment Files
**Command:** `test -f env/dev.env.json && echo '✅ dev.env.json exists' || echo '❌ Missing env/dev.env.json'; test -f env/prod.env.json && echo '✅ prod.env.json exists' || echo '⚠️ Missing env/prod.env.json (optional for local dev)'`  
**Purpose:** Check if environment files exist  
**When to use:** After cloning repository, troubleshooting build issues  

**Expected files:**
- `env/dev.env.json` - **Required** for local development
- `env/prod.env.json` - Optional (production deployments use GitHub Secrets)

---

### 7. Project Maintenance

#### 🧹 Clean: Build Artifacts
**Command:** `flutter clean && flutter pub get`  
**Purpose:** Remove build cache and reinstall dependencies  
**When to use:** 
- Build errors, stale cache issues
- After Flutter SDK upgrade
- After changing `pubspec.yaml`

**Warning:** Takes 2-3 minutes to rebuild caches

#### 📚 Docs: Health Check
**Command:** `./scripts/docs-health-check.sh`  
**Purpose:** Validate documentation structure (Divio system compliance)  
**When to use:** After adding/updating documentation  

**Checks:**
- Frontmatter presence (title, status, category)
- Broken internal links
- Proper categorization (guides/, reference/, explanation/)

#### 🎨 Color Guard: Verify No Ad-Hoc Colors
**Command:** `./scripts/verify_no_adhoc_colors.sh`  
**Purpose:** Ensure all colors use `RiskPalette` tokens (C3 compliance)  
**When to use:** Before committing UI changes  

**Forbidden patterns:**
- `Color(0xFF...)` outside theme files
- `Colors.red`, `Colors.blue` (use `RiskPalette.riskHigh`, etc.)

#### 📦 Dependencies: Update
**Command:** `flutter pub upgrade && flutter pub outdated`  
**Purpose:** Upgrade dependencies and show outdated packages  
**When to use:** Monthly maintenance, before releases  

**Output:**
- List of outdated packages with versions
- Breaking change warnings

---

### 8. Feature Development (Spec-Driven)

#### 📝 Feature: Update Agent Context
**Command:** `.specify/scripts/bash/update-agent-context.sh copilot`  
**Purpose:** Regenerate `.github/copilot-instructions.md` from feature plans  
**When to use:** After completing a feature, before merging  

**Process:**
1. Scans `specs/*/plan.md` for active features
2. Extracts technologies, patterns, commands
3. Updates copilot-instructions.md incrementally

**Important:** Always run with `copilot` argument (not `cursor` or other targets)

#### 📝 Feature: Check Prerequisites
**Command:** `.specify/scripts/bash/check-prerequisites.sh`  
**Purpose:** Validate spec-driven development environment  
**When to use:** After cloning repo, troubleshooting spec scripts  

**Checks:**
- Required directories exist (`.specify/`, `specs/`)
- Template files present
- Script permissions correct

---

### 9. Composite Workflows

#### 🚀 Deploy Prep: Full Pipeline
**Depends on:**
1. `🧪 Pre-commit: Full Check`
2. `🔒 Security: Check for Leaked Keys`
3. `🔨 Build: Web (CI mode with API key)`

**Purpose:** Complete pre-deployment validation  
**Execution:** Sequential (stops on first failure)  
**When to use:** Before creating PR to main, manual production prep  

**Timeline:**
- Pre-commit checks: ~2 minutes
- Security scan: ~10 seconds
- Web build: ~1 minute
- **Total:** ~3-4 minutes

---

## Common Workflows

### Daily Development
```
1. 🌐 Run: Web (with API keys)         # Start dev server
2. [Make changes]
3. ✨ Format Code (Apply)              # Format on save
4. 🧪 Test: Unit Only                  # Quick validation
5. 🧪 Pre-commit: Full Check           # Before commit
```

### Before Creating PR
```
1. 🧪 Pre-commit: Full Check           # All tests pass
2. 🔒 Security: Check for Leaked Keys  # No secrets leaked
3. 🏛️ Constitutional Gates (C1-C5)     # Full compliance
4. 📝 Feature: Update Agent Context    # Update docs
5. 📦 PR: Create to Staging            # Create PR
```

### After Merging to Staging
```
1. 🚀 Deploy: Check Staging Status     # Wait for deployment
2. [Test on staging URL]
3. [If issues, fix and repeat]
4. [If stable, create PR staging → main]
```

### Production Deployment
```
1. 🚀 Deploy Prep: Full Pipeline       # Complete validation
2. [Create PR staging → main]
3. 🚀 CI: Watch Current Run            # Monitor deployment
4. [Manual approval in GitHub]
5. [Verify production URL]
```

---

## Troubleshooting

### Task Not Found
**Problem:** "No task found with the label..."  
**Solution:** Reload VS Code window (`Cmd+Shift+P` → "Developer: Reload Window")

### Build Script Fails
**Problem:** `./scripts/build_web_ci.sh: Permission denied`  
**Solution:** `chmod +x ./scripts/build_web_ci.sh`

### Environment File Missing
**Problem:** `❌ Error: Environment file not found`  
**Solution:** 
```bash
cp env/dev.env.json.template env/dev.env.json
# Edit env/dev.env.json with your API keys
```

### Gitleaks Requires Docker
**Problem:** "Cannot connect to Docker daemon"  
**Solution:** Start Docker Desktop, or use alternative security check:
```bash
# Run without Docker:
🔒 Security: Check for Leaked Keys
```

### Test Timeout on Web Platform
**Problem:** Tests hang when run with `--platform=chrome`  
**Solution:** Close other Chrome instances, or use headless mode:
```bash
flutter test --platform=chrome --headless
```

---

## Customization

### Adding New Tasks

Edit `.vscode/tasks.json`:

```json
{
  "label": "🎯 My Custom Task",
  "type": "shell",
  "command": "echo 'Hello World'",
  "problemMatcher": []
}
```

### Keyboard Shortcuts

Add to `.vscode/keybindings.json`:

```json
[
  {
    "key": "cmd+shift+t",
    "command": "workbench.action.tasks.runTask",
    "args": "🧪 Test: All"
  }
]
```

### Task Dependencies

Chain multiple tasks:

```json
{
  "label": "Full Build Pipeline",
  "dependsOn": [
    "Format Code",
    "Analyze",
    "Test All"
  ],
  "dependsOrder": "sequence"
}
```

---

## Related Documentation

- **CI/CD Workflow:** `docs/CI_CD_WORKFLOW_GUIDE.md`
- **Deployment Process:** `docs/DEPLOYMENT_WORKFLOW.md`
- **Google Maps Setup:** `docs/guides/setup/google-maps.md`
- **Security Guidelines:** `docs/PREVENT_API_KEY_LEAKS.md`
- **Testing Guide:** `docs/INTEGRATION_TESTING.md`

---

## Quick Reference Card

| Emoji | Category | Most Used |
|-------|----------|-----------|
| 🧪 | Testing | Pre-commit Full Check, Test All |
| 🌐 | Platform Runs | Run Web, Run iOS |
| 🔨 | Builds | Build Web (CI mode) |
| 🚀 | CI/CD | Check Latest Run, Watch Run |
| 🔒 | Security | Check Leaked Keys |
| 🧹 | Maintenance | Clean Artifacts |
| 📝 | Spec-Driven | Update Agent Context |

**Pro Tip:** Add task labels to your commit messages:
```
git commit -m "feat: add feature X

Validated with:
- 🧪 Pre-commit: Full Check ✅
- 🔒 Security: Check for Leaked Keys ✅
- 🏛️ Constitutional Gates (C1-C5) ✅
```
