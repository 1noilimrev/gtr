#!/bin/sh
# gtr installer
# Usage: curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/install.sh | sh
set -e

REPO_URL="https://raw.githubusercontent.com/1noilimrev/gtr/main"
INSTALL_PATH="$HOME/.gtr.zsh"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE='[[ -f ~/.gtr.zsh ]] && source ~/.gtr.zsh'

# Colors (if terminal supports)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color
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

error() {
    printf "${RED}✗${NC} %s\n" "$1" >&2
    exit 1
}

# Check for zsh
if ! command -v zsh >/dev/null 2>&1; then
    error "zsh is required but not installed"
fi

# Check for curl
if ! command -v curl >/dev/null 2>&1; then
    error "curl is required but not installed"
fi

# Check for git
if ! command -v git >/dev/null 2>&1; then
    error "git is required but not installed"
fi

echo "Installing gtr..."

# Backup existing file if present
if [ -f "$INSTALL_PATH" ]; then
    BACKUP_PATH="${INSTALL_PATH}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$INSTALL_PATH" "$BACKUP_PATH"
    info "Backed up existing file to $BACKUP_PATH"
fi

# Download gtr.zsh
if ! curl -fsSL "$REPO_URL/gtr.zsh" -o "$INSTALL_PATH"; then
    error "Failed to download gtr.zsh"
fi
info "Downloaded gtr.zsh to $INSTALL_PATH"

# Add source line to .zshrc if not present
if [ -f "$ZSHRC" ]; then
    if ! grep -qF ".gtr.zsh" "$ZSHRC" 2>/dev/null; then
        echo "" >> "$ZSHRC"
        echo "$SOURCE_LINE" >> "$ZSHRC"
        info "Added source line to $ZSHRC"
    else
        info "Source line already exists in $ZSHRC"
    fi
else
    echo "$SOURCE_LINE" > "$ZSHRC"
    info "Created $ZSHRC with source line"
fi

# Get installed version
VERSION=$(grep -m1 'GTR_VERSION=' "$INSTALL_PATH" | cut -d'"' -f2)

echo ""
echo "${GREEN}✓ gtr ${VERSION} installed successfully!${NC}"
echo ""
echo "To start using gtr, run:"
echo "  ${YELLOW}source ~/.zshrc${NC}"
echo ""
echo "Or open a new terminal."
