#!/usr/bin/env python3
"""Regenerate src/theme/Icons.qml from the installed Nerd Font.

Reads JetBrainsMonoNerdFont-Regular.ttf, resolves each semantic name to a real
glyph (never a guess), and writes the singleton with literal characters plus a
`// <glyph-name> U+XXXX` trail so a human can audit the mapping.

    python3 tools/check-icons.py --write     regenerate Icons.qml
    python3 tools/check-icons.py             verify only (used by tests/CI)
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ICONS_QML = ROOT / "src/theme/Icons.qml"
FONT = Path.home() / ".local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf"

# ── Name → candidate Nerd Font glyph names, in preference order ────────────
# Grouped the way the views use them. Add entries here, then --write.
GROUPS = [
    ("navigation", [
        ("dashboard", ["md-view_dashboard_outline", "md-view_dashboard"]),
        ("files", ["md-folder_outline", "md-folder"]),
        ("terminal", ["md-console_line", "md-console"]),
        ("heightmap", ["md-grid", "md-view_grid_outline"]),
        ("machine", ["md-printer_3d", "fa-print"]),
        ("history", ["md-history", "md-calendar_clock_outline"]),
        ("viewer", ["md-cube_outline", "md-cube_scan"]),
        ("layermind", ["md-brain", "md-head_cog_outline"]),
        ("settings", ["md-cog_outline", "md-cog"]),
        ("expand", ["md-chevron_down"]),
        ("prev", ["md-chevron_left"]),
        ("next", ["md-chevron_right"]),
        ("up", ["md-chevron_up", "md-arrow_up"]),
        ("down", ["md-chevron_down", "md-arrow_down"]),
    ]),
    ("status", [
        ("check", ["md-check_circle_outline", "md-check_circle"]),
        ("ok", ["md-check", "md-check_bold"]),
        ("warning", ["md-alert_outline", "md-warning_outline"]),
        ("error", ["md-alert_circle_outline", "md-close_circle_outline"]),
        ("info", ["md-information_outline", "md-information"]),
        ("offline", ["md-wifi_off", "md-lan_disconnect"]),
        ("server", ["md-server_outline", "md-server"]),
        ("chip", ["md-memory", "md-cpu_64_bit"]),
        ("clock", ["md-clock_outline", "md-clock"]),
        ("power", ["md-power"]),
        ("bell", ["md-bell_outline", "md-bell"]),
    ]),
    ("actions", [
        ("play", ["md-play"]),
        ("pause", ["md-pause"]),
        ("stop", ["md-stop"]),
        ("end", ["md-page_last"]),
        ("refresh", ["md-refresh"]),
        ("restart", ["md-restart", "md-reload"]),
        ("load", ["md-folder_open_outline", "md-folder_open"]),
        ("upload", ["md-upload_outline", "md-upload"]),
        ("download", ["md-download_outline", "md-download"]),
        ("trash", ["md-delete_outline", "md-delete"]),
        ("save", ["md-content_save_outline", "md-content_save"]),
        ("clear", ["md-close_circle_outline", "md-broom"]),
        ("close", ["md-close"]),
        ("plus", ["md-plus"]),
        ("minus", ["md-minus"]),
        ("search", ["md-magnify"]),
        ("copy", ["md-content_copy"]),
        ("tune", ["md-tune", "md-tune_variant"]),
        ("eye", ["md-eye_outline", "md-eye"]),
        ("camera", ["md-camera_outline", "md-camera"]),
        ("swap", ["md-swap_horizontal"]),
        ("palette", ["md-palette_outline", "md-palette"]),
        ("edit", ["md-pencil_outline", "md-pencil"]),
    ]),
    ("printer", [
        ("printer", ["md-printer_3d"]),
        ("nozzle", ["md-printer_3d_nozzle_outline", "md-printer_3d_nozzle"]),
        ("bed", ["md-bed_outline", "md-bed"]),
        ("thermometer", ["md-thermometer", "md-thermometer_high"]),
        ("spool", ["md-paper_roll_outline", "md-disc"]),
        ("layers", ["md-layers_triple_outline", "md-layers_triple"]),
        ("target", ["md-crosshairs_gps", "md-target"]),
        ("move", ["md-axis_arrow", "md-cursor_move"]),
        ("home", ["md-home_outline", "md-home"]),
        ("gauge", ["md-gauge", "md-speedometer"]),
        ("chart", ["md-chart_line", "md-chart_line_variant"]),
        ("grid", ["md-grid", "md-view_grid_outline"]),
        ("gcode", ["md-file_code_outline", "md-code_braces"]),
        ("file", ["md-file_document_outline", "md-file_outline"]),
        ("folder", ["md-folder_outline"]),
    ]),
]

HEADER = '''pragma Singleton
import QtQuick

// Nerd Font glyph set for klipshell.
//
// Every codepoint here is verified against the *installed* font by
// tools/check-icons.py — a glyph the font lacks renders as a tofu box, so do
// not hand-add an icon without re-running:
//
//     python3 tools/check-icons.py          # verify
//     python3 tools/check-icons.py --write  # regenerate after editing GROUPS
//
// Glyphs sit in the supplementary plane (U+F0000+), which \\uXXXX escapes
// cannot express, so they are literal characters; the trailing comment names
// the Nerd Font glyph and its codepoint for auditing.
QtObject {
'''


def build(font_path: Path):
    from fontTools.ttLib import TTFont

    font = TTFont(str(font_path))
    cmap = font.getBestCmap()
    by_name = {}
    for cp, name in cmap.items():
        by_name.setdefault(name, cp)

    resolved, missing = [], []
    for group, entries in GROUPS:
        rows = []
        for semantic, candidates in entries:
            if semantic in RESERVED:
                missing.append("%s (reserved word in QML)" % semantic)
                continue
            for cand in candidates:
                if cand in by_name:
                    rows.append((semantic, cand, by_name[cand]))
                    break
            else:
                missing.append("%s (%s)" % (semantic, candidates[0]))
        resolved.append((group, rows))
    return resolved, missing


def render(resolved) -> str:
    out = [HEADER]
    for group, rows in resolved:
        out.append("    // ── %s %s\n" % (group, "─" * max(0, 58 - len(group))))
        width = max(len(r[0]) for r in rows)
        for semantic, glyph, cp in rows:
            pad = " " * (width - len(semantic))
            out.append('    readonly property string %s:%s "%s"  // %s U+%04X\n'
                       % (semantic, pad, chr(cp), glyph, cp))
        out.append("\n")
    out.append("}\n")
    return "".join(out)


# Names QML already binds in the global object or treats as reserved: a
# property with one of these names parses but the shell fails to load the
# type at runtime ("Illegal property name"), which qmllint does not catch.
RESERVED = {"console", "eval", "window", "document", "top", "self", "parent",
            "delete", "in", "new", "default", "this", "super", "class", "null",
            "true", "false", "void", "typeof", "instanceof", "with", "do", "if",
            "for", "while", "return", "var", "let", "const", "function", "break",
            "continue", "switch", "case", "catch", "finally", "throw", "try",
            "import", "export", "extends", "yield", "await", "enum", "static"}


# ── verification ──────────────────────────────────────────────────────────
LINE = re.compile(r'readonly property string (\w+):\s*"([^"]+)"\s*//\s*(\S+)\s+U\+([0-9A-Fa-f]{4,6})')


def verify(font_path: Path) -> int:
    if not ICONS_QML.exists():
        print("missing %s" % ICONS_QML, file=sys.stderr)
        return 1
    from fontTools.ttLib import TTFont

    font = TTFont(str(font_path))
    cmap = font.getBestCmap()
    names = {}
    for cp, name in cmap.items():
        names.setdefault(name, cp)
    glyf = font.get("glyf")
    hmtx = font.get("hmtx")

    problems, count = [], 0
    seen = {}
    for i, line in enumerate(ICONS_QML.read_text().splitlines(), 1):
        m = LINE.search(line)
        if not m:
            continue
        semantic, glyph, glyph_name, hexcp = m.groups()
        cp = int(hexcp, 16)
        count += 1
        if semantic in RESERVED:
            problems.append("Icons.qml:%d %s is a QML reserved name" % (i, semantic))
        if len(glyph) != 1 or ord(glyph) != cp:
            problems.append("Icons.qml:%d %s literal does not match U+%04X" % (i, semantic, cp))
        if cp not in cmap:
            problems.append("Icons.qml:%d %s U+%04X missing from %s" % (i, semantic, cp, font_path.name))
            continue
        if cmap[cp] != glyph_name:
            problems.append("Icons.qml:%d %s comment says %s but font glyph is %s"
                            % (i, semantic, glyph_name, cmap[cp]))
        if names.get(glyph_name, cp) != cp:
            problems.append("Icons.qml:%d %s glyph %s also maps to U+%04X" % (i, semantic, glyph_name, names[glyph_name]))
        # A codepoint can exist and still draw nothing: assert the glyph has
        # contours and a real advance, which is what makes it visible ink.
        if glyf is not None and glyph_name in glyf:
            if glyf[glyph_name].numberOfContours == 0 and not glyf[glyph_name].isComposite():
                problems.append("Icons.qml:%d %s %s draws no contours" % (i, semantic, glyph_name))
        if hmtx is not None:
            adv = hmtx[glyph_name][0] if glyph_name in hmtx.metrics else 0
            if adv <= 0:
                problems.append("Icons.qml:%d %s %s has zero advance" % (i, semantic, glyph_name))
        seen.setdefault(semantic, i)

    for p in problems:
        print(p, file=sys.stderr)
    print("checked %d icons, %d problem(s)" % (count, len(problems)))
    return 1 if problems else 0


def main() -> int:
    if not FONT.exists():
        print("font not found: %s" % FONT, file=sys.stderr)
        return 1
    if "--write" in sys.argv:
        resolved, missing = build(FONT)
        if missing:
            print("unresolved icons: %s" % ", ".join(missing), file=sys.stderr)
            return 1
        ICONS_QML.write_text(render(resolved))
        total = sum(len(r) for _, r in resolved)
        print("wrote %s (%d icons, %d groups)" % (ICONS_QML.relative_to(ROOT), total, len(resolved)))
    return verify(FONT)


if __name__ == "__main__":
    raise SystemExit(main())
