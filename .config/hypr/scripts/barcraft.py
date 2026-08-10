#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║                  Barcraft — Waybar Manager                   ║
║  Scan, enable, and disable waybar modules per section.       ║
╚══════════════════════════════════════════════════════════════╝
"""

import curses
import json
import re
import subprocess
import sys
import shutil
import time
from pathlib import Path

# ── Paths & Dynamic Config Lookup ──────────────────────────────────────
def get_active_waybar_config() -> Path:
    """Find the actively running waybar config, or fallback to default."""
    try:
        out = subprocess.check_output(['ps', '-eo', 'args']).decode('utf-8')
        for line in out.splitlines():
            if 'waybar' in line and '-c' in line and 'barcraft' not in line and 'waybar-modules-manager' not in line:
                m = re.search(r'\bwaybar\b.*?-c\s+([^\s]+)', line)
                if m:
                    return Path(m.group(1)).expanduser().resolve()
    except Exception:
        pass
    return Path.home() / ".config" / "waybar" / "config.jsonc"

WAYBAR_CONFIG = get_active_waybar_config()
WAYBAR_CONFIG_BACKUP = WAYBAR_CONFIG.with_name(f"{WAYBAR_CONFIG.name}.bak")
DISABLED_MODULES_FILE = WAYBAR_CONFIG.parent / f".disabled-{WAYBAR_CONFIG.name}"

WAYBAR_MODULES_USER = Path.home() / ".config" / "waybar" / "modules"
WAYBAR_MODULES_SHARE = Path.home() / ".local" / "share" / "waybar" / "modules"


# ── Module type icons ──────────────────────────────────────────────────
MODULE_ICONS = {
    'clock':              '󰥔',
    'battery':            '󰁹',
    'network':            '󰖩',
    'bluetooth':          '󰂯',
    'pulseaudio':         '󰕾',
    'backlight':          '󰃟',
    'cpu':                '󰘚',
    'memory':             '󰍛',
    'temperature':        '󰔏',
    'tray':               '󰏖',
    'privacy':            '󰊪',
    'mpris':              '󰎈',
    'idle_inhibitor':     '󰒲',
    'custom/weather':     '󰖐',
    'custom/power':       '󰐥',
    'custom/updates':     '󰚰',
    'custom/bluetooth':   '󰂯',
    'custom/gpuinfo':     '󰢮',
    'custom/cpuinfo':     '󰘚',
    'custom/sensorsinfo': '󰔏',
    'custom/swaync':      '󰂞',
    'custom/dunst':       '󰂞',
    'custom/hyde-menu':   '󰍜',
    'custom/clipboard':   '󰅍',
    'custom/hyprsunset':  '󰖔',
    'custom/keybindhint': '󰌌',
    'custom/gamemode':    '󰊴',
    'hyprland/workspaces': '󰖯',
    'wlr/taskbar':        '󰖲',
    'power-profiles-daemon': '󱐋',
    'keyboard-state':     '󰌌',
}

def get_module_icon(name: str) -> str:
    """Get an icon for a module name, with smart fallbacks."""
    if name in MODULE_ICONS:
        return MODULE_ICONS[name]
    # Strip instance suffix (e.g., "pulseaudio#microphone" → "pulseaudio")
    base = name.split('#')[0]
    if base in MODULE_ICONS:
        return MODULE_ICONS[base]
    # Category fallbacks
    if name.startswith('custom/'):
        return '󰣖'
    if name.startswith('hyprland/'):
        return '󰖯'
    if name.startswith('wlr/'):
        return '󰖲'
    if name.startswith('group/'):
        return '󰅩'
    if name.startswith('network'):
        return '󰖩'
    return '󰣆'


# ── Colors ──────────────────────────────────────────────────────────────
C_HEADER    = 1
C_SECTION   = 2
C_ENABLED   = 3
C_DISABLED  = 4
C_SELECTED  = 5
C_HELP      = 6
C_WARNING   = 7
C_ACCENT    = 8
C_DIM       = 9
C_SEARCH    = 10
C_BAR_BG    = 11
C_SEL_EN    = 12
C_SEL_DIS   = 13

def init_colors():
    try:
        curses.start_color()
        curses.use_default_colors()
        bg = -1
    except curses.error:
        try:
            curses.start_color()
        except curses.error:
            return
        bg = curses.COLOR_BLACK
    try:
        curses.init_pair(C_HEADER,  curses.COLOR_BLACK,  curses.COLOR_CYAN)
        curses.init_pair(C_SECTION, curses.COLOR_CYAN,   bg)
        curses.init_pair(C_ENABLED, curses.COLOR_GREEN,  bg)
        curses.init_pair(C_DISABLED,curses.COLOR_RED,    bg)
        curses.init_pair(C_SELECTED,curses.COLOR_BLACK,  curses.COLOR_WHITE)
        curses.init_pair(C_HELP,    curses.COLOR_YELLOW, bg)
        curses.init_pair(C_WARNING, curses.COLOR_RED,    bg)
        curses.init_pair(C_ACCENT,  curses.COLOR_MAGENTA,bg)
        curses.init_pair(C_DIM,     curses.COLOR_WHITE,  bg)
        curses.init_pair(C_SEARCH,  curses.COLOR_BLACK,  curses.COLOR_YELLOW)
        curses.init_pair(C_BAR_BG,  curses.COLOR_CYAN,   bg)
        curses.init_pair(C_SEL_EN,  curses.COLOR_GREEN,  curses.COLOR_WHITE)
        curses.init_pair(C_SEL_DIS, curses.COLOR_RED,    curses.COLOR_WHITE)
    except (curses.error, ValueError):
        pass


# ── JSONC parsing ──────────────────────────────────────────────────────
def strip_jsonc_comments(text: str) -> str:
    """Remove // and /* */ comments from JSONC, respecting strings."""
    result = []
    i = 0
    in_string = False
    escape = False
    while i < len(text):
        c = text[i]
        if escape:
            result.append(c)
            escape = False
            i += 1
            continue
        if c == '\\' and in_string:
            result.append(c)
            escape = True
            i += 1
            continue
        if c == '"' and not in_string:
            in_string = True
            result.append(c)
            i += 1
            continue
        if c == '"' and in_string:
            in_string = False
            result.append(c)
            i += 1
            continue
        if not in_string:
            if c == '/' and i + 1 < len(text) and text[i + 1] == '/':
                while i < len(text) and text[i] != '\n':
                    i += 1
                continue
            if c == '/' and i + 1 < len(text) and text[i + 1] == '*':
                i += 2
                while i + 1 < len(text) and not (text[i] == '*' and text[i + 1] == '/'):
                    i += 1
                i += 2
                continue
        result.append(c)
        i += 1
    return ''.join(result)

