#!/bin/bash
# ─────────────────────────────────────────────────────────
#  ✦  chameleon-chwall.sh
#  ✦  Picks a wallpaper, runs pywal, and reloads all components
# ─────────────────────────────────────────────────────────

set -eo pipefail

THEME_DIR="$HOME/.config/hypr/themes/Chameleon"
WALLPAPER_DIR="$THEME_DIR/wallpapers"
WAL_CACHE="$HOME/.cache/wal"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Pick wallpaper                                                      ║
# ╚══════════════════════════════════════════════════════════════════════╝
if [[ -n "${1:-}" && -f "$1" ]]; then
    WALLPAPER="$1"
else
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
fi

if [[ -z "$WALLPAPER" ]]; then
    notify-send "Chameleon" "No wallpapers found in $WALLPAPER_DIR" -i dialog-warning
    exit 1
fi

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Set wallpaper via swww                                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
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

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Run pywal                                                           ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Use the default 'wal' (imagemagick) backend for accurate natural colors
wal -i "$WALLPAPER" --backend wal -q -n -s -t || true

# Wait for pywal to finish writing cache
sleep 0.3

# Update Cava Config for Chameleon
mkdir -p "$HOME/.config/hypr/themes/Chameleon/cava"
cp -f "$HOME/.cache/wal/cava.config" "$HOME/.config/hypr/themes/Chameleon/cava/config" 2>/dev/null || true
mkdir -p "$HOME/.config/cava"
cp -f "$HOME/.cache/wal/cava.config" "$HOME/.config/cava/config" 2>/dev/null || true
killall -USR2 cava 2>/dev/null || true

# Update Zen Browser theme for Chameleon
ZEN_CHROME="$HOME/.var/app/app.zen_browser.zen/.zen/peppvdil.Default (release)/chrome"
mkdir -p "$ZEN_CHROME"
mkdir -p "$HOME/.config/hypr/themes/Chameleon/zen"
cp -f "$HOME/.cache/wal/zen-userChrome.css" "$HOME/.config/hypr/themes/Chameleon/zen/userChrome.css" 2>/dev/null || true
cp -f "$HOME/.cache/wal/zen-userChrome.css" "$ZEN_CHROME/userChrome.css" 2>/dev/null || true

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Smart Chameleon Palette Enhancer                                    ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Extracts colors DIRECTLY from the wallpaper image.
# color1–color6 = the 6 most vivid, hue-diverse colors in the image (boosted).
# color8–color14 = dimmed versions of those same colors.
# background/foreground preserved from pywal's initial extraction.
# (Disabled: Using native pywal output instead for better accuracy)
if false; then
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

def boost_color(r, g, b, sat_boost=0.2, val_floor=0.70):
    """Lightly boost saturation and ensure minimum brightness."""
    h, s, v = rgb_to_hsv(r, g, b)
    s = min(1.0, s + sat_boost)
    v = max(val_floor, v)
    return hsv_to_hex(h, s, v)

def dim_color(r, g, b):
    """Dim a color to ~60% brightness for muted variants."""
    h, s, v = rgb_to_hsv(r, g, b)
    s = s * 0.65
    v = v * 0.60
    return hsv_to_hex(h, s, v)

wal_cache   = os.path.expanduser("~/.cache/wal")
colors_sh   = os.path.join(wal_cache, "colors.sh")
colors_json = os.path.join(wal_cache, "colors.json")

# Read existing pywal output for background/foreground/wallpaper
bg_hex   = "#0a0a0f"
fg_hex   = "#c0c0cf"
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

# Extract a rich palette directly from the wallpaper image
try:
    ct = ColorThief(wallpaper)
    # Get 16 candidates at max quality; we'll pick best 6 as accents
    raw_palette = ct.get_palette(color_count=16, quality=1)
except Exception as e:
    print(f"ColorThief failed: {e}")
    exit(0)

