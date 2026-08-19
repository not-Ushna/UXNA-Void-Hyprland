#!/bin/bash
# ============================================================
# detect.sh — OS and package manager detection
# ============================================================
# Uses /etc/os-release (ID, ID_LIKE) to identify the distro
# family and select the correct package manager.
#
# Exports:
#   DETECTED_ID       — raw ID from os-release (e.g. "void", "kali")
#   DETECTED_NAME     — PRETTY_NAME from os-release
#   DETECTED_FAMILY   — normalized family (arch, debian, fedora, suse, void, gentoo, alpine, nix)
#   DETECTED_PM       — package manager binary (pacman, apt, dnf, zypper, xbps, emerge, apk, nix)

DETECTED_ID=""
DETECTED_NAME=""
DETECTED_FAMILY=""
DETECTED_PM=""

# ── Parse /etc/os-release ───────────────────────────────────
_parse_os_release() {
    if [[ ! -f /etc/os-release ]]; then
        log_fatal "Cannot find /etc/os-release. Is this a supported Linux distribution?"
    fi

    # Source it (it's designed to be sourced)
    # shellcheck source=/dev/null
    . /etc/os-release

    DETECTED_ID="${ID:-unknown}"
    DETECTED_NAME="${PRETTY_NAME:-$ID}"

    log_verbose "os-release: ID=$ID ID_LIKE=${ID_LIKE:-} NAME=$DETECTED_NAME"
}

# ── Map ID/ID_LIKE to a family ──────────────────────────────
_detect_family() {
    local id="$DETECTED_ID"
    local id_like="${ID_LIKE:-}"

    # Direct ID matches first
    case "$id" in
        arch)                           DETECTED_FAMILY="arch" ;;
        manjaro|endeavouros|cachyos|garuda|artix|arcolinux)
                                        DETECTED_FAMILY="arch" ;;
        debian)                         DETECTED_FAMILY="debian" ;;
        ubuntu|linuxmint|pop|kali|parrot|zorin|elementary|mx|deepin|raspbian)
                                        DETECTED_FAMILY="debian" ;;
        fedora|nobara)                  DETECTED_FAMILY="fedora" ;;
        rocky|almalinux|centos|rhel)    DETECTED_FAMILY="fedora" ;;
        opensuse-tumbleweed|opensuse-leap|opensuse-slowroll|opensuse)
                                        DETECTED_FAMILY="suse" ;;
        void)                           DETECTED_FAMILY="void" ;;
        gentoo)                         DETECTED_FAMILY="gentoo" ;;
        alpine)                         DETECTED_FAMILY="alpine" ;;
        nixos)                          DETECTED_FAMILY="nix" ;;
    esac

    # If still unknown, try ID_LIKE
    if [[ -z "$DETECTED_FAMILY" && -n "$id_like" ]]; then
        for like in $id_like; do
            case "$like" in
                arch)    DETECTED_FAMILY="arch"; break ;;
                debian)  DETECTED_FAMILY="debian"; break ;;
                ubuntu)  DETECTED_FAMILY="debian"; break ;;
                fedora)  DETECTED_FAMILY="fedora"; break ;;
                rhel)    DETECTED_FAMILY="fedora"; break ;;
                suse)    DETECTED_FAMILY="suse"; break ;;
                opensuse) DETECTED_FAMILY="suse"; break ;;
            esac
        done
    fi

    if [[ -z "$DETECTED_FAMILY" ]]; then
        log_error "Could not determine distro family for ID='$id' ID_LIKE='$id_like'"
        log_error "Supported families: arch, debian, fedora, suse, void, gentoo, alpine, nix"
        log_fatal "Unsupported distribution. Please open an issue."
    fi

    log_verbose "Detected family: $DETECTED_FAMILY"
}

# ── Map family to package manager ───────────────────────────
_detect_package_manager() {
    case "$DETECTED_FAMILY" in
        arch)    DETECTED_PM="pacman" ;;
        debian)  DETECTED_PM="apt" ;;
        fedora)  DETECTED_PM="dnf" ;;
        suse)    DETECTED_PM="zypper" ;;
        void)    DETECTED_PM="xbps" ;;
        gentoo)  DETECTED_PM="emerge" ;;
        alpine)  DETECTED_PM="apk" ;;
        nix)     DETECTED_PM="nix" ;;
    esac

    # Verify the binary actually exists
    local pm_bin="$DETECTED_PM"
    [[ "$pm_bin" == "xbps" ]] && pm_bin="xbps-install"
    [[ "$pm_bin" == "apt" ]] && pm_bin="apt-get"

    if ! command -v "$pm_bin" &>/dev/null 2>&1; then
        log_fatal "Detected package manager '$DETECTED_PM' but '$pm_bin' binary not found in PATH."
    fi

    log_verbose "Detected package manager: $DETECTED_PM ($pm_bin)"
}

# ── Detect AUR helper (Arch family only) ────────────────────
DETECTED_AUR=""

_detect_aur_helper() {
    if [[ "$DETECTED_FAMILY" != "arch" ]]; then
        return 0
    fi

    for helper in paru yay; do
        if command -v "$helper" &>/dev/null 2>&1; then
            DETECTED_AUR="$helper"
            log_verbose "Detected AUR helper: $DETECTED_AUR"
            return
        fi
    done

    log_verbose "No AUR helper detected (paru, yay)"
}

# ── Detect if Nix is available on a non-NixOS system ────────
NIX_ON_OTHER=false

_detect_nix_supplement() {
    if [[ "$DETECTED_FAMILY" == "nix" ]]; then
        return 0  # Already NixOS
    fi
    if command -v nix &>/dev/null 2>&1; then
        NIX_ON_OTHER=true
        log_verbose "Nix detected on non-NixOS system (available as fallback)"
    fi
}

# ── Public entry point ──────────────────────────────────────
detect_system() {
    _parse_os_release
    _detect_family
    _detect_package_manager
    _detect_aur_helper
    _detect_nix_supplement

    log_info "Detected OS:      ${_C_BOLD}${DETECTED_NAME}${_C_RESET} (${DETECTED_ID})"
    log_info "Family:           ${_C_BOLD}${DETECTED_FAMILY}${_C_RESET}"
    log_info "Package manager:  ${_C_BOLD}${DETECTED_PM}${_C_RESET}"
    [[ -n "$DETECTED_AUR" ]] && log_info "AUR helper:       ${_C_BOLD}${DETECTED_AUR}${_C_RESET}"
    [[ "$NIX_ON_OTHER" == true ]] && log_info "Nix supplement:   ${_C_BOLD}available${_C_RESET}"

    _log_raw "SYSTEM: id=$DETECTED_ID family=$DETECTED_FAMILY pm=$DETECTED_PM aur=$DETECTED_AUR nix_supplement=$NIX_ON_OTHER"
}
