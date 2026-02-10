---
title: New Feature Workflow
status: active
last_updated: 2026-02-10
category: guides
subcategory: development
related:
  - .github/skills/feature-scaffold.md
  - .github/skills/theme-and-style.md
  - .github/skills/testing-patterns.md
  - .github/PULL_REQUEST_TEMPLATE.md
  - .specify/memory/constitution.md
---

# New Feature Workflow

> Lightweight, plan-mode workflow for creating new features in WildFire MVP.  
> Replaces the previous 7-step `.specify` workflow with a faster, skill-driven approach.

---

## Overview

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────────┐
│  1. Brief    │───▶│  2. Plan &   │───▶│  3. Implement│───▶│  4. Ship     │
│  (you, 5min) │    │  Approve     │    │  & Test      │    │  (PR + CI)   │
└─────────────┘    └──────────────┘    └──────────────┘    └─────────────┘
     Write a            Agent plans        Agent builds         Pre-commit
     short brief         approach,          with skills          hooks,
     in specs/           you approve        loaded               CI gates,
                                                                 PR review
```

**Total time to first working code: ~2 agent turns** (vs. 6 with `.specify`).

---

## Step 1: Write a Feature Brief (5 minutes)

Create a short file in `specs/`:

```
specs/025-feature-name.md
```

Contents — keep it short:

```markdown
# Feature: [Name]

## What
2-3 sentences describing the feature.

## Why
The user problem this solves.

## Acceptance Criteria
- [ ] Given [state], when [action], then [result]
- [ ] Given [state], when [action], then [result]
- [ ] Given [error case], then [graceful handling]

