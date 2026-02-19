# WildFire MVP v3 Documentation

**Welcome!** This is your central hub for all WildFire MVP v3 documentation.

> New here? Start with [Getting Started](../QUICK_START.md) or [Project README](../README.md)

## Documentation Categories

We follow the [Divio Documentation System](https://documentation.divio.com/) with four types of documentation:

---

### Guides (How-To)
**Problem-solving documentation** - Step-by-step instructions for specific tasks.

#### Setup
- [Google Maps Configuration](guides/setup/google-maps.md) - Complete setup for Web, iOS, Android
- [Google Maps API Setup](guides/setup/google-maps-api-setup.md) - API key configuration and restrictions
- [Google Maps Crash Fix](guides/setup/google-maps-crash-fix.md) - Troubleshooting native map crashes
- [iOS Crash Fix Summary](guides/setup/ios-crash-fix-summary.md) - iOS-specific crash resolutions
- [Dev Mode Setup](guides/setup/dev-mode.md) - Local development environment
- [M3 Implementation Plan](guides/setup/M3_IMPLEMENTATION_PLAN.md) - Material 3 migration
- [PWA Best Practices](guides/setup/PWA_BEST_PRACTICES.md) - Progressive Web App setup
- [PWA Icon Fix](guides/setup/PWA_ICON_FIX.md) - PWA icon configuration
- [PWA Updates](guides/setup/pwa-updates.md) - Service worker and caching updates

#### Testing
- [Integration Testing Guide](guides/testing/integration-testing.md) - Comprehensive integration test guide
- [Integration Test Quickstart](guides/testing/integration-test-quickstart.md) - Quick-start for running tests
- [Integration Tests (consolidated)](guides/testing/integration-tests.md) - Consolidated test patterns
- [Preview Deployment Testing](guides/testing/preview-deployment-testing.md) - Testing deployed web apps
- [Platform-Specific Testing](guides/testing/platform-specific.md) - Platform-specific test considerations
- [Test Troubleshooting](guides/testing/troubleshooting.md) - Common test failure solutions

#### CI/CD and Deployment
- [CI/CD Workflow Guide](guides/ci-cd/ci-cd-workflow.md) - Full CI/CD pipeline walkthrough
- [iOS Build Phase Verification](guides/ci-cd/ios-build-phase-verification.md) - Xcode build phase CI job
- [Branching Strategy](guides/deployment/branching-strategy.md) - Feature to Staging to Production workflow
- [Deployment Workflow](guides/deployment/deployment-workflow.md) - Step-by-step deployment procedures
- [3-Tier Deployment](guides/deployment/3-tier-deployment.md) - Dev / Staging / Production architecture

#### Security
- [API Key Management](guides/security/api-key-management.md) - Secure key handling practices
- [Prevent API Key Leaks](guides/security/prevent-api-key-leaks.md) - Prevention strategies and tools
- [Gitleaks Configuration](guides/security/gitleaks-configuration.md) - Secret detection setup
- [Security Controls](guides/security/security-controls.md) - Multi-layer security overview

#### Development
- [New Feature Workflow](guides/development/new-feature-workflow.md) - End-to-end feature development process
- [VS Code Tasks](guides/development/vscode-tasks.md) - Task runner configuration
- [Location Helper Implementation](guides/features/LOCATION_HELPER_IMPLEMENTATION.md) - Location service guide

---

### Reference (Technical Details)
**Information-oriented documentation** - Technical specifications and data.

#### Project
- [App Overview](reference/app-overview.md) - Use case, architecture, tech stack, and current state
- [Brand Guidelines](reference/brand-guidelines.md) - Colours, typography, spacing, and marketing asset rules

#### API and Data
- [EFFIS API Endpoints](reference/EFFIS_API_ENDPOINTS.md) - EFFIS/GWIS endpoint specifications
- [API Endpoints Summary](reference/api-endpoints-summary.md) - All API endpoints at a glance
- [Data Sources](reference/data-sources.md) - Fire data source documentation
- [Data Source Attribution](reference/data-source-attribution.md) - Attribution and licensing
- [Test Regions](reference/test-regions.md) - Geographic test data and coordinates

#### Testing and Quality
- [Test Coverage](reference/test-coverage.md) - Current test coverage metrics
- [Integration Test Results](reference/integration-test-results.md) - Test pass/fail tracking
- [Test Platform Compatibility](reference/test-platform-compatibility.md) - Platform support matrix
- [Material 3 Compliance Audit](reference/material3-compliance-audit.md) - M3 design compliance

#### Platform and Architecture
- [Deployment Diagrams](reference/deployment-diagrams.md) - Infrastructure architecture visuals
- [macOS and Web Support](reference/macos-web-support.md) - Platform compatibility notes
- [Map Data Display Review](reference/map-data-display-review.md) - Map layer data review
- [Tooltip Visual Examples](reference/tooltip-visual-examples.md) - UI tooltip reference
- [UX Cues](reference/ux-cues.md) - UX design patterns and cues
- [Project Status Review](reference/project-status-review.md) - Feature completion status

#### Compliance
- [Accessibility Statement](reference/compliance/accessibility-statement.md) - WCAG compliance
- [Privacy Compliance](reference/compliance/privacy-compliance.md) - GDPR and data privacy
- [Legal Docs TODO](reference/LEGAL_DOCS_TODO.md) - Outstanding legal requirements

---

### Explanation (Understanding)
**Understanding-oriented documentation** - Context, rationale, and design decisions.

- [Project Context](explanation/project-context.md) - Project background and goals
- [Google Maps Integration Context](explanation/google-maps-context.md) - Map integration rationale
- [A11 CI/CD Review](explanation/a11-ci-cd-review.md) - CI/CD architecture decisions
- [Worktree Workflow](explanation/worktree-workflow.md) - Git worktree usage rationale
- [Fire Incident Map Plan](explanation/fire-incident-map-plan.md) - Map feature design and planning
- [Web Platform Research](explanation/web-platform-research.md) - Web deployment research
- [Onboarding Legal Draft](explanation/onboarding-legal-draft.md) - Onboarding flow planning
- [Live Fire Data Refactor TODO](explanation/live-fire-data-refactor-todo.md) - Refactoring plan

---

### Tutorials (Learning)
**Learning-oriented documentation** - Step-by-step lessons for beginners.

> Coming soon - Curated tutorials for new team members.

---

### Runbooks (Operations)
**Operational procedures** - Step-by-step guides for maintaining the system.

- [Firebase Deployment](runbooks/firebase-deployment.md) - Deploy to Firebase Hosting
- [EFFIS Monitoring](runbooks/effis-monitoring.md) - Monitor EFFIS service health
- [Manual Integration Tests](runbooks/manual-integration-tests.md) - Manual test procedures
- [Security Incident Response](runbooks/incident-response/security-incidents.md) - API key leak response

---

### Feature Documentation
- [023: Settings and Help Hubs](features/023-settings-help-hubs/PLAN.md)

---

## Historical Documentation

Historical documentation is preserved in `history/`:
- [Session Summaries](history/sessions/) - Development session notes
- [Deprecated Documentation](history/deprecated/) - Superseded docs (22 files)
- [Security Audits](history/audits/) - Past security audit reports

---

## Documentation Standards

### File Naming
- Use kebab-case: `google-maps-setup.md`
- Dates in ISO format: `2025-10-30-audit.md`
- Legacy UPPERCASE files are grandfathered

### Documentation Lifecycle
1. **Draft** - Work in progress
2. **Active** - Current, maintained
3. **Deprecated** - Superseded, will be archived
4. **Archived** - Historical reference in `history/`

---

## For AI Agents

When creating documentation:
- Place in appropriate category folder (`guides/`, `reference/`, `explanation/`, `runbooks/`)
- Add frontmatter with `status: draft`
- Link to related documentation
- Use kebab-case filenames
- Do NOT create docs in root `docs/` folder
- Do NOT duplicate existing docs - check `history/deprecated/` first

See [Documentation Strategy](DOCUMENTATION_STRATEGY.md) for complete guidelines.

---

**Last Updated**: 2025-02-10
**Strategy**: [DOCUMENTATION_STRATEGY.md](DOCUMENTATION_STRATEGY.md)
