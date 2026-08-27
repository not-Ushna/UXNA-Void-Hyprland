#!/usr/bin/env python3
# generate-startpage-colors.py
# Reads the active theme's colors.conf and injects a CSS :root block
# into ~/.config/hypr/themes/startpage/index.html
# Called by switch-theme.sh after every theme change.

import re, os

COLORS_CONF = os.path.expanduser("~/.config/hypr/themes/current/colors.conf")
STARTPAGE   = os.path.expanduser("~/.config/hypr/themes/startpage/index.html")

def parse_hex(line):
    m = re.search(r'(?:rgb\(|rgba\(|#)([0-9a-fA-F]{6})', line)
    return m.group(1) if m else None

# Defaults (catppuccin mocha)
c = {
    "accent":  "cba6f7",
    "bg":      "1e1e2e",
    "surface": "313244",
    "text":    "cdd6f4",
    "subtext": "a6adc8",
    "red":     "f38ba8",
    "green":   "a6e3a1",
    "yellow":  "f9e2af",
    "blue":    "89b4fa",
}

try:
    with open(COLORS_CONF) as f:
        lines = f.readlines()
    for line in lines:
        line = line.strip()
        h = parse_hex(line)
        if not h:
            continue
        if "active_border" in line and "inactive" not in line:
            c["accent"] = h
        if "inactive_border" in line:
            c["surface"] = h
        if "color0" in line:
            c["bg"] = h
        if "color7" in line:
            c["text"] = h
        if "color6" in line:
            c["subtext"] = h
        if "color1" in line:
            c["red"] = h
        if "color2" in line:
            c["green"] = h
        if "color3" in line:
            c["yellow"] = h
        if "color4" in line:
            c["blue"] = h
except FileNotFoundError:
    pass

css_block = f"""  <style>
    :root {{
      --accent:   #{c['accent']};
      --bg:       #{c['bg']};
      --surface:  #{c['surface']};
      --text:     #{c['text']};
      --subtext:  #{c['subtext']};
      --red:      #{c['red']};
      --green:    #{c['green']};
      --yellow:   #{c['yellow']};
      --blue:     #{c['blue']};
    }}
  </style>"""

with open(STARTPAGE) as f:
    html = f.read()

html = re.sub(
    r'<!-- THEME-COLORS-START -->.*?<!-- THEME-COLORS-END -->',
    f'<!-- THEME-COLORS-START -->\n{css_block}\n  <!-- THEME-COLORS-END -->',
    html,
    flags=re.DOTALL
)

with open(STARTPAGE, "w") as f:
    f.write(html)

print(f"Startpage colors injected → accent #{c['accent']}")
