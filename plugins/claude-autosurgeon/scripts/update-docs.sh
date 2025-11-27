#!/usr/bin/env bash

# Claude AutoSurgeon - Documentation Update Script
#
# This script fetches the latest Claude Code documentation from
# Anthropic's servers and updates the cached docs in this plugin.
#
# Usage: ./update-docs.sh
#
# The script will:
# 1. Fetch the documentation map to get the file list
# 2. Download all 45 documentation files
# 3. Update the VERSION file with new timestamp
# 4. Report what was updated

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="https://code.claude.com/docs/en"
DOCS_DIR="skills/claude-autosurgeon/docs/en"
VERSION_FILE="skills/claude-autosurgeon/docs/VERSION"

# File lists by category (as of 2025-11-06)
GETTING_STARTED=(overview quickstart common-workflows claude-code-on-the-web)
BUILD=(sub-agents plugins skills output-styles hooks-guide headless github-actions gitlab-ci-cd mcp migration-guide troubleshooting)
DEPLOYMENT=(third-party-integrations amazon-bedrock google-vertex-ai network-config llm-gateway devcontainer sandboxing)
ADMINISTRATION=(setup iam security data-usage monitoring-usage costs analytics plugin-marketplaces)
CONFIGURATION=(settings vs-code jetbrains terminal-config model-config memory statusline)
REFERENCE=(cli-reference interactive-mode slash-commands checkpointing hooks plugins-reference)
RESOURCES=(legal-and-compliance)

# Ensure we're in the plugin directory
if [[ ! -f "plugin.json" ]]; then
    echo -e "${RED}Error: Must run from plugin root directory (where plugin.json is located)${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Claude AutoSurgeon - Documentation Update Script  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Create docs directory if it doesn't exist
mkdir -p "$DOCS_DIR"

# Function to download a file
download_file() {
    local filename="$1"
    local filepath="$DOCS_DIR/$filename"

    if curl -sf "$BASE_URL/$filename" -o "$filepath"; then
        echo -e "${GREEN}✓${NC} $filename"
        return 0
    else
        echo -e "${RED}✗${NC} $filename (failed)"
        return 1
    fi
}

# Fetch the documentation map first
echo -e "${YELLOW}Fetching documentation map...${NC}"
if download_file "claude_code_docs_map.md"; then
    # Extract the "Last updated" timestamp from the map
    LAST_UPDATED=$(grep "Last updated:" "$DOCS_DIR/claude_code_docs_map.md" | sed 's/.*Last updated: //')
    echo -e "${GREEN}Documentation source last updated: $LAST_UPDATED${NC}"
    echo ""
else
    echo -e "${RED}Failed to fetch documentation map. Aborting.${NC}"
    exit 1
fi

# Download all documentation files by category
total_files=0
failed_files=0

echo -e "${YELLOW}Downloading Getting Started (4 files)...${NC}"
for file in "${GETTING_STARTED[@]}"; do
    download_file "$file.md" && ((total_files++)) || ((failed_files++))
done
echo ""

echo -e "${YELLOW}Downloading Build (11 files)...${NC}"
for file in "${BUILD[@]}"; do
    download_file "$file.md" && ((total_files++)) || ((failed_files++))
done
echo ""

echo -e "${YELLOW}Downloading Deployment (7 files)...${NC}"
for file in "${DEPLOYMENT[@]}"; do
    download_file "$file.md" && ((total_files++)) || ((failed_files++))
done
echo ""

echo -e "${YELLOW}Downloading Administration (8 files)...${NC}"
for file in "${ADMINISTRATION[@]}"; do
    download_file "$file.md" && ((total_files++)) || ((failed_files++))
done
echo ""

echo -e "${YELLOW}Downloading Configuration (7 files)...${NC}"
for file in "${CONFIGURATION[@]}"; do
    download_file "$file.md" && ((total_files++)) || ((failed_files++))
done
echo ""

echo -e "${YELLOW}Downloading Reference (6 files)...${NC}"
for file in "${REFERENCE[@]}"; do
    download_file "$file.md" && ((total_files++)) || ((failed_files++))
done
echo ""

echo -e "${YELLOW}Downloading Resources (1 file)...${NC}"
for file in "${RESOURCES[@]}"; do
    download_file "$file.md" && ((total_files++)) || ((failed_files++))
done
echo ""

# Update VERSION file
FETCH_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$VERSION_FILE" << EOF
Claude Code Documentation Cache
================================

Fetched: $FETCH_TIMESTAMP
Source Last Updated: $LAST_UPDATED
Total Files: $((total_files + 1))
Source: $BASE_URL/

This cache contains the complete Claude Code documentation
as of the fetch date above. Use the update-docs.sh script
to refresh when new Claude Code versions are released.
EOF

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Documentation Update Complete!${NC}"
echo ""
echo -e "  Total files: ${GREEN}$((total_files + 1))${NC} (including map file)"
if [[ $failed_files -gt 0 ]]; then
    echo -e "  Failed: ${RED}$failed_files${NC}"
fi
echo -e "  Fetch time: ${BLUE}$FETCH_TIMESTAMP${NC}"
echo -e "  Source updated: ${BLUE}$LAST_UPDATED${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Review the VERSION file: $VERSION_FILE"
echo -e "  2. Test the plugin to ensure docs are accessible"
echo -e "  3. Update plugin version in plugin.json if needed"
echo -e "  4. Commit changes: git add . && git commit -m 'docs: update cached documentation'"
echo -e "  5. Release new plugin version via Jake's marketplace"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# Exit with error if any files failed
if [[ $failed_files -gt 0 ]]; then
    exit 1
fi
