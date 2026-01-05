#!/usr/bin/env zsh
# ---------------------------------------------------------------------------------------
# gtr - DEPRECATED: Use gwt instead
#
# This is a wrapper that calls gwt and shows a deprecation warning.
# Run the migration script to switch to gwt:
#   curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/migrate.sh | sh
# --------------------------------------------------------------------------------------

GTR_VERSION="1.0.0"

gtr() {
    local YELLOW='\033[0;33m'
    local CYAN='\033[0;36m'
    local NC='\033[0m'

    echo "" >&2
    echo "${YELLOW}⚠ DEPRECATION WARNING: 'gtr' is deprecated. Please use 'gwt' instead.${NC}" >&2
    echo "" >&2
    echo "To migrate from gtr to gwt, run:" >&2
    echo "  ${CYAN}curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/migrate.sh | sh${NC}" >&2
    echo "" >&2
    echo "Or manually:" >&2
    echo "  Uninstall gtr: ${CYAN}curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/uninstall.sh | sh${NC}" >&2
    echo "  Install gwt:   ${CYAN}curl -fsSL https://raw.githubusercontent.com/1noilimrev/gwt/main/install.sh | sh${NC}" >&2
    echo "" >&2

    if (( $+functions[gwt] )); then
        gwt "$@"
    else
        echo "error: gwt is not installed. Please run the migration script above." >&2
        return 1
    fi
}
