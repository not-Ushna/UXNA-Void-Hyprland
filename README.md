# UXNA Void Hyprland

A unified, theme-aware desktop environment for Void Linux powered by Hyprland.

[![Void Linux](https://img.shields.io/badge/Void_Linux-478061?style=flat-square&logo=voidlinux&logoColor=white)](https://voidlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-89B4FA?style=flat-square&logo=hyprland&logoColor=white)](https://hyprland.org/)

## Features

- **Dynamic Theming:** Seamlessly extract color palettes from your wallpapers and instantly apply them across Hyprland, Kitty, Waybar, Rofi, and GTK applications.
- **Visual Launcher:** Browse and apply wallpapers and themes through an interactive, grid-based image gallery powered by Rofi.
- **Unified Aesthetics:** GTK and Qt applications sync their stylesheet properties, fonts, cursors, and icon themes dynamically on reload.
- **Waybar Layouts:** Cycle between default, minimal, and extended system monitoring configurations instantly without breaking the active theme stylesheet.

## Installation

The bootstrap script automatically installs all required dependencies and links the configuration files to your workspace.

```bash
git clone https://github.com/yourusername/void-hyprland-themes.git ~/Projects/void-hyprland-themes
cd ~/Projects/void-hyprland-themes
./scripts/install.sh
```

*(Note: Installing alongside an existing custom desktop setup may overwrite some default GTK and cursor configurations. Please back up your configs first.)*

## Themes

- **Chameleon:** Dynamic, wallpaper-driven aesthetics. UI elements automatically conform to the dominant colors of your current background.
- **Osaka-Jade:** Forest-black background, active jade green borders, warm grey-green text. Square window borders and boxy modules.
- **Lumon-Severance:** Deep slate background, active pale cyan borders, muted cyan text. Modern corporate aesthetic with soft shadows and slight border rounding.
- **Magi-Evangelion:** Absolute black background, active emergency red borders, warning amber accents. Tactical alert warning layout.

## Keybindings

| Shortcut | Action |
| :--- | :--- |
| `Super` + `Shift` + `T` | Open theme switcher gallery |
| `Super` + `Shift` + `W` | Open wallpaper selection gallery |
| `Super` + `Alt` + `Left/Right` | Quick-cycle to next/previous wallpaper |
| `Super` + `Q` / `Alt` + `F4` | Close active window |
| `Super` + `L` | Lock desktop session |
| `Super` + `Ctrl` + `L` | Start custom screensaver |
| `Super` + `X` | Open power menu |
| `Super` + `Delete` | Exit Hyprland |
| `Super` + `A` | Open application launcher |
| `Super` + `TAB` | Open window switcher |
| `Super` + `V` | Open clipboard history |
| `Super` + `N` | Open network menu |
| `Super` + `T` | Open Kitty terminal |
| `Super` + `E` | Open file manager |
| `Super` + `B` | Open Zen Browser |
| `Super` + `C` | Open VS Code |
| `Super` + `K` | Open Kate editor |
| `Super` + `S` | Open Spotify |
| `Ctrl` + `Shift` + `Escape`| Open system monitor (Btop) |
| `Super` + `W` / `G` | Toggle floating / toggle group |
| `Shift` + `F11` | Toggle fullscreen |
| `Super` + `Arrows` | Move focus |
| `Super` + `Shift` + `Arrows` | Resize window |
| `Super` + `1-0` | Switch to workspace 1-10 |
| `Super` + `Shift` + `1-0` | Move window to workspace 1-10 |
| `Super` + `Scroll` | Scroll through workspaces |
| `Super` + `LMB/RMB` | Drag to move / resize |
| `Super` + `P` / `Print` | Capture screenshot |
| `Super` + `Shift` + `P` | Color picker |
| `Super` + `/` | Show keybindings hint overlay |
| `Super` + `F1/F2/F3` | Set Power Profile (Saver, Balanced, Perf) |
| `Media Keys` | System volume, media, and brightness controls |

## Requirements

- Void Linux
- Hyprland
- Pywal (Required for Chameleon dynamic theming)

## License

MIT
