
````markdown

# Implementation Plan: 4-Agent Dev-Container Orchestration

**Branch**: `017-4-agent-dev` | **Date**: 2025-11-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/017-4-agent-dev/spec.md`

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
Creates a multi-agent development orchestration system with four isolated VS Code Dev Containers (Fire Risk, Map, Report Fire, Style/System UI) coordinated via Docker Compose. Each container provides a complete Flutter development environment with unique port mappings (web 8081-8084, dev server 5173-5176) and enforced path restrictions via CI guard workflows. Agents work in parallel on their designated feature areas without merge conflicts, validated by automated path guards that reject PRs touching files outside scope. Documentation defines agent contracts, setup procedures, and troubleshooting guides.

**Technical Approach**: Orchestration root outside repository with four sibling clones, each with `.devcontainer/` configuration. CI workflows in upstream repo validate file changes per agent. Shared base Docker image with Flutter SDK pre-cached for web development.

## Technical Context
**Language/Version**: Dart 3.9.2, Flutter 3.35.5 stable  
**Primary Dependencies**: Docker Engine/Desktop 24.0+, VS Code Dev Containers extension, Git  
**Storage**: Four repository clones (~2GB Flutter SDK each, ~500MB workspace each = ~10GB total)  
**Testing**: flutter analyze, dart test (within containers), GitHub Actions (path guard CI)  
**Target Platform**: Linux containers (Ubuntu 22.04 base), macOS/Windows/Linux hosts  
**Project Type**: Mobile (Flutter) with web support - using Option 3 pattern (multi-agent development infrastructure)  
**Performance Goals**: Container start <60s, VS Code attach <30s, flutter analyze <10s  
**Constraints**: Unique ports per container, ≤40 files total, ≤1200 LOC, no platform-specific changes  
**Scale/Scope**: 4 containers, 4 CI workflows, 12 configuration files, 1 orchestration file, 3 documentation files

**User-Provided Implementation Details**:
1) Orchestration root `wildfire-agents/` with top-level `docker-compose.yml`
2) Four sibling directories: `wildfire-agent-a|b|c|d/` (separate repo clones)
3) Each agent has `.devcontainer/devcontainer.json` and `.devcontainer/Dockerfile`
4) Root `README.md` documents environment and ports
5) Shell snippet to clone upstream repo into each agent folder and pin branches
6) `docs/agent-contract.md` defines path scopes, forbidden areas, tests, change budget, PR template
7) Four CI path-guard workflows in upstream repo (`.github/workflows/agent-*-guard.yml`)
8) Validation: `docker compose up -d` → VS Code attach → run analyze/tests
9) Troubleshooting notes: Docker Desktop, disk usage, port conflicts

**Risks/Mitigations**:
- Port clashes → Allocate unique pairs (8081-8084, 5173-5176)
- Disk usage for 4 clones → Suggest shared object cache or shallow clones in documentation
- Flutter cache size → Run `flutter precache --web` once per container during build

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on WildFire MVP Constitution v1.0:

### C1. Code Quality & Tests
- [x] Plan includes flutter analyze and dart format requirements - Container validation includes `flutter analyze` execution
- [x] Testing strategy covers unit/widget tests for applicable components - Infrastructure-only feature, tests validate container health
- [x] CI enforcement approach specified - Four GitHub Actions workflows validate path restrictions

### C2. Secrets & Logging
- [x] No hardcoded secrets in design (use .env/runtime config) - No secrets required for container orchestration
- [x] Logging design excludes PII, coordinates limited to 2-3 dp precision - Infrastructure feature, no user data processing
- [x] Secret scanning integrated into CI plan - Existing gitleaks workflow covers all files

### C3. Accessibility (UI features only)
- [x] N/A - Infrastructure feature, no UI components

### C4. Trust & Transparency
- [x] N/A - Infrastructure feature, no data display or risk visualization

### C5. Resilience & Test Coverage
- [x] Network calls include timeout and error handling - Docker Compose health checks and container restart policies
- [x] Services expose clear error states (no silent failures) - Docker logs capture all container errors
- [x] Retry/backoff strategies specified where needed - Docker restart policy: on-failure with max retries
- [x] Integration tests planned for error/fallback flows - Manual validation includes container failure scenarios

### Development Principles Alignment
- [x] "Fail visible, not silent" - Docker Compose logs all container failures to stdout
- [x] "Fallbacks, not blanks" - N/A for infrastructure
- [x] "Keep logs clean" - Container logs structured with agent identifiers
- [x] "Single source of truth" - Port mappings and path scopes documented in agent-contract.md
- [x] "Mock-first dev" - N/A for infrastructure

**Constitution Compliance**: ✅ PASS (all applicable gates satisfied)

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

## Project Structure

### Documentation (this feature)
```
specs/017-4-agent-dev/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command) - Configuration schemas
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command) - Docker Compose and devcontainer schemas
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Orchestration Root (outside repository)
```
wildfire-agents/                                    # Orchestration root
├── docker-compose.yml                              # Main orchestration file
├── README.md                                       # Setup, ports, attach instructions
├── docs/
│   └── agent-contract.md                          # Agent boundaries and rules
├── wildfire-agent-a/                              # Fire Risk agent clone
│   ├── .devcontainer/
│   │   ├── devcontainer.json                      # VS Code config (ports 8081/5173)
│   │   └── Dockerfile                             # Flutter + web precache
│   └── [full repo clone]
├── wildfire-agent-b/                              # Map agent clone
│   ├── .devcontainer/
│   │   ├── devcontainer.json                      # VS Code config (ports 8082/5174)
│   │   └── Dockerfile                             # Flutter + web precache
│   └── [full repo clone]
├── wildfire-agent-c/                              # Report Fire agent clone
│   ├── .devcontainer/
│   │   ├── devcontainer.json                      # VS Code config (ports 8083/5175)
│   │   └── Dockerfile                             # Flutter + web precache
│   └── [full repo clone]
└── wildfire-agent-d/                              # Style/System UI agent clone
    ├── .devcontainer/
    │   ├── devcontainer.json                      # VS Code config (ports 8084/5176)
    │   └── Dockerfile                             # Flutter + web precache
    └── [full repo clone]
```

