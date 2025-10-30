# Documentation Strategy for WildFire MVP v3

**Last Updated**: 2025-10-30  
**Status**: Proposed  
**Owner**: Project Team

## Executive Summary

This document outlines a comprehensive documentation strategy based on industry best practices (Write the Docs, Google, Divio Documentation System) to manage the growing documentation set in this project, particularly in the context of AI agent-generated content.

## Current State Analysis

**Total Documentation**: 50+ markdown files (~500KB)

**Key Issues Identified**:
1. ⚠️ **Duplication**: 4 Google Maps setup guides, 8 security docs, 20+ testing docs
2. ⚠️ **Flat Structure**: Most docs in root `/docs` - hard to navigate
3. ⚠️ **Session Summaries**: Historical artifacts mixed with active documentation
4. ⚠️ **Naming Inconsistency**: `GOOGLE_MAPS_SETUP.md` vs `google-maps-setup.md`
5. ⚠️ **Unclear Lifecycle**: No clear process for archiving or deprecating docs

## Documentation Philosophy: Divio System

We adopt the [Divio Documentation System](https://documentation.divio.com/) which categorizes all documentation into 4 types:

| Type | Purpose | Audience | Example |
|------|---------|----------|---------|
| **Tutorials** | Learning-oriented | New developers | "Building your first feature" |
| **How-To Guides** | Problem-oriented | Practitioners | "How to add a new map layer" |
| **Reference** | Information-oriented | Lookup/recall | API docs, configuration reference |
| **Explanation** | Understanding-oriented | Context seekers | Architecture decisions, design rationale |

### Why This Matters for Agent-Generated Docs

AI agents often produce:
- ✅ Excellent **reference** documentation (API contracts, config files)
- ✅ Good **how-to guides** (step-by-step troubleshooting)
- ⚠️ Mixed **explanations** (sometimes missing "why")
- ❌ Rarely complete **tutorials** (need human curation)

## Proposed Documentation Structure

```
docs/
├── README.md                          # Documentation index + navigation
├── GETTING_STARTED.md                 # Quick start for new developers
│
├── tutorials/                         # Learning-oriented (curated)
│   ├── 01-your-first-feature.md
│   └── 02-testing-workflow.md
│
├── guides/                            # Problem-solving (how-to)
│   ├── setup/
│   │   ├── google-maps.md           # Consolidated Google Maps setup
│   │   ├── firebase.md
│   │   └── api-keys.md
│   ├── testing/
│   │   ├── integration-tests.md     # Consolidated testing guide
│   │   ├── platform-specific.md     # iOS/Android/Web
│   │   └── troubleshooting.md
│   ├── deployment/
│   │   ├── ci-cd-workflow.md
│   │   └── firebase-deployment.md
│   └── security/
│       ├── api-key-management.md    # Consolidated security guide
│       ├── pre-commit-hooks.md
│       └── incident-response.md
│
├── reference/                         # Technical reference
│   ├── architecture/
│   │   ├── features.md              # Feature catalog (A1-A12)
│   │   ├── data-sources.md
│   │   └── state-management.md
│   ├── configuration/
│   │   ├── environment-variables.md
│   │   ├── feature-flags.md
│   │   └── test-regions.md
│   ├── api/
│   │   ├── effis-service.md
│   │   ├── sepa-service.md
│   │   └── cache-service.md
│   └── compliance/
│       ├── accessibility.md
│       ├── privacy.md
│       └── constitution-gates.md
│
├── explanation/                       # Understanding & decisions
│   ├── architecture-decisions/      # ADRs (Architecture Decision Records)
│   │   ├── 001-flutter-framework.md
│   │   ├── 002-dartz-error-handling.md
│   │   └── 003-worktree-workflow.md
│   ├── design-rationale/
│   │   ├── scottish-color-palette.md
│   │   └── risk-level-mapping.md
│   └── context/
│       ├── project-context.md       # High-level project context
│       └── ux-principles.md
│
├── runbooks/                          # Operational procedures
│   ├── monitoring/
│   │   └── effis-monitoring.md
│   ├── incident-response/
│   │   └── api-key-leak-response.md
│   └── maintenance/
│       └── dependency-updates.md
│
└── history/                           # Archived/historical
    ├── sessions/
    │   ├── 2025-10-19-session.md
    │   ├── 2025-10-20-integration-tests.md
    │   └── 2025-10-20-web.md
    ├── deprecated/
    │   └── old-google-maps-setup.md
    └── audits/
        ├── 2025-10-29-security-audit.md
        └── test-coverage-reports/
```

## Documentation Principles

### 1. Minimum Viable Documentation (Google Best Practice)

> "A small set of fresh and accurate docs is better than a large assembly of 'documentation' in various states of disrepair."

**Action**: Delete or archive 80% of current docs, consolidate the rest.

### 2. Update Docs with Code (Docs as Code)

**Rules**:
- Documentation changes in same PR as code changes
- Code review includes documentation review
- CI checks for broken links, outdated examples
- Docs live in version control with code

### 3. Delete Dead Documentation Aggressively

**Detection Criteria**:
- ❌ Last updated > 3 months ago
- ❌ Refers to code/features that no longer exist
- ❌ Duplicates content in another doc
- ❌ "TODO" or "WIP" older than 2 weeks

**Process**:
```bash
# Don't just delete - archive first
git mv docs/old-doc.md docs/history/deprecated/old-doc.md
git commit -m "docs: archive outdated X documentation"
```

### 4. Single Source of Truth (No Duplication)

**Instead of**:
- `GOOGLE_MAPS_SETUP.md` (18KB)
- `google-maps-setup.md` (14KB)
- `GOOGLE_MAPS_API_SETUP.md` (18KB)
- `IOS_GOOGLE_MAPS_INTEGRATION.md` (12KB)

**Create**:
- `guides/setup/google-maps.md` (consolidated, 25KB)
- With sections: Web, iOS, Android, Troubleshooting
- Link to platform-specific details only when necessary

### 5. Lifecycle Management for Agent-Generated Docs

| Stage | Action | Example |
|-------|--------|---------|
| **Generated** | Agent creates doc with `[AI-Generated]` tag | Session summary, test results |
| **Review (24h)** | Human reviews, marks `[Reviewed]` or archives | Keep if valuable, archive if ephemeral |
| **Consolidate (1 week)** | Merge valuable content into permanent docs | Extract troubleshooting tips into guide |
| **Archive (1 month)** | Move session summaries to `history/` | All session summaries → `history/sessions/` |

### 6. Naming Conventions

```
# File naming (kebab-case)
✅ google-maps-setup.md
❌ GOOGLE_MAPS_SETUP.md
❌ GoogleMapsSetup.md

# Section headers (Title Case)
✅ ## Google Maps Configuration
❌ ## GOOGLE MAPS CONFIGURATION

# Dates (ISO 8601)
✅ 2025-10-30-security-audit.md
❌ oct-30-2025-security-audit.md
```

## Documentation Maintenance Process

### Weekly: Documentation Health Check
```bash
# Run docs health check
./scripts/docs-health-check.sh

# Checks:
# - Files not updated in 90 days
# - Broken internal links
# - Duplicate content (>80% similarity)
# - Missing frontmatter (status, owner, last-updated)
```

### Monthly: Documentation Sprint
- **1 hour team session**
- Review flagged docs (outdated, duplicated)
- Consolidate or archive
- Update index/navigation

### Quarterly: Documentation Audit
- Full review of all active documentation
- Verify accuracy against current codebase
- User feedback survey (what's missing? what's confusing?)
- Update this strategy document

## Frontmatter Standard (All Docs)

```markdown
---
title: Google Maps Setup Guide
category: guides/setup
status: active | draft | deprecated
last_updated: 2025-10-30
owner: @username
reviewers: [@reviewer1, @reviewer2]
related: [guides/setup/api-keys.md, reference/configuration/environment-variables.md]
---
```

**Status Values**:
- `active` - Current, maintained documentation
- `draft` - Work in progress, may have gaps
- `deprecated` - Superseded, archived soon
- `archived` - Historical reference only

## Migration Plan (Phased)

### Phase 1: Structure + Index (Week 1)
- ✅ Create new directory structure
- ✅ Create `docs/README.md` navigation index
- ✅ Add frontmatter to top 10 most-used docs

### Phase 2: Consolidation (Week 2)
- Consolidate Google Maps docs → `guides/setup/google-maps.md`
- Consolidate Security docs → `guides/security/` (3 files max)
- Consolidate Testing docs → `guides/testing/` + `reference/`

### Phase 3: Archive Historical (Week 3)
- Move all session summaries → `history/sessions/`
- Move outdated integration test docs → `history/deprecated/`
- Move old security audits → `history/audits/`

### Phase 4: Automation (Week 4)
- Create `scripts/docs-health-check.sh`
- Add CI job to check for broken links
- Set up monthly cron reminder for doc sprint

## Success Metrics

**Quantitative**:
- ✅ Reduce total doc count by 60% (50 → 20 active docs)
- ✅ 100% of active docs have frontmatter
- ✅ Zero broken internal links (CI enforced)
- ✅ <10% duplication score (text similarity tool)

**Qualitative**:
- ✅ New developer can find setup docs in <2 minutes
- ✅ Team uses docs/README.md as primary entry point
- ✅ AI agents reference correct docs in their responses
- ✅ Quarterly feedback shows >80% satisfaction

## Tools & Automation

### Recommended Tools

1. **Link Checking**: `markdown-link-check` (npm package)
   ```bash
   npx markdown-link-check docs/**/*.md
   ```

2. **Similarity Detection**: `simhash` or `diff-so-fancy`
   ```bash
   # Find duplicate sections
   ./scripts/find-duplicate-docs.sh
   ```

3. **Frontmatter Validation**: Custom script
   ```bash
   ./scripts/validate-frontmatter.sh
   ```

4. **Documentation Site** (Future): Docusaurus, MkDocs, or mdBook
   - Auto-generate navigation from structure
   - Search functionality
   - Versioned documentation

## Agent Guidelines

### For AI Agents Creating Documentation

**DO**:
- ✅ Add frontmatter with `status: draft`, current date, and category
- ✅ Link to related existing documentation
- ✅ Use clear, descriptive filenames (kebab-case)
- ✅ Place docs in appropriate category folder
- ✅ Mark time-sensitive content (e.g., session summaries) for archival

**DON'T**:
- ❌ Duplicate existing documentation (search first!)
- ❌ Create docs in root `/docs` folder (use subdirectories)
- ❌ Use acronyms without defining them
- ❌ Create "final" documentation without human review

### For Humans Reviewing Agent Docs

**Review Checklist**:
- [ ] Does this duplicate existing docs? → Consolidate
- [ ] Is this time-sensitive? → Add archive date
- [ ] Is this a how-to, reference, explanation, or tutorial? → Categorize
- [ ] Are there broken links? → Fix
- [ ] Is the frontmatter complete? → Add missing fields
- [ ] Does this belong in `history/`? → Archive

## Example: Consolidating Google Maps Documentation

**Before** (4 files, 57KB total, duplication ~70%):
```
docs/GOOGLE_MAPS_SETUP.md (18KB)
docs/google-maps-setup.md (14KB)
docs/GOOGLE_MAPS_API_SETUP.md (18KB)
docs/IOS_GOOGLE_MAPS_INTEGRATION.md (12KB)
```

**After** (1 file, 25KB, zero duplication):
```
docs/guides/setup/google-maps.md
  ├── Overview
  ├── Prerequisites
  ├── Web Configuration
  ├── iOS Configuration
  ├── Android Configuration
  ├── API Key Management
  ├── Troubleshooting
  └── Related: [api-keys.md, firebase.md]

docs/history/deprecated/
  ├── 2025-10-old-google-maps-setup.md (archived)
  └── 2025-10-ios-google-maps-integration.md (archived)
```

## Resources & References

### Industry Standards
- [Divio Documentation System](https://documentation.divio.com/) - 4 types framework
- [Write the Docs](https://www.writethedocs.org/guide/docs-as-code/) - Docs as Code philosophy
- [Google Doc Guide](https://google.github.io/styleguide/docguide/best_practices.html) - Best practices

### Books
- "Docs Like Code" - Anne Gentle
- "Modern Technical Writing" - Andrew Etter

### Tools
- [markdown-link-check](https://github.com/tcort/markdown-link-check) - Link validation
- [Docusaurus](https://docusaurus.io/) - Documentation site generator
- [Vale](https://vale.sh/) - Prose linting

## Next Steps

1. **Review & Approve** this strategy (team discussion)
2. **Create** new directory structure (`docs/guides/`, `docs/reference/`, etc.)
3. **Prioritize** consolidation (start with Google Maps, Security, Testing)
4. **Implement** Phase 1 migration (1 week sprint)
5. **Document** results in `docs/history/migrations/2025-10-documentation-consolidation.md`

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2025-10-30 | Initial strategy document | AI Agent + Human Review |

---

**Questions or feedback?** Update this document or discuss in team chat.
