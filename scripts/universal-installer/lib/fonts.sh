#!/bin/bash
# ============================================================
# fonts.sh — Font installation and fallback
# ============================================================
# Handles font installation through native repos or by
# downloading directly from GitHub Releases.

NERD_FONTS_VERSION="v3.4.0"
NERD_FONTS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download"

# ── Install a Nerd Font from GitHub ─────────────────────────
_install_nerd_font_from_github() {
    local font_name="$1"  # e.g. "JetBrainsMono"
    local dest_dir="$HOME/.local/share/fonts/NerdFonts"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_verbose "(dry-run) would download ${font_name} Nerd Font from GitHub"
        return 0
    fi

    mkdir -p "$dest_dir"

    local url="${NERD_FONTS_URL}/${NERD_FONTS_VERSION}/${font_name}.tar.xz"
    local tmp_file="/tmp/nerd-font-${font_name}.tar.xz"

    log_verbose "Downloading $url"
    log_cmd "curl -fsSL -o $tmp_file $url"

    if ! curl -fsSL -o "$tmp_file" "$url" 2>>"$_LOG_FILE"; then
        # Try .zip fallback
        url="${NERD_FONTS_URL}/${NERD_FONTS_VERSION}/${font_name}.zip"
        tmp_file="/tmp/nerd-font-${font_name}.zip"
        log_verbose "tar.xz failed, trying .zip: $url"
        if ! curl -fsSL -o "$tmp_file" "$url" 2>>"$_LOG_FILE"; then
            log_error "Failed to download ${font_name} Nerd Font"
            return 1
        fi
        # Extract zip
        log_cmd "unzip -o $tmp_file -d $dest_dir"
        unzip -o "$tmp_file" -d "$dest_dir" >> "$_LOG_FILE" 2>&1 || return 1
    else
        # Extract tar.xz
        log_cmd "tar -xf $tmp_file -C $dest_dir"
        tar -xf "$tmp_file" -C "$dest_dir" >> "$_LOG_FILE" 2>&1 || return 1
    fi

    rm -f "$tmp_file"
    return 0
}

# ── Rebuild font cache ─────────────────────────────────────
_rebuild_font_cache() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_verbose "(dry-run) would run fc-cache -fv"
        return 0
    fi

    log_verbose "Rebuilding font cache..."
    log_cmd "fc-cache -f"
    fc-cache -f >> "$_LOG_FILE" 2>&1 || true
}

# ── Check if a font is installed ────────────────────────────
font_is_installed() {
    local font_name="$1"
    if command -v fc-list &>/dev/null; then
        fc-list | grep -qi "${font_name}" &>/dev/null
        return $?
    fi
    return 1
}

# ── Install fonts (main entry point) ────────────────────────
# Called by installer.sh for font-type packages
install_font_package() {
    local canonical="$1"
    local resolved
    resolved=$(resolve_package "$canonical")

    # Already installed?
    case "$canonical" in
        font-jetbrains-mono-nerd)
            if font_is_installed "JetBrains"; then
                log_skip "$canonical (already installed)"
                return 2  # 2 = already installed
            fi
            ;;
        nerd-fonts)
            if font_is_installed "Symbols Nerd Font"; then
                log_skip "$canonical (already installed)"
                return 2
            fi
            ;;
    esac

    # Try native package manager first
    if [[ -n "$resolved" ]]; then
        if pm_install "$resolved"; then
            _rebuild_font_cache
            log_ok "$canonical → $resolved (repo)"
            return 0
        fi
    fi

    # Fallback: download from GitHub
    log_verbose "Repo install failed for $canonical, trying GitHub download..."
    case "$canonical" in
        font-jetbrains-mono-nerd)
            if _install_nerd_font_from_github "JetBrainsMono"; then
                _rebuild_font_cache
                log_ok "$canonical (GitHub download)"
                return 0
            fi
            ;;
        nerd-fonts)
            if _install_nerd_font_from_github "NerdFontsSymbolsOnly"; then
                _rebuild_font_cache
                log_ok "$canonical (GitHub download)"
                return 0
            fi
            ;;
    esac

    log_error "$canonical — could not install via repo or GitHub"
    return 1
}
