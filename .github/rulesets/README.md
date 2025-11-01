# Branch Protection Rulesets

This directory contains GitHub branch protection rulesets in JSON format for easy import.

## Files

- **`main-branch-protection.json`** - Production branch protection (requires approval)
- **`staging-branch-protection.json`** - Integration branch protection (CI checks only)

## How to Import

### Option 1: GitHub Web UI (Recommended)

1. **Navigate to Rulesets page**:
   ```
   https://github.com/PD2015/wildfire_mvp_v3/settings/rules
   ```

2. **Click "New ruleset" → "Import a ruleset"**

3. **Upload JSON files**:
   - Upload `main-branch-protection.json`
   - Click "Create"
   - Repeat for `staging-branch-protection.json`

### Option 2: GitHub CLI (Advanced)

```bash
# Main branch ruleset
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/PD2015/wildfire_mvp_v3/rulesets \
  --input .github/rulesets/main-branch-protection.json

# Staging branch ruleset
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/PD2015/wildfire_mvp_v3/rulesets \
  --input .github/rulesets/staging-branch-protection.json
```

## What These Rulesets Enforce

### Main Branch (`main`)
- ✅ Requires pull request with 1 approval
- ✅ All CI status checks must pass
- ✅ Dismisses stale reviews on new commits
- ✅ Requires conversation resolution
- ✅ Requires linear history (no merge commits)
- ✅ Blocks direct pushes and deletions
- ✅ Blocks force pushes

### Staging Branch (`staging`)
- ✅ Requires pull request (no approval needed)
- ✅ All CI status checks must pass
- ✅ Dismisses stale reviews on new commits
- ✅ Requires conversation resolution
- ✅ Blocks direct pushes and deletions
- ✅ Blocks force pushes
- ❌ No linear history requirement (allows merge commits)

## Required Status Checks

Both rulesets require these CI checks to pass:

1. `Quality Gates (Format, Analyze, Test)`
2. `Constitutional Compliance (C1-C5)`
3. `Build Web Artifact`
4. `Verify iOS Xcode Build Phase`

## Verify Rulesets

After import, verify with:

```bash
# List all rulesets
gh api /repos/PD2015/wildfire_mvp_v3/rulesets

# Get specific ruleset details
gh api /repos/PD2015/wildfire_mvp_v3/rulesets/{ruleset_id}
```

## Modify Rulesets

To modify a ruleset:

1. Export from GitHub UI: Settings → Rules → Click ruleset → Export
2. Edit the JSON file
3. Re-import via GitHub UI

Or edit directly via API:

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/PD2015/wildfire_mvp_v3/rulesets/{ruleset_id} \
  --input .github/rulesets/main-branch-protection.json
```

## Troubleshooting

### "Required status checks not found"

If CI check names have changed, update the `context` values in the JSON files:

```json
{
  "context": "Your New Job Name Here",
  "integration_id": null
}
```

### Import fails with validation error

Check that:
- JSON is valid (use `jq` or JSON validator)
- Branch names match your repository
- Status check names match your workflow job names

## Related Documentation

- [Branching Strategy](../../docs/BRANCHING_STRATEGY.md)
- [CI/CD Workflow Guide](../../docs/CI_CD_WORKFLOW_GUIDE.md)
- [GitHub Rulesets Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
