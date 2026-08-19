#!/bin/bash
# ============================================================
# packages.sh — Canonical package list and mapping resolver
# ============================================================
# Defines the 31-package canonical list organized by category,
# loads distro-specific name mappings, and resolves names.
#
# Requires: DETECTED_FAMILY (from detect.sh)

# ── The canonical package list ──────────────────────────────
# These are logical names. The actual package name installed
# may differ per distro — that's what the mappings handle.

declare -A PKG_CATEGORIES
PKG_CATEGORIES=(
    [core]="waybar rofi-wayland dunst kitty thunar wlogout swayidle swww"
    [utilities]="grim slurp wl-clipboard cliphist brightnessctl NetworkManager blueman pavucontrol"
    [theming]="pywal nwg-look kvantum qt5ct qt6ct papirus-icon-theme"
    [shell]="zsh fastfetch eza bat zoxide python3"
    [fonts]="font-jetbrains-mono-nerd nerd-fonts"
)

CATEGORY_ORDER=(core utilities theming shell fonts)

# Category labels for display
declare -A CATEGORY_LABELS
CATEGORY_LABELS=(
    [core]="Core"
    [utilities]="Utilities"
    [theming]="Theming"
    [shell]="Shell & Tools"
    [fonts]="Fonts"
)

# ── Bootstrap dependencies (installed before everything) ────
BOOTSTRAP_DEPS="curl wget git sudo tar unzip"

# ── Package name mappings ───────────────────────────────────
declare -A PKG_MAP

# ── Binary name for verification ────────────────────────────
# Maps canonical names to the binary/command they provide
# (used by verify.sh to check if something is actually installed)
declare -A PKG_BINARY
PKG_BINARY=(
    [waybar]="waybar"
    [rofi-wayland]="rofi"
    [dunst]="dunst"
    [kitty]="kitty"
    [thunar]="thunar"
    [wlogout]="wlogout"
    [swayidle]="swayidle"
    [swww]="swww"
    [grim]="grim"
    [slurp]="slurp"
    [wl-clipboard]="wl-copy"
    [cliphist]="cliphist"
    [brightnessctl]="brightnessctl"
    [NetworkManager]="nmcli"
    [blueman]="blueman-applet"
    [pavucontrol]="pavucontrol"
    [pywal]="wal"
    [nwg-look]="nwg-look"
    [kvantum]="kvantummanager"
    [qt5ct]="qt5ct"
    [qt6ct]="qt6ct"
    [zsh]="zsh"
    [fastfetch]="fastfetch"
    [eza]="eza"
    [bat]="bat"
    [zoxide]="zoxide"
    [python3]="python3"
    # Fonts and icon themes don't have binaries — checked differently
    [font-jetbrains-mono-nerd]=""
    [nerd-fonts]=""
    [papirus-icon-theme]=""
)

# ── Fallback methods ────────────────────────────────────────
# Maps canonical names to fallback install methods when repo fails
declare -A PKG_FALLBACK
PKG_FALLBACK=(
    [pywal]="pip:pywal"
    [nwg-look]="skip"
    [swww]="cargo:swww"
    [wlogout]="skip"
    [cliphist]="go:go.senan.xyz/cliphist@latest"
    [fastfetch]="skip"
    [eza]="cargo:eza"
    [font-jetbrains-mono-nerd]="font"
    [nerd-fonts]="font"
)

# ── Load mappings ───────────────────────────────────────────
_load_mappings() {
    local installer_dir
    installer_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local packages_dir="$installer_dir/packages"

    # Load common defaults first
    if [[ -f "$packages_dir/common.conf" ]]; then
        while IFS='=' read -r key value; do
            # Skip comments and blank lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            key=$(echo "$key" | xargs)  # trim
            value=$(echo "$value" | xargs)
            PKG_MAP["$key"]="$value"
        done < "$packages_dir/common.conf"
    fi

    # Overlay distro-specific mappings
    local family_conf="$packages_dir/${DETECTED_FAMILY}.conf"
    if [[ -f "$family_conf" ]]; then
        log_verbose "Loading package mappings from $family_conf"
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            PKG_MAP["$key"]="$value"
        done < "$family_conf"
    else
        log_warn "No package mapping file for family '$DETECTED_FAMILY' — using common defaults"
    fi

    log_verbose "Loaded ${#PKG_MAP[@]} package mappings"
}

# ── Public functions ────────────────────────────────────────

# Resolve a canonical name to the distro-specific package name
# Returns empty string if package is unavailable on this distro
resolve_package() {
    local canonical="$1"
    echo "${PKG_MAP[$canonical]:-$canonical}"
}

# Get all canonical package names for a category
get_category_packages() {
    local category="$1"
    echo "${PKG_CATEGORIES[$category]}"
}

# Get all canonical package names across all categories
get_all_packages() {
    local all=""
    for cat in "${CATEGORY_ORDER[@]}"; do
        all+=" ${PKG_CATEGORIES[$cat]}"
    done
    echo "$all" | xargs  # trim
}

# Initialize the package system
packages_init() {
    _load_mappings
}