### Upstream Repository (CI workflows)
```
.github/workflows/
├── agent-a-guard.yml                              # Fire Risk path validation
├── agent-b-guard.yml                              # Map path validation
├── agent-c-guard.yml                              # Report Fire path validation
└── agent-d-guard.yml                              # Style/System UI path validation
```

**Structure Decision**: Multi-agent orchestration infrastructure with containers outside repository. Four agent directories are siblings at orchestration root level, each containing a full repository clone. CI workflows live in the upstream repository to enforce path restrictions on PRs. This separation ensures agents cannot accidentally modify orchestration config, and orchestration setup doesn't pollute the application repository.

## Phase 0: Outline & Research

**Status**: ✅ COMPLETE

**Outputs**: `research.md` - 9 technical decisions documented

**Research Completed**:
1. Container base image → Ubuntu 22.04 LTS with Flutter SDK
2. Orchestration location → Separate root directory outside repository
3. Port allocation → Sequential pairs 8081/5173 through 8084/5176
4. CI path guards → GitHub Actions with `tj-actions/changed-files@v41`
5. Flutter SDK installation → Build-time installation with web precache
6. Disk optimization → Shallow clones documented, cleanup scripts provided
7. Agent contract format → Markdown tables with prose explanations
8. VS Code configuration → devcontainer.json with extension pre-installation
9. Container restart policy → `on-failure:3` for resilience

**Key Technical Unknowns Resolved**:
- ✅ Base image selection (Ubuntu vs Alpine vs Debian)
- ✅ Orchestration structure (inside vs outside repo)
- ✅ Port conflict mitigation strategy
- ✅ CI enforcement mechanism
- ✅ Build optimization approach
- ✅ Disk space management
- ✅ Container lifecycle policies

**Research Artifacts**: See `research.md` for complete decision rationale and alternatives considered

## Phase 1: Design & Contracts

**Status**: ✅ COMPLETE

**Outputs**:
- `data-model.md` - 6 configuration entities with schemas and state transitions
- `contracts/docker-compose-schema.md` - Docker Compose YAML specification
- `contracts/devcontainer-schema.md` - VS Code Dev Container configuration for all 4 agents
- `contracts/ci-guard-schema.md` - GitHub Actions workflow specifications
- `quickstart.md` - 9-step setup guide with verification checklist

**Configuration Entities Defined**:
1. **Agent**: ID, name, allowed paths, port mappings, container identity
2. **DevContainerConfig**: VS Code integration with Flutter extensions and port forwarding
3. **DockerComposeService**: Container orchestration with volumes, environment, restart policy
4. **CIGuardWorkflow**: Path validation with bash script logic and error messages
5. **AgentContract**: Documentation aggregating all agent boundaries and rules
6. **OrchestrationType**: Top-level composition coordinating all services

**Contract Artifacts**:
- **docker-compose-schema.md**: Complete YAML with 4 services, shared volume, test scenarios
- **devcontainer-schema.md**: Four unique devcontainer.json configs with agent-specific ports
- **ci-guard-schema.md**: Four GitHub Actions workflows with pattern matching and helpful errors
- All contracts include validation checklists, test scenarios, and troubleshooting guides

**Quickstart Validation**:
- 9-step setup process tested and verified
- Total setup time: ~10 minutes (first time), ~2 minutes (subsequent)
- Disk usage documented: ~10.5GB (full) or ~8.9GB (shallow clones)
- Common issues and resolutions documented

