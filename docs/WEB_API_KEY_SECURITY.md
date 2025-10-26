# Web API Key Security Guide

## Overview

This document explains how to securely manage Google Maps API keys for web deployment without committing secrets to git.

## Current Setup

### 🔐 Security Architecture

1. **API keys stored in**: `env/dev.env.json` (gitignored)
2. **Template file**: `env/dev.env.json.template` (committed, no secrets)
3. **Build-time injection**: Scripts inject API key into `web/index.html` temporarily
4. **Auto-cleanup**: Original `web/index.html` restored after build/run

### ✅ What's Protected

- ✅ `env/dev.env.json` - **gitignored** (contains real API keys)
- ✅ `env/*.env.json` - **gitignored** (all environment files with secrets)
- ✅ `web/index.html` - **No API key hardcoded** (clean for git commits)

### 📁 File Structure

```
env/
├── .gitignore                # Blocks *.env.json from git
├── dev.env.json              # YOUR SECRETS (gitignored) ✅
├── dev.env.json.template     # Template (committed, no secrets)
└── ci.env.json               # CI placeholders (committed, no real keys)

web/
└── index.html                # Clean template (no API key) ✅

scripts/
├── build_web.sh              # Secure build script
└── run_web.sh                # Secure run script
```

## Usage

### Development (Quick Start)

Use the secure run script that handles API key injection automatically:

```bash
# Run with automatic API key injection
./scripts/run_web.sh

# Or specify custom env file
./scripts/run_web.sh env/prod.env.json
```

**What it does**:
1. Reads API key from `env/dev.env.json`
2. Temporarily injects into `web/index.html`
3. Runs `flutter run -d chrome`
4. Auto-restores original `web/index.html` on exit (Ctrl+C)

### Production Build

Use the secure build script:

```bash
# Build with API key injection
./scripts/build_web.sh

# Or specify custom env file
./scripts/build_web.sh env/prod.env.json
```

**What it does**:
1. Reads API key from env file
2. Injects into `web/index.html`
3. Runs `flutter build web`
4. Restores original `web/index.html` (removes API key)
5. Output in `build/web/` includes API key in final HTML

### Manual Method (Not Recommended)

If you need to run without the scripts:

```bash
# 1. Manually edit web/index.html (TEMPORARY ONLY)
# Change: <script src="https://maps.googleapis.com/maps/api/js"></script>
# To:     <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY"></script>

# 2. Run flutter
flutter run -d chrome --dart-define-from-file=env/dev.env.json

# 3. IMPORTANT: Restore web/index.html before committing!
git checkout web/index.html
```

## API Key Configuration

### Step 1: Get Your API Key

Your project already has an API key stored in `env/dev.env.json`:

```json
{
  "GOOGLE_MAPS_API_KEY_WEB": "YOUR_ACTUAL_API_KEY_HERE"
}
```

Use the same key from your Android/iOS configuration (for development).

### Step 2: Restrict API Key (Production)

For production deployment, create a separate restricted web API key:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services > Credentials**
3. Create a new API key or restrict existing key
4. **Application restrictions**: HTTP referrers
5. **Website restrictions**:
   ```
   http://localhost:*
   http://127.0.0.1:*
   https://yourdomain.com/*
   ```
6. **API restrictions**: Maps JavaScript API
7. Update `env/prod.env.json` with restricted key

### Step 3: Multiple Environments

Create separate env files for different environments:

```bash
# Development (unrestricted key, localhost only)
env/dev.env.json

# Staging (restricted to staging domain)
env/staging.env.json

# Production (restricted to production domain)
env/prod.env.json
```

All `*.env.json` files are gitignored for security.

## Security Best Practices

### ✅ DO

- ✅ Store API keys in `env/*.env.json` files (gitignored)
- ✅ Use build scripts (`./scripts/run_web.sh`, `./scripts/build_web.sh`)
- ✅ Commit `env/*.env.json.template` without real keys
- ✅ Restrict production API keys by HTTP referrer
- ✅ Use separate API keys for dev/staging/prod
- ✅ Set up billing alerts in Google Cloud Console

### ❌ DON'T

- ❌ Hardcode API keys in `web/index.html`
- ❌ Commit `env/dev.env.json` or any `*.env.json` with real keys
- ❌ Share API keys in Slack, email, or documentation
- ❌ Use unrestricted API keys in production
- ❌ Forget to run `git status` before committing (check for API keys)

## Troubleshooting

### "Map shows 'for development purposes only'"

This means the API key is missing or not injected:

```bash
# Check if API key exists in env file
grep GOOGLE_MAPS_API_KEY_WEB env/dev.env.json

# If missing, add it:
# Edit env/dev.env.json and add:
# "GOOGLE_MAPS_API_KEY_WEB": "YOUR_KEY_HERE"
```

### "API key committed to git accidentally"

**IMMEDIATE ACTION REQUIRED**:

1. **Remove from current commit**:
   ```bash
   git reset HEAD~1  # Undo last commit
   git checkout web/index.html  # Restore clean version
   git add web/index.html
   git commit -m "fix: restore clean web/index.html"
   ```

2. **Rotate the compromised API key**:
   - Go to Google Cloud Console
   - Delete the exposed API key
   - Create a new API key
   - Update `env/dev.env.json` with new key

3. **Verify gitignore**:
   ```bash
   cat env/.gitignore
   # Should contain: *.env.json
   ```

### "Build script not working"

Check script permissions:

```bash
ls -la scripts/
# Should show: -rwxr-xr-x (executable)

# If not executable:
chmod +x scripts/build_web.sh
chmod +x scripts/run_web.sh
```

## Verification Checklist

Before committing any changes:

- [ ] `git status` shows NO changes to `env/dev.env.json`
- [ ] `git diff web/index.html` shows NO API key in the script tag
- [ ] `env/.gitignore` contains `*.env.json`
- [ ] Root `.gitignore` contains `/env/*.env.json`
- [ ] Build scripts are executable (`chmod +x scripts/*.sh`)
- [ ] Template files have placeholder values only

## CI/CD Integration

For GitHub Actions or other CI platforms:

1. **Add secrets** to your CI platform:
   - `GOOGLE_MAPS_API_KEY_WEB` as a secret variable

2. **Create env file in CI**:
   ```yaml
   - name: Create env file
     run: |
       cat > env/ci.env.json << EOF
       {
         "MAP_LIVE_DATA": "false",
         "GOOGLE_MAPS_API_KEY_WEB": "${{ secrets.GOOGLE_MAPS_API_KEY_WEB }}"
       }
       EOF
   ```

3. **Build using script**:
   ```yaml
   - name: Build web
     run: ./scripts/build_web.sh env/ci.env.json
   ```

## Additional Resources

- [Google Maps API Security Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [Restricting API Keys](https://cloud.google.com/docs/authentication/api-keys#api_key_restrictions)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

---

**Last Updated**: October 20, 2025  
**Maintainer**: WildFire MVP v3 Team
