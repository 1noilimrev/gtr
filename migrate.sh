#!/bin/sh
# gtr -> gwt migration script
# Usage: curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/migrate.sh | sh
set -e

GTR_UNINSTALL_URL="https://raw.githubusercontent.com/1noilimrev/gtr/main/uninstall.sh"
GWT_INSTALL_URL="https://raw.githubusercontent.com/1noilimrev/gwt/main/install.sh"

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

echo "${BLUE}=== gtr -> gwt Migration ===${NC}"
echo ""

echo "${YELLOW}Step 1/2: Uninstalling gtr...${NC}"
curl -fsSL "$GTR_UNINSTALL_URL" | sh

echo ""
echo "${YELLOW}Step 2/2: Installing gwt...${NC}"
curl -fsSL "$GWT_INSTALL_URL" | sh

echo ""
echo "${GREEN}=== Migration Complete ===${NC}"
echo ""
echo "The 'gtr' command has been replaced with 'gwt'."
echo "All commands remain the same, just use 'gwt' instead of 'gtr'."
echo ""
echo "To start using gwt, run:"
echo "  ${YELLOW}source ~/.zshrc${NC}"
echo ""
echo "Or open a new terminal."
