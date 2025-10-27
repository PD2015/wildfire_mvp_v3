# Data Model: CI/CD Deployment Entities

**Feature**: A11 – CI/CD: Flutter Web → Firebase Hosting  
**Date**: 2025-10-27  
**Version**: 1.0

---

## Overview

This document defines the data entities involved in the CI/CD pipeline for Flutter web deployments to Firebase Hosting. Since this is an infrastructure feature (not application code), the "data model" represents configuration files, workflow state, and deployment metadata rather than traditional database entities.

---

## Entity 1: GitHub Actions Workflow Configuration

**Represents**: YAML configuration defining the CI/CD pipeline

**File Location**: `.github/workflows/flutter.yml`

**Schema**:
```yaml
name: String                # Workflow name (display in GitHub Actions UI)
on:                         # Trigger events
  push:
    branches: [String]      # Array of branch names
  pull_request:
    branches: [String]      # Array of branch names

jobs:                       # Map of job definitions
  [job_id]:
    name: String            # Human-readable job name
    runs-on: String         # Runner environment (ubuntu-latest, etc.)
    needs: [String]         # Array of job IDs (dependencies)
    if: String              # Conditional expression (GitHub context)
    timeout-minutes: Integer # Max execution time (default: 360)
    environment:            # GitHub Environment (for approvals)
      name: String          # Environment name
      url: String           # Deployment URL
    steps:                  # Array of step definitions
      - name: String
        uses: String        # Action reference (owner/repo@version)
        with:               # Action inputs (map)
          key: value
        env:                # Environment variables (map)
          key: value
        run: String         # Shell command
```

**Relationships**:
- Job dependencies: `needs: [job_id]` creates directed acyclic graph (DAG)
- Environment: References GitHub Environment entity (external)
- Secrets: References GitHub Secrets entity (external)

**Validation Rules**:
- Job names MUST be unique within workflow
- `needs` MUST reference existing job IDs (no cycles)
- `if` conditions MUST use valid GitHub expression syntax
- `timeout-minutes` MUST be positive integer

**State Lifecycle**:
1. **Defined**: Workflow file committed to repository
2. **Triggered**: Event matches `on` conditions
3. **Queued**: Workflow run created, jobs waiting for runners
4. **Running**: Jobs executing on runners (respects `needs` dependencies)
5. **Completed**: All jobs finished (success, failure, cancelled, skipped)

**Example** (simplified):
```yaml
name: Flutter CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Tests & Constitutional Gates
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: flutter test
  
  build-web:
    name: Build Web Artifact
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/build_web_ci.sh
  
  deploy-preview:
    name: Deploy Preview
    needs: build-web
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: FirebaseExtended/action-hosting-deploy@v0
```

---

## Entity 2: Build Artifact

**Represents**: Compiled Flutter web application ready for deployment

**File Location**: `build/web/` (generated during build job)

**Schema**:
```
build/web/
├── index.html              # Main HTML entry point (with injected API key)
├── main.dart.js            # Compiled Dart code (minified)
├── flutter.js              # Flutter web bootstrap
├── flutter_service_worker.js # PWA service worker
├── manifest.json           # Web app manifest
├── version.json            # Build metadata
├── assets/                 # Static assets
│   ├── fonts/
│   ├── images/
│   └── NOTICES             # License notices
├── icons/                  # PWA icons
└── canvaskit/              # Rendering engine
```

**Metadata** (version.json):
```json
{
  "app_name": "wildfire_mvp_v3",
  "version": "1.0.0+1",
  "build_number": "1",
  "build_mode": "release",
  "commit": "<git-sha>",      # From GitHub context
  "build_timestamp": "<iso>"  # Build time
}
```

**Attributes**:
- **Size**: ~2-10 MB (typical Flutter web build)
- **Commit SHA**: GitHub commit that triggered build
- **API Key**: Injected during build (not in source)
- **Build Mode**: `release` (optimized, minified)
- **Dart Compile Flags**: `--dart-define=MAP_LIVE_DATA=false`

