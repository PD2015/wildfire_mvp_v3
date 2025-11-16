#!/bin/bash
# Setup git hooks to use .githooks/ directory
# This ensures pre-commit security checks run for all developers

echo "🔧 Configuring git hooks..."

# Set git to use .githooks/ directory instead of .git/hooks/
git config core.hooksPath .githooks

echo "✅ Git hooks configured to use .githooks/"
echo ""
echo "Pre-commit hook will now run:"
echo "  • dart format (auto-format)"
echo "  • flutter analyze (static analysis)"
echo "  • gitleaks (secret detection)"
echo ""
echo "To bypass (not recommended): git commit --no-verify"