# Sort by vividness (saturation * value) — most vivid colors first
raw_palette.sort(key=lambda c: rgb_to_hsv(*c)[1] * rgb_to_hsv(*c)[2], reverse=True)

# Deduplicate by hue: keep colors whose hue is >20° apart from already-selected ones.
# This prevents 6 nearly identical blues swamping the palette.
selected = []
for c in raw_palette:
    h, s, v = rgb_to_hsv(*c)
    too_close = any(
        min(abs(h - rgb_to_hsv(*sc)[0]), 1.0 - abs(h - rgb_to_hsv(*sc)[0])) < 0.055
        for sc in selected
    )
    if not too_close:
        selected.append(c)
    if len(selected) >= 6:
        break

# Pad to 6 if the wallpaper has few distinct hues (e.g. monochrome)
for c in raw_palette:
    if len(selected) >= 6:
        break
    if c not in selected:
        selected.append(c)

# Build palette from actual wallpaper colors (lightly boosted for vibrancy)
accent_colors = [boost_color(*c) for c in selected[:6]]
dim_colors    = [dim_color(*c)   for c in selected[:6]]

palette = {
    "color0":  bg_hex,
    "color1":  accent_colors[0],   # Most vivid wallpaper color
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

# Overwrite colors.sh in-place (keep all other lines like FZF, LS_COLORS)
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

print(f"Chameleon palette (from wallpaper): accent={accent_colors[0]} bg={bg_hex}")
PYEOF
fi

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Re-source the enhanced colors (Python rewrote colors.sh above)      ║
# ╚══════════════════════════════════════════════════════════════════════╝
# shellcheck source=/dev/null
source "$WAL_CACHE/colors.sh"

# Helper: strip leading # from hex
strip_hash() { echo "${1#\#}"; }

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update Hyprland border colors                                       ║
# ╚══════════════════════════════════════════════════════════════════════╝
ACTIVE_HEX=$(strip_hash "$color4")
INACTIVE_HEX=$(strip_hash "$color8")
BG_HEX=$(strip_hash "$background")

hyprctl keyword "general:col.active_border"   "rgba(${ACTIVE_HEX}e6)"   2>/dev/null || true
hyprctl keyword "general:col.inactive_border" "rgba(${INACTIVE_HEX}66)" 2>/dev/null || true

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update Chameleon colors.conf (for theme reloads)                    ║
# ╚══════════════════════════════════════════════════════════════════════╝
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
$shadow_color = rgba({strip_hash(colors.get('color1','000000'))}44)
$wallpaper = {wallpaper}
"""

tmp = os.path.join(theme_dir, "colors.conf.tmp")
with open(tmp, "w") as f:
    f.write(conf)
os.replace(tmp, os.path.join(theme_dir, "colors.conf"))
print(f"colors.conf written: accent={colors.get('color1','?')}")
CONF_EOF

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Generate GTK4 colors from pywal                                     ║
# ╚══════════════════════════════════════════════════════════════════════╝
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

mkdir -p "$HOME/.config/gtk-3.0"
cp "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
cat "$HOME/Projects/UXNA-Hyprland/.config/hypr/scripts/thunar.css" >> "$HOME/.config/gtk-3.0/gtk.css"
pkill thunar 2>/dev/null || true



# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update Dunst colors                                                 ║
# ╚══════════════════════════════════════════════════════════════════════╝
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

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update Kitty colors                                                 ║
# ╚══════════════════════════════════════════════════════════════════════╝
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

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update btop colors                                                  ║
# ╚══════════════════════════════════════════════════════════════════════╝
mkdir -p "$THEME_DIR/btop"
cat > "$THEME_DIR/btop/theme.theme" << EOF
# Chameleon Theme for btop (auto-generated)
theme[main_bg]="${background}"
theme[main_fg]="${foreground}"
theme[title]="${color7}"
theme[hi_fg]="${color1}"
theme[selected_bg]="${color8}"
theme[selected_fg]="${color7}"
theme[inactive_fg]="${color8}"
theme[graph_text]="${color4}"
theme[meter_bg]="${color0}"
theme[proc_misc]="${color5}"
theme[cpu_box]="${color2}"
theme[mem_box]="${color3}"
theme[net_box]="${color4}"
theme[proc_box]="${color5}"
theme[div_line]="${color8}"
theme[temp_start]="${color2}"
theme[temp_mid]="${color3}"
theme[temp_end]="${color1}"
theme[cpu_start]="${color2}"
theme[cpu_mid]="${color4}"
theme[cpu_end]="${color1}"
theme[free_start]="${color2}"
theme[free_mid]="${color4}"
theme[free_end]="${color6}"
theme[cached_start]="${color6}"
theme[cached_mid]="${color4}"
theme[cached_end]="${color2}"
theme[available_start]="${foreground}"
theme[available_mid]="${color4}"
theme[available_end]="${color2}"
theme[used_start]="${color4}"
theme[used_mid]="${color1}"
theme[used_end]="${color1}"
theme[download_start]="${color4}"
theme[download_mid]="${color6}"
theme[download_end]="${foreground}"
theme[upload_start]="${color5}"
theme[upload_mid]="${color3}"
theme[upload_end]="${color1}"
theme[process_start]="${color2}"
theme[process_mid]="${color4}"
theme[process_end]="${color1}"
EOF

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update Waybar HyDE theme.css                                        ║
# ╚══════════════════════════════════════════════════════════════════════╝
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

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update Hyprlock config with current colors                          ║
# ╚══════════════════════════════════════════════════════════════════════╝
python3 << 'HYPRLOCK_EOF'
import os, re

colors_sh   = os.path.expanduser("~/.cache/wal/colors.sh")
theme_dir   = os.path.expanduser("~/.config/hypr/themes/Chameleon")
output_path = os.path.join(theme_dir, "hyprlock", "hyprlock.conf")

# Parse colors from enhanced colors.sh
colors = {}
wallpaper = ""
with open(colors_sh) as f:
    for line in f:
        m = re.match(r"^(color\d+|background|foreground|wallpaper)='?(#?[^']+)'?", line)
        if m:
            colors[m.group(1)] = m.group(2).strip().strip("'")
        if line.startswith("wallpaper="):
            wallpaper = line.split("=", 1)[1].strip().strip("'\"")

def hex_rgba(h, alpha="ff"):
    return f"rgba({h.lstrip('#')}{alpha})"

accent  = colors.get("color4", "#00bbd3")
accent2 = colors.get("color6", "#00ef6b")
fail    = colors.get("color5", "#c714f1")
bg      = colors.get("background", "#020206")
fg      = colors.get("foreground", "#9d9da7")
muted   = colors.get("color8", "#2f7198")

conf = f"""# ╔══════════════════════════════════════════════════════════════════╗
# ║  Hyprlock  ·  Chameleon Theme                                  ║
# ║  Auto-regenerated by chameleon-chwall.sh on wallpaper change   ║
# ╚══════════════════════════════════════════════════════════════════╝

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  General                                                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
general {{
    no_fade_in         = false
    no_fade_out        = false
    grace              = 0
    ignore_empty_input = true
    hide_cursor        = true
}}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Background                                                          ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Wallpaper with blur + slight dim for readability
background {{
    monitor           =
    path              = ~/.cache/current_wallpaper
    blur_passes       = 4
    blur_size         = 7
    contrast          = 0.95
    brightness        = 0.45
    vibrancy          = 0.15
    vibrancy_darkness = 0.35
}}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Clock (large, centered)                                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
label {{
    monitor       =
    text          = $TIME
    color         = {hex_rgba(accent)}
    font_size     = 96
    font_family   = JetBrainsMono Nerd Font Bold
    position      = 0, 120
    halign        = center
    valign        = center
    shadow_passes = 3
    shadow_size   = 12
    shadow_color  = rgba(0,0,0,0.8)
    shadow_boost  = 1.2
}}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Date (below clock)                                                  ║
# ╚══════════════════════════════════════════════════════════════════════╝
label {{
    monitor       =
    text          = cmd[update:60000] date +"%A, %B %d"
    color         = {hex_rgba(accent, "cc")}
    font_size     = 16
    font_family   = JetBrainsMono Nerd Font
    position      = 0, 42
    halign        = center
    valign        = center
    shadow_passes = 2
    shadow_size   = 6
    shadow_color  = rgba(0,0,0,0.7)
}}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Password input field (glassmorphic card)                            ║
# ╚══════════════════════════════════════════════════════════════════════╝
input-field {{
    monitor           =
    size              = 320, 55
    outline_thickness = 2
    dots_size         = 0.28
    dots_spacing      = 0.55
    dots_center       = true
    dots_rounding     = -1

    outer_color       = {hex_rgba(accent, "66")}
    inner_color       = {hex_rgba(bg, "99")}
    font_color        = {hex_rgba(accent)}
    font_family       = JetBrainsMono Nerd Font

    fade_on_empty     = true
    placeholder_text  = <span foreground="{accent}99"> Enter Password</span>
    hide_input        = false

    check_color       = {hex_rgba(accent2)}
    fail_color        = {hex_rgba(fail)}
    fail_text         = <span foreground="{fail}"><i> $FAIL ($ATTEMPTS)</i></span>
    capslock_color    = {hex_rgba(muted)}

    position          = 0, -80
    halign            = center
    valign            = center
    rounding          = 14

    shadow_passes     = 3
    shadow_size       = 10
    shadow_color      = rgba(0,0,0,0.6)
}}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Username label (above input field)                                  ║
# ╚══════════════════════════════════════════════════════════════════════╝
label {{
    monitor       =
    text          =  uxna
    color         = {hex_rgba(fg, "cc")}
    font_size     = 13
    font_family   = JetBrainsMono Nerd Font
    position      = 0, -28
    halign        = center
    valign        = center
    shadow_passes = 1
    shadow_size   = 4
    shadow_color  = rgba(0,0,0,0.5)
}}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Bottom: uptime (left)                                               ║
# ╚══════════════════════════════════════════════════════════════════════╝
label {{
    monitor     =
    text        = cmd[update:60000] echo " $(uptime -p | sed 's/up //')"
    color       = {hex_rgba(fg, "66")}
    font_size   = 11
    font_family = JetBrainsMono Nerd Font
    position    = -40, 28
    halign      = left
    valign      = bottom
}}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Bottom: battery (right)                                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
label {{
    monitor     =
    text        = cmd[update:30000] bash -c 'b=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "?"); s=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo ""); [ "$s" = "Charging" ] && echo "󰂄 $b%" || echo "󰁹 $b%"'
    color       = {hex_rgba(fg, "66")}
    font_size   = 11
    font_family = JetBrainsMono Nerd Font
    position    = -40, 28
    halign      = right
    valign      = bottom
}}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Bottom: theme branding (center)                                     ║
# ╚══════════════════════════════════════════════════════════════════════╝
label {{
    monitor     =
    text        = 🦎 CHAMELEON
    color       = {hex_rgba(accent, "33")}
    font_size   = 10
    font_family = JetBrainsMono Nerd Font
    position    = 0, 14
    halign      = center
    valign      = bottom
}}
"""

os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, "w") as f:
    f.write(conf)
print(f"hyprlock.conf written: accent={accent} bg={bg}")
HYPRLOCK_EOF

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update Wlogout colors and SVGs                                      ║
# ╚══════════════════════════════════════════════════════════════════════╝
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

# Recolor SVG icons and convert to PNG
if os.path.exists(icons_dir):
    for fname in os.listdir(icons_dir):
        if not fname.endswith(".svg"):
            continue
        p = os.path.join(icons_dir, fname)
        with open(p) as f:
            content = f.read()
        color = bg if "-hover" in fname else accent
        content = re.sub(r'stroke="[^"]+"', f'stroke="{color}"', content)
        content = re.sub(r'fill="#[0-9a-fA-F]+"', f'fill="{color}"', content)
        with open(p, "w") as f:
            f.write(content)
        # Convert to crisp PNG
        png_path = p.replace(".svg", ".png")
        os.system(f'magick -background none -size 256x256 "{p}" "{png_path}" 2>/dev/null || convert -background none -size 256x256 "{p}" "{png_path}" 2>/dev/null')

# Write CSS — using only valid GTK CSS properties, glassmorphism card design
ax_hex = accent.lstrip("#")
ar, ag, ab = int(ax_hex[0:2],16), int(ax_hex[2:4],16), int(ax_hex[4:6],16)
accent_rgb = f"{ar},{ag},{ab}"

css = f"""/* ╔══════════════════════════════════════════════════════════════╗
   ║  Wlogout Style  ·  Chameleon Theme                         ║
   ║  Auto-regenerated by chameleon-chwall.sh on wallpaper change║
   ╚══════════════════════════════════════════════════════════════╝ */

/* --- Reset ------------------------------------------------- */
* {{
    background-image: none;
    font-family: "JetBrainsMono Nerd Font", "Inter", sans-serif;
    all: unset;
}}

/* --- Window Background ------------------------------------- */
window {{
    background-color: rgba({bg_rgb}, 0.82);   /* Dark overlay behind cards */
    color: {accent};
}}

/* --- Button Cards (default state) -------------------------- */
button {{
    background-color: rgba({bg_rgb}, 0.85);            /* Card background */
    border:           1px solid rgba({accent_rgb}, 0.2);/* Subtle accent border */
    border-radius:    12px;
    color:            rgba({accent_rgb}, 0.55);          /* Muted accent text */
    font-size:        12px;
    font-weight:      600;
    letter-spacing:   0.08em;
    margin:           8px;
    padding-bottom:   24px;

    /* Icon — positioned above the label */
    background-repeat:   no-repeat;
    background-position: center calc(50% - 14px);
    background-size:     40px;

    transition: background-color 150ms ease,
                border-color     150ms ease,
                color            150ms ease,
                box-shadow       150ms ease;

    min-height: 0;
}}

/* --- Button Cards (hover / focus state) -------------------- */
button:hover,
button:focus {{
    background-color: rgba({accent_rgb}, 0.1);         /* Tinted card on hover */
    border-color:     rgba({accent_rgb}, 0.6);
    color:            {accent};
    box-shadow:       0 0 24px rgba({accent_rgb}, 0.2); /* Glow */
    background-size:  44px;                           /* Slight icon scale */
    outline:          none;
}}

/* --- Icons (per-button background images) ------------------ */
#lock      {{ background-image: url("{icons_dir}/lock.png"); }}
#logout    {{ background-image: url("{icons_dir}/logout.png"); }}
#suspend   {{ background-image: url("{icons_dir}/suspend.png"); }}
#shutdown  {{ background-image: url("{icons_dir}/shutdown.png"); }}
#hibernate {{ background-image: url("{icons_dir}/hibernate.png"); }}
#reboot    {{ background-image: url("{icons_dir}/reboot.png"); }}

/* --- Icons (hover state — same PNGs, styling handled by button:hover) --- */
#lock:hover,      #lock:focus      {{ background-image: url("{icons_dir}/lock-hover.png"); }}
#logout:hover,    #logout:focus    {{ background-image: url("{icons_dir}/logout-hover.png"); }}
#suspend:hover,   #suspend:focus   {{ background-image: url("{icons_dir}/suspend-hover.png"); }}
#shutdown:hover,  #shutdown:focus  {{ background-image: url("{icons_dir}/shutdown-hover.png"); }}
#hibernate:hover, #hibernate:focus {{ background-image: url("{icons_dir}/hibernate-hover.png"); }}
#reboot:hover,    #reboot:focus    {{ background-image: url("{icons_dir}/reboot-hover.png"); }}
"""


css_path = os.path.join(theme_dir, "wlogout", "style.css")
with open(css_path, "w") as f:
    f.write(css)

print(f"wlogout style.css written: accent={accent} bg={bg}")
WLOGOUT_EOF

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update Rofi (Ultra Minimal Style)                                   ║
# ╚══════════════════════════════════════════════════════════════════════╝
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

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Reload kitty terminals                                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
kill -SIGUSR1 $(pgrep kitty) 2>/dev/null || true

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Restart Dunst                                                       ║
# ╚══════════════════════════════════════════════════════════════════════╝
pkill dunst 2>/dev/null || true
sleep 0.2
dunst -conf "$THEME_DIR/dunst/dunstrc" &
disown

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Reload Waybar                                                       ║
# ╚══════════════════════════════════════════════════════════════════════╝
WAYBAR_CONFIG="$THEME_DIR/waybar/layout.jsonc"

pkill waybar 2>/dev/null || true
while pgrep -x waybar >/dev/null; do
    sleep 0.1
done
pkill -9 waybar 2>/dev/null || true

# Start waybar in background, fully detached from the script.
setsid waybar -c "$WAYBAR_CONFIG" -s "$THEME_DIR/waybar/style.css" > /dev/null 2>&1 &
disown

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Restart file manager to pick up GTK4 colors                         ║
# ╚══════════════════════════════════════════════════════════════════════╝
pkill nautilus 2>/dev/null || true
pkill thunar 2>/dev/null || true


# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Notify                                                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
notify-send "🦎 Chameleon" "Palette from: $(basename "$WALLPAPER")" -t 3000

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Update VS Code & Antigravity IDE Colors                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
python3 << 'EOF'
import os, json, re

colors_sh = os.path.expanduser("~/.cache/wal/colors.sh")
vscode_settings = "/home/uxna/.var/app/com.visualstudio.code/config/Code/User/settings.json"
ide_settings = os.path.expanduser("~/.config/Antigravity IDE/User/settings.json")

colors = {}
if os.path.exists(colors_sh):
    with open(colors_sh) as f:
        for line in f:
            m = re.match(r"^(color\d+|background|foreground)='?(#[0-9a-fA-F]+)'?", line)
            if m:
                colors[m.group(1)] = m.group(2)

bg      = colors.get("background", "#0c0b07")
fg      = colors.get("foreground", "#b1b0a7")
accent  = colors.get("color1",     "#b2773b")
accent2 = colors.get("color2",     "#a4b237")
accent3 = colors.get("color3",     "#6db276")
muted   = colors.get("color8",     "#675748")

def hex_add(h, amount):
    h = h.lstrip("#")
    r, g, b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
    r = max(0, min(255, r + amount))
    g = max(0, min(255, g + amount))
    b = max(0, min(255, b + amount))
    return f"#{r:02x}{g:02x}{b:02x}"

def alpha(h, a):
    return h + a

bg_light   = hex_add(bg, 12)
bg_sidebar = hex_add(bg, 6)
bg_input   = hex_add(bg, 18)
bg_hover   = hex_add(bg, 22)
border     = hex_add(muted, -20)

color_theme = {
    "editor.background":                            bg_light,
    "editor.foreground":                            fg,
    "editor.lineHighlightBackground":               alpha(accent, "15"),
    "editor.selectionBackground":                   alpha(accent, "44"),
    "editor.selectionHighlightBackground":          alpha(accent, "22"),
    "editor.inactiveSelectionBackground":           alpha(accent, "22"),
    "editor.wordHighlightBackground":               alpha(accent, "33"),
    "editor.findMatchBackground":                   alpha(accent2, "55"),
    "editor.findMatchHighlightBackground":          alpha(accent2, "33"),
    "editorLineNumber.foreground":                  alpha(muted, "cc"),
    "editorLineNumber.activeForeground":            accent,
    "editorCursor.foreground":                      accent,
    "editorWhitespace.foreground":                  alpha(muted, "44"),
    "editorIndentGuide.background1":                alpha(muted, "44"),
    "editorIndentGuide.activeBackground1":          alpha(accent, "66"),
    "editorRuler.foreground":                       alpha(muted, "44"),
    "sideBar.background":                           bg_sidebar,
    "sideBar.foreground":                           fg,
    "sideBar.border":                               alpha(border, "88"),
    "sideBarSectionHeader.background":              bg,
    "sideBarSectionHeader.foreground":              accent,
    "activityBar.background":                       bg,
    "activityBar.foreground":                       fg,
    "activityBar.inactiveForeground":               alpha(muted, "cc"),
    "activityBar.border":                           alpha(border, "66"),
    "activityBarBadge.background":                  accent,
    "activityBarBadge.foreground":                  bg,
    "titleBar.activeBackground":                    bg,
    "titleBar.activeForeground":                    fg,
    "titleBar.inactiveBackground":                  bg,
    "titleBar.inactiveForeground":                  alpha(fg, "77"),
    "titleBar.border":                              alpha(border, "55"),
    "tab.activeBackground":                         bg_light,
    "tab.activeForeground":                         fg,
    "tab.inactiveBackground":                       bg_sidebar,
    "tab.activeBorder":                             accent,
    "tab.hoverBackground":                          bg_hover,
    "editorGroupHeader.tabsBackground":             bg,
    "statusBar.background":                         bg,
    "statusBar.foreground":                         fg,
    "statusBar.border":                             alpha(border, "55"),
    "statusBar.noFolderBackground":                 bg,
    "statusBar.debuggingBackground":                accent,
    "panel.background":                             bg_sidebar,
    "panel.border":                                 alpha(border, "88"),
    "terminal.background":                          bg,
    "terminal.foreground":                          fg,
    "terminal.ansiBlack":                           colors.get("color0", "#0c0b07"),
    "terminal.ansiRed":                             colors.get("color1", "#b2773b"),
    "terminal.ansiGreen":                           colors.get("color2", "#a4b237"),
    "terminal.ansiYellow":                          colors.get("color3", "#6db276"),
    "terminal.ansiBlue":                            colors.get("color4", "#89b27c"),
    "terminal.ansiMagenta":                         colors.get("color5", "#b26b3b"),
    "terminal.ansiCyan":                            colors.get("color6", "#b29849"),
    "terminal.ansiWhite":                           colors.get("color7", "#b1b0a7"),
    "terminalCursor.foreground":                    accent,
    "terminalCursor.background":                    bg,
    "dropdown.background":                          bg_input,
    "dropdown.border":                              alpha(border, "88"),
    "input.background":                             bg_input,
    "input.border":                                 alpha(border, "88"),
    "scrollbarSlider.background":                   alpha(muted, "44"),
    "scrollbarSlider.hoverBackground":              alpha(muted, "88"),
    "scrollbarSlider.activeBackground":             alpha(accent, "88"),
    "gitDecoration.addedResourceForeground":        accent2,
    "gitDecoration.modifiedResourceForeground":     accent,
    "gitDecoration.deletedResourceForeground":      colors.get("color5", "#b26b3b"),
    "button.background":                            accent,
    "button.foreground":                            bg,
    "list.activeSelectionBackground":               alpha(accent, "33"),
    "list.hoverBackground":                         alpha(accent, "15"),
}

for path in [vscode_settings, ide_settings]:
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        try:
            with open(path) as f:
                settings = json.load(f)
        except Exception:
            settings = {}
        settings["workbench.colorCustomizations"] = color_theme
        with open(path, "w") as f:
            json.dump(settings, f, indent=4)
    except Exception:
        pass
EOF

echo "✓ Chameleon recolored from: $WALLPAPER"