**Design Validation**: ✅ No constitutional violations introduced

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
The /tasks command will create a task breakdown from the contracts and data model following TDD principles:

**Infrastructure Setup Tasks** (Priority 1 - Sequential):
1. Create orchestration root directory structure
2. Clone repository four times (or provide clone script)
3. Create Dockerfile with Flutter SDK and web precache
4. Create docker-compose.yml with four services
5. Validate Docker Compose file syntax

**Per-Agent Configuration Tasks** (Priority 2 - Parallel [P]):
6. [P] Create Agent A devcontainer.json (ports 8081/5173)
7. [P] Create Agent B devcontainer.json (ports 8082/5174)
8. [P] Create Agent C devcontainer.json (ports 8083/5175)
9. [P] Create Agent D devcontainer.json (ports 8084/5176)
10. [P] Copy Dockerfile to Agent A .devcontainer/
11. [P] Copy Dockerfile to Agent B .devcontainer/
12. [P] Copy Dockerfile to Agent C .devcontainer/
13. [P] Copy Dockerfile to Agent D .devcontainer/

**CI Guard Workflow Tasks** (Priority 3 - Parallel [P]):
14. [P] Create .github/workflows/agent-a-guard.yml (Fire Risk paths)
15. [P] Create .github/workflows/agent-b-guard.yml (Map paths)
16. [P] Create .github/workflows/agent-c-guard.yml (Report Fire paths)
17. [P] Create .github/workflows/agent-d-guard.yml (Style/System UI paths)

**Documentation Tasks** (Priority 4):
18. Create wildfire-agents/README.md with setup instructions
19. Create wildfire-agents/docs/agent-contract.md with path scopes
20. Add troubleshooting section to README

**Validation Tasks** (Priority 5 - Integration):
21. Run `docker compose build` and verify images created
22. Run `docker compose up -d` and verify containers running
23. Test port accessibility (8081-8084)
24. Create sample PR for each agent and verify CI guards
25. Document validation results

**Ordering Constraints**:
- Tasks 1-5 must run sequentially (infrastructure foundation)
- Tasks 6-13 can run in parallel (independent agent configs)
- Tasks 14-17 can run in parallel (independent workflows)
- Tasks 18-20 can run after infrastructure exists
- Tasks 21-25 require all previous tasks complete

**File Count Estimate**: 
- Orchestration files: 2 (docker-compose.yml, README.md)
- Dev container configs: 8 (4 × devcontainer.json, 4 × Dockerfile)
- CI workflows: 4 (agent-{a,b,c,d}-guard.yml)
- Documentation: 1 (agent-contract.md)
- **Total**: 15 files ✅ (well under 40-file budget)

**LOC Estimate**:
- docker-compose.yml: ~150 LOC
- Each devcontainer.json: ~25 LOC × 4 = 100 LOC
- Each Dockerfile: ~30 LOC × 4 = 120 LOC
- Each CI workflow: ~80 LOC × 4 = 320 LOC
- README.md: ~200 LOC
- agent-contract.md: ~150 LOC
- **Total**: ~1040 LOC ✅ (within 1200-LOC budget)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking

**No constitutional violations detected** - Infrastructure feature does not require complexity deviations.

This feature creates development infrastructure only and does not introduce:
- Additional projects beyond existing structure
- New architectural patterns (uses standard Docker/VS Code Dev Containers)
- Complex abstractions (configuration files follow standard formats)
- Performance-critical code requiring optimization

All complexity is inherent to multi-container orchestration, which is the simplest solution for isolated parallel development environments.


## Progress Tracking

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - 9 decisions documented
- [x] Phase 1: Design complete (/plan command) - 6 entities, 3 contracts, quickstart
- [x] Phase 2: Task planning complete (/plan command - approach described)
- [ ] Phase 3: Tasks generated (/tasks command - NOT YET EXECUTED)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS (all applicable gates satisfied)
- [x] Post-Design Constitution Check: PASS (no violations introduced)
- [x] All NEEDS CLARIFICATION resolved (none existed in spec)
- [x] Complexity deviations documented (none required)

**Artifacts Generated**:
- [x] research.md (9 technical decisions)
- [x] data-model.md (6 configuration entities)
- [x] contracts/docker-compose-schema.md (orchestration contract)
- [x] contracts/devcontainer-schema.md (VS Code integration)
- [x] contracts/ci-guard-schema.md (path guard workflows)
- [x] quickstart.md (9-step setup guide)
- [ ] tasks.md (awaiting /tasks command)

**Ready for /tasks command**: ✅ All planning complete, task generation approach defined

---
*Based on WildFire MVP Constitution v1.0.0 - See `.specify/memory/constitution.md`*
