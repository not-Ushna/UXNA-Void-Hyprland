#!/bin/bash
# ============================================================
# logging.sh — Structured logging
# ============================================================
# All output and file logging goes through this module.
# Log file: ~/.local/state/uxna-installer/install.log

_LOG_DIR="$HOME/.local/state/uxna-installer"
_LOG_FILE=""
_VERBOSE=false

# ── Colors ──────────────────────────────────────────────────
_C_RESET="\033[0m"
_C_BOLD="\033[1m"
_C_DIM="\033[2m"
_C_RED="\033[38;5;196m"
_C_GREEN="\033[38;5;82m"
_C_YELLOW="\033[38;5;226m"
_C_CYAN="\033[38;5;51m"
_C_PURPLE="\033[38;5;141m"
_C_WHITE="\033[38;5;255m"

# ── Symbols ─────────────────────────────────────────────────
_SYM_OK="✓"
_SYM_FAIL="✗"
_SYM_WARN="!"
_SYM_INFO="›"
_SYM_SKIP="○"

# ── Init ────────────────────────────────────────────────────
log_init() {
    mkdir -p "$_LOG_DIR"
    _LOG_FILE="$_LOG_DIR/install-$(date +%Y%m%d_%H%M%S).log"

    # Symlink latest
    ln -sfn "$_LOG_FILE" "$_LOG_DIR/install.log"

    _log_raw "================================================================"
    _log_raw "UXNA Universal Installer — $(date)"
    _log_raw "================================================================"
}

log_set_verbose() {
    _VERBOSE=true
}

# ── Internal: write to log file only ────────────────────────
_log_raw() {
    [[ -n "$_LOG_FILE" ]] && echo "$*" >> "$_LOG_FILE"
}

# ── Public logging functions ────────────────────────────────

# Info — cyan prefix, always shown
log_info() {
    echo -e "  ${_C_CYAN}${_SYM_INFO}${_C_RESET} $*"
    _log_raw "[INFO]  $*"
}

# OK — green check
log_ok() {
    echo -e "  ${_C_GREEN}${_SYM_OK}${_C_RESET} $*"
    _log_raw "[OK]    $*"
}

# Warning — yellow
log_warn() {
    echo -e "  ${_C_YELLOW}${_SYM_WARN}${_C_RESET} $*"
    _log_raw "[WARN]  $*"
}

# Error — red (does NOT exit)
log_error() {
    echo -e "  ${_C_RED}${_SYM_FAIL}${_C_RESET} $*"
    _log_raw "[ERROR] $*"
}

# Fatal — red + exit 1
log_fatal() {
    echo -e "  ${_C_RED}${_C_BOLD}FATAL:${_C_RESET} $*"
    _log_raw "[FATAL] $*"
    exit 1
}

# Skip — dimmed circle
log_skip() {
    echo -e "  ${_C_DIM}${_SYM_SKIP}${_C_RESET} ${_C_DIM}$*${_C_RESET}"
    _log_raw "[SKIP]  $*"
}

# Verbose — only shown with --verbose
log_verbose() {
    _log_raw "[DEBUG] $*"
    [[ "$_VERBOSE" == true ]] && echo -e "  ${_C_DIM}  $*${_C_RESET}" || true
}

# Command logging — logs the command being executed
log_cmd() {
    _log_raw "[CMD]   $*"
    [[ "$_VERBOSE" == true ]] && echo -e "  ${_C_DIM}  \$ $*${_C_RESET}" || true
}

# ── Section headers ─────────────────────────────────────────
log_section() {
    local title="$1"
    echo ""
    echo -e "  ${_C_BOLD}${_C_PURPLE}${title}${_C_RESET}"
    echo -e "  ${_C_DIM}$(printf '─%.0s' {1..55})${_C_RESET}"
    _log_raw ""
    _log_raw "── $title ──────────────────────────────────"
}

# ── Banner ──────────────────────────────────────────────────
log_banner() {
    echo ""
    echo -e "${_C_BOLD}${_C_CYAN}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║     UXNA · Universal Installer                          ║"
    echo "  ║     Cross-distro package bootstrap                      ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${_C_RESET}"
}

# ── Summary table ───────────────────────────────────────────
log_summary() {
    local installed="$1"
    local skipped="$2"
    local failed="$3"
    local total=$(( installed + skipped + failed ))

    echo ""
    echo -e "  ${_C_DIM}$(printf '═%.0s' {1..55})${_C_RESET}"
    echo -e "  ${_C_BOLD}Installation Summary${_C_RESET}"
    echo -e "  ${_C_DIM}$(printf '─%.0s' {1..55})${_C_RESET}"
    echo ""
    printf "  ${_C_GREEN}${_SYM_OK}${_C_RESET} Installed:  %d\n" "$installed"
    printf "  ${_C_DIM}${_SYM_SKIP}${_C_RESET} Skipped:    %d  ${_C_DIM}(already installed)${_C_RESET}\n" "$skipped"
    if [[ "$failed" -gt 0 ]]; then
        printf "  ${_C_RED}${_SYM_FAIL}${_C_RESET} Failed:     %d\n" "$failed"
    else
        printf "  ${_C_DIM}${_SYM_FAIL}${_C_RESET} Failed:     %d\n" "$failed"
    fi
    echo ""
    echo -e "  ${_C_DIM}Total: ${total}${_C_RESET}"
    echo -e "  ${_C_DIM}$(printf '═%.0s' {1..55})${_C_RESET}"

    _log_raw ""
    _log_raw "SUMMARY: installed=$installed skipped=$skipped failed=$failed total=$total"
}

# Print log file location
log_location() {
    echo ""
    echo -e "  ${_C_DIM}Log: ${_LOG_FILE}${_C_RESET}"
}
