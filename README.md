<div align="center">

# UXNA · Universal Hyprland

**A hand-crafted, distro-agnostic themeable Hyprland desktop environment.**  
Every pixel is intentional. Every animation, scripted. Built to be yours.

[![Hyprland](https://img.shields.io/badge/Hyprland-89B4FA?style=for-the-badge&logo=hyprland&logoColor=white)](https://hyprland.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<br/>

[Overview](#-overview) · [Themes](#-themes) · [Features](#-features) · [Installation](#-installation) · [Keybindings](#-keybindings) · [Scripts](#-scripts) · [Dependencies](#-dependencies)

</div>

---

## ✦ Overview

This is my personal Hyprland rice — a fully unified desktop where themes propagate across every component instantly. Choose a theme once, and everything snaps into place: window borders, terminal colors, Waybar, lock screen, notification daemon, Rofi, GTK apps, VS Code, and even GRUB.

### Key Highlights

- **🌈 Chameleon Mode** — Dynamic wallpaper-driven theming powered by `pywal`. The entire UI extracts and adapts to your wallpaper's color palette in real-time.
- **🎨 Unified Aesthetics** — GTK, Qt, Waybar, Kitty, Dunst, Rofi, Hyprlock, Btop, Fastfetch, and VS Code all update together on a single theme change.
- **🎞️ Live Wallpapers** — Native support for animated `.gif` wallpapers via `swww` built directly into the wallpaper switcher.
- **🔧 Barcraft** — A custom GUI tool to enable/disable individual Waybar modules with live preview.
- **💾 Smart Backup** — A `sync` + `push` workflow to effortlessly version-control your entire desktop config on GitHub.
- **🎨 Custom GRUB Theme** — A personalized `Pochita_Pochita` GRUB bootloader theme backed up and installable from this repo.

---

## ✦ Themes

| Theme | Description | Style |
|:---:|:---|:---|
| **🌿 Chameleon** | Dynamic wallpaper-extracted colors via `pywal`. The whole UI conforms to your background. | Adaptive |
| **💎 Jade** | Forest-black background, active jade green borders, warm grey-green text. Boxy, square modules. | Dark · Minimal |
| **🏢 Lumon** | Deep slate background, pale cyan borders, muted corporate aesthetic. Inspired by *Severance*. | Dark · Modern |
| **⚠️ Evangelion** | Absolute black background, emergency red borders, warning amber accents. Tactical alert layout. | Dark · Aggressive |
| **✨ PromisedFuture** | Frutiger Aero: teal aurora, vibrant green, golden warmth. Classic glassy aesthetic with blur. | Glossy · Aero |
| **⚔️ PixelCraft** | Cozy RPG village aesthetic. Warm woody browns, amber gold, Monocraft font, and Pokemon battle UI. | Retro · Pixel |

> **💡 Tip:** Press `Super + Shift + T` to open the visual theme gallery, or `Super + Shift + W` for the wallpaper gallery.

---

## ✦ Features

<table>
<tr>
<td width="50%">

### 🎨 Chameleon Engine
The Chameleon theme uses `pywal` to extract a color palette from your wallpaper and pushes it live across Waybar, Kitty, Hyprlock, Rofi, Dunst, GTK, and VS Code — all in a single pass.

</td>
<td width="50%">

### 🖥️ Barcraft
A custom Python GUI to manage your Waybar modules. Toggle modules on and off per-section, search by name, and see changes reflected instantly without editing JSON.

</td>
</tr>
<tr>
<td>

### 🔒 Lock & Screensaver
A themed Hyprlock configuration with a custom screensaver that matches your active theme. Activate with `Super + L` to lock or `Super + Ctrl + L` for the screensaver.

</td>
<td>

### 🔋 Smart Battery
An intelligent battery monitor that automatically adjusts your power profile:
- **≤ 20%** → Power Saver
- **20–80%** → Balanced
- **≥ 80%** → Performance

</td>
</tr>
<tr>
<td colspan="2">

### 🌐 Network Menu
A Rofi-powered interactive menu for managing WiFi connections, toggling VPNs, and switching networks — no terminal needed.

</td>
</tr>
</table>

---

## ✦ Repository Structure

```
UXNA-Hyprland/
├── .config/
│   ├── hypr/
│   │   ├── hyprland.conf          # Main Hyprland configuration
│   │   ├── themes/                # All theme directories
│   │   │   ├── Chameleon/         #   Dynamic pywal-driven theme
│   │   │   ├── Jade/              #   Forest-black minimal theme
│   │   │   ├── Lumon/             #   Severance-inspired corporate theme
│   │   │   ├── Evangelion/        #   Tactical red-on-black theme
│   │   │   ├── PromisedFuture/    #   Frutiger Aero glassy theme
│   │   │   ├── PixelCraft/        #   Cozy RPG pixel art theme
│   │   │   └── current -> ...     #   Symlink to active theme
│   │   ├── scripts/               # All desktop automation scripts
│   │   └── waybar/                # Waybar configuration
│   ├── kitty/                     # Kitty terminal configuration
│   ├── fastfetch/                 # System info configuration
│   └── btop/                      # Resource monitor configuration
├── home/
│   ├── .zshrc                     # Zsh config (Powerlevel10k, aliases)
│   └── .p10k.zsh                  # Powerlevel10k prompt configuration
├── vscode/
│   └── settings.json              # VS Code settings with pywal injection
├── boot/grub/themes/
│   └── Pochita_Pochita/           # Custom GRUB bootloader theme
├── scripts/
│   ├── universal-installer/       # Cross-distro universal package installer
│   │   ├── install.sh             # Main installer entry point
│   │   ├── lib/                   # Installer library modules (detection, etc.)
│   │   └── packages/              # Distro-specific package mappings
│   ├── install.sh                 # Legacy wrapper script (redirects to universal-installer)
│   └── install-pochita-grub.sh    # GRUB theme installer
└── setup.sh                       # One-liner bootstrap script
```

---

## ✦ Installation

### One-Liner (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/not-Ushna/UXNA-Hyprland/main/setup.sh)
```

This will clone the repo, install all packages, set up Zsh with Oh-My-Zsh and Powerlevel10k, and symlink all configuration files.

### Manual

```bash
git clone https://github.com/not-Ushna/UXNA-Hyprland.git ~/Projects/UXNA-Hyprland
cd ~/Projects/UXNA-Hyprland
./scripts/universal-installer/install.sh
```

**Common Flags:**
| Flag | Description |
|:---|:---|
| `--dry-run` | Preview what will be installed without making any changes |
| `--verify-only` | Verify installed packages instead of installing |
| `--core` / `--theming` | Selectively install specific categories of packages |
| `--skip <pkg>` | Skip specific packages or categories (e.g., `--skip fonts`) |

### Package Verification

Before or after installing, you can verify your system has every required dependency:

```bash
./scripts/universal-installer/install.sh --verify-only
```

The installer verifies packages across **5 categories** — Core, Utilities, Theming, Shell, and Fonts — and prints a clean `✓ / ✗` status for each one based on the presence of binaries and fonts, not just package manager records.

### GRUB Theme (Optional)

```bash
sudo bash ./scripts/install-pochita-grub.sh
```

---

## ✦ Keybindings

### Core

| Shortcut | Action |
|:---|:---|
| `Super + Q` / `Alt + F4` | Close active window |
| `Super + L` | Lock session |
| `Super + Ctrl + L` | Start screensaver |
| `Super + X` | Open power menu |
| `Super + Delete` | Exit Hyprland |

### Launchers

| Shortcut | Action |
|:---|:---|
| `Super + A` | Application launcher |
| `Super + Tab` | Window switcher |
| `Super + V` | Clipboard history |
| `Super + N` | Network menu |
| `Super + /` | Keybindings cheatsheet |

### Applications

| Shortcut | Action |
|:---|:---|
| `Super + T` | Kitty terminal |
| `Super + E` | File manager |
| `Super + B` | Zen Browser |
| `Super + C` | VS Code |
| `Super + K` | Kate editor |
| `Super + S` | Spotify |
| `Ctrl + Shift + Escape` | System monitor (Btop) |

### Theming

| Shortcut | Action |
|:---|:---|
| `Super + Shift + T` | Open theme gallery |
| `Super + Shift + W` | Open wallpaper gallery |
| `Super + Alt + ←/→` | Cycle wallpapers |

### Window Management

| Shortcut | Action |
|:---|:---|
| `Super + W` | Toggle floating |
| `Super + G` | Toggle group |
| `Shift + F11` | Toggle fullscreen |
| `Super + Arrows` | Move focus |
| `Super + Shift + Arrows` | Resize window |
| `Super + 1-0` | Switch to workspace 1–10 |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Scroll` | Scroll through workspaces |
| `Super + LMB / RMB` | Drag move / resize |

### Utilities

| Shortcut | Action |
|:---|:---|
| `Super + P` / `Print` | Screenshot |
| `Super + F1/F2/F3` | Power profile (Saver / Balanced / Performance) |
| Media Keys | Volume, playback, brightness |

---

## ✦ Scripts

All scripts live in `.config/hypr/scripts/`.

| Script | Purpose |
|:---|:---|
| `switch-theme.sh` | Visual theme switcher with Rofi gallery |
| `chameleon-chwall.sh` | Chameleon engine: picks wallpaper, runs pywal, pushes colors everywhere |
| `switch-wallpaper.sh` | Wallpaper switcher with swww transitions |
| `barcraft.py` | GUI module manager for Waybar |
| `smart-battery.sh` | Automatic power profile based on battery level |
| `toggle-caffeine.sh` | Toggle sleep/idle prevention |
| `toggle-dropdown.sh` | Persistent dropdown Kitty terminal |
| `focus-mode.sh` | Distraction-free layout toggle |
| `network-menu.sh` | Rofi-powered NetworkManager menu |
| `screenshot.sh` | Capture with grim + slurp |
| `lock.sh` | Lock session with Hyprlock |
| `launch-screensaver.sh` | Start the themed screensaver |
| `launch-wlogout.sh` | Styled power menu |
| `keybinds-hint.sh` | Keybindings overlay |
| `brightness.sh` | Brightness controls |

---

## ✦ Shell Aliases & Custom Commands

All custom aliases are defined in `home/.zshrc`, while custom command binaries are located in `~/.local/bin/`.

| Alias / Command | Description |
|:---|:---|
| `ls` | Modern replacement for `ls` with icons and colors (powered by `eza`) |
| `ll` | Detailed list view for `ls` with icons (powered by `eza -l`) |
| `la` | Detailed list view including hidden files (powered by `eza -la`) |
| `cat` | Modern replacement for `cat` with syntax highlighting (powered by `bat`) |
| `z` | Smarter, memory-based replacement for `cd` (powered by `zoxide`) |
| `sync` | Syncs your active configs to the local Git repository folder |
| `push` | Commits and pushes your synced configs to GitHub |
| `pokemon` | Displays a random Pokémon sprite in the terminal |
| `barcraft` | Custom GUI module manager for Waybar |
| `anifetch` | Displays an animated theme-based GIF alongside `fastfetch` |

---

## ✦ Dependencies

The Universal Installer handles the downloading and configuration of the following canonical packages:

| Category | Packages |
|:---|:---|
| **Core** | `hyprland` `waybar` `rofi-wayland` `dunst` `kitty` `thunar` `hyprlock` `wlogout` `swayidle` `swww` `swww-daemon` |
| **Utilities** | `grim` `slurp` `wl-clipboard` `cliphist` `brightnessctl` `NetworkManager` `blueman` `pavucontrol` |
| **Theming** | `pywal` `nwg-look` `kvantum` `qt5ct` `qt6ct` `papirus-icon-theme` |
| **Shell** | `zsh` `fastfetch` `eza` `bat` `zoxide` `python3` |
| **Fonts** | `font-jetbrains-mono-nerd` `nerd-fonts` |

---

<div align="center">

**MIT** — Do whatever you want with it. A ⭐ is appreciated.

*Built with obsessive attention to detail.*

</div>