**Lifecycle**:
1. **Generated**: Created by `flutter build web` command
2. **Validated**: Script checks build/web/index.html exists
3. **Uploaded**: GitHub Actions uploads as artifact
4. **Downloaded**: Deploy jobs download artifact
5. **Deployed**: Firebase Hosting serves from CDN
6. **Expired**: GitHub deletes artifact after retention period (7 days)

**Validation Rules**:
- index.html MUST exist and be valid HTML5
- main.dart.js MUST exist and be non-empty
- assets/ directory MUST contain all referenced files
- API key MUST be injected (not placeholder %MAPS_API_KEY%)
- Total size SHOULD be <50 MB (Firebase Hosting limit: 2 GB)

**Example Artifact Upload** (GitHub Actions):
```yaml
- name: Upload build artifact
  uses: actions/upload-artifact@v4
  with:
    name: web-build-${{ github.sha }}  # Unique per commit
    path: build/web/
    retention-days: 7
    if-no-files-found: error
```

---

## Entity 3: Firebase Hosting Channel

**Represents**: Deployment target environment (preview or production)

**Managed By**: Firebase Hosting API (external service)

**Schema** (logical):
```
Channel {
  id: String                    # Channel identifier
  type: Enum                    # "preview" | "live" (production)
  url: String                   # Public URL
  site_id: String               # Firebase site ID (from .firebaserc)
  created_at: DateTime          # Channel creation timestamp
  expires_at: DateTime?         # Expiry time (preview only, null for live)
  version: String               # Firebase Hosting version ID
  status: Enum                  # "active" | "expired" | "deleted"
}
```

**Channel Types**:

### Preview Channel (PR Previews)
- **ID Format**: `pr-<number>` (e.g., `pr-42`)
- **URL Pattern**: `https://<site>--pr-<number>-<hash>.web.app`
- **Example**: `https://wildfire-app-e11f8--pr-42-abc123.web.app`
- **TTL**: 7 days (auto-cleanup)
- **Trigger**: Pull request to main branch
- **API Key**: `GOOGLE_MAPS_API_KEY_WEB_PREVIEW`
- **Approval**: None (auto-deployed)

### Live Channel (Production)
- **ID**: `live` (reserved channel)
- **URL**: `https://wildfire-app-e11f8.web.app`
- **TTL**: Permanent (no expiry)
- **Trigger**: Push to main branch
- **API Key**: `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION`
- **Approval**: Manual (GitHub Environment protection)

**Relationships**:
- Channels belong to one Firebase site (configured in .firebaserc)
- Each channel serves one version (deployment snapshot)
- Preview channels linked to pull request number (1:1)
- Live channel history shows rollback options (1:many versions)

**State Lifecycle** (Preview):
1. **Created**: PR opened, deploy-preview job runs
2. **Active**: Channel serving content, URL posted as PR comment
3. **Updated**: New commits pushed, channel redeployed with latest
4. **Expired**: 7 days after creation, Firebase auto-deletes
5. **Deleted**: PR closed, channel can be manually deleted (optional)

**State Lifecycle** (Live):
1. **Initialized**: First deployment to live channel
2. **Active**: Serving production traffic
3. **Updated**: New version deployed after manual approval
4. **Rollback**: Previous version restored (live channel serves older version)

**Example Channel Creation** (Firebase Action):
```yaml
- uses: FirebaseExtended/action-hosting-deploy@v0
  with:
    channelId: pr-${{ github.event.pull_request.number }}
    expires: 7d
  # Output: Channel URL posted as PR comment
```

---

## Entity 4: GitHub Secret

**Represents**: Encrypted credential stored in repository settings

**Managed By**: GitHub Secrets API (external service)

**Schema** (logical):
```
Secret {
  name: String                  # Secret identifier (uppercase snake_case)
  value: String                 # Encrypted value (write-only)
  visibility: Enum              # "repository" | "environment"
  created_at: DateTime          # Creation timestamp
  updated_at: DateTime          # Last update timestamp
}
```

**Required Secrets**:

