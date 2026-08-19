#!/bin/bash
# ============================================================
# nix.sh — NixOS-specific handler
# ============================================================
# NixOS is fundamentally different from imperative distros.
# This module handles Nix-specific installation logic.
#
# Supports:
#   1. NixOS (the distro) — nix profile install
#   2. Nix on another distro — nix profile as supplement

# ── Detect Nix environment ──────────────────────────────────
nix_is_nixos() {
    [[ "$DETECTED_FAMILY" == "nix" ]]
}

nix_is_available() {
    command -v nix &>/dev/null
}

nix_has_flakes() {
    nix --version &>/dev/null && nix flake --help &>/dev/null 2>&1
}

# ── Install a package via nix profile ───────────────────────
nix_install() {
    local pkg="$1"
    local resolved
    resolved=$(resolve_package "$pkg")

    if [[ -z "$resolved" ]]; then
        log_verbose "Package '$pkg' has no nix mapping, skipping"
        return 1
    fi

    local cmd="nix profile install nixpkgs#${resolved}"
    log_cmd "$cmd"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_verbose "(dry-run) would execute: $cmd"
        return 0
    fi

    if eval "$cmd" >> "$_LOG_FILE" 2>&1; then
        return 0
    else
        log_verbose "nix profile install failed for $resolved"
        return 1
    fi
}

# ── Check if a package is installed in nix profile ──────────
nix_is_installed() {
    local pkg="$1"
    nix profile list 2>/dev/null | grep -q "$pkg"
    return $?
}

# ── Print NixOS guidance ────────────────────────────────────
nix_print_guidance() {
    echo ""
    log_info "${_C_BOLD}NixOS detected${_C_RESET}"
    echo ""
    echo -e "  ${_C_DIM}On NixOS, packages installed via 'nix profile install' are${_C_RESET}"
    echo -e "  ${_C_DIM}user-level and do not modify your system configuration.${_C_RESET}"
    echo ""
    echo -e "  ${_C_DIM}For a declarative setup, add these to your configuration.nix:${_C_RESET}"
    echo ""
    echo -e "  ${_C_CYAN}environment.systemPackages = with pkgs; [${_C_RESET}"

    local all_pkgs
    all_pkgs=$(get_all_packages)
    for pkg in $all_pkgs; do
        local resolved
        resolved=$(resolve_package "$pkg")
        [[ -n "$resolved" ]] && echo -e "    ${_C_WHITE}${resolved}${_C_RESET}"
    done

    echo -e "  ${_C_CYAN}];${_C_RESET}"
    echo ""
    _log_raw "NixOS guidance printed"
}
