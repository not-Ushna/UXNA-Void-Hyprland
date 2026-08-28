#!/usr/bin/env python3
import re, os

COLORS_CONF = os.path.expanduser("~/.config/hypr/themes/current/colors.conf")
TEMPLATE = os.path.expanduser("~/.config/swayosd/style.css.template")
OUT_FILE = os.path.expanduser("~/.config/swayosd/style.css")

def parse_hex(line):
    m = re.search(r'(?:rgb\(|rgba\(|#)([0-9a-fA-F]{6})', line)
    return m.group(1) if m else None

c = {"accent": "cba6f7", "bg": "1e1e2e", "surface": "313244", "text": "cdd6f4"}

try:
    with open(COLORS_CONF) as f:
        for line in f:
            h = parse_hex(line)
            if not h: continue
            if "active_border" in line and "inactive" not in line: c["accent"] = h
            elif "inactive_border" in line: c["surface"] = h
            elif "color0" in line: c["bg"] = h
            elif "color7" in line: c["text"] = h
except FileNotFoundError: pass

try:
    with open(TEMPLATE) as f: style = f.read()
    style = style.replace("{accent}", f"#{c['accent']}").replace("{bg}", f"#{c['bg']}").replace("{surface}", f"#{c['surface']}").replace("{text}", f"#{c['text']}")
    with open(OUT_FILE, "w") as f: f.write(style)
except FileNotFoundError: pass
