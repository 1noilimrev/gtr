#!/bin/sh
# gtr uninstaller
# Usage: curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/uninstall.sh | sh
set -e

INSTALL_PATH="$HOME/.gtr.zsh"
ZSHRC="$HOME/.zshrc"

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

info() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

warn() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

echo "Uninstalling gtr..."

if [ -f "$INSTALL_PATH" ]; then
    rm -f "$INSTALL_PATH"
    info "Removed $INSTALL_PATH"
else
    warn "$INSTALL_PATH not found (already removed?)"
fi

if [ -f "$ZSHRC" ]; then
    if grep -qF ".gtr.zsh" "$ZSHRC" 2>/dev/null; then
        if [ "$(uname)" = "Darwin" ]; then
            sed -i '' '/\.gtr\.zsh/d' "$ZSHRC"
        else
            sed -i '/\.gtr\.zsh/d' "$ZSHRC"
        fi
        info "Removed gtr source line from $ZSHRC"
    else
        info "No gtr source line found in $ZSHRC"
    fi
fi

echo ""
echo "${GREEN}✓ gtr uninstalled successfully!${NC}"
echo ""
echo "To complete uninstallation, run:"
echo "  ${YELLOW}source ~/.zshrc${NC}"
echo ""
echo "Or open a new terminal."
