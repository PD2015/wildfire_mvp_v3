#!/bin/bash
# Documentation Health Check Script
# Identifies stale, duplicate, or problematic documentation

set -e

DOCS_DIR="docs"
STALE_DAYS=90
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 WildFire MVP v3 - Documentation Health Check"
echo "================================================"
echo ""

# Check 1: Files not updated in X days
echo "📅 Checking for stale documentation (>$STALE_DAYS days)..."
STALE_COUNT=0
while IFS= read -r file; do
    if [ -f "$file" ]; then
        DAYS_OLD=$(( ($(date +%s) - $(stat -f %m "$file")) / 86400 ))
        if [ $DAYS_OLD -gt $STALE_DAYS ]; then
            echo -e "${YELLOW}⚠️  $file${NC} (${DAYS_OLD} days old)"
            ((STALE_COUNT++))
        fi
    fi
done < <(find "$DOCS_DIR" -name "*.md" -not -path "*/history/*" -not -path "*/deprecated/*")

if [ $STALE_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ No stale documentation found${NC}"
else
    echo -e "${YELLOW}Found $STALE_COUNT stale files${NC}"
fi
echo ""

# Check 2: Potential duplicates (same filename, different case/location)
echo "📋 Checking for potential duplicate filenames..."
DUPLICATE_COUNT=0
find "$DOCS_DIR" -name "*.md" -not -path "*/history/*" | \
    sed 's|.*/||' | \
    tr '[:upper:]' '[:lower:]' | \
    sort | \
    uniq -d | \
while read -r duplicate; do
    echo -e "${YELLOW}⚠️  Potential duplicate: $duplicate${NC}"
    find "$DOCS_DIR" -name "*.md" -not -path "*/history/*" | grep -i "$duplicate" | sed 's/^/    /'
    ((DUPLICATE_COUNT++))
done

if [ $DUPLICATE_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ No duplicate filenames found${NC}"
else
    echo -e "${YELLOW}Found $DUPLICATE_COUNT potential duplicates${NC}"
fi
echo ""

# Check 3: Missing frontmatter
echo "📝 Checking for missing frontmatter..."
MISSING_FM_COUNT=0
while IFS= read -r file; do
    if ! grep -q "^---$" "$file" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  $file${NC}"
        ((MISSING_FM_COUNT++))
    fi
done < <(find "$DOCS_DIR" -name "*.md" -not -path "*/history/*" -not -path "*/deprecated/*")

if [ $MISSING_FM_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ All active docs have frontmatter${NC}"
else
    echo -e "${YELLOW}Found $MISSING_FM_COUNT files without frontmatter${NC}"
fi
echo ""

# Check 4: Broken internal links
echo "🔗 Checking for broken internal links..."
BROKEN_LINKS=0
while IFS= read -r file; do
    # Extract markdown links: [text](path)
    grep -oE '\[.*?\]\(([^)]+)\)' "$file" 2>/dev/null | \
        grep -oE '\(([^)]+)\)' | \
        tr -d '()' | \
    while read -r link; do
        # Skip external links
        if [[ "$link" =~ ^https?:// ]]; then
            continue
        fi
        
        # Check if file exists (relative to docs directory)
        LINK_PATH="$DOCS_DIR/$link"
        if [ ! -f "$LINK_PATH" ] && [ ! -d "$LINK_PATH" ]; then
            echo -e "${RED}❌ Broken link in $file: $link${NC}"
            ((BROKEN_LINKS++))
        fi
    done
done < <(find "$DOCS_DIR" -name "*.md")

if [ $BROKEN_LINKS -eq 0 ]; then
    echo -e "${GREEN}✅ No broken internal links found${NC}"
else
    echo -e "${RED}Found $BROKEN_LINKS broken links${NC}"
fi
echo ""

# Summary
echo "================================================"
echo "📊 Summary:"
echo "  - Stale files (>$STALE_DAYS days): $STALE_COUNT"
echo "  - Potential duplicates: $DUPLICATE_COUNT"
echo "  - Missing frontmatter: $MISSING_FM_COUNT"
echo "  - Broken links: $BROKEN_LINKS"
echo ""

TOTAL_ISSUES=$((STALE_COUNT + DUPLICATE_COUNT + MISSING_FM_COUNT + BROKEN_LINKS))
if [ $TOTAL_ISSUES -eq 0 ]; then
    echo -e "${GREEN}🎉 Documentation health: EXCELLENT${NC}"
    exit 0
elif [ $TOTAL_ISSUES -lt 10 ]; then
    echo -e "${YELLOW}⚠️  Documentation health: GOOD (minor issues)${NC}"
    exit 0
else
    echo -e "${RED}❌ Documentation health: NEEDS ATTENTION${NC}"
    exit 1
fi
