#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Dependency Checker — UXNA Universal Hyprland                        ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Scans your system for every required dependency and reports which are
# installed and which are missing. Run this before a fresh install or
# after cloning to verify your environment is complete.
#
# Usage:
#   bash scripts/check-deps.sh
#   bash scripts/check-deps.sh --fix   # Auto-install missing packages


# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Colors & formatting                                                 ║
# ╚══════════════════════════════════════════════════════════════════════╝
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
GREEN="\e[38;5;82m"
RED="\e[38;5;196m"
YELLOW="\e[38;5;226m"
CYAN="\e[38;5;51m"
PURPLE="\e[38;5;141m"
WHITE="\e[38;5;255m"
ICON_OK="✓"
ICON_FAIL="✗"
ICON_WARN="!"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Dependency lists by category                                        ║
# ╚══════════════════════════════════════════════════════════════════════╝
declare -A CATEGORIES
declare -A CATEGORY_LABELS

CATEGORIES[core]="hyprland waybar dunst kitty thunar hyprlock wlogout swayidle"
CATEGORY_LABELS[core]="Core"

CATEGORIES[utilities]="grim slurp wl-copy:wl-clipboard cliphist brightnessctl nmcli:NetworkManager blueman pavucontrol"
CATEGORY_LABELS[utilities]="Utilities"

CATEGORIES[theming]="wal:pywal nwg-look kvantummanager:kvantum qt5ct qt6ct papirus-icon-theme"
CATEGORY_LABELS[theming]="Theming"

CATEGORIES[shell]="zsh fastfetch eza bat zoxide playerctl git curl wget unzip make gcc"
CATEGORY_LABELS[shell]="Shell"

CATEGORIES[system]="pipewire wireplumber polkit-gnome gsettings-desktop-schemas dconf"
CATEGORY_LABELS[system]="System"

CATEGORIES[rofi]="rofi:rofi-wayland"
CATEGORY_LABELS[rofi]="Launcher"

CATEGORY_ORDER=(core utilities theming shell system rofi)

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Counters                                                            ║
# ╚══════════════════════════════════════════════════════════════════════╝
MISSING_PKGS=()
FOUND_COUNT=0
TOTAL_COUNT=0

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Helper functions                                                    ║
# ╚══════════════════════════════════════════════════════════════════════╝
check_command() {
  local cmd="$1"
  local pkg="${2:-$1}"
  TOTAL_COUNT=$((TOTAL_COUNT + 1))

  # Special directory checks for themes
  if [[ "$cmd" == "papirus-icon-theme" ]]; then
    if [[ -d "/usr/share/icons/Papirus" ]]; then
      printf "    ${GREEN}${ICON_OK}${RESET} ${WHITE}%-22s${RESET} ${DIM}(dir found)${RESET}\n" "$cmd"
      FOUND_COUNT=$((FOUND_COUNT + 1))
      return 0
    fi
  elif [[ "$cmd" == "polkit-gnome" ]]; then
    if [[ -d "/usr/libexec/polkit-gnome" || -f "/usr/libexec/polkit-gnome-authentication-agent-1" || -f "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" ]]; then
      printf "    ${GREEN}${ICON_OK}${RESET} ${WHITE}%-22s${RESET} ${DIM}(libexec found)${RESET}\n" "$cmd"
      FOUND_COUNT=$((FOUND_COUNT + 1))
      return 0
    fi
  elif command -v "$cmd" &>/dev/null; then
    printf "    ${GREEN}${ICON_OK}${RESET} ${WHITE}%-22s${RESET} ${DIM}%s${RESET}\n" "$cmd" "$(command -v "$cmd")"
    FOUND_COUNT=$((FOUND_COUNT + 1))
    return 0
  fi

  printf "    ${RED}${ICON_FAIL}${RESET} ${WHITE}%-22s${RESET} ${DIM}${RED}not found${RESET}\n" "$cmd"
  MISSING_PKGS+=("$pkg")
  return 1
}

