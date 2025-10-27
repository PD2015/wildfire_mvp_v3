
# Implementation Plan: A11 – CI/CD: Flutter Web → Firebase Hosting

**Branch**: `012-a11-ci-cd` | **Date**: 2025-10-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/012-a11-ci-cd/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Build a CI/CD pipeline for automated Flutter web deployments to Firebase Hosting with PR preview channels and production deployments requiring manual approval. The system extends the existing .github/workflows/flutter.yml to add deployment jobs that inject Google Maps API keys securely from GitHub Secrets, generate unique preview URLs for pull requests (auto-cleanup after 7 days), and enforce all constitutional gates (C1-C5) before any deployment.

**Primary Technical Approach**: Extend existing GitHub Actions workflow with three new jobs: (1) build-web job that creates deployable artifacts with injected API keys using scripts/build_web_ci.sh, (2) deploy-preview job that uses Firebase Hosting channels API for PR previews, (3) deploy-production job that requires manual approval via GitHub Environments and deploys to main channel. The build script reads API keys from MAPS_API_KEY_WEB environment variable and replaces %MAPS_API_KEY% placeholder in web/index.html during build, ensuring zero secrets in repository.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable  
**Primary Dependencies**: Firebase Hosting (deployment infrastructure), GitHub Actions (CI/CD orchestration), google_maps_flutter ^2.5.0 (mapping component), firebase-tools CLI (deployment tool)  
**Storage**: Firebase Hosting (web build artifacts), GitHub Secrets (API keys: FIREBASE_SERVICE_ACCOUNT, FIREBASE_PROJECT_ID, GOOGLE_MAPS_API_KEY_WEB_PREVIEW, GOOGLE_MAPS_API_KEY_WEB_PRODUCTION)  
**Testing**: flutter test (unit/widget tests), integration tests for deployment validation, Lighthouse CI for performance (M5: ≥90 score)  
**Target Platform**: Web (Chrome, Safari, Firefox, Edge) deployed to Firebase Hosting with SPA routing  
**Project Type**: Single Flutter project with web target (existing structure: lib/, test/, web/, .github/workflows/)  
**Performance Goals**: Preview deployment <5 minutes (M1), deep link success rate 100% (M4), production deployment availability ≥99.9% (M5)  
**Constraints**: Zero API key exposures in logs/repository (M3), production requires manual approval (M2), all constitutional gates (C1-C5) must pass before deployment  
**Scale/Scope**: Multi-channel deployments (1 production + N PR preview channels), 4 GitHub Secrets, 7-day auto-cleanup for preview channels