| Name | Type | Value Format | Used By | Validation |
|------|------|--------------|---------|------------|
| `FIREBASE_SERVICE_ACCOUNT` | JSON | `{"type":"service_account",...}` | Deploy jobs | Must contain `private_key` field |
| `FIREBASE_PROJECT_ID` | String | `wildfire-app-e11f8` | Deploy jobs | Must match .firebaserc |
| `GOOGLE_MAPS_API_KEY_WEB_PREVIEW` | String | `AIza...` | Build job (preview) | Must work with `*.web.app` referrer |
| `GOOGLE_MAPS_API_KEY_WEB_PRODUCTION` | String | `AIza...` | Build job (production) | Must work with production domain referrer |

**Access Control**:
- Secrets visible to workflow runs (via `${{ secrets.SECRET_NAME }}`)
- Secrets never logged in plaintext (GitHub redacts known patterns)
- Secrets not accessible to forks (PR from forks can't deploy)

**Rotation Strategy**:
1. Generate new service account key / API key in Google Cloud Console
2. Update secret value in GitHub repository settings
3. Trigger workflow to validate new secret works
4. Revoke old key in Google Cloud Console

**Validation Rules**:
- Secret names MUST be uppercase with underscores (SCREAMING_SNAKE_CASE)
- Service account JSON MUST be valid (parseable with `jq`)
- API keys MUST start with `AIza` (Google API key prefix)
- API keys MUST have HTTP referrer restrictions configured

---

## Entity 5: GitHub Environment

**Represents**: Deployment target with protection rules (production only)

**Managed By**: GitHub Environments API (external service)

**Schema** (logical):
```
Environment {
  name: String                  # Environment identifier
  url: String                   # Deployment URL (optional)
  protection_rules: {
    required_reviewers: [User]  # Array of required reviewers
    wait_timer: Integer         # Minutes to wait before deploy (0 = manual)
    deployment_branches: [String] # Allowed branches (e.g., ["main"])
  }
  deployment_history: [Deployment] # Past deployments
}
```

**Production Environment Configuration**:
```yaml
name: production
url: https://wildfire-app-e11f8.web.app
protection_rules:
  required_reviewers: [maintainer-username]
  wait_timer: 0  # No auto-approval
  deployment_branches: [main]
```

**Deployment Approval Workflow**:
1. **Triggered**: Push to main branch, build-web job succeeds
2. **Pending**: Deploy-production job waits for approval
3. **Review**: Required reviewer receives GitHub notification
4. **Approved**: Reviewer clicks "Approve" in GitHub UI
5. **Executing**: Deploy job runs, Firebase Hosting updated
6. **Completed**: Deployment URL visible in Environment deployments tab

**Validation Rules**:
- Environment name MUST match workflow `environment.name`
- Required reviewers MUST have write access to repository
- Deployment branches MUST include branch that triggered workflow
- URL MUST be accessible HTTPS endpoint (no http://)

**Example Usage** (GitHub Actions):
```yaml
deploy-production:
  environment:
    name: production
    url: https://wildfire-app-e11f8.web.app
  # Job waits for manual approval before executing
```

---

## Entity 6: Deployment Event

**Represents**: Record of a deployment action (metadata, not stored as file)

**Tracked By**: GitHub Actions logs, Firebase Hosting release history

**Schema** (logical):
```
DeploymentEvent {
  id: String                    # Unique deployment ID
  type: Enum                    # "preview" | "production"
  channel_id: String            # Firebase channel ID
  commit_sha: String            # Git commit deployed
  workflow_run_id: String       # GitHub Actions run ID
  triggered_by: String          # GitHub username or "github-actions[bot]"
  triggered_at: DateTime        # Workflow start time
  deployed_at: DateTime?        # Deployment completion time (null if failed)
  status: Enum                  # "pending" | "approved" | "success" | "failure" | "cancelled"
  approval: {
    required: Boolean           # Environment requires approval
    approved_by: String?        # Reviewer username (null if auto-deployed)
    approved_at: DateTime?      # Approval timestamp
  }
  build_artifact: {
    name: String                # Artifact name (web-build-<sha>)
    size_bytes: Integer         # Artifact size
    uploaded_at: DateTime       # Artifact upload time
  }
  deployment: {
    url: String                 # Deployed URL
    duration_seconds: Integer   # Deployment time
    firebase_version: String    # Firebase Hosting version ID
  }
  errors: [String]              # Error messages (if status = failure)
}
```

**Example: Preview Deployment Event**:
```json
{
  "id": "run-1234567890",
  "type": "preview",
  "channel_id": "pr-42",
  "commit_sha": "abc123def456",
  "workflow_run_id": "1234567890",
  "triggered_by": "developer-username",
  "triggered_at": "2025-10-27T14:30:00Z",
  "deployed_at": "2025-10-27T14:34:30Z",
  "status": "success",
  "approval": {
    "required": false,
    "approved_by": null,
    "approved_at": null
  },
  "build_artifact": {
    "name": "web-build-abc123def456",
    "size_bytes": 5242880,
    "uploaded_at": "2025-10-27T14:32:00Z"
  },
  "deployment": {
    "url": "https://wildfire-app-e11f8--pr-42-abc123.web.app",
    "duration_seconds": 28,
    "firebase_version": "fb-hosting-version-xyz"
  },
  "errors": []
}
```

**Example: Production Deployment Event**:
```json
{
  "id": "run-9876543210",
  "type": "production",
  "channel_id": "live",
  "commit_sha": "def456abc123",
  "workflow_run_id": "9876543210",
  "triggered_by": "github-actions[bot]",
  "triggered_at": "2025-10-27T15:00:00Z",
  "deployed_at": "2025-10-27T15:10:15Z",
  "status": "success",
  "approval": {
    "required": true,
    "approved_by": "maintainer-username",
    "approved_at": "2025-10-27T15:05:00Z"
  },
  "build_artifact": {
    "name": "web-build-def456abc123",
    "size_bytes": 5340160,
    "uploaded_at": "2025-10-27T15:02:30Z"
  },
  "deployment": {
    "url": "https://wildfire-app-e11f8.web.app",
    "duration_seconds": 15,
    "firebase_version": "fb-hosting-version-uvw"
  },
  "errors": []
}
```

**Querying Deployment Events**:
- **GitHub Actions**: Repository → Actions tab → Workflow runs
- **Firebase Console**: Project → Hosting → Release history
- **GitHub API**: `GET /repos/{owner}/{repo}/actions/runs`

---

## Relationships Diagram

```
┌──────────────────────┐
│ GitHub Repository    │
│ ┌──────────────────┐ │
│ │ Workflow Config  │ │──triggers──┐
│ │ (.github/...)    │ │            │
│ └──────────────────┘ │            v
│ ┌──────────────────┐ │     ┌─────────────┐
│ │ Build Script     │ │────>│ Build Job   │
│ │ (scripts/...)    │ │     └─────────────┘
│ └──────────────────┘ │            │
│ ┌──────────────────┐ │            v
│ │ GitHub Secrets   │ │     ┌─────────────┐
│ └──────────────────┘ │────>│ Build       │
└──────────────────────┘     │ Artifact    │
                              └─────────────┘
                                     │
                                     v
                              ┌─────────────┐
                              │ Deploy Job  │
                              └─────────────┘
                                     │
                     ┌───────────────┴───────────────┐
                     v                               v
            ┌────────────────┐            ┌─────────────────┐
            │ Preview Channel│            │ Live Channel    │
            │ (Firebase)     │            │ (Firebase)      │
            └────────────────┘            └─────────────────┘
                     │                               │
                     v                               v
            ┌────────────────┐            ┌─────────────────┐
            │ PR Comment     │            │ Production URL  │
            │ (GitHub)       │            │ (Environment)   │
            └────────────────┘            └─────────────────┘
```

---

## Summary

This data model describes the infrastructure entities involved in CI/CD deployments:

1. **Workflow Configuration** - YAML defining pipeline jobs and dependencies
2. **Build Artifact** - Compiled Flutter web app with injected API key
3. **Firebase Hosting Channel** - Deployment target (preview or production)
4. **GitHub Secret** - Encrypted credentials for deployment
5. **GitHub Environment** - Production target with approval rules
6. **Deployment Event** - Metadata tracking deployment execution

These entities work together to enable automated, secure, and auditable deployments of the Flutter web application to Firebase Hosting.

---

**Next Phase**: Create quickstart.md with deployment testing procedures using these entities.
