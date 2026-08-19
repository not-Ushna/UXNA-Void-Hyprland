#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  UXNA · Universal Installer                                         ║
# ║  Cross-distro package bootstrap for the UXNA Hyprland desktop       ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   ./install.sh                        # Install everything
#   ./install.sh --dry-run              # Preview only, nothing installed
#   ./install.sh --core                 # Only core packages
#   ./install.sh --utilities            # Only utilities
#   ./install.sh --theming              # Only theming packages
#   ./install.sh --shell                # Only shell tools
#   ./install.sh --fonts                # Only fonts
#   ./install.sh --all                  # Explicit all (default)
#   ./install.sh --skip fonts           # Skip a category
#   ./install.sh --skip pywal,nwg-look  # Skip specific packages
#   ./install.sh --verbose              # Extra debug output
#   ./install.sh --verify-only          # Only run verification
#   ./install.sh --help                 # Show this help

set -eo pipefail

# ── Resolve script directory ────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Source all library modules ──────────────────────────────
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/package-manager.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/fonts.sh"
source "$SCRIPT_DIR/lib/nix.sh"
source "$SCRIPT_DIR/lib/installer.sh"
source "$SCRIPT_DIR/lib/verify.sh"

# ── Globals ─────────────────────────────────────────────────
DRY_RUN=false
VERIFY_ONLY=false
SELECTED_CATEGORIES=()
SKIP_CATEGORIES=()
SKIP_PACKAGES=()

# ── Parse arguments ─────────────────────────────────────────
_parse_args() {
    local expect_skip=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --verbose)
                log_set_verbose
                ;;
            --verify-only)
                VERIFY_ONLY=true
                ;;
            --core|--utilities|--theming|--shell|--fonts)
                SELECTED_CATEGORIES+=("${1#--}")
                ;;
            --all)
                SELECTED_CATEGORIES=()  # empty = all
                ;;
            --skip)
                expect_skip=true
                ;;
            --help|-h)
                _print_help
                exit 0
                ;;
            *)
                if [[ "$expect_skip" == true ]]; then
                    # Parse comma-separated skip list
                    IFS=',' read -ra items <<< "$1"
                    for item in "${items[@]}"; do
                        item=$(echo "$item" | xargs)
                        # Is it a category name?
                        if [[ -n "${PKG_CATEGORIES[$item]+_}" ]]; then
                            SKIP_CATEGORIES+=("$item")
                        else
                            SKIP_PACKAGES+=("$item")
                        fi
                    done
                    expect_skip=false
                else
                    echo "Unknown option: $1 (use --help)"
                    exit 1
                fi
                ;;
        esac
        shift
    done
}

_print_help() {
    echo "UXNA · Universal Installer"
    echo ""
    echo "Usage: install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run         Preview what would be installed (nothing changes)"
    echo "  --verbose         Show detailed debug output"
    echo "  --verify-only     Only verify installed packages, don't install"
    echo ""
    echo "  --core            Install only core packages"
    echo "  --utilities       Install only utilities"
    echo "  --theming         Install only theming packages"
    echo "  --shell           Install only shell tools"
    echo "  --fonts           Install only fonts"
    echo "  --all             Install everything (default)"
    echo ""
    echo "  --skip <list>     Skip categories or packages (comma-separated)"
    echo "                    e.g. --skip fonts"
    echo "                    e.g. --skip pywal,nwg-look,kvantum"
    echo ""
    echo "  --help, -h        Show this help"
    echo ""
    echo "Supported distro families:"
    echo "  Arch, Debian, Fedora, openSUSE, Void, Gentoo, Alpine, NixOS"
}

# ── Check if a package should be skipped ────────────────────
_is_skipped() {
    local pkg="$1"
    for s in "${SKIP_PACKAGES[@]}"; do
        [[ "$s" == "$pkg" ]] && return 0
    done
    return 1
}

_is_category_skipped() {
    local cat="$1"
    for s in "${SKIP_CATEGORIES[@]}"; do
        [[ "$s" == "$cat" ]] && return 0
    done
    return 1
}

# ── Privilege check ─────────────────────────────────────────
_check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running as root. The installer will use sudo only when needed."
        log_warn "It is recommended to run as a normal user."
    fi

    # Check if sudo is available (not needed on NixOS for nix profile)
    if [[ "$DETECTED_PM" != "nix" ]] && ! command -v sudo &>/dev/null; then
        log_fatal "sudo is required but not found. Please install sudo first."
    fi
}

# ── Main ────────────────────────────────────────────────────
main() {
    _parse_args "$@"

    # Init logging
    log_init
    log_banner

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${_C_YELLOW}${_C_BOLD}DRY RUN${_C_RESET} — nothing will be installed"
        echo ""
    fi

    # Detect system
    log_section "System Detection"
    detect_system

    # Init package mappings
    packages_init

    # NixOS guidance
    if nix_is_nixos; then
        nix_print_guidance
    fi

    # Verify-only mode
    if [[ "$VERIFY_ONLY" == true ]]; then
        verify_installation
        log_location
        exit $?
    fi

    # Privilege check
    _check_privileges

    # Update package index
    if [[ "$DRY_RUN" != true ]]; then
        pm_update
    fi

    # Bootstrap dependencies
    install_bootstrap

    # Determine which categories to install
    local categories_to_install=()
    if [[ ${#SELECTED_CATEGORIES[@]} -gt 0 ]]; then
        categories_to_install=("${SELECTED_CATEGORIES[@]}")
    else
        categories_to_install=("${CATEGORY_ORDER[@]}")
    fi

    # Remove skipped categories
    local final_categories=()
    for cat in "${categories_to_install[@]}"; do
        if ! _is_category_skipped "$cat"; then
            final_categories+=("$cat")
        else
            log_verbose "Skipping category: $cat"
        fi
    done

    # Remove individually skipped packages from PKG_CATEGORIES
    # (Temporarily override the category lists)
    if [[ ${#SKIP_PACKAGES[@]} -gt 0 ]]; then
        for cat in "${final_categories[@]}"; do
            local filtered=""
            for pkg in ${PKG_CATEGORIES[$cat]}; do
                if ! _is_skipped "$pkg"; then
                    filtered+="$pkg "
                else
                    log_verbose "Skipping package: $pkg"
                fi
            done
            PKG_CATEGORIES[$cat]="$filtered"
        done
    fi

    # Install
    for cat in "${final_categories[@]}"; do
        install_category "$cat"
    done

    # Print failures
    print_failures

    # Summary
    log_summary "$_INSTALLED_COUNT" "$_SKIPPED_COUNT" "$_FAILED_COUNT"

    # Verification (unless dry-run)
    if [[ "$DRY_RUN" != true ]]; then
        verify_installation
    fi

    # Log location
    log_location
    echo ""
}

main "$@"