**Prerequisites Completed**:
- ✅ Firebase project created: wildfire-app-e11f8
- ✅ Firebase Hosting configured (.firebaserc, firebase.json with SPA rewrites)
- ✅ Service account with Firebase Hosting Admin role created
- ✅ Google Maps API key restricted to *.wildfire-app-e11f8.web.app/* (3 HTTP referrer patterns)
- ✅ 4 GitHub Secrets configured in repository
- ✅ GitHub production environment with required reviewer protection
- ✅ Current deployment tested and live: https://wildfire-app-e11f8.web.app

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements
  - Existing flutter.yml already enforces analyze, format, and tests before any deployment
  - New deployment jobs depend on test job success
- [x] Testing strategy covers unit/widget tests for applicable components
  - Build script (scripts/build_web_ci.sh) will have unit tests for API key injection logic
  - Integration tests will validate deployment workflow (not code tests, infrastructure tests)
- [x] CI enforcement approach specified
  - All existing CI checks preserved as prerequisites for deployment jobs

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (use .env/runtime config)
  - API keys stored in GitHub Secrets, injected at build time via environment variables
  - web/index.html uses %MAPS_API_KEY% placeholder (no hardcoded keys)
  - Service account JSON stored in GitHub Secrets only
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision
  - Build script logs only masked API key values (first 8 chars + ***)
  - Firebase deployment logs do not expose secrets (handled by firebase-tools CLI)
  - No coordinate logging in CI/CD pipeline (infrastructure layer)
- [x] Secret scanning integrated into CI plan
  - Existing gitleaks check in flutter.yml runs before deployment
  - Build script validates API key format before injection

### C3. Accessibility (UI features only)
- [x] N/A - No UI components added in this feature
  - CI/CD infrastructure only (workflow files, scripts, documentation)
  - Existing UI accessibility remains unchanged

### C4. Trust & Transparency
- [x] N/A - No risk display components added
  - CI/CD does not modify data presentation
  - Deployment metadata (timestamps, URLs) visible in GitHub Actions UI and PR comments
  - Source labeling unchanged (existing A1-A10 features)

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling
  - Firebase deployment commands wrapped with timeout (firebase deploy --timeout 600s)
  - Build script exits with error codes on failure (set -e)
  - GitHub Actions jobs have timeout-minutes: 15 (prevents hung deployments)
- [x] Services expose clear error states (no silent failures)
  - Failed deployments reported in GitHub Actions UI with exit codes
  - PR comments include deployment status (success/failure)
  - Build artifacts preserved on failure for debugging
- [x] Retry/backoff strategies specified where needed
  - Firebase Hosting API includes built-in retry logic (firebase-tools handles this)
  - GitHub Actions supports workflow re-run for transient failures
  - No custom retry needed (infrastructure layer, not application code)
- [x] Integration tests planned for error/fallback flows
  - Quickstart includes deployment validation steps
  - Contract tests validate GitHub Actions workflow schema
  - Manual testing procedures documented in FIREBASE_DEPLOYMENT.md

### Development Principles Alignment
- [x] "Fail visible, not silent" - loading/error/cached states planned
  - Deployment failures visible in GitHub Actions UI and PR comments
  - Build script echoes progress messages (🔑 Injecting API key, 🔨 Building, ✅ Complete)
- [x] "Fallbacks, not blanks" - cached/mock fallbacks with clear labels
  - N/A for CI/CD infrastructure (no data fallbacks)
  - Failed deployments preserve previous production version (zero-downtime)
- [x] "Keep logs clean" - structured logging, no PII
  - Build script uses echo with emoji prefixes for structured output
  - API keys masked in logs, no coordinate logging in CI
- [x] "Single source of truth" - colors/thresholds in constants with tests
  - GitHub Secrets are single source of truth for API keys
  - firebase.json is single source of truth for hosting configuration
- [x] "Mock-first dev" - UI components support mock data injection
  - N/A for CI/CD infrastructure
  - Build script supports local testing with env vars

## Project Structure

### Documentation (this feature)
```
specs/012-a11-ci-cd/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output - best practices for Firebase CI/CD
├── data-model.md        # Phase 1 output - deployment event data model
├── quickstart.md        # Phase 1 output - deployment testing procedures
├── contracts/           # Phase 1 output - GitHub Actions workflow schemas
│   ├── workflow-schema.yml     # GitHub Actions workflow contract
│   ├── build-script-contract.sh # Build script API contract
│   └── firebase-config-schema.json # firebase.json validation schema
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Single Flutter project with web target (existing structure extended)
.github/
├── workflows/
│   └── flutter.yml      # MODIFIED - Add deploy-preview and deploy-production jobs
├── copilot-instructions.md # MODIFIED - Add A11 CI/CD guidelines
└── PULL_REQUEST_TEMPLATE.md # (existing, unchanged)

scripts/
├── build_web.sh         # (existing, unchanged) - Local development builds
├── build_web_ci.sh      # NEW - CI-specific build script with env var API key injection
└── run_web.sh           # (existing, unchanged)

web/
├── index.html           # MODIFIED - Replace hardcoded API key with %MAPS_API_KEY% placeholder
├── manifest.json        # (existing, unchanged)
└── favicon.png          # (existing, unchanged)

docs/
├── FIREBASE_DEPLOYMENT.md # NEW - Deployment runbook (procedures, rollback, troubleshooting)
├── API_KEY_SETUP.md     # (existing, may need update)
└── SESSION_SUMMARY_*.md # (existing, unchanged)

# Firebase configuration (existing, may need validation)
firebase.json            # (existing) - Verify SPA rewrites and cache headers
.firebaserc              # (existing) - Verify project ID

# Environment files (unchanged)
env/
├── dev.env.json.template # (existing) - Local development template
└── dev.env.json         # (gitignored) - Local development secrets
```

**Structure Decision**: Single Flutter project structure with web target. CI/CD components integrate into existing .github/workflows/ and scripts/ directories. No new source code directories needed—all changes are workflow automation, build tooling, and documentation. This aligns with "extend existing infrastructure" rather than "new feature implementation."

## Phase 0: Outline & Research
**Status**: ✅ COMPLETE

1. **Extracted unknowns from Technical Context**: None (all prerequisites completed)

2. **Research tasks completed**:
   - ✅ Firebase Hosting Channel Deployments (PR Previews) → FirebaseExtended/action-hosting-deploy
   - ✅ API Key Injection in CI/CD Builds → Placeholder replacement with sed pattern
   - ✅ GitHub Actions Job Dependencies and Artifact Sharing → needs: + upload/download-artifact
   - ✅ GitHub Environments for Production Approval → Environment protection rules
   - ✅ SPA Routing Configuration for go_router → Firebase rewrites
   - ✅ Rollback Strategies for Production Deployments → Multi-tiered approach

3. **Consolidated findings** in `research.md`:
   - Decision: Use Firebase Hosting Channels with GitHub Actions
   - Rationale: Official Firebase action, built-in preview URLs, auto-cleanup
   - Alternatives considered: Manual CLI, Netlify, custom Docker

**Output**: ✅ research.md with 6 research areas, all decisions documented

## Phase 1: Design & Contracts
**Status**: ✅ COMPLETE

1. **Extracted entities from feature spec** → `data-model.md`:
   - ✅ GitHub Actions Workflow Configuration (YAML schema)
   - ✅ Build Artifact (build/web/ directory structure)
   - ✅ Firebase Hosting Channel (preview vs live)
   - ✅ GitHub Secret (4 required secrets)
   - ✅ GitHub Environment (production with approval)
   - ✅ Deployment Event (metadata tracking)

2. **Generated API contracts** from functional requirements:
   - ✅ `/contracts/workflow-schema.yml` - GitHub Actions workflow contract
     - Job 1: test (existing, preserved constitutional gates)
     - Job 2: build-web (NEW - artifact creation with API key injection)
     - Job 3: deploy-preview (NEW - PR preview channels)
     - Job 4: deploy-production (NEW - production with approval)
   - ✅ `/contracts/build-script-contract.sh` - Build script interface contract
     - Input: MAPS_API_KEY_WEB environment variable
     - Output: build/web/ artifact, exit codes, cleanup guarantee

3. **Generated contract tests** from contracts:
   - ✅ Unit tests: Test 1-5 in build-script-contract.sh
     - Test 1: Missing API key (expect exit 1)
     - Test 2: Missing placeholder (expect exit 1)
     - Test 3: Successful build (expect exit 0, artifact created)
     - Test 4: Build failure rollback (expect exit 1, cleanup)
     - Test 5: Cleanup validation (expect placeholder restored)
   - ✅ Integration tests: Documented in workflow-schema.yml
     - Test failed gates block deployment
     - Test PR preview auto-deploys
     - Test production requires approval
   - ✅ Smoke tests: Documented in workflow-schema.yml
     - Test preview URL returns 200
     - Test deep link /map works
     - Test no watermark (API key working)

4. **Extracted test scenarios** from user stories:
   - ✅ Scenario 1: Local Build Script Validation (5 min)
   - ✅ Scenario 2: PR Preview Deployment (10 min)
   - ✅ Scenario 3: Production Deployment with Approval (10 min)
   - ✅ Scenario 4: Failed Tests Block Deployment (5 min)
   - ✅ Scenario 5: Rollback Production Deployment (5 min)
   - ✅ Scenario 6: API Key Rotation (5 min)

5. **Update agent file incrementally**:
   - 📝 Pending: Run `.specify/scripts/bash/update-agent-context.sh copilot` after plan completion

**Output**: ✅ data-model.md (6 entities), contracts/ (2 files), quickstart.md (6 scenarios)

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:

1. **Contract Implementation Tasks** (from contracts/):
   - Task: Modify .github/workflows/flutter.yml
     - Preserve existing test job (constitutional gates C1-C5)
     - Add build-web job with API key injection
     - Add deploy-preview job with Firebase action
     - Add deploy-production job with environment: production
     - Priority: [P1] (foundational, blocks all deployment tasks)
   
   - Task: Create scripts/build_web_ci.sh
     - Implement API key injection with sed replacement
     - Add input validation (exit 1 on missing key)
     - Add cleanup logic (restore original web/index.html)
     - Add masked logging (C2 compliance)
     - Priority: [P1] (required by build-web job)
   
   - Task: Modify web/index.html
     - Replace hardcoded API key with %MAPS_API_KEY% placeholder
     - Verify placeholder location matches sed pattern
     - Priority: [P1] (required by build_web_ci.sh)

2. **Entity Implementation Tasks** (from data-model.md):
   - Task: Create docs/FIREBASE_DEPLOYMENT.md
     - Document deployment procedures (preview, production)
     - Document rollback procedures (Console, CLI, git)
     - Document troubleshooting guide
     - Document API key rotation procedures
     - Priority: [P2] (documentation, can parallel with testing)

3. **Test Implementation Tasks** (from quickstart.md):
   - Task: Create test/scripts/build_web_ci_test.sh
     - Implement Test 1: Missing API key validation
     - Implement Test 2: Missing placeholder validation
     - Implement Test 3: Successful build validation
     - Implement Test 4: Build failure rollback validation
     - Implement Test 5: Cleanup validation
     - Priority: [P2] (validation, can parallel with workflow)
   
   - Task: Execute Quickstart Scenario 1 (Local Build)
     - Run build_web_ci.sh with test key
     - Verify artifact created, placeholder restored
     - Priority: [P3] (depends on build script implementation)
   
   - Task: Execute Quickstart Scenario 2 (PR Preview)
     - Create test PR, verify preview URL posted
     - Test deep link, map loading
     - Priority: [P4] (depends on workflow implementation)
   
   - Task: Execute Quickstart Scenario 3 (Production)
     - Merge PR, verify approval required
     - Approve deployment, verify production updated
     - Priority: [P4] (depends on workflow + environment setup)

4. **Agent Context Update Task**:
   - Task: Update .github/copilot-instructions.md
     - Run `.specify/scripts/bash/update-agent-context.sh copilot`
     - Add A11 CI/CD guidelines (deployment commands, troubleshooting)
     - Preserve existing A1-A10 content
     - Priority: [P2] (documentation, parallel with implementation)

**Ordering Strategy**:
- **Phase 1: Foundation** (P1 - Sequential)
  1. Modify web/index.html (prerequisite for build script)
  2. Create scripts/build_web_ci.sh (prerequisite for workflow)
  3. Modify .github/workflows/flutter.yml (orchestrates all)
  
- **Phase 2: Validation** (P2 - Parallel)
  4. Create test/scripts/build_web_ci_test.sh [P]
  5. Create docs/FIREBASE_DEPLOYMENT.md [P]
  6. Update .github/copilot-instructions.md [P]

- **Phase 3: Testing** (P3-P4 - Sequential, depends on P1-P2)
  7. Execute Quickstart Scenario 1 (local)
  8. Execute Quickstart Scenario 2 (PR preview)
  9. Execute Quickstart Scenario 3 (production)
  10. Execute Quickstart Scenario 4 (failed tests)
  11. Execute Quickstart Scenario 5 (rollback)
  12. Execute Quickstart Scenario 6 (key rotation)

**Estimated Output**: ~12 tasks total
- 3 implementation tasks (P1 - sequential)
- 3 documentation/testing tasks (P2 - parallel)
- 6 validation scenario tasks (P3-P4 - sequential)

**Complexity Notes**:
- No new Dart/Flutter code (infrastructure only)
- Workflow modification preserves existing jobs (extend, not replace)
- Build script simple bash (no dependencies beyond Flutter SDK)
- Testing mostly integration tests (actual deployments)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

**No constitutional violations identified**. All checks passed:
- ✅ C1: Existing CI checks preserved, tests required before deployment
- ✅ C2: API keys in GitHub Secrets, masked logging, placeholder pattern
- ✅ C3: N/A (no UI components)
- ✅ C4: N/A (no risk display)
- ✅ C5: Timeout, error handling, zero-downtime rollback

**No complexity deviations required**. Implementation uses:
- Standard GitHub Actions patterns (official Firebase action)
- Simple bash script (sed replacement, no complex logic)
- Existing Flutter build tooling (no custom compilation)
- Firebase Hosting managed service (no custom infrastructure)

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | (none) | (none) |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - ✅ 2025-10-27
- [x] Phase 1: Design complete (/plan command) - ✅ 2025-10-27
- [x] Phase 2: Task planning complete (/plan command - describe approach only) - ✅ 2025-10-27
- [ ] Phase 3: Tasks generated (/tasks command) - Pending
- [ ] Phase 4: Implementation complete - Pending
- [ ] Phase 5: Validation passed - Pending

**Gate Status**:
- [x] Initial Constitution Check: PASS - ✅ 2025-10-27
- [x] Post-Design Constitution Check: PASS - ✅ 2025-10-27
- [x] All NEEDS CLARIFICATION resolved - ✅ None present (prerequisites completed)
- [x] Complexity deviations documented - ✅ None required

**Artifacts Generated**:
- [x] research.md (6 research areas, all decisions documented)
- [x] data-model.md (6 entities with schemas, validation rules, lifecycles)
- [x] contracts/workflow-schema.yml (4 job contracts with validation tests)
- [x] contracts/build-script-contract.sh (5 validation tests, security/performance contracts)
- [x] quickstart.md (6 test scenarios, 40 minutes total, validation checklist)

**Next Action**: Run `/tasks` command to generate tasks.md from this plan

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