check_font() {
  local font_name="$1"
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  if fc-list | grep -qi "${font_name%% *}"; then
    printf "    ${GREEN}${ICON_OK}${RESET} ${WHITE}%-22s${RESET} ${DIM}(fc-list found)${RESET}\n" "$font_name"
    FOUND_COUNT=$((FOUND_COUNT + 1))
    return 0
  fi
  printf "    ${YELLOW}${ICON_WARN}${RESET} ${WHITE}%-22s${RESET} ${DIM}${YELLOW}not detected${RESET}\n" "$font_name"
  return 1
}

print_category() {
  local label="$1"
  echo ""
  echo -e "  ${BOLD}${CYAN}${label}${RESET}"
  echo -e "  ${DIM}$(printf '─%.0s' {1..50})${RESET}"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Banner                                                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
echo ""
echo -e "${BOLD}${PURPLE}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║  UXNA - Universal Hyprland - Dependency Checker         ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Scan each category                                                  ║
# ╚══════════════════════════════════════════════════════════════════════╝
for cat in "${CATEGORY_ORDER[@]}"; do
  print_category "${CATEGORY_LABELS[$cat]}"
  for item in ${CATEGORIES[$cat]}; do
    cmd="${item%%:*}"
    pkg="${item#*:}"
    check_command "$cmd" "$pkg"
  done
done

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Fonts                                                               ║
# ╚══════════════════════════════════════════════════════════════════════╝
print_category "Fonts"
check_font "JetBrains Mono Nerd"
check_font "Nerd Fonts"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Summary                                                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
MISSING_COUNT=${#MISSING_PKGS[@]}
echo ""
echo -e "  ${DIM}$(printf '═%.0s' {1..60})${RESET}"

if [[ $MISSING_COUNT -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}${ICON_OK} All ${FOUND_COUNT}/${TOTAL_COUNT} dependencies are installed. You're good to go!${RESET}"
else
  echo -e "  ${YELLOW}${BOLD}${ICON_WARN} ${FOUND_COUNT}/${TOTAL_COUNT} found — ${RED}${MISSING_COUNT} missing:${RESET}"
  echo ""
  for pkg in "${MISSING_PKGS[@]}"; do
    echo -e "      ${RED}${ICON_FAIL}${RESET} $pkg"
  done
  echo ""
  if [[ "${1:-}" == "--fix" ]]; then
    echo -e "  ${CYAN}${BOLD}Detecting package manager...${RESET}"
    PM=""
    if command -v xbps-install &> /dev/null; then
        PM="sudo xbps-install -y"
    elif command -v pacman &> /dev/null; then
        PM="sudo pacman -S --noconfirm"
    elif command -v apt-get &> /dev/null; then
        PM="sudo apt-get update && sudo apt-get install -y"
    elif command -v dnf &> /dev/null; then
        PM="sudo dnf install -y"
    elif command -v zypper &> /dev/null; then
        PM="sudo zypper install -y"
    fi
    
    if [[ -n "$PM" ]]; then
        echo -e "  ${CYAN}${BOLD}Installing missing packages via ${PM%% *}...${RESET}"
        echo ""
        eval "$PM ${MISSING_PKGS[*]}" && \
          echo -e "  ${GREEN}${BOLD}${ICON_OK} Done! All missing packages installed.${RESET}" || \
          echo -e "  ${RED}${BOLD}${ICON_FAIL} Some packages failed. Note: package names vary by distro. Please install remaining packages manually.${RESET}"
    else
        echo -e "  ${RED}${BOLD}${ICON_FAIL} Unknown package manager. Please install missing packages manually.${RESET}"
    fi
  else
    echo -e "  ${DIM}Tip: Run with ${CYAN}--fix${RESET}${DIM} to auto-install missing packages:${RESET}"
    echo -e "  ${DIM}  bash scripts/dependency-checker.sh --fix${RESET}"
  fi
fi

echo -e "  ${DIM}$(printf '═%.0s' {1..60})${RESET}"
echo ""

if [[ $MISSING_COUNT -ne 0 ]]; then
  exit 1
fi