## Constraints (if any)
- Must work offline / Scotland-only / etc.
- Performance: loads in < Xs
```

**That's it.** No templates, no clarification rounds. You know your product.

---

## Step 2: Plan & Approve (Plan Mode)

Open VS Code Copilot in **plan mode** and reference your brief:

> "I want to implement the feature described in `specs/025-feature-name.md`. Please plan the approach."

The agent will:
1. Read your brief
2. **Automatically load skills** from `.github/skills/`:
   - `feature-scaffold.md` — knows your directory structure, controller/state/screen patterns
   - `theme-and-style.md` — knows your theme system, color rules, accessibility requirements
   - `testing-patterns.md` — knows your test structure, mock patterns, const rules
3. Propose file structure, architecture approach, and implementation steps
4. You review and adjust before any code is written

**Tips for the plan step:**
- Be specific about edge cases you care about
- Mention if it integrates with existing services (e.g., "uses LocationResolver")
- Flag any non-obvious requirements ("needs to work in dark mode")

---

## Step 3: Implement & Test

Switch to act/agent mode and say:

> "Implement the plan."

The agent will:
- Create files following your established patterns (from skills)
- Use `Theme.of(context).colorScheme.*` — never ad-hoc colors
- Use sealed states with Equatable
- Use ChangeNotifier controllers with DI
- Write tests with const data, proper mocks, correct structure
- Add the route to `app.dart`

**During implementation**, the agent should:
- Run `flutter analyze` after creating files
- Run `flutter test test/unit/features/<name>/` to validate tests
- Fix any issues before moving on

---

## Step 4: Ship (PR + CI)

### Local pre-commit checks (automatic)

When you commit, git hooks run automatically:

| Hook | What it does |
|------|-------------|
| `pre-commit` | Scans for API keys in staged files |
| `commit-msg` | Validates conventional commit format |
| `pre-push` | Runs gitleaks secret scan |

### Commit message format

```
feat(map): add polygon toggle button
fix(onboarding): handle back button on consent page
test(report): add integration tests for location picker
docs: update deployment workflow
refactor(services): extract cache timeout logic
```

### Create PR

```bash
git checkout -b feature/025-feature-name
git add -A
git commit -m "feat(feature): short description"
git push origin feature/025-feature-name
```

Then create PR — the template at `.github/PULL_REQUEST_TEMPLATE.md` auto-loads with the C1–C5 checklist.

### CI gates (automatic)

The `flutter.yml` workflow runs:

| Gate | Checks |
|------|--------|
| **C1** | `dart format`, `flutter analyze`, `flutter test` |
| **C2** | Gitleaks secret scan, hardcoded secret grep |
| **C3** | Semantics/accessibility heuristics |
| **C4** | Color guard (no ad-hoc `Colors.*` or unapproved hex), timestamp/source checks |
| **C5** | Error handling pattern detection, retry/fallback grep |

### PR review

Use the C1–C5 checklist in the PR template. Focus manual review on:
- C3 (accessibility) — hard to automate fully
- C4 (trust) — visual check of timestamps and source labels
- UX quality — does it feel right?

---

## Quick Reference: What Goes Where

| What you're creating | Where it goes |
|---------------------|--------------|
| Controller | `lib/features/<name>/controllers/<name>_controller.dart` |
| State | `lib/features/<name>/models/<name>_state.dart` |
| Screen | `lib/features/<name>/screens/<name>_screen.dart` |
| Feature widgets | `lib/features/<name>/widgets/` |
| Shared service | `lib/services/<name>_service.dart` + `<name>_service_impl.dart` |
| Shared model | `lib/models/<name>.dart` |
| Shared widget | `lib/widgets/<name>.dart` |
| Route | `lib/app.dart` (GoRoute entry) |
| Unit tests | `test/unit/features/<name>/` |
| Widget tests | `test/widget/<name>/` |
| Integration tests | `test/integration/<name>/` or `test/integration/<name>_flow_test.dart` |

---

## What Changed from `.specify` Workflow

| Before (`.specify`) | After (Plan Mode + Skills) |
|---------------------|---------------------------|
| 7 sequential steps (specify → clarify → plan → tasks → analyze → implement) | 2 steps (plan → implement) |
| Generated spec.md, plan.md, tasks.md, data-model.md, contracts/ | One brief file written by you |
| Agent lost context between steps | Single conversation, full context |
| Rigid template-driven | Flexible, skill-informed |
| ~6 agent turns before any code | ~2 turns to working code |
| `.specify/` prompts as entry points | Plan mode + skills loaded automatically |

**The `.specify/` directory and prompts are retained** as optional reference material. The constitution (`C1–C5`) is still enforced via CI and PR template — nothing changes there.

---

## Automation Summary

### Git Hooks (local, instant feedback)

| Hook | File | Purpose |
|------|------|---------|
| `pre-commit` | `.git/hooks/pre-commit` | Block commits with API keys |
| `commit-msg` | `.git/hooks/commit-msg` | Enforce conventional commits |
| `pre-push` | `.git/hooks/pre-push` | Gitleaks secret scan |

### Analyzer Rules (IDE + CI)

`analysis_options.yaml` enforces:
- `avoid_print` — use `debugPrint()` or `developer.log()`
- `prefer_const_constructors` — performance + immutability
- `prefer_const_declarations` — const over final for constants
- `prefer_const_literals_to_create_immutables` — `const []` not `[]`
- `prefer_single_quotes` — style consistency
- `sort_child_properties_last` — child always last in widgets
- `use_build_context_synchronously` — prevent stale context bugs
- Plus safety rules for subscriptions, sinks, null returns

### CI Pipeline (GitHub Actions)

`flutter.yml` runs on every push/PR:
- Format check, analyze, test (C1)
- Secret scan with gitleaks (C2)
- Accessibility heuristics (C3)
- Color guard scripts (C4)
- Error handling detection (C5)
- iOS build phase verification
- Web build + Firebase deploy (preview/staging/production)

### Agent Skills (`.github/skills/`)

| Skill | Purpose |
|-------|---------|
| `feature-scaffold.md` | Directory structure, controller/state/screen patterns, routing |
| `theme-and-style.md` | Color rules, accessibility, Material 3 components, dark mode |
| `testing-patterns.md` | Test structure, mock patterns, const data, binding init |
