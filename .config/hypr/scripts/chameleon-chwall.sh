#!/bin/bash
# ============================================================
# chameleon-chwall.sh — Chameleon Theme Wallpaper Changer
# Picks a wallpaper, runs pywal, and reloads all components
# with the freshly generated color palette.
#
# Usage:
#   chameleon-chwall.sh              # Random wallpaper
#   chameleon-chwall.sh /path/to/img # Specific wallpaper
# ============================================================

set -eo pipefail

THEME_DIR="$HOME/.config/hypr/themes/Chameleon"
WALLPAPER_DIR="$THEME_DIR/wallpapers"
WAL_CACHE="$HOME/.cache/wal"

# --- Pick wallpaper ---
if [[ -n "${1:-}" && -f "$1" ]]; then
    WALLPAPER="$1"
else
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
fi

if [[ -z "$WALLPAPER" ]]; then
    notify-send "Chameleon" "No wallpapers found in $WALLPAPER_DIR" -i dialog-warning
    exit 1
fi

# --- Set wallpaper via swww ---
if ! pgrep -x swww-daemon > /dev/null 2>&1; then
    swww-daemon &
    sleep 0.5
fi

swww img "$WALLPAPER" \
    --transition-fps 60 \
    --transition-type wipe \
    --transition-angle 30 \
    --transition-duration 1.5

# Cache current wallpaper path (for hyprlock background)
ln -sf "$WALLPAPER" "$HOME/.cache/current_wallpaper"

# --- Run pywal ---
# Use colorthief backend to extract raw palette
wal -i "$WALLPAPER" --backend colorthief -q -n -s -t || true

# Wait for pywal to finish writing cache
sleep 0.3

# --- Smart Chameleon Palette Enhancer ---
# Replaces the flat pywal output with a vibrant, hue-diverse palette
# derived from the dominant wallpaper colors.
python3 << 'PYEOF'
import os, colorsys, json
from colorthief import ColorThief

def rgb_to_hsv(r, g, b):
    return colorsys.rgb_to_hsv(r/255, g/255, b/255)

