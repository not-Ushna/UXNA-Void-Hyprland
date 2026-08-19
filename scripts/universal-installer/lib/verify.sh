#!/bin/bash
# ============================================================
# verify.sh — Post-installation verification
# ============================================================
# After installation, verify each package is actually present
# by checking for its binary, directory, or font entry.
# Does NOT trust the package manager's exit code alone.

verify_installation() {
    log_section "Verification"

    local total=0
    local found=0
    local missing=0
    local missing_list=()

    local all_pkgs
    all_pkgs=$(get_all_packages)

    for pkg in $all_pkgs; do
        total=$((total + 1))
        local binary="${PKG_BINARY[$pkg]:-}"
        local status=""

        case "$pkg" in
            font-jetbrains-mono-nerd)
                if font_is_installed "JetBrains"; then
                    status="ok"
                fi
                ;;
            nerd-fonts)
                if font_is_installed "Symbols Nerd Font" || font_is_installed "NerdFont"; then
                    status="ok"
                fi
                ;;
            papirus-icon-theme)
                if [[ -d "/usr/share/icons/Papirus" ]]; then
                    status="ok"
                fi
                ;;
            *)
                if [[ -n "$binary" ]] && command -v "$binary" &>/dev/null; then
                    status="ok"
                elif [[ -z "$binary" ]]; then
                    # No binary to check — try package manager
                    local resolved
                    resolved=$(resolve_package "$pkg")
                    if [[ -n "$resolved" ]] && pm_is_installed "$resolved"; then
                        status="ok"
                    fi
                fi
                ;;
        esac

        if [[ "$status" == "ok" ]]; then
            found=$((found + 1))
            printf "  ${_C_GREEN}${_SYM_OK}${_C_RESET} %-28s" "$pkg"
            if [[ -n "$binary" ]] && command -v "$binary" &>/dev/null; then
                echo -e " ${_C_DIM}$(command -v "$binary")${_C_RESET}"
            else
                echo ""
            fi
        else
            missing=$((missing + 1))
            missing_list+=("$pkg")
            printf "  ${_C_RED}${_SYM_FAIL}${_C_RESET} %-28s ${_C_RED}not found${_C_RESET}\n" "$pkg"
        fi
    done

    echo ""
    echo -e "  ${_C_DIM}$(printf '─%.0s' {1..55})${_C_RESET}"

    if [[ $missing -eq 0 ]]; then
        echo -e "  ${_C_GREEN}${_C_BOLD}${_SYM_OK} All ${found}/${total} packages verified.${_C_RESET}"
    else
        echo -e "  ${_C_YELLOW}${_C_BOLD}${_SYM_WARN} ${found}/${total} verified — ${_C_RED}${missing} missing${_C_RESET}"
    fi

    _log_raw "VERIFY: found=$found missing=$missing total=$total"
    if [[ ${#missing_list[@]} -gt 0 ]]; then
        _log_raw "VERIFY_MISSING: ${missing_list[*]}"
    fi

    return $missing
}