def remove_trailing_commas(text: str) -> str:
    return re.sub(r',\s*([}\]])', r'\1', text)

def load_config() -> dict:
    raw = WAYBAR_CONFIG.read_text()
    cleaned = strip_jsonc_comments(raw)
    cleaned = remove_trailing_commas(cleaned)
    return json.loads(cleaned)

def save_config(config: dict):
    if WAYBAR_CONFIG.exists():
        shutil.copy2(WAYBAR_CONFIG, WAYBAR_CONFIG_BACKUP)
    output = json.dumps(config, indent=2)
    WAYBAR_CONFIG.write_text(output + "\n")


# ── Disabled modules persistence ───────────────────────────────────────
def load_disabled_modules() -> dict:
    if DISABLED_MODULES_FILE.exists():
        try:
            return json.loads(DISABLED_MODULES_FILE.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {}

def save_disabled_modules(disabled: dict):
    DISABLED_MODULES_FILE.write_text(json.dumps(disabled, indent=2) + "\n")


# ── Module discovery ───────────────────────────────────────────────────
def discover_available_modules() -> list[str]:
    modules = set()
    for modules_dir in [WAYBAR_MODULES_USER, WAYBAR_MODULES_SHARE]:
        if not modules_dir.exists():
            continue
        for f in modules_dir.iterdir():
            if f.suffix in ('.jsonc', '.json') and f.stem not in ('README', 'style', 'theme'):
                name = f.stem
                for prefix in ('custom-', 'hyprland-', 'wlr-', 'group-', 'image-'):
                    if name.startswith(prefix):
                        slash_prefix = prefix.rstrip('-')
                        name = slash_prefix + '/' + name[len(prefix):]
                        break
                name = name.replace('##', '#')
                modules.add(name)
    return sorted(modules)


# ── Config structure ───────────────────────────────────────────────────
class ModuleEntry:
    def __init__(self, name: str, enabled: bool = True):
        self.name = name
        self.enabled = enabled

class Section:
    SIDE_LABELS = {
        'modules-left':   ('← Left',   '◂'),
        'modules-center': ('◆ Center',  '◈'),
        'modules-right':  ('→ Right',   '▸'),
    }

    def __init__(self, key: str, modules: list['ModuleEntry']):
        self.key = key
        self.modules = modules

    @property
    def display_name(self) -> str:
        if self.key in self.SIDE_LABELS:
            return self.SIDE_LABELS[self.key][0]
        group_name = self.key.replace('group/', '')
        return f"󰅩 {group_name}"

    @property
    def short_icon(self) -> str:
        if self.key in self.SIDE_LABELS:
            return self.SIDE_LABELS[self.key][1]
        return '󰅩'

    @property
    def enabled_modules(self) -> list[str]:
        return [m.name for m in self.modules if m.enabled]

    @property
    def enabled_count(self) -> int:
        return sum(1 for m in self.modules if m.enabled)

    @property
    def disabled_count(self) -> int:
        return sum(1 for m in self.modules if not m.enabled)

    @property
    def total_count(self) -> int:
        return len(self.modules)


def extract_sections(config: dict, disabled: dict) -> list[Section]:
    sections = []

    # Top-level module lists
    for side in ('modules-left', 'modules-center', 'modules-right'):
        if side in config:
            entries = [ModuleEntry(m, True) for m in config[side]]
            for dm in disabled.get(side, []):
                if dm not in config[side]:
                    entries.append(ModuleEntry(dm, False))
            sections.append(Section(side, entries))

    # Group definitions (the pills)
    for key, value in config.items():
        if key.startswith('group/') and isinstance(value, dict) and 'modules' in value:
            entries = [ModuleEntry(m, True) for m in value['modules']]
            for dm in disabled.get(key, []):
                if dm not in value['modules']:
                    entries.append(ModuleEntry(dm, False))
            sections.append(Section(key, entries))

    return sections


# ── Drawing helpers ────────────────────────────────────────────────────
def safe_addstr(stdscr, y, x, text, attr=0):
    """Write text without crashing on terminal edge."""
    h, w = stdscr.getmaxyx()
    if y < 0 or y >= h or x >= w:
        return
    max_len = w - x - 1
    if max_len <= 0:
        return
    try:
        stdscr.addnstr(y, x, text, max_len, attr)
    except curses.error:
        pass

def draw_hline(stdscr, y, char='─', attr=0):
    h, w = stdscr.getmaxyx()
    if 0 <= y < h:
        safe_addstr(stdscr, y, 0, char * (w - 1), attr)

def draw_scrollbar(stdscr, y_start, vis_h, total, offset, x):
    """Draw a thin scrollbar on column x."""
    h, w = stdscr.getmaxyx()
    if total <= vis_h or x >= w:
        return
    thumb_h = max(1, vis_h * vis_h // total)
    thumb_pos = y_start + (offset * (vis_h - thumb_h) // max(1, total - vis_h))
    for i in range(vis_h):
        y = y_start + i
        if y >= h:
            break
        ch = '┃' if thumb_pos <= y < thumb_pos + thumb_h else '│'
        attr = curses.color_pair(C_ACCENT) if ch == '┃' else curses.color_pair(C_DIM) | curses.A_DIM
        safe_addstr(stdscr, y, x, ch, attr)


# ── TUI ────────────────────────────────────────────────────────────────
class WaybarManager:
    HEADER_HEIGHT = 3       # title + subtitle + separator
    FOOTER_HEIGHT = 3       # separator + help + message

    def __init__(self, stdscr):
        self.stdscr = stdscr
        self.config = load_config()
        self.disabled = load_disabled_modules()
        self.available_modules = discover_available_modules()
        self.sections = extract_sections(self.config, self.disabled)
        self.dirty = False

        self.items = []          # flat list: ('section'|'module', section_idx, module_idx|None)
        self._build_items()

        self.cursor = 0
        self.scroll_offset = 0
        self.mode = 'browse'     # browse | add | confirm_quit

        # Add-mode state
        self.add_candidates = []
        self.add_filtered = []
        self.add_cursor = 0
        self.add_scroll = 0
        self.add_section_idx = -1
        self.add_search = ""

        # Message toast
        self.message = ""
        self.message_color = C_HELP
        self.message_time = 0

    # ── Item list ──────────────────────────────────────────────────────
    def _build_items(self):
        self.items = []
        for si, section in enumerate(self.sections):
            self.items.append(('section', si, None))
            for mi, _ in enumerate(section.modules):
                self.items.append(('module', si, mi))

    def _vis_height(self):
        h, _ = self.stdscr.getmaxyx()
        return max(1, h - self.HEADER_HEIGHT - self.FOOTER_HEIGHT)

    # ── Drawing ────────────────────────────────────────────────────────
    def draw(self):
        self.stdscr.erase()
        h, w = self.stdscr.getmaxyx()

        # Auto-expire message after 4 seconds
        if self.message and (time.monotonic() - self.message_time > 4):
            self.message = ""

        self._draw_header(w)

        vis_h = self._vis_height()
        body_y = self.HEADER_HEIGHT

        if self.mode == 'browse':
            self._draw_browse(body_y, vis_h, w)
        elif self.mode == 'add':
            self._draw_add(body_y, vis_h, w)
        elif self.mode == 'confirm_quit':
            self._draw_browse(body_y, vis_h, w)

        self._draw_footer(h, w)
        self.stdscr.refresh()

    def _draw_header(self, w):
        # ── Row 0: Title bar ──
        title = "  ⚒  Barcraft — Waybar Manager  "
        self.stdscr.attron(curses.color_pair(C_HEADER) | curses.A_BOLD)
        safe_addstr(self.stdscr, 0, 0, " " * (w - 1))
        safe_addstr(self.stdscr, 0, max(0, (w - len(title)) // 2), title)
        self.stdscr.attroff(curses.color_pair(C_HEADER) | curses.A_BOLD)

        # ── Row 1: Status line ──
        cfg_label = WAYBAR_CONFIG.parent.name + "/" + WAYBAR_CONFIG.name
        total_en = sum(s.enabled_count for s in self.sections)
        total_dis = sum(s.disabled_count for s in self.sections)
        total_mod = total_en + total_dis
        parts = [
            f" 󰒓 {cfg_label}",
            f"󰣆 {total_mod} modules",
            f"󰄬 {total_en} on",
        ]
        if total_dis:
            parts.append(f"󰅖 {total_dis} off")
        if self.dirty:
            parts.append("● unsaved")
        subtitle = "  │  ".join(parts) + " "

        attr = curses.color_pair(C_ACCENT)
        if self.dirty:
            attr |= curses.A_BOLD
        safe_addstr(self.stdscr, 1, 0, subtitle, attr)

        # ── Row 2: Separator ──
        draw_hline(self.stdscr, 2, '─', curses.color_pair(C_DIM) | curses.A_DIM)

    def _draw_footer(self, h, w):
        footer_y = h - self.FOOTER_HEIGHT

        # ── Separator ──
        draw_hline(self.stdscr, footer_y, '─', curses.color_pair(C_DIM) | curses.A_DIM)

        # ── Help line ──
        if self.mode == 'browse':
            keys = [
                ("↑↓/jk", "navigate"),
                ("x/Space", "toggle"),
                ("a", "add"),
                ("d/DEL", "remove"),
                ("+/-/K/J", "reorder"),
                ("Tab", "next section"),
                ("s", "save"),
                ("r/R", "reload/restart"),
                ("q", "quit"),
            ]
        elif self.mode == 'add':
            keys = [
                ("↑↓", "navigate"),
                ("Enter/Space", "add"),
                ("/", "search"),
                ("Esc", "back"),
            ]
        elif self.mode == 'confirm_quit':
            keys = [
                ("s", "save & quit"),
                ("q/Q", "discard & quit"),
                ("Esc", "cancel"),
            ]

        help_y = footer_y + 1
        x = 1
        for i, (key, desc) in enumerate(keys):
            if x >= w - 1:
                break
            safe_addstr(self.stdscr, help_y, x, key,
                        curses.color_pair(C_HELP) | curses.A_BOLD)
            x += len(key)
            safe_addstr(self.stdscr, help_y, x, f" {desc}",
                        curses.color_pair(C_DIM))
            x += len(desc) + 1
            if i < len(keys) - 1:
                safe_addstr(self.stdscr, help_y, x, " │ ",
                            curses.color_pair(C_DIM) | curses.A_DIM)
                x += 3

        # ── Message line ──
        msg_y = footer_y + 2
        if self.mode == 'confirm_quit':
            safe_addstr(self.stdscr, msg_y, 1,
                        " ⚠  You have unsaved changes. Save before quitting?",
                        curses.color_pair(C_WARNING) | curses.A_BOLD)
        elif self.message:
            safe_addstr(self.stdscr, msg_y, 1, self.message,
                        curses.color_pair(self.message_color) | curses.A_BOLD)

    # ── Browse mode drawing ────────────────────────────────────────────
    def _draw_browse(self, start_y, vis_h, w):
        # Clamp scroll
        if self.cursor < self.scroll_offset:
            self.scroll_offset = self.cursor
        if self.cursor >= self.scroll_offset + vis_h:
            self.scroll_offset = self.cursor - vis_h + 1

        scrollbar_x = w - 2

        for i in range(vis_h):
            idx = self.scroll_offset + i
            if idx >= len(self.items):
                break
            y = start_y + i
            item_type, si, mi = self.items[idx]
            is_sel = (idx == self.cursor)

            if item_type == 'section':
                self._draw_section_row(y, w, si, is_sel)
            else:
                self._draw_module_row(y, w, si, mi, is_sel)

        draw_scrollbar(self.stdscr, start_y, vis_h, len(self.items),
                       self.scroll_offset, scrollbar_x)

    def _draw_section_row(self, y, w, si, is_sel):
        section = self.sections[si]
        en = section.enabled_count
        dis = section.disabled_count

        # Build: ┌── 󰅩 pill#right1 ─── 4 on  2 off ──────────────
        prefix = f"┌── {section.display_name} "
        stats = f" {en} on"
        if dis:
            stats += f"  {dis} off"
        stats += " "

        # Fill with thin dash
        fill_len = max(0, w - len(prefix) - len(stats) - 3)
        line = prefix + "─" * 3 + stats + "─" * fill_len

        if is_sel:
            safe_addstr(self.stdscr, y, 0, line, curses.color_pair(C_SELECTED) | curses.A_BOLD)
        else:
            # Render in parts for color richness
            safe_addstr(self.stdscr, y, 0, "┌── ", curses.color_pair(C_DIM) | curses.A_DIM)
            safe_addstr(self.stdscr, y, 4, section.display_name + " ",
                        curses.color_pair(C_SECTION) | curses.A_BOLD)
            x = 4 + len(section.display_name) + 1
            safe_addstr(self.stdscr, y, x, "─── ", curses.color_pair(C_DIM) | curses.A_DIM)
            x += 4
            # Stats colored
            safe_addstr(self.stdscr, y, x, f"{en} on",
                        curses.color_pair(C_ENABLED))
            x += len(f"{en} on")
            if dis:
                safe_addstr(self.stdscr, y, x, f"  {dis} off",
                            curses.color_pair(C_DISABLED))
                x += len(f"  {dis} off")
            safe_addstr(self.stdscr, y, x, " " + "─" * max(0, w - x - 3),
                        curses.color_pair(C_DIM) | curses.A_DIM)

    def _draw_module_row(self, y, w, si, mi, is_sel):
        mod = self.sections[si].modules[mi]
        icon = get_module_icon(mod.name)

        if mod.enabled:
            check = "󰄬"   # checkmark
            color = C_ENABLED
        else:
            check = "󰅖"   # x-mark
            color = C_DISABLED

        # Compose: │   󰄬  󰕾  pulseaudio#microphone
        line_prefix = "│   "
        line_body = f"{check}  {icon}  {mod.name}"

        if is_sel:
            # Full row highlight, but tint the check icon
            safe_addstr(self.stdscr, y, 0, (line_prefix + line_body).ljust(w - 3),
                        curses.color_pair(C_SELECTED) | curses.A_BOLD)
            # Overdraw the check with color
            check_color = C_SEL_EN if mod.enabled else C_SEL_DIS
            safe_addstr(self.stdscr, y, len(line_prefix),
                        check, curses.color_pair(check_color) | curses.A_BOLD)
        else:
            safe_addstr(self.stdscr, y, 0, line_prefix,
                        curses.color_pair(C_DIM) | curses.A_DIM)
            safe_addstr(self.stdscr, y, len(line_prefix), check,
                        curses.color_pair(color) | curses.A_BOLD)
            x = len(line_prefix) + len(check)
            safe_addstr(self.stdscr, y, x, f"  {icon}  ",
                        curses.color_pair(C_ACCENT))
            x += len(f"  {icon}  ")
            name_color = color if not mod.enabled else C_DIM
            safe_addstr(self.stdscr, y, x, mod.name,
                        curses.color_pair(name_color))

    # ── Add mode drawing ───────────────────────────────────────────────
    def _draw_add(self, start_y, vis_h, w):
        section = self.sections[self.add_section_idx]
        existing = {m.name for m in section.modules}

        # ── Title ──
        title = f"  Add module to {section.display_name} "
        safe_addstr(self.stdscr, start_y, 0, title,
                    curses.color_pair(C_ACCENT) | curses.A_BOLD)

        # ── Search bar ──
        search_y = start_y + 1
        search_prompt = "  󰍉 Filter: "
        safe_addstr(self.stdscr, search_y, 0, search_prompt,
                    curses.color_pair(C_DIM))
        if self.add_search:
            safe_addstr(self.stdscr, search_y, len(search_prompt), self.add_search,
                        curses.color_pair(C_SEARCH) | curses.A_BOLD)
            safe_addstr(self.stdscr, search_y, len(search_prompt) + len(self.add_search), "▎",
                        curses.color_pair(C_HELP))
        else:
            safe_addstr(self.stdscr, search_y, len(search_prompt), "type to filter…▎",
                        curses.color_pair(C_DIM) | curses.A_DIM)

        count_text = f"  {len(self.add_filtered)} / {len(self.add_candidates)} modules"
        safe_addstr(self.stdscr, search_y, w - len(count_text) - 2, count_text,
                    curses.color_pair(C_DIM))

        draw_hline(self.stdscr, start_y + 2, '─', curses.color_pair(C_DIM) | curses.A_DIM)

        # ── Module list ──
        list_y = start_y + 3
        list_h = vis_h - 3

        if self.add_cursor < self.add_scroll:
            self.add_scroll = self.add_cursor
        if self.add_cursor >= self.add_scroll + list_h:
            self.add_scroll = self.add_cursor - list_h + 1

        scrollbar_x = w - 2

        for i in range(list_h):
            idx = self.add_scroll + i
            if idx >= len(self.add_filtered):
                break
            y = list_y + i
            mod = self.add_filtered[idx]
            is_sel = (idx == self.add_cursor)
            already = mod in existing
            icon = get_module_icon(mod)

            if already:
                prefix = f"    󰄬  {icon}  "
            else:
                prefix = f"       {icon}  "

            label = prefix + mod

            if is_sel:
                safe_addstr(self.stdscr, y, 0, label.ljust(w - 3),
                            curses.color_pair(C_SELECTED) | curses.A_BOLD)
                if already:
                    safe_addstr(self.stdscr, y, 4, "󰄬",
                                curses.color_pair(C_SEL_EN) | curses.A_BOLD)
            elif already:
                safe_addstr(self.stdscr, y, 0, label,
                            curses.color_pair(C_DIM) | curses.A_DIM)
                safe_addstr(self.stdscr, y, 4, "󰄬",
                            curses.color_pair(C_ENABLED))
            else:
                safe_addstr(self.stdscr, y, 0, prefix,
                            curses.color_pair(C_ACCENT))
                safe_addstr(self.stdscr, y, len(prefix), mod,
                            curses.color_pair(C_DIM))

        draw_scrollbar(self.stdscr, list_y, list_h, len(self.add_filtered),
                       self.add_scroll, scrollbar_x)

    # ── Input handling ─────────────────────────────────────────────────
    def _set_message(self, msg, color=C_HELP):
        self.message = msg
        self.message_color = color
        self.message_time = time.monotonic()

    def handle_input(self, key):
        if self.mode == 'browse':
            self._handle_browse(key)
        elif self.mode == 'add':
            self._handle_add(key)
        elif self.mode == 'confirm_quit':
            self._handle_confirm_quit(key)

    def _handle_browse(self, key):
        # ── Navigation ──
        if key in (curses.KEY_UP, ord('k')):
            if self.cursor > 0:
                self.cursor -= 1
        elif key in (curses.KEY_DOWN, ord('j')):
            if self.cursor < len(self.items) - 1:
                self.cursor += 1
        elif key == curses.KEY_HOME or key == ord('g'):
            self.cursor = 0
        elif key == curses.KEY_END or key == ord('G'):
            self.cursor = len(self.items) - 1
        elif key == curses.KEY_PPAGE:    # Page Up
            self.cursor = max(0, self.cursor - self._vis_height())
        elif key == curses.KEY_NPAGE:    # Page Down
            self.cursor = min(len(self.items) - 1, self.cursor + self._vis_height())

        # ── Tab: jump to next section ──
        elif key == ord('\t'):
            self._jump_next_section()
        elif key == 353:                 # Shift-Tab
            self._jump_prev_section()

        # ── Toggle ──
        elif key in (ord('x'), ord(' ')):
            if not self.items:
                return
            item_type, si, mi = self.items[self.cursor]
            if item_type == 'module':
                mod = self.sections[si].modules[mi]
                mod.enabled = not mod.enabled
                self._apply_section_to_config(si)
                self._sync_disabled()
                self.dirty = True
                if mod.enabled:
                    self._set_message(f"󰄬 Enabled: {mod.name}", C_ENABLED)
                else:
                    self._set_message(f"󰅖 Disabled: {mod.name}", C_DISABLED)
            else:
                self._set_message("Press x or Space on a module to toggle", C_HELP)

        # ── Delete (permanent removal) ──
        elif key in (curses.KEY_DC, ord('d')):
            if not self.items:
                return
            item_type, si, mi = self.items[self.cursor]
            if item_type == 'module':
                mod = self.sections[si].modules[mi]
                self.sections[si].modules.pop(mi)
                self._apply_section_to_config(si)
                self._sync_disabled()
                self._build_items()
                if self.cursor >= len(self.items):
                    self.cursor = max(0, len(self.items) - 1)
                self.dirty = True
                self._set_message(f"󰆴 Removed: {mod.name}", C_WARNING)
            else:
                self._set_message("Cannot remove a section header", C_WARNING)

        # ── Add module ──
        elif key == ord('a'):
            si = self._get_current_section_idx()
            if si < 0:
                return
            self.add_section_idx = si
            self.add_candidates = self.available_modules[:]
            self.add_search = ""
            self.add_filtered = self.add_candidates[:]
            self.add_cursor = 0
            self.add_scroll = 0
            self.mode = 'add'

        # ── Reorder ──
        elif key in (ord('K'), ord('+'), ord('='), 337):     # Shift+Up or +/=
            if not self.items:
                return
            item_type, si, mi = self.items[self.cursor]
            if item_type == 'module' and mi > 0:
                mods = self.sections[si].modules
                mods[mi], mods[mi - 1] = mods[mi - 1], mods[mi]
                self._apply_section_to_config(si)
                self._sync_disabled()
                self._build_items()
                self.cursor -= 1
                self.dirty = True

        elif key in (ord('J'), ord('-'), 336):     # Shift+Down or -
            if not self.items:
                return
            item_type, si, mi = self.items[self.cursor]
            if item_type == 'module':
                mods = self.sections[si].modules
                if mi < len(mods) - 1:
                    mods[mi], mods[mi + 1] = mods[mi + 1], mods[mi]
                    self._apply_section_to_config(si)
                    self._sync_disabled()
                    self._build_items()
                    self.cursor += 1
                    self.dirty = True

        # ── Save ──
        elif key == ord('s'):
            self._apply_all_to_config()
            save_config(self.config)
            save_disabled_modules(self.disabled)
            self.dirty = False
            self._set_message(f"󰄬 Saved → {WAYBAR_CONFIG.name}", C_ENABLED)

        # ── Reload / Restart ──
        elif key == ord('r'):
            subprocess.Popen(['pkill', '-SIGUSR2', 'waybar'],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self._set_message("󰑓 Reloaded waybar", C_HELP)

        elif key == ord('R'):
            subprocess.Popen(['pkill', 'waybar'],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            import time as _t
            _t.sleep(0.3)
            subprocess.Popen(['waybar'],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
            self._set_message("󰑓 Restarted waybar", C_HELP)

        # ── Quit ──
        elif key in (ord('q'), 27):
            if self.dirty:
                self.mode = 'confirm_quit'
            else:
                raise SystemExit(0)

        elif key == ord('Q'):
            raise SystemExit(0)

    def _handle_add(self, key):
        if key in (curses.KEY_UP, ord('k')):
            if self.add_cursor > 0:
                self.add_cursor -= 1
        elif key in (curses.KEY_DOWN, ord('j')):
            if self.add_cursor < len(self.add_filtered) - 1:
                self.add_cursor += 1
        elif key == curses.KEY_HOME:
            self.add_cursor = 0
        elif key == curses.KEY_END:
            self.add_cursor = len(self.add_filtered) - 1
        elif key == curses.KEY_PPAGE:
            self.add_cursor = max(0, self.add_cursor - self._vis_height())
        elif key == curses.KEY_NPAGE:
            self.add_cursor = min(len(self.add_filtered) - 1,
                                  self.add_cursor + self._vis_height())

        elif key in (10, 13, ord(' ')):  # Enter / Space
            if not self.add_filtered:
                return
            mod = self.add_filtered[self.add_cursor]
            section = self.sections[self.add_section_idx]
            existing = {m.name for m in section.modules}
            if mod in existing:
                self._set_message(f"'{mod}' already in {section.display_name}", C_WARNING)
            else:
                section.modules.append(ModuleEntry(mod, True))
                self._apply_section_to_config(self.add_section_idx)
                self._sync_disabled()
                self.dirty = True
                self._set_message(f"󰄬 Added '{mod}' → {section.display_name}", C_ENABLED)
                self._build_items()

        elif key == 27:                  # Escape
            self.mode = 'browse'
            self._build_items()
            self.message = ""

        elif key in (curses.KEY_BACKSPACE, 127, 263):
            if self.add_search:
                self.add_search = self.add_search[:-1]
                self._filter_add_list()

        elif 32 <= key <= 126:           # Printable character → search
            self.add_search += chr(key)
            self._filter_add_list()

    def _handle_confirm_quit(self, key):
        if key == ord('s'):
            self._apply_all_to_config()
            save_config(self.config)
            save_disabled_modules(self.disabled)
            raise SystemExit(0)
        elif key in (ord('q'), ord('Q')):
            raise SystemExit(0)
        elif key == 27:                  # Escape → cancel
            self.mode = 'browse'

    # ── Helpers ────────────────────────────────────────────────────────
    def _filter_add_list(self):
        q = self.add_search.lower()
        if q:
            self.add_filtered = [m for m in self.add_candidates if q in m.lower()]
        else:
            self.add_filtered = self.add_candidates[:]
        self.add_cursor = min(self.add_cursor, max(0, len(self.add_filtered) - 1))
        self.add_scroll = 0

    def _jump_next_section(self):
        for i in range(self.cursor + 1, len(self.items)):
            if self.items[i][0] == 'section':
                self.cursor = i
                return
        # Wrap around
        for i in range(len(self.items)):
            if self.items[i][0] == 'section':
                self.cursor = i
                return

    def _jump_prev_section(self):
        for i in range(self.cursor - 1, -1, -1):
            if self.items[i][0] == 'section':
                self.cursor = i
                return
        # Wrap around
        for i in range(len(self.items) - 1, -1, -1):
            if self.items[i][0] == 'section':
                self.cursor = i
                return

    def _get_current_section_idx(self) -> int:
        if not self.items:
            return -1
        _, si, _ = self.items[self.cursor]
        return si

    def _apply_section_to_config(self, si: int):
        section = self.sections[si]
        key = section.key
        enabled_list = section.enabled_modules
        if key in ('modules-left', 'modules-center', 'modules-right'):
            self.config[key] = enabled_list
        elif key.startswith('group/'):
            if key in self.config and isinstance(self.config[key], dict):
                self.config[key]['modules'] = enabled_list

    def _apply_all_to_config(self):
        for si in range(len(self.sections)):
            self._apply_section_to_config(si)

    def _sync_disabled(self):
        self.disabled = {}
        for section in self.sections:
            disabled_in_section = [m.name for m in section.modules if not m.enabled]
            if disabled_in_section:
                self.disabled[section.key] = disabled_in_section

    # ── Main loop ──────────────────────────────────────────────────────
    def run(self):
        try:
            curses.curs_set(0)
        except curses.error:
            pass
        init_colors()
        self.stdscr.timeout(500)     # Refresh every 500ms for message expiry

        while True:
            self.draw()
            try:
                key = self.stdscr.getch()
                if key == -1:        # Timeout, just redraw
                    continue
                self.handle_input(key)
            except SystemExit:
                break


def main(stdscr):
    if not WAYBAR_CONFIG.exists():
        curses.endwin()
        print(f"Error: Config not found: {WAYBAR_CONFIG}", file=sys.stderr)
        sys.exit(1)
    manager = WaybarManager(stdscr)
    manager.run()


if __name__ == '__main__':
    curses.wrapper(main)