def hsv_to_hex(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"

def hex_to_rgb(hx):
    hx = hx.lstrip('#')
    return tuple(int(hx[i:i+2], 16) for i in (0, 2, 4))

wal_cache = os.path.expanduser("~/.cache/wal")
colors_sh  = os.path.join(wal_cache, "colors.sh")
colors_json = os.path.join(wal_cache, "colors.json")

# Read existing pywal output for background/foreground/wallpaper
bg_hex = "#0a0a0f"
fg_hex = "#c0c0cf"
wallpaper = ""
if os.path.exists(colors_sh):
    with open(colors_sh) as f:
        for line in f:
            if line.startswith("background="):
                bg_hex = line.split("=")[1].strip().strip("'\"")
            elif line.startswith("foreground="):
                fg_hex = line.split("=")[1].strip().strip("'\"")
            elif line.startswith("wallpaper="):
                wallpaper = line.split("=")[1].strip().strip("'\"")

# Extract a rich palette from the wallpaper
try:
    ct = ColorThief(wallpaper)
    raw_palette = ct.get_palette(color_count=12, quality=1)
except Exception:
    exit(0)

# Find the most saturated/vivid color as the primary accent
best = max(raw_palette, key=lambda c: rgb_to_hsv(*c)[1] * rgb_to_hsv(*c)[2])
h_accent, s_accent, v_accent = rgb_to_hsv(*best)

# Boost saturation of the accent heavily
s_accent = min(1.0, s_accent + 0.35)
v_accent = max(0.75, v_accent)  # Ensure it's bright enough

# Generate 6 distinct hue-shifted ANSI accent colors (color1–color6)
# Each shifted by 60° in hue for visual variety, maintaining accent's energy
hue_offsets = [0, 0.08, 0.16, -0.08, 0.24, -0.16]
accent_colors = []
for offset in hue_offsets:
    h = (h_accent + offset) % 1.0
    # Alternate slightly between more saturated and slightly lighter
    s = min(1.0, s_accent - abs(offset) * 0.3)
    v = min(1.0, v_accent + abs(offset) * 0.1)
    accent_colors.append(hsv_to_hex(h, s, v))

# Dim variants for color8–color14 (slightly darker/less saturated)
dim_colors = []
for offset in hue_offsets:
    h = (h_accent + offset) % 1.0
    s = min(1.0, (s_accent - abs(offset) * 0.3) * 0.7)
    v = min(1.0, (v_accent + abs(offset) * 0.1) * 0.65)
    dim_colors.append(hsv_to_hex(h, s, v))

# Compose the final 16-color palette
palette = {
    "color0":  bg_hex,
    "color1":  accent_colors[0],  # primary accent
    "color2":  accent_colors[1],
    "color3":  accent_colors[2],
    "color4":  accent_colors[3],
    "color5":  accent_colors[4],
    "color6":  accent_colors[5],
    "color7":  fg_hex,
    "color8":  dim_colors[0],
    "color9":  dim_colors[1],
    "color10": dim_colors[2],
    "color11": dim_colors[3],
    "color12": dim_colors[4],
    "color13": dim_colors[5],
    "color14": dim_colors[0],
    "color15": fg_hex,
}

# Overwrite colors.sh
with open(colors_sh, "r") as f:
    lines = f.readlines()
new_lines = []
for line in lines:
    replaced = False
    for key, val in palette.items():
        if line.startswith(key + "="):
            new_lines.append(f"{key}='{val}'\n")
            replaced = True
            break
    if not replaced:
        new_lines.append(line)
with open(colors_sh, "w") as f:
    f.writelines(new_lines)

# Also patch colors.json if it exists
if os.path.exists(colors_json):
    with open(colors_json) as f:
        jdata = json.load(f)
    for key, val in palette.items():
        r, g, b = hex_to_rgb(val)
        if "colors" in jdata and key in jdata["colors"]:
            jdata["colors"][key] = val
        if "special" in jdata:
            if key == "color0":
                jdata["special"]["background"] = val
            elif key == "color7":
                jdata["special"]["foreground"] = val
                jdata["special"]["cursor"] = val
    with open(colors_json, "w") as f:
        json.dump(jdata, f, indent=4)

print(f"Chameleon palette enhanced: accent={accent_colors[0]}")
PYEOF

# --- Re-source the enhanced colors (Python rewrote colors.sh above) ---
# shellcheck source=/dev/null
source "$WAL_CACHE/colors.sh"

# Helper: strip leading # from hex
strip_hash() { echo "${1#\#}"; }

# --- Update Hyprland border colors ---
ACTIVE_HEX=$(strip_hash "$color4")
INACTIVE_HEX=$(strip_hash "$color8")
BG_HEX=$(strip_hash "$background")

hyprctl keyword "general:col.active_border"   "rgba(${ACTIVE_HEX}e6)"   2>/dev/null || true
hyprctl keyword "general:col.inactive_border" "rgba(${INACTIVE_HEX}66)" 2>/dev/null || true

# --- Update Chameleon colors.conf (for theme reloads) ---
python3 << 'CONF_EOF'
import os, re
from datetime import datetime

wal_cache = os.path.expanduser("~/.cache/wal")
colors_sh = os.path.join(wal_cache, "colors.sh")
theme_dir = os.path.expanduser("~/.config/hypr/themes/Chameleon")

# Parse colors from the already-enhanced colors.sh
colors = {}
wallpaper = ""
with open(colors_sh) as f:
    for line in f:
        m = re.match(r"^(color\d+|background|foreground|wallpaper)='?(#?[^']+)'?", line)
        if m:
            colors[m.group(1)] = m.group(2).strip().strip("'")
        if line.startswith("wallpaper="):
            wallpaper = line.split("=",1)[1].strip().strip("'\"")

def strip_hash(h): return h.lstrip("#")

conf = f"""# Chameleon Theme — colors.conf (auto-generated by chameleon-chwall.sh)
# Generated: {datetime.now()}

$color0  = rgba({strip_hash(colors.get('color0','000000'))}ff)
$color1  = rgba({strip_hash(colors.get('color1','ffffff'))}ff)
$color2  = rgba({strip_hash(colors.get('color2','ffffff'))}ff)
$color3  = rgba({strip_hash(colors.get('color3','ffffff'))}ff)
$color4  = rgba({strip_hash(colors.get('color4','ffffff'))}ff)
$color5  = rgba({strip_hash(colors.get('color5','ffffff'))}ff)
$color6  = rgba({strip_hash(colors.get('color6','ffffff'))}ff)
$color7  = rgba({strip_hash(colors.get('color7','ffffff'))}ff)
$color8  = rgba({strip_hash(colors.get('color8','444444'))}ff)

$font      = "JetBrains Mono"
$rounding  = 10
$wallpaper = {wallpaper}
"""

tmp = os.path.join(theme_dir, "colors.conf.tmp")
with open(tmp, "w") as f:
    f.write(conf)
os.replace(tmp, os.path.join(theme_dir, "colors.conf"))
print(f"colors.conf written: accent={colors.get('color1','?')}")
CONF_EOF

# --- Generate GTK4 colors from pywal ---
mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/gtk.css" << EOF
/* Chameleon — GTK4 colors from pywal — $(date) */
@define-color accent_color ${color4};
@define-color accent_bg_color ${color4};
@define-color accent_fg_color ${background};
@define-color window_bg_color ${background};
@define-color window_fg_color ${foreground};
@define-color view_bg_color ${background};
@define-color view_fg_color ${foreground};
@define-color headerbar_bg_color ${color0};
@define-color headerbar_fg_color ${foreground};
@define-color headerbar_border_color ${color4};
@define-color headerbar_backdrop_color @window_bg_color;
@define-color card_bg_color rgba(255,255,255,0.05);
@define-color card_fg_color ${foreground};
@define-color card_border_color rgba(255,255,255,0.1);
@define-color popover_bg_color ${background};
@define-color popover_fg_color ${foreground};
@define-color dialog_bg_color ${background};
@define-color dialog_fg_color ${foreground};
@define-color sidebar_bg_color ${color0};
@define-color sidebar_fg_color ${foreground};
@define-color sidebar_border_color ${color4};
selection { background-color: ${color4}; color: ${background}; }
headerbar { background-color: @headerbar_bg_color; border-bottom: 1px solid @headerbar_border_color; box-shadow: none; }
EOF

# --- Update Dunst colors ---
cat > "$THEME_DIR/dunst/dunstrc" << EOF
# Chameleon Theme — Dunst (auto-generated by chameleon-chwall.sh)
[global]
    monitor = 0
    follow = mouse
    width = 320
    height = (0, 300)
    origin = top-right
    offset = 20x20
    indicate_hidden = yes
    shrink = no
    transparency = 10
    separator_height = 1
    padding = 12
    horizontal_padding = 12
    frame_width = 2
    frame_color = "${color4}"
    sort = yes
    font = "JetBrainsMono Nerd Font 11"
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    max_icon_size = 32
    sticky_history = yes
    history_length = 20
    browser = xdg-open
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 10
    mouse_left_click = do_action, close_current
    mouse_middle_click = close_all
    mouse_right_click = close_current

[urgency_low]
    background = "${background}"
    foreground = "${foreground}"
    frame_color = "${color8}"
    timeout = 3

[urgency_normal]
    background = "${background}"
    foreground = "${foreground}"
    frame_color = "${color4}"
    timeout = 5

[urgency_critical]
    background = "${color1}"
    foreground = "${background}"
    frame_color = "${color1}"
    timeout = 0
EOF

# --- Update Kitty colors ---
python3 << 'KITTY_EOF'
import os, re

colors_sh = os.path.expanduser("~/.cache/wal/colors.sh")
theme_dir = os.path.expanduser("~/.config/hypr/themes/Chameleon")

colors = {}
with open(colors_sh) as f:
    for line in f:
        m = re.match(r"^(color\d+|background|foreground|cursor)='?(#[0-9a-fA-F]+)'?", line)
        if m:
            colors[m.group(1)] = m.group(2)

bg = colors.get("background","#0a0a0f")
fg = colors.get("foreground","#c0c0cf")

kitty_conf = f"""# Chameleon — Kitty theme (auto-generated by chameleon-chwall.sh)
foreground {fg}
background {bg}
selection_foreground {bg}
selection_background {colors.get("color4", fg)}
cursor {fg}
color0  {colors.get("color0", bg)}
color8  {colors.get("color8", bg)}
color1  {colors.get("color1", fg)}
color9  {colors.get("color1", fg)}
color2  {colors.get("color2", fg)}
color10 {colors.get("color2", fg)}
color3  {colors.get("color3", fg)}
color11 {colors.get("color3", fg)}
color4  {colors.get("color4", fg)}
color12 {colors.get("color4", fg)}
color5  {colors.get("color5", fg)}
color13 {colors.get("color5", fg)}
color6  {colors.get("color6", fg)}
color14 {colors.get("color6", fg)}
color7  {colors.get("color7", fg)}
color15 {colors.get("color7", fg)}
"""

with open(os.path.join(theme_dir, "kitty", "theme.conf"), "w") as f:
    f.write(kitty_conf)
print(f"kitty theme.conf written: bg={bg} fg={fg}")
KITTY_EOF

# --- Update Waybar HyDE theme.css ---
BG="${background#\#}"
BG_RGB=$(printf '%d, %d, %d' 0x${BG:0:2} 0x${BG:2:2} 0x${BG:4:2})
cat > "$THEME_DIR/waybar/theme.css" << EOF
/* Chameleon — Waybar HyDE theme.css (auto-generated by chameleon-chwall.sh) */
@define-color bar-bg rgba($BG_RGB, 0.0);
@define-color main-bg rgba($BG_RGB, 0.95);
@define-color main-fg ${foreground};
@define-color wb-act-bg ${color4};
@define-color wb-act-fg ${background};
@define-color wb-hvr-bg ${color4};
@define-color wb-hvr-fg ${background};
EOF

# --- Update Wlogout colors and SVGs ---
python3 << 'WLOGOUT_EOF'
import os, re, json

colors_sh = os.path.expanduser("~/.cache/wal/colors.sh")
theme_dir = os.path.expanduser("~/.config/hypr/themes/Chameleon")
icons_dir = os.path.join(theme_dir, "wlogout", "icons")

# Parse colors from enhanced colors.sh
colors = {}
with open(colors_sh) as f:
    for line in f:
        m = re.match(r"^(color\d+|background|foreground)='?(#[0-9a-fA-F]+)'?", line)
        if m:
            colors[m.group(1)] = m.group(2)

accent = colors.get("color4", "#00bbd3")
bg     = colors.get("background", "#000101")

# Convert hex background to rgb for rgba()
bg_hex = bg.lstrip("#")
bg_rgb = f"{int(bg_hex[0:2],16)},{int(bg_hex[2:4],16)},{int(bg_hex[4:6],16)}"

# Recolor SVG icons
if os.path.exists(icons_dir):
    for fname in os.listdir(icons_dir):
        if not fname.endswith(".svg"):
            continue
        p = os.path.join(icons_dir, fname)
        with open(p) as f:
            content = f.read()
        color = bg if "-hover" in fname else accent
        content = re.sub(r'fill="[^"]+"', f'fill="{color}"', content)
        content = re.sub(r'stroke="[^"]+"', f'stroke="{color}"', content)
        with open(p, "w") as f:
            f.write(content)

# Write CSS — using only valid GTK CSS properties, glassmorphism card design
ax_hex = accent.lstrip("#")
ar, ag, ab = int(ax_hex[0:2],16), int(ax_hex[2:4],16), int(ax_hex[4:6],16)
accent_rgb = f"{ar},{ag},{ab}"

css = f"""/* Chameleon — Wlogout Glassmorphism Cards (auto-generated by chameleon-chwall.sh) */
* {{
    background-image: none;
    font-family: "JetBrainsMono Nerd Font", "Inter", sans-serif;
}}
window {{ background-color: rgba({bg_rgb}, 0.78); }}
button {{
    background-color: rgba({bg_rgb}, 0.55);
    border: 1px solid rgba({accent_rgb}, 0.35);
    border-radius: 18px;
    color: rgba({ar},{ag},{ab}, 0.7);
    font-size: 13px;
    font-weight: 700;
    margin: 12px;
    padding-bottom: 25px;
    background-repeat: no-repeat;
    background-position: center 30%;
    background-size: 38%;
    box-shadow: 0 8px 32px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.04);
    transition: all 200ms ease;
}}
button:hover, button:focus {{
    background-color: rgba({accent_rgb}, 0.12);
    border: 1px solid {accent};
    color: {accent};
    box-shadow:
        0 0 0 1px rgba({accent_rgb}, 0.6),
        0 0 35px rgba({accent_rgb}, 0.35),
        0 8px 32px rgba(0,0,0,0.5);
    background-size: 42%;
    outline: none;
}}
#lock      {{ background-image: image(url("{icons_dir}/lock.svg")); }}
#logout    {{ background-image: image(url("{icons_dir}/logout.svg")); }}
#suspend   {{ background-image: image(url("{icons_dir}/suspend.svg")); }}
#shutdown  {{ background-image: image(url("{icons_dir}/shutdown.svg")); }}
#hibernate {{ background-image: image(url("{icons_dir}/hibernate.svg")); }}
#reboot    {{ background-image: image(url("{icons_dir}/reboot.svg")); }}
#lock:hover, #lock:focus           {{ background-image: image(url("{icons_dir}/lock-hover.svg")); }}
#logout:hover, #logout:focus       {{ background-image: image(url("{icons_dir}/logout-hover.svg")); }}
#suspend:hover, #suspend:focus     {{ background-image: image(url("{icons_dir}/suspend-hover.svg")); }}
#shutdown:hover, #shutdown:focus   {{ background-image: image(url("{icons_dir}/shutdown-hover.svg")); }}
#hibernate:hover, #hibernate:focus {{ background-image: image(url("{icons_dir}/hibernate-hover.svg")); }}
#reboot:hover, #reboot:focus       {{ background-image: image(url("{icons_dir}/reboot-hover.svg")); }}
"""

css_path = os.path.join(theme_dir, "wlogout", "style.css")
with open(css_path, "w") as f:
    f.write(css)

print(f"wlogout style.css written: accent={accent} bg={bg}")
WLOGOUT_EOF

# --- Update Rofi (Ultra Minimal Style) ---
cat > "$THEME_DIR/rofi/launcher.rasi" << EOF
/* Chameleon Theme — Ultra Minimal Rofi Launcher (auto-generated) */
configuration {
    modi:                "drun,run";
    show-icons:          true;
    display-drun:        "  ";
    display-run:         "  ";
    drun-display-format: "{name}";
}

* {
    font:             "JetBrains Mono Nerd Font 11";
    background:       ${background}E6;
    background-alt:   ${color8}66;
    foreground:       ${foreground};
    selected:         ${color4};
    active:           ${color2};
    urgent:           ${color1};
}

window {
    width:            500px;
    transparency:     "real";
    location:         center;
    anchor:           center;
    border:           2px solid;
    border-color:     @selected;
    border-radius:    16px;
    background-color: @background;
    padding:          12px;
}

mainbox {
    spacing:          12px;
    background-color: transparent;
    children:         [ "inputbar", "listview" ];
}

inputbar {
    spacing:          8px;
    padding:          12px;
    border-radius:    12px;
    background-color: @background-alt;
    text-color:       @foreground;
    children:         [ "prompt", "entry" ];
}

prompt {
    background-color: transparent;
    text-color:       @selected;
    vertical-align:   0.5;
}

entry {
    background-color: transparent;
    text-color:       @foreground;
    placeholder:      "Search...";
    placeholder-color: #888888;
    vertical-align:   0.5;
}

listview {
    lines:            6;
    columns:          1;
    cycle:            true;
    dynamic:          true;
    scrollbar:        false;
    layout:           vertical;
    spacing:          4px;
    background-color: transparent;
}

element {
    padding:          10px 14px;
    border-radius:    10px;
    background-color: transparent;
    text-color:       @foreground;
    spacing:          12px;
}

element selected.normal {
    background-color: @selected;
    text-color:       @background;
}

element-icon {
    size:             24px;
    background-color: transparent;
}

element-text {
    background-color: transparent;
    text-color:       inherit;
    vertical-align:   0.5;
}
EOF

# --- Reload kitty terminals ---
kill -SIGUSR1 $(pgrep kitty) 2>/dev/null || true

# --- Restart Dunst ---
pkill dunst 2>/dev/null || true
sleep 0.2
dunst -conf "$THEME_DIR/dunst/dunstrc" &
disown

# --- Reload Waybar ---
WAYBAR_CONFIG="$THEME_DIR/waybar/layout.jsonc"

pkill waybar 2>/dev/null || true
while pgrep -x waybar >/dev/null; do
    sleep 0.1
done
pkill -9 waybar 2>/dev/null || true

# Start waybar in background, fully detached from the script.
setsid waybar -c "$WAYBAR_CONFIG" -s "$THEME_DIR/waybar/style.css" > /dev/null 2>&1 &
disown

# --- Restart file manager to pick up GTK4 colors ---
pkill nautilus 2>/dev/null || true
pkill thunar 2>/dev/null || true

# --- Notify ---
notify-send "🦎 Chameleon" "Palette from: $(basename "$WALLPAPER")" -t 3000

echo "✓ Chameleon recolored from: $WALLPAPER"
