#!/bin/bash
# ============================================================
# package-manager.sh — Unified package manager abstraction
# ============================================================
# The rest of the codebase NEVER calls a package manager
# directly. Everything goes through these functions.
#
# Requires: DETECTED_PM, DETECTED_AUR (from detect.sh)

# Track whether we've already updated the package index
_PM_UPDATED=false

# ── Update package index ────────────────────────────────────
pm_update() {
    if [[ "$_PM_UPDATED" == true ]]; then
        log_verbose "Package index already updated this session, skipping"
        return 0
    fi

    log_info "Updating package index..."

    local cmd
    case "$DETECTED_PM" in
        pacman)  cmd="sudo pacman -Sy" ;;
        apt)     cmd="sudo apt-get update -qq" ;;
        dnf)     cmd="sudo dnf check-update" ;;
        zypper)  cmd="sudo zypper --non-interactive refresh" ;;
        xbps)    cmd="sudo xbps-install -S" ;;
        emerge)  cmd="sudo emerge --sync" ;;
        apk)     cmd="sudo apk update" ;;
        nix)     cmd="nix-channel --update" ;;
        *)       log_warn "Unknown PM '$DETECTED_PM', cannot update index"; return 1 ;;
    esac

    log_cmd "$cmd"
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_verbose "(dry-run) would execute: $cmd"
        _PM_UPDATED=true
        return 0
    fi

    # dnf check-update returns 100 when updates are available, which is not an error
    if [[ "$DETECTED_PM" == "dnf" ]]; then
        eval "$cmd" >> "$_LOG_FILE" 2>&1 || true
    else
        if eval "$cmd" >> "$_LOG_FILE" 2>&1; then
            _PM_UPDATED=true
        else
            log_warn "Package index update returned non-zero (may be fine)"
            _PM_UPDATED=true
        fi
    fi
}

# ── Install one or more packages ────────────────────────────
# Returns 0 on success, 1 on failure
pm_install() {
    local pkgs=("$@")
    if [[ ${#pkgs[@]} -eq 0 ]]; then
        return 0
    fi

    local cmd
    case "$DETECTED_PM" in
        pacman)  cmd="sudo pacman -S --noconfirm --needed ${pkgs[*]}" ;;
        apt)     cmd="sudo apt-get install -y ${pkgs[*]}" ;;
        dnf)     cmd="sudo dnf install -y ${pkgs[*]}" ;;
        zypper)  cmd="sudo zypper --non-interactive install ${pkgs[*]}" ;;
        xbps)    cmd="sudo xbps-install -y ${pkgs[*]}" ;;
        emerge)  cmd="sudo emerge --ask=n ${pkgs[*]}" ;;
        apk)     cmd="sudo apk add ${pkgs[*]}" ;;
        nix)     cmd="" ;;  # Handled separately
        *)       log_error "Unknown PM '$DETECTED_PM'"; return 1 ;;
    esac

    # NixOS: install each package individually via nix profile
    if [[ "$DETECTED_PM" == "nix" ]]; then
        local all_ok=true
        for p in "${pkgs[@]}"; do
            local nix_cmd="nix profile install nixpkgs#${p}"
            log_cmd "$nix_cmd"
            if [[ "${DRY_RUN:-false}" == true ]]; then
                log_verbose "(dry-run) would execute: $nix_cmd"
            else
                if ! eval "$nix_cmd" >> "$_LOG_FILE" 2>&1; then
                    all_ok=false
                fi
            fi
        done
        [[ "$all_ok" == true ]]
        return $?
    fi

    log_cmd "$cmd"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_verbose "(dry-run) would execute: $cmd"
        return 0
    fi

    if eval "$cmd" >> "$_LOG_FILE" 2>&1; then
        return 0
    else
        return 1
    fi
}

# ── Install via AUR helper (Arch only) ──────────────────────
pm_install_aur() {
    local pkg="$1"
    if [[ -z "$DETECTED_AUR" ]]; then
        log_verbose "No AUR helper available, cannot install '$pkg' from AUR"
        return 1
    fi

    local cmd="$DETECTED_AUR -S --noconfirm --needed $pkg"
    log_cmd "$cmd"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_verbose "(dry-run) would execute: $cmd"
        return 0
    fi

    if eval "$cmd" >> "$_LOG_FILE" 2>&1; then
        return 0
    else
        return 1
    fi
}

# ── Check if a package is already installed ─────────────────
# Returns 0 if installed, 1 if not
pm_is_installed() {
    local pkg="$1"

    case "$DETECTED_PM" in
        pacman)
            pacman -Qi "$pkg" &>/dev/null
            return $?
            ;;
        apt)
            dpkg -s "$pkg" &>/dev/null
            return $?
            ;;
        dnf)
            rpm -q "$pkg" &>/dev/null
            return $?
            ;;
        zypper)
            rpm -q "$pkg" &>/dev/null
            return $?
            ;;
        xbps)
            xbps-query "$pkg" &>/dev/null
            return $?
            ;;
        emerge)
            # Check if installed in /var/db/pkg
            local cat_pkg="$pkg"
            if [[ "$pkg" == */* ]]; then
                # category/package format
                ls /var/db/pkg/${pkg}* &>/dev/null
            else
                ls /var/db/pkg/*/${pkg}* &>/dev/null
            fi
            return $?
            ;;
        apk)
            apk info -e "$pkg" &>/dev/null
            return $?
            ;;
        nix)
            nix profile list 2>/dev/null | grep -q "$pkg"
            return $?
            ;;
    esac
    return 1
}

# ── Check if a package exists in repositories ───────────────
# Returns 0 if found, 1 if not
pm_search() {
    local pkg="$1"

    case "$DETECTED_PM" in
        pacman)  pacman -Ss "^${pkg}$" &>/dev/null ;;
        apt)     apt-cache show "$pkg" &>/dev/null ;;
        dnf)     dnf info "$pkg" &>/dev/null ;;
        zypper)  zypper search --match-exact "$pkg" &>/dev/null ;;
        xbps)    xbps-query -Rs "$pkg" 2>/dev/null | grep -q "^\\[" ;;
        emerge)  emerge --search "$pkg" &>/dev/null ;;
        apk)     apk search -e "$pkg" &>/dev/null ;;
        nix)     nix-env -qaP "$pkg" &>/dev/null ;;
        *)       return 1 ;;
    esac
    return $?
}

# ── Install via pip (fallback for pywal etc.) ───────────────
pm_install_pip() {
    local pkg="$1"
    if ! command -v pip3 &>/dev/null && ! command -v pip &>/dev/null; then
        log_verbose "pip not available for fallback install of '$pkg'"
        return 1
    fi

    local pip_cmd
    pip_cmd=$(command -v pip3 || command -v pip)

    local cmd="$pip_cmd install --user --break-system-packages $pkg"
    log_cmd "$cmd"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_verbose "(dry-run) would execute: $cmd"
        return 0
    fi

    if eval "$cmd" >> "$_LOG_FILE" 2>&1; then
        return 0
    fi
    # Try without --break-system-packages for older pip
    cmd="$pip_cmd install --user $pkg"
    log_cmd "$cmd (retry without --break-system-packages)"
    eval "$cmd" >> "$_LOG_FILE" 2>&1
    return $?
}
