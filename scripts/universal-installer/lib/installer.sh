#!/bin/bash
# ============================================================
# installer.sh — Core installation logic
# ============================================================
# Iterates through packages, resolves names, installs, and
# handles fallbacks. Never aborts on a single failure.
#
# Requires: all other lib modules loaded

# ── Counters ────────────────────────────────────────────────
_INSTALLED_COUNT=0
_SKIPPED_COUNT=0
_FAILED_COUNT=0
_FAILED_PKGS=()

# ── Check if already installed via binary probe ─────────────
_is_already_installed() {
    local canonical="$1"
    local binary="${PKG_BINARY[$canonical]:-}"

    # Font/icon packages: check differently
    case "$canonical" in
        font-jetbrains-mono-nerd)
            font_is_installed "JetBrains" && return 0
            return 1
            ;;
        nerd-fonts)
            font_is_installed "Symbols Nerd Font" && return 0
            return 1
            ;;
        papirus-icon-theme)
            [[ -d "/usr/share/icons/Papirus" ]] && return 0
            return 1
            ;;
    esac

    # Binary check
    if [[ -n "$binary" ]]; then
        command -v "$binary" &>/dev/null && return 0
    fi

    # Also try the package manager's own check
    local resolved
    resolved=$(resolve_package "$canonical")
    if [[ -n "$resolved" ]]; then
        pm_is_installed "$resolved" && return 0
    fi

    return 1
}

# ── Attempt fallback installation ───────────────────────────
_try_fallback() {
    local canonical="$1"
    local fallback="${PKG_FALLBACK[$canonical]:-}"

    if [[ -z "$fallback" ]]; then
        return 1
    fi

    local method="${fallback%%:*}"
    local target="${fallback#*:}"

    case "$method" in
        pip)
            log_verbose "Fallback: pip install $target"
            pm_install_pip "$target"
            return $?
            ;;
        cargo)
            if command -v cargo &>/dev/null; then
                log_verbose "Fallback: cargo install $target"
                local cmd="cargo install $target"
                log_cmd "$cmd"
                if [[ "${DRY_RUN:-false}" == true ]]; then
                    log_verbose "(dry-run) would execute: $cmd"
                    return 0
                fi
                eval "$cmd" >> "$_LOG_FILE" 2>&1
                return $?
            fi
            log_verbose "cargo not available for fallback"
            return 1
            ;;
        go)
            if command -v go &>/dev/null; then
                log_verbose "Fallback: go install $target"
                local cmd="go install $target"
                log_cmd "$cmd"
                if [[ "${DRY_RUN:-false}" == true ]]; then
                    log_verbose "(dry-run) would execute: $cmd"
                    return 0
                fi
                eval "$cmd" >> "$_LOG_FILE" 2>&1
                return $?
            fi
            log_verbose "go not available for fallback"
            return 1
            ;;
        font)
            install_font_package "$canonical"
            local ret=$?
            [[ $ret -eq 0 || $ret -eq 2 ]] && return 0
            return 1
            ;;
        skip)
            log_warn "$canonical — not available on this distro (skipped)"
            return 2  # 2 = intentional skip, not a failure
            ;;
        *)
            log_verbose "Unknown fallback method: $method"
            return 1
            ;;
    esac
}

# ── Install a single package ────────────────────────────────
# Returns: 0=installed, 1=failed, 2=skipped (already installed or intentional)
_install_one() {
    local canonical="$1"

    # 1. Already installed?
    if _is_already_installed "$canonical"; then
        log_skip "$canonical (already installed)"
        return 2
    fi

    # 2. Resolve distro-specific name
    local resolved
    resolved=$(resolve_package "$canonical")

    # 3. Empty mapping = not available in repos
    if [[ -z "$resolved" ]]; then
        log_verbose "$canonical has empty mapping — trying fallback"
        _try_fallback "$canonical"
        return $?
    fi

    # 4. Font packages get special handling
    if [[ "$canonical" == font-* || "$canonical" == nerd-fonts ]]; then
        install_font_package "$canonical"
        local ret=$?
        [[ $ret -eq 2 ]] && return 2  # already installed
        return $ret
    fi

    # 5. Try repo install
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_info "$canonical → ${_C_BOLD}$resolved${_C_RESET}"
        return 0
    fi

    if pm_install "$resolved"; then
        log_ok "$canonical → $resolved"
        return 0
    fi

    # 6. Repo failed — try AUR (Arch only)
    if [[ "$DETECTED_FAMILY" == "arch" && -n "$DETECTED_AUR" ]]; then
        log_verbose "Repo failed for $resolved, trying AUR..."
        if pm_install_aur "$resolved"; then
            log_ok "$canonical → $resolved (AUR)"
            return 0
        fi
    fi

    # 7. Try fallback
    log_verbose "Repo install failed for $canonical, trying fallback..."
    _try_fallback "$canonical"
    return $?
}

# ── Install a category of packages ──────────────────────────
install_category() {
    local category="$1"
    local label="${CATEGORY_LABELS[$category]:-$category}"
    local pkgs
    pkgs=$(get_category_packages "$category")

    if [[ -z "$pkgs" ]]; then
        log_warn "No packages defined for category '$category'"
        return
    fi

    log_section "$label"

    for pkg in $pkgs; do
        _install_one "$pkg" && ret=0 || ret=$?
        case $ret in
            0) _INSTALLED_COUNT=$((_INSTALLED_COUNT + 1)) ;;
            2) _SKIPPED_COUNT=$((_SKIPPED_COUNT + 1)) ;;
            *)
                _FAILED_COUNT=$((_FAILED_COUNT + 1))
                _FAILED_PKGS+=("$pkg")
                ;;
        esac
    done
}

# ── Install bootstrap dependencies ──────────────────────────
install_bootstrap() {
    log_section "Bootstrap Dependencies"

    for dep in $BOOTSTRAP_DEPS; do
        if command -v "$dep" &>/dev/null; then
            log_skip "$dep (already installed)"
        else
            local resolved
            resolved=$(resolve_package "$dep")
            resolved="${resolved:-$dep}"  # Fall back to canonical name

            if [[ "${DRY_RUN:-false}" == true ]]; then
                log_info "$dep → ${_C_BOLD}$resolved${_C_RESET}"
            else
                if pm_install "$resolved"; then
                    log_ok "$dep → $resolved"
                else
                    log_warn "$dep — could not install (continuing)"
                fi
            fi
        fi
    done
}

# ── Install all categories ──────────────────────────────────
install_all() {
    for cat in "${CATEGORY_ORDER[@]}"; do
        install_category "$cat"
    done
}

# ── Print failed packages ──────────────────────────────────
print_failures() {
    if [[ ${#_FAILED_PKGS[@]} -gt 0 ]]; then
        echo ""
        echo -e "  ${_C_RED}Failed packages:${_C_RESET}"
        for pkg in "${_FAILED_PKGS[@]}"; do
            echo -e "    ${_C_RED}${_SYM_FAIL}${_C_RESET} $pkg"
        done
    fi
}

# ── Get counters ────────────────────────────────────────────
get_installed_count() { echo "$_INSTALLED_COUNT"; }
get_skipped_count()   { echo "$_SKIPPED_COUNT"; }
get_failed_count()    { echo "$_FAILED_COUNT"; }
