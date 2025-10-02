# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup
- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools (C1: Code Quality)
- [ ] T004 [P] Configure flutter analyze and dart format in CI (C1: Code Quality)
- [ ] T005 [P] Set up secret scanning with gitleaks (C2: Secrets & Logging)
- [ ] T006 [P] Configure .env template for runtime secrets (C2: Secrets & Logging)

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T007 [P] Contract test POST /api/users in tests/contract/test_users_post.py
- [ ] T008 [P] Contract test GET /api/users/{id} in tests/contract/test_users_get.py
- [ ] T009 [P] Integration test user registration in tests/integration/test_registration.py
- [ ] T010 [P] Integration test auth flow in tests/integration/test_auth.py
- [ ] T011 [P] Widget tests with ≥44dp touch target validation (C3: Accessibility)
- [ ] T012 [P] Integration tests for error/fallback flows (C5: Resilience)

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T013 [P] User model in src/models/user.py
- [ ] T014 [P] UserService CRUD in src/services/user_service.py
- [ ] T015 [P] CLI --create-user in src/cli/user_commands.py
- [ ] T016 POST /api/users endpoint
- [ ] T017 GET /api/users/{id} endpoint
- [ ] T018 Input validation
- [ ] T019 Error handling with visible error states (C5: Resilience)
- [ ] T020 [P] Official color constants from risk palette (C4: Trust & Transparency)
- [ ] T021 [P] Timestamp and source labeling components (C4: Trust & Transparency)
- [ ] T022 [P] Structured logging without PII (C2: Secrets & Logging)

## Phase 3.4: Integration
- [ ] T023 Connect UserService to DB
- [ ] T024 Auth middleware
- [ ] T025 Request/response logging with coordinate precision limits (C2: Secrets & Logging)
- [ ] T026 CORS and security headers
- [ ] T027 [P] Network timeout and retry/backoff implementation (C5: Resilience)
- [ ] T028 [P] Semantic labels for screen readers (C3: Accessibility)

## Phase 3.5: Polish
- [ ] T029 [P] Unit tests for validation in tests/unit/test_validation.py
- [ ] T030 Performance tests (<200ms)
- [ ] T031 [P] Update docs/api.md
- [ ] T032 Remove duplication
- [ ] T033 Run manual-testing.md
- [ ] T034 [P] Color guard script validation (C4: Trust & Transparency)
- [ ] T035 [P] Mock data injection support for UI components (Principle: Mock-first dev)
- [ ] T036 [P] Fallback state UI with clear labeling (Principle: Fallbacks, not blanks)

## Dependencies
- Setup (T001-T006) before everything
- Tests (T007-T012) before implementation (T013-T022)
- Constitutional compliance tasks (C1-C5) integrated throughout phases
- T008 blocks T009, T015
- T016 blocks T018
- Implementation before polish (T019-T023)

## Parallel Example
```
# Launch T004-T007 together:
Task: "Contract test POST /api/users in tests/contract/test_users_post.py"
Task: "Contract test GET /api/users/{id} in tests/contract/test_users_get.py"
Task: "Integration test registration in tests/integration/test_registration.py"
Task: "Integration test auth in tests/integration/test_auth.py"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task