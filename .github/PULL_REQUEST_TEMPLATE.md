# Pull Request — WildFire MVP

> Link the spec this PR implements and check all applicable boxes. Keep changes minimal and focused.

**Spec**: `A?-<name>.md`  
**Issue link**: #

## Summary
Explain *what* this PR does in 2–3 sentences and *why*. If UI, include a brief before/after.

## Screenshots / Demos
- [ ] Attached images or a short gif (light + dark mode)
- [ ] For Risk UI: include a screenshot per risk level if relevant

## How Tested
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated (if UI)
- [ ] Integration tests for error/fallback flows (if network/service)
- [ ] Manual QA steps documented below

**Manual QA Steps**
1.
2.
3.

---

## Constitution Gates

### C1 — Code Quality & Tests (CI enforced)
- [ ] `flutter analyze` passes
- [ ] `dart format --set-exit-if-changed` passes
- [ ] All tests pass (`flutter test`)

### C2 — Secrets & Logging (CI enforced)
- [ ] No hardcoded secrets/keys added
- [ ] Logs do not contain PII; coordinates rounded (2–3 dp)
- [ ] `.env` / runtime config used for secrets

### C3 — Accessibility (PR review)
- [ ] Interactive elements ≥44dp
- [ ] Semantic labels for screen readers
- [ ] Focus order & keyboard navigation sane (where applicable)

### C4 — Trust & Transparency (PR review)
- [ ] Official wildfire risk colors used (from constants)
- [ ] "Last updated" timestamp visible wherever data is shown
- [ ] Source chip/badge shown (EFFIS/SEPA/Cache/Mock)

### C5 — Resilience & Fallbacks (CI + PR review)
- [ ] Network calls have timeouts & error handling
- [ ] Retries/backoff implemented where spec requires
- [ ] Fallback paths covered by tests (e.g., EFFIS→SEPA→cache→mock)

---

## Backward Compatibility & Risks
- [ ] No breaking API changes, or changes documented below
- [ ] Migration notes included (if any)

**Breaking changes (if any):**

**Risk assessment / mitigations:**

---

## Rollout & Monitoring
- [ ] Feature flag or config guarded (if risky)
- [ ] Basic telemetry/structured logs added (latency, errors, cache hit rate)
- [ ] Revert plan stated below

**Revert plan:**

---

## Checklist (General)
- [ ] Scope limited to a single spec/feature
- [ ] Updated docs/comments where needed
- [ ] Added TODOs with issue links for follow-ups

> Reviewer: verify the above and leave a note on any Constitution Gate exceptions. Use "needs-followup" label if deferring non-blocking items.

