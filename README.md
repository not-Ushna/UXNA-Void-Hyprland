<div align="center">

# UXNA · Void Hyprland

**A hand-crafted, theme-aware Hyprland desktop environment for Void Linux.**  
Every pixel is intentional. Every animation, scripted. Built to be yours.

[![Void Linux](https://img.shields.io/badge/Void_Linux-478061?style=for-the-badge&logo=voidlinux&logoColor=white)](https://voidlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-89B4FA?style=for-the-badge&logo=hyprland&logoColor=white)](https://hyprland.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

</div>

---

## Overview

This is my personal Hyprland rice for Void Linux — a fully unified desktop where themes propagate across every component instantly. Choose a theme once, and everything snaps into place: window borders, terminal colors, Waybar, lock screen, notification daemon, Rofi, GTK apps, VS Code, and even GRUB.

### Key Highlights

- **Chameleon Mode** — Dynamic wallpaper-driven theming powered by `pywal`. The entire UI extracts and adapts to your wallpaper's color palette in real-time.
- **Theme Switcher** — A visual, grid-based Rofi gallery to switch between full preset themes or browse wallpapers with live preview.
- **Unified Aesthetics** — GTK, Qt, Waybar, Kitty, Dunst, Rofi, Hyprlock, and VS Code all update together on a single theme change.
- **Smart Backup** — A `sync` + `push` workflow to effortlessly version-control your entire desktop config on GitHub.
- **Custom GRUB Theme** — A personalized `Pochita_Pochita` GRUB bootloader theme backed up and installable from this repo.
- **Waybar Layouts** — Cycle between default, minimal, and extended monitoring layouts without touching the theme.

---

## Themes

| Theme | Description | Style |
|:---|:---|:---|
| ** Chameleon** | Dynamic, wallpaper-extracted colors via `pywal`. The whole UI conforms to your background. | Adaptive |
| ** Jade** | Forest-black background, active jade green borders, warm grey-green text. Boxy, square modules. | Dark / Minimal |
| ** Lumon** | Deep slate background, pale cyan borders, muted corporate aesthetic. Inspired by *Severance*. | Dark / Modern |
| ** Evangelion** | Absolute black background, emergency red borders, warning amber accents. Tactical alert layout. | Dark / Aggressive |

Switch themes with `Super + Shift + T` to open the visual gallery.

---

## Repository Structure

```
UXNA-Void-Hyprland/
 .config/
  hypr/                   # Hyprland core: keybindings, animations, rules
     hyprland.conf       # Main Hyprland configuration
     themes/             # All theme directories (Chameleon, Jade, Lumon, Evangelion)
        current -> ... # Symlink pointing to the active theme
     scripts/            # All desktop automation scripts
  fastfetch/              # Fastfetch system info configuration
  kitty/                  # Kitty terminal configuration
 boot/
  grub/themes/
      Pochita_Pochita/    # Custom personalized GRUB bootloader theme
 home/
  .zshrc                  # Zsh config (Powerlevel10k, aliases, sync/push workflow)
  .p10k.zsh               # Powerlevel10k prompt configuration
 vscode/
  settings.json           # VS Code settings (includes live pywal color injection)
 waybar-layouts/             # Switchable Waybar layout files
 scripts/
   install.sh              # Full automated installer for fresh systems
   install-pochita-grub.sh # GRUB theme installer (used on fresh installs)
```

---

## Fresh Install

Clone the repository and run the installer. It will automatically install all required packages via `xbps`, set up Zsh with Oh-My-Zsh and Powerlevel10k, and symlink all configuration files.

```bash
git clone https://github.com/uxna/UXNA-Void-Hyprland.git ~/Projects/UXNA-Void-Hyprland
cd ~/Projects/UXNA-Void-Hyprland
./scripts/install.sh
```

**Flags:**
```bash
./scripts/install.sh --no-packages   # Skip package installation (if already installed)
./scripts/install.sh --no-shell      # Skip Zsh/Oh-My-Zsh setup
```

### GRUB Theme (Optional)

To restore your personalized `Pochita_Pochita` bootloader theme:
```bash
sudo bash ~/Projects/UXNA-Void-Hyprland/scripts/install-pochita-grub.sh
```

---

## Dependency Checker

Before installing, verify your system has every required dependency:

```bash
bash ~/Projects/UXNA-Void-Hyprland/scripts/dependency-checker.sh
```

If anything is missing, pass `--fix` to automatically install everything via `xbps`:

```bash
bash ~/Projects/UXNA-Void-Hyprland/scripts/dependency-checker.sh --fix
```

The checker scans across **6 categories** — Core, Utilities, Theming, Shell, Launcher, and Fonts — and prints a clean ` / ` status for each one with a summary at the bottom.

---

## Daily Workflow: Sync & Push

This setup comes with two custom terminal commands that keep everything backed up to GitHub automatically.

**`sync`** — Copies all live system configs into your local repo:
```bash
sync
```

**`push`** — Commits and pushes to GitHub. Supports custom messages:
```bash
push                               # Default: "sync latest configs and theme updates: 2026-08-02 13:13"
push fixed chameleon animations    # Custom commit message (no quotes needed)
```

**What `sync` backs up:**

| Source | Destination in Repo |
|:---|:---|
| `~/.config/hypr/` | `.config/hypr/` |
| `~/.config/fastfetch/` | `.config/fastfetch/` |
| `~/.config/kitty/` | `.config/kitty/` |
| `~/.var/app/com.visualstudio.code/.../settings.json` | `vscode/settings.json` |
| `/boot/grub/themes/Pochita_Pochita/` | `boot/grub/themes/Pochita_Pochita/` |
| `~/.zshrc` | `home/.zshrc` |
| `~/.p10k.zsh` | `home/.p10k.zsh` |

---

## Scripts Reference

All scripts live in `~/.config/hypr/scripts/`.

| Script | Purpose |
|:---|:---|
| `install.sh` | Full automated installer for fresh systems |
| `dependency-checker.sh` | Scan and verify all required dependencies are installed |
| `install-pochita-grub.sh` | Install the custom Pochita_Pochita GRUB bootloader theme |
| `chameleon-chwall.sh` | Chameleon engine: picks wallpaper, runs pywal, and pushes colors everywhere |
| `switch-wallpaper.sh` | Manually switch wallpaper with swww transition |
| `cycle-waybar-layout.sh` | Rotate between Waybar layout files |
| `screenshot.sh` | Capture screenshot with grim + slurp |
| `lock.sh` | Lock the session with Hyprlock |
| `launch-screensaver.sh` | Start the custom Hyprland screensaver |
| `smart-battery.sh` | Monitors battery and automatically adjusts power profiles |
| `toggle-caffeine.sh` | Toggle sleep/idle prevention |
| `network-menu.sh` | Interactive NetworkManager connection switcher via Rofi |
| `focus-mode.sh` | Toggles a distraction-free layout |
| `toggle-dropdown.sh` | Show/hide a persistent dropdown Kitty terminal |
| `keybinds-hint.sh` | Display a keybindings cheatsheet overlay |
| `brightness.sh` | Handle brightness controls |
| `launch-wlogout.sh` | Launch the styled power menu |

---

## Keybindings

| Shortcut | Action |
|:---|:---|
| `Super + Shift + T` | Open theme switcher gallery |
| `Super + Shift + W` | Open wallpaper selection gallery |
| `Super + Alt + Left/Right` | Cycle to next/previous wallpaper |
| `Super + Q` / `Alt + F4` | Close active window |
| `Super + L` | Lock desktop session |
| `Super + Ctrl + L` | Start custom screensaver |
| `Super + X` | Open power menu |
| `Super + Delete` | Exit Hyprland |
| `Super + A` | Open application launcher |
| `Super + Tab` | Open window switcher |
| `Super + V` | Open clipboard history |
| `Super + N` | Open network menu |
| `Super + T` | Open Kitty terminal |
| `Super + E` | Open file manager |
| `Super + B` | Open Zen Browser |
| `Super + C` | Open VS Code |
| `Super + K` | Open Kate editor |
| `Super + S` | Open Spotify |
| `Ctrl + Shift + Escape` | Open system monitor (Btop) |
| `Super + W / G` | Toggle floating / toggle group |
| `Shift + F11` | Toggle fullscreen |
| `Super + Arrows` | Move focus between windows |
| `Super + Shift + Arrows` | Resize active window |
| `Super + 1-0` | Switch to workspace 1–10 |
| `Super + Shift + 1-0` | Move window to workspace 1–10 |
| `Super + Scroll` | Scroll through workspaces |
| `Super + LMB / RMB` | Drag to move / resize |
| `Super + P` / `Print` | Capture screenshot |
| `Super + Shift + P` | Color picker |
| `Super + /` | Show keybindings hint overlay |
| `Super + F1/F2/F3` | Set power profile (Saver / Balanced / Performance) |
| Media Keys | System volume, media playback, and brightness |

---

## Dependencies

Installed automatically by `install.sh`:

**Core:** `hyprland` `waybar` `rofi-wayland` `dunst` `kitty` `thunar` `hyprlock` `wlogout` `swayidle`

**Utilities:** `grim` `slurp` `wl-clipboard` `cliphist` `brightnessctl` `NetworkManager` `blueman` `pavucontrol`

**Theming:** `pywal` `nwg-look` `kvantum` `qt5ct` `qt6ct` `papirus-icon-theme`

**Shell:** `zsh` `fastfetch` `eza` `bat` `zoxide`

**Fonts:** `font-jetbrains-mono-nerd` `nerd-fonts`

---

## License

MIT — Do whatever you want with it. A star is appreciated. 
