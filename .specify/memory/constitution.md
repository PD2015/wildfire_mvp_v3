<!--
Sync Impact Report:
- Version change: Template → 1.0.0
- Added Gates: C1 (Code Quality & Tests), C2 (Secrets & Logging), C3 (Accessibility), C4 (Trust & Transparency), C5 (Resilience & Test Coverage)
- Added Principles: 6 development principles for rapid prototyping
- Added sections: Purpose, Gates, Principles, Enforcement, PR Checklist, Definition of Done, Future Amendments
- Templates requiring updates: ✅ constitution.md updated
- Follow-up TODOs: None - all placeholders resolved
-->

# WildFire MVP Constitution

> Guardrails for rapid prototyping with GitHub Spec Kit. Lightweight but enforceable rules for Phase 0 prototype.

---

## Purpose
To provide **clear, minimal guardrails** for contributors building the WildFire MVP prototype. This ensures speed of iteration while maintaining baseline quality, accessibility, and trust.

The Constitution defines **Gates** (enforced automatically or via PR checklist) and **Principles** (guidance that developers must follow). It is not intended to be exhaustive or legally binding, but a shared agreement to keep the codebase safe and consistent.

---

## Gates (must pass)

### C1. Code Quality & Tests
- All code must pass `flutter analyze` and `dart format --set-exit-if-changed`.
- PRs must include unit tests or widget tests where applicable.
- CI will enforce both analyze/format/test.

### C2. Secrets & Logging
- No hardcoded secrets or API keys in the repository.
- All secrets configured via `.env` or runtime config.
- Logs must not contain PII. Coordinates logged only at 2–3 dp precision.
- Secret scan runs in CI; PR will fail if violation detected.

### C3. Accessibility (UI only)
- All interactive elements must:
  - Be ≥44dp touch target.
  - Have semantic labels for screen readers.
- A11y verified in widget tests and via PR checklist.

### C4. Trust & Transparency
- Only official Scottish wildfire risk colors used.
- All risk data displayed must include a **Last Updated** timestamp and a visible source label (e.g., EFFIS, SEPA, Cache, Mock).
- PRs adding UI must include proof of timestamp + color checks.

### C5. Resilience & Test Coverage
- Network calls must have a timeout and error handling.
- Services must expose clear error states, not swallow them.
- Retry/backoff strategies implemented where specified.
- Integration tests must cover error/fallback flows.

---

## Principles (should follow)
- **Fail visible, not silent:** Always show loading, error, or cached states clearly to users.
- **Fallbacks, not blanks:** If primary data fails, show cached/mock with clear labels.
- **Keep logs clean:** Use structured logging. No PII.
- **Single source of truth:** Colors, thresholds, and risk mapping live in constants and are unit-tested.
- **Mock-first dev:** UI components should support mock data injection for fast iteration.

---

## Enforcement
- **Automated (CI/Precommit):** C1, C2, C4, C5.
- **Manual (PR checklist):** C3 (Accessibility), sanity of timestamps/colors, adherence to Principles.

---

## PR Checklist (attached in `.github/PULL_REQUEST_TEMPLATE.md`)
- [ ] C1: Analyze/format/tests pass
- [ ] C2: No secrets, safe logging
- [ ] C3: Accessibility labels & 44dp targets
- [ ] C4: Official colors + timestamp visible (if UI)
- [ ] C5: Error handling + tests for fallbacks
- [ ] Principles: Fail visible, Fallbacks not blanks, Logs clean, Constants used

---

## Definition of Done (Prototype phase)
- Code merged only if all Gates pass.
- Reviewers verify Principles in PR comments.
- CI green is required.

---

## Future Amendments
- Constitution is **lightweight** and will evolve. For Phase 0, scope is prototype guardrails. Later versions may add compliance, analytics, security hardening.

## Governance
- Constitution supersedes all other practices and guides all development decisions.
- All PRs/reviews must verify compliance with Gates and Principles.
- Amendments require documentation, approval, and migration plan.
- Complexity deviations must be justified in implementation plans.

**Version**: 1.0.0 | **Ratified**: 2025-10-02 | **Last Amended**: 2025-10-02