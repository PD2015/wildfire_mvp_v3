#!/usr/bin/env bash
set -euo pipefail


# Color Guard — WildFire (Gate C4)
# Fails CI if any hardcoded hex color in the codebase is not present in scripts/allowed_colors.txt
# Usage (CI): scripts/color_guard.sh
# Requires: bash, grep, awk, sort, tr


ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
ALLOWED_FILE="$ROOT_DIR/scripts/allowed_colors.txt"
CODE_DIRS=("lib" "assets" "packages")


if [[ ! -f "$ALLOWED_FILE" ]]; then
echo "[color-guard] ERROR: $ALLOWED_FILE not found. Add it before running." >&2
exit 2
fi


# Collect all hex colors from code (e.g., #A1B2C3). Exclude comments in the allowlist.
mapfile -t FOUND < <(grep -RInE "#[0-9a-fA-F]{6}\b" "${CODE_DIRS[@]}" 2>/dev/null \
| awk '{
match($0, /#[0-9a-fA-F]{6}\b/);
if (RSTART>0) print toupper(substr($0, RSTART, RLENGTH));
}' | sort -u)


# Load allowed and exception lists
mapfile -t ALLOWED < <(grep -vE '^\s*#|^\s*$' "$ALLOWED_FILE" | tr '[:lower:]' '[:upper:]')


if [[ ${#FOUND[@]} -eq 0 ]]; then
echo "[color-guard] No hex colors found in code directories (${CODE_DIRS[*]}). OK"
exit 0
fi


# Compute disallowed = FOUND - ALLOWED
# Use temporary files for portability
FOUND_FILE=$(mktemp)
ALLOW_FILE=$(mktemp)
printf "%s\n" "${FOUND[@]}" | sort -u > "$FOUND_FILE"
printf "%s\n" "${ALLOWED[@]}" | sort -u > "$ALLOW_FILE"
DISALLOWED=$(comm -23 "$FOUND_FILE" "$ALLOW_FILE" || true)
rm -f "$FOUND_FILE" "$ALLOW_FILE"


if [[ -n "$DISALLOWED" ]]; then
echo "[color-guard] ❌ Disallowed colors detected (not in scripts/allowed_colors.txt):"
echo "$DISALLOWED" | sed 's/^/ - /'
echo
echo "To fix:"
echo " 1) Replace these colors with approved constants; or"
echo " 2) If they are intentionally approved, add them to scripts/allowed_colors.txt (with a comment)."
exit 1
fi


echo "[color-guard] ✅ All colors are approved."