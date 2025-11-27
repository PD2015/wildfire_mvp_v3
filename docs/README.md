# WildFire MVP v3 Documentation

**Welcome!** This is your central hub for all WildFire MVP v3 documentation.

> 📖 **New here?** Start with [Getting Started](../QUICK_START.md) or [Project README](../README.md)

## 🗂️ Documentation Categories

We follow the [Divio Documentation System](https://documentation.divio.com/) with four types of documentation:

### 📚 Guides (How-To)
**Problem-solving documentation** - Step-by-step instructions for specific tasks

#### Setup
- [Google Maps Configuration](guides/setup/google-maps.md) - Complete setup for Web, iOS, Android
- [Material 3 Implementation Plan](guides/setup/M3_IMPLEMENTATION_PLAN.md) - Comprehensive plan for M3 compliance
- [Firebase Configuration](FIREBASE_DEPLOYMENT.md) *(to be moved)*
- [API Keys Management](API_KEY_SETUP.md) *(to be moved)*

#### Testing
- [Integration Testing Guide](guides/testing/integration-tests.md) *(pending consolidation)*
- [Preview Deployment Testing](guides/testing/preview-deployment-testing.md) - Testing web apps in deployed environments
- [Platform-Specific Testing](guides/testing/platform-specific.md) *(pending consolidation)*
- [Test Troubleshooting](guides/testing/troubleshooting.md) *(pending consolidation)*

#### Deployment
- [CI/CD Workflow](CI_CD_WORKFLOW_GUIDE.md) *(to be moved)*
- [Branching Strategy](BRANCHING_STRATEGY.md) - Feature → Staging → Production workflow
- [Firebase Deployment](FIREBASE_DEPLOYMENT.md) *(to be moved)*
- [iOS Build Phase Verification](guides/ci-cd/ios-build-phase-verification.md) - CI/CD job for Xcode build phase

#### Security
- [API Key Management](guides/security/api-key-management.md) *(pending consolidation)*
- [Pre-commit Hooks](guides/security/pre-commit-hooks.md) *(pending consolidation)*
- [Incident Response](guides/security/incident-response.md) *(pending consolidation)*

### 📖 Reference (Technical Details)
**Information-oriented documentation** - Technical specifications and API documentation

#### Architecture
- [Feature Catalog (A1-A12)](reference/architecture/features.md) *(pending creation)*
- [Data Sources](DATA-SOURCES.md) *(to be moved)*
- [State Management](reference/architecture/state-management.md) *(pending creation)*

#### Configuration
- [Environment Variables](reference/configuration/environment-variables.md) *(pending creation)*
- [Feature Flags](reference/configuration/feature-flags.md) *(pending creation)*
- [Test Regions](TEST_REGIONS.md) *(to be moved)*

#### API
- [EFFIS Service](reference/api/effis-service.md) *(pending creation)*
- [SEPA Service](reference/api/sepa-service.md) *(pending creation)*
- [Cache Service](reference/api/cache-service.md) *(pending creation)*

#### Features
- [Map Data Display Review](MAP_DATA_DISPLAY_REVIEW.md) - Comprehensive review of fire marker tooltips and detail sheets

#### Compliance
- [Accessibility Statement](accessibility-statement.md) *(to be moved)*
- [Privacy Compliance](privacy-compliance.md) *(to be moved)*
- [Constitution Gates](reference/compliance/constitution-gates.md) *(pending creation)*

### 💡 Explanation (Understanding)
**Understanding-oriented documentation** - Context, rationale, and design decisions

#### Architecture Decisions (ADRs)
- [001: Flutter Framework](explanation/architecture-decisions/001-flutter-framework.md) *(pending creation)*
- [002: Dartz Error Handling](explanation/architecture-decisions/002-dartz-error-handling.md) *(pending creation)*
- [003: Worktree Workflow](WORKTREE_WORKFLOW.md) *(to be moved)*

#### Design Rationale
- [Scottish Colour Palette](explanation/design-rationale/scottish-color-palette.md) *(pending creation)*
- [Risk Level Mapping](explanation/design-rationale/risk-level-mapping.md) *(pending creation)*
- [UX Principles](ux_cues.md) *(to be moved)*

#### Context
- [Project Context](context.md) *(to be moved)*
- [Google Maps Integration Context](context01.md) *(to be moved)*

### 🎓 Tutorials (Learning)
**Learning-oriented documentation** - Step-by-step lessons for beginners

> 🚧 **Coming soon** - Curated tutorials for new team members

### 🔧 Runbooks (Operations)
**Operational procedures** - Step-by-step guides for maintaining the system

#### Monitoring
- [EFFIS Monitoring](runbooks/effis-monitoring.md)

#### Incident Response
- [API Key Leak Response](runbooks/incident-response/api-key-leak-response.md) *(pending creation)*

#### Maintenance
- [Dependency Updates](runbooks/maintenance/dependency-updates.md) *(pending creation)*

## 📊 Documentation Health

Last health check: Run `./scripts/docs-health-check.sh`

**Current Metrics**:
- Total active docs: ~50 *(target: 20)*
- Stale docs (>90 days): 0
- Missing frontmatter: 12
- Broken links: 1

## 🔍 Quick Links

### Most Used Documentation
1. [Quick Start Guide](../QUICK_START.md)
2. [Google Maps Setup](guides/setup/google-maps.md) *(pending consolidation)*
3. [CI/CD Workflow](CI_CD_WORKFLOW_GUIDE.md)
4. [Integration Testing](INTEGRATION_TESTING.md)
5. [API Key Setup](API_KEY_SETUP.md)

### Security Documentation
- [API Key Security Checklist](API_KEY_SECURITY_CHECKLIST.md)
- [Multi-Layer Security Controls](MULTI_LAYER_SECURITY_CONTROLS.md)
- [Security Audit Reports](history/audits/) *(pending migration)*

### Platform-Specific Guides
- [macOS Web Support](MACOS_WEB_SUPPORT.md)
- [iOS Testing](IOS_MANUAL_TEST_SESSION.md)
- [Android Testing](ANDROID_TESTING_SESSION.md)
- [Cross-Platform Testing](CROSS_PLATFORM_TESTING.md)

## 📋 Documentation Standards

All documentation in this project follows these standards:

### Frontmatter Template
```yaml
---
title: Document Title
category: guides/setup | reference/api | explanation/adr | tutorials | runbooks
status: active | draft | deprecated | archived
last_updated: YYYY-MM-DD
owner: @username
reviewers: [@reviewer1, @reviewer2]
related: [path/to/related-doc.md]
---
```

### File Naming
- Use kebab-case: `google-maps-setup.md` ✅
- Avoid UPPERCASE: `GOOGLE_MAPS_SETUP.md` ❌
- Dates in ISO format: `2025-10-30-audit.md` ✅

### Documentation Lifecycle
1. **Draft** - Work in progress, may have gaps
2. **Review** - Under review, ready for feedback
3. **Active** - Current, maintained documentation
4. **Deprecated** - Superseded, will be archived
5. **Archived** - Historical reference only

## 🤖 For AI Agents

When creating documentation:
- ✅ Add frontmatter with `status: draft`
- ✅ Place in appropriate category folder
- ✅ Link to related documentation
- ✅ Use clear, descriptive filenames
- ❌ Don't duplicate existing docs
- ❌ Don't create docs in root `/docs` folder

See [Documentation Strategy](DOCUMENTATION_STRATEGY.md) for complete guidelines.

## 📜 Historical Documentation

Historical documentation is preserved in `history/`:
- [Session Summaries](history/sessions/)
- [Deprecated Documentation](history/deprecated/)
- [Security Audits](history/audits/)

## 🛠️ Maintenance

- **Weekly**: Run `./scripts/docs-health-check.sh`
- **Monthly**: Documentation sprint (consolidate/archive)
- **Quarterly**: Full documentation audit

See [Documentation Strategy](DOCUMENTATION_STRATEGY.md) for complete maintenance procedures.

## 📞 Need Help?

- **Can't find something?** Use GitHub search or ask in team chat
- **Found an error?** Open an issue or submit a PR
- **Want to contribute?** Read [Documentation Strategy](DOCUMENTATION_STRATEGY.md)

---

**Last Updated**: 2025-10-30
**Maintained By**: Project Team
**Strategy**: [DOCUMENTATION_STRATEGY.md](DOCUMENTATION_STRATEGY.md)
