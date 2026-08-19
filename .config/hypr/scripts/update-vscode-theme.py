#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────
#  ✦  update-vscode-theme.py
#  ✦  ✦  Utility Script
# ─────────────────────────────────────────────────────────

import os
import json
import re

def adjust_lightness(hex_color, factor):
    if len(hex_color) == 7:
        hex_color = hex_color.lstrip('#')
        r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
        r = max(0, min(255, int(r * factor)))
        g = max(0, min(255, int(g * factor)))
        b = max(0, min(255, int(b * factor)))
        return f"#{r:02x}{g:02x}{b:02x}"
    return hex_color

def hex_with_alpha(hex_color, alpha_hex):
    return hex_color[:7] + alpha_hex

def main():
    colors_file = os.path.expanduser("~/.config/hypr/themes/current/colors.conf")
    if not os.path.exists(colors_file):
        return

    colors = {}
    with open(colors_file, 'r') as f:
        for line in f:
            # Match $colorN = rgba(RRGGBBaa)
            match = re.search(r'\$(color\d+)\s*=\s*rgba\(([a-fA-F0-9]{6})[a-fA-F0-9]{2}\)', line)
            if match:
                colors[match.group(1)] = '#' + match.group(2).upper()

    bg = colors.get('color0', '#181617')
    fg = colors.get('color7', '#ccbec3')
    accent = colors.get('color1', '#D71401')
    red = colors.get('color9', colors.get('color1', '#ff0000'))
    green = colors.get('color10', colors.get('color2', '#00ff00'))
    yellow = colors.get('color11', colors.get('color3', '#ffff00'))
    blue = colors.get('color12', colors.get('color4', '#0000ff'))
    magenta = colors.get('color13', colors.get('color5', '#ff00ff'))
    cyan = colors.get('color14', colors.get('color6', '#00ffff'))

    bg_dark = adjust_lightness(bg, 0.7)
    fg_dim = adjust_lightness(fg, 0.7)
    
    # If the theme defines a specific dark surface, use it. But Chameleon uses color8 for grey.
    # We will just rely on bg_dark for safety.
    
    vscode_colors = {
        "editor.background": bg,
        "editor.foreground": fg,
        "editor.lineHighlightBackground": hex_with_alpha(accent, "15"),
        "editor.selectionBackground": hex_with_alpha(accent, "44"),
        "editor.selectionHighlightBackground": hex_with_alpha(accent, "22"),
        "editor.inactiveSelectionBackground": hex_with_alpha(accent, "22"),
        "editor.wordHighlightBackground": hex_with_alpha(accent, "33"),
        "editor.findMatchBackground": hex_with_alpha(yellow, "55"),
        "editor.findMatchHighlightBackground": hex_with_alpha(yellow, "33"),
        "editorLineNumber.foreground": hex_with_alpha(fg, "88"),
        "editorLineNumber.activeForeground": accent,
        "editorCursor.foreground": accent,
        "editorWhitespace.foreground": hex_with_alpha(fg, "44"),
        "editorIndentGuide.background1": hex_with_alpha(fg, "44"),
        "editorIndentGuide.activeBackground1": hex_with_alpha(accent, "66"),
        "editorRuler.foreground": hex_with_alpha(fg, "44"),
        "sideBar.background": bg_dark,
        "sideBar.foreground": fg,
        "sideBar.border": hex_with_alpha(accent, "44"),
        "sideBarSectionHeader.background": bg,
        "sideBarSectionHeader.foreground": accent,
        "activityBar.background": bg,
        "activityBar.foreground": fg,
        "activityBar.inactiveForeground": hex_with_alpha(fg, "88"),
        "activityBar.border": hex_with_alpha(accent, "44"),
        "activityBarBadge.background": accent,
        "activityBarBadge.foreground": bg_dark,
        "titleBar.activeBackground": bg,
        "titleBar.activeForeground": fg,
        "titleBar.inactiveBackground": bg_dark,
        "titleBar.inactiveForeground": hex_with_alpha(fg, "77"),
        "titleBar.border": hex_with_alpha(accent, "44"),
        "tab.activeBackground": bg,
        "tab.activeForeground": fg,
        "tab.inactiveBackground": bg_dark,
        "tab.activeBorder": accent,
        "tab.hoverBackground": adjust_lightness(bg, 1.2),
        "editorGroupHeader.tabsBackground": bg_dark,
        "statusBar.background": bg_dark,
        "statusBar.foreground": fg,
        "statusBar.border": hex_with_alpha(accent, "44"),
        "statusBar.noFolderBackground": bg_dark,
        "statusBar.debuggingBackground": accent,
        "panel.background": bg_dark,
        "panel.border": hex_with_alpha(accent, "44"),
        "terminal.background": bg,
        "terminal.foreground": fg,
        "terminal.ansiBlack": bg_dark,
        "terminal.ansiRed": red,
        "terminal.ansiGreen": green,
        "terminal.ansiYellow": yellow,
        "terminal.ansiBlue": blue,
        "terminal.ansiMagenta": magenta,
        "terminal.ansiCyan": cyan,
        "terminal.ansiWhite": fg,
        "terminalCursor.foreground": accent,
        "terminalCursor.background": bg,
        "dropdown.background": bg_dark,
        "dropdown.border": hex_with_alpha(accent, "44"),
        "input.background": bg_dark,
        "input.border": hex_with_alpha(accent, "44"),
        "scrollbarSlider.background": hex_with_alpha(fg, "22"),
        "scrollbarSlider.hoverBackground": hex_with_alpha(fg, "44"),
        "scrollbarSlider.activeBackground": hex_with_alpha(accent, "88"),
        "gitDecoration.addedResourceForeground": green,
        "gitDecoration.modifiedResourceForeground": yellow,
        "gitDecoration.deletedResourceForeground": red,
        "button.background": accent,
        "button.foreground": bg,
        "list.activeSelectionBackground": hex_with_alpha(accent, "33"),
        "list.hoverBackground": hex_with_alpha(accent, "15")
    }

    targets = [
        os.path.expanduser("~/.config/Antigravity IDE/User/settings.json"),
        os.path.expanduser("~/.var/app/com.visualstudio.code/config/Code/User/settings.json")
    ]

    for target in targets:
        if os.path.exists(target):
            try:
                with open(target, 'r') as f:
                    data = json.load(f)
            except:
                data = {}

            if "workbench.colorCustomizations" not in data:
                data["workbench.colorCustomizations"] = {}
                
            for k, v in vscode_colors.items():
                data["workbench.colorCustomizations"][k] = v
                
            with open(target, 'w') as f:
                json.dump(data, f, indent=4)

if __name__ == "__main__":
    main()
