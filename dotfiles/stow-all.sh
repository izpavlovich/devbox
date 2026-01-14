#!/usr/bin/env bash
#
# Stow all dotfiles modules to the home directory
# Usage: ./stow-all.sh [--dry-run] [--restow]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
DRY_RUN=false
RESTOW=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --restow|-R)
            RESTOW=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Stow all dotfiles modules to the home directory."
            echo ""
            echo "Options:"
            echo "  -n, --dry-run   Show what would be done without making changes"
            echo "  -R, --restow    Restow packages (useful for updating symlinks)"
            echo "  -v, --verbose   Show verbose output"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo -e "${RED}Error: GNU Stow is not installed.${NC}"
    echo ""
    echo "Install it with:"
    echo "  macOS:  brew install stow"
    echo "  Ubuntu: sudo apt install stow"
    echo "  Fedora: sudo dnf install stow"
    exit 1
fi

# Define modules to stow
# Order matters: shell should be stowed before bash/zsh since they may depend on it
MODULES=(
    shell      # Shared shell configuration (aliases, shellrc)
    bash       # Bash configuration
    zsh        # Zsh configuration
    git        # Git configuration
    starship   # Starship prompt
    tmux       # Tmux configuration
    bat        # Bat (better cat) configuration
    ghostty    # Ghostty terminal configuration
    claude     # Claude AI settings
    cspell     # CSpell dictionary
)

# Platform-specific modules (uncomment if needed)
# case "$(uname -s)" in
#     Darwin)
#         MODULES+=(macos-specific)
#         ;;
#     Linux)
#         MODULES+=(linux-specific)
#         ;;
# esac

echo -e "${GREEN}Stowing dotfiles to ${TARGET_DIR}${NC}"
echo ""

# Build stow options
STOW_OPTS=("--target=${TARGET_DIR}")

if [[ "${DRY_RUN}" == true ]]; then
    STOW_OPTS+=("--simulate")
    echo -e "${YELLOW}Dry run mode - no changes will be made${NC}"
    echo ""
fi

if [[ "${RESTOW}" == true ]]; then
    STOW_OPTS+=("--restow")
fi

if [[ "${VERBOSE}" == true ]]; then
    STOW_OPTS+=("--verbose")
fi

# Track results
SUCCESS=()
SKIPPED=()
FAILED=()

# Stow each module
for module in "${MODULES[@]}"; do
    module_path="${SCRIPT_DIR}/${module}"

    # Check if module directory exists
    if [[ ! -d "${module_path}" ]]; then
        echo -e "${YELLOW}Skipping ${module}: directory not found${NC}"
        SKIPPED+=("${module}")
        continue
    fi

    # Check if module has any files to stow
    if [[ -z "$(find "${module_path}" -type f 2>/dev/null)" ]]; then
        echo -e "${YELLOW}Skipping ${module}: no files to stow${NC}"
        SKIPPED+=("${module}")
        continue
    fi

    echo -n "Stowing ${module}... "

    if stow "${STOW_OPTS[@]}" --dir="${SCRIPT_DIR}" "${module}" 2>&1; then
        echo -e "${GREEN}done${NC}"
        SUCCESS+=("${module}")
    else
        echo -e "${RED}failed${NC}"
        FAILED+=("${module}")
    fi
done

# Print summary
echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo -e "${GREEN}Stowed:${NC}  ${#SUCCESS[@]} modules"
[[ ${#SUCCESS[@]} -gt 0 ]] && echo "         ${SUCCESS[*]}"

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Skipped:${NC} ${#SKIPPED[@]} modules"
    echo "         ${SKIPPED[*]}"
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo -e "${RED}Failed:${NC}  ${#FAILED[@]} modules"
    echo "         ${FAILED[*]}"
    echo ""
    echo "To debug failures, run with --verbose flag"
    exit 1
fi

echo ""
echo -e "${GREEN}Dotfiles installation complete!${NC}"
