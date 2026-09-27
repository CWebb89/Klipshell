pragma Singleton
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
// Glyphs sit in the supplementary plane (U+F0000+), which \uXXXX escapes
// cannot express, so they are literal characters; the trailing comment names
// the Nerd Font glyph and its codepoint for auditing.
QtObject {
    // ── navigation ────────────────────────────────────────────────
    readonly property string dashboard: "󰨝"  // md-view_dashboard_outline U+F0A1D
    readonly property string files:     "󰉖"  // md-folder_outline U+F0256
    readonly property string terminal:  "󰞷"  // md-console_line U+F07B7
    readonly property string heightmap: "󰋁"  // md-grid U+F02C1
    readonly property string machine:   "󰐫"  // md-printer_3d U+F042B
    readonly property string history:   "󰋚"  // md-history U+F02DA
    readonly property string viewer:    "󰆧"  // md-cube_outline U+F01A7
    readonly property string layermind: "󰧑"  // md-brain U+F09D1
    readonly property string settings:  "󰢻"  // md-cog_outline U+F08BB
    readonly property string expand:    "󰅀"  // md-chevron_down U+F0140
    readonly property string prev:      "󰅁"  // md-chevron_left U+F0141
    readonly property string next:      "󰅂"  // md-chevron_right U+F0142
    readonly property string up:        "󰅃"  // md-chevron_up U+F0143
    readonly property string down:      "󰅀"  // md-chevron_down U+F0140

    // ── status ────────────────────────────────────────────────────
    readonly property string check:   "󰗡"  // md-check_circle_outline U+F05E1
    readonly property string ok:      "󰄬"  // md-check U+F012C
    readonly property string warning: "󰀪"  // md-alert_outline U+F002A
    readonly property string error:   "󰗖"  // md-alert_circle_outline U+F05D6
    readonly property string info:    "󰋽"  // md-information_outline U+F02FD
    readonly property string offline: "󰖪"  // md-wifi_off U+F05AA
    readonly property string server:  "󰒋"  // md-server U+F048B
    readonly property string chip:    "󰍛"  // md-memory U+F035B
    readonly property string clock:   "󰅐"  // md-clock_outline U+F0150
    readonly property string power:   "󰐥"  // md-power U+F0425
    readonly property string bell:    "󰂜"  // md-bell_outline U+F009C

    // ── actions ───────────────────────────────────────────────────
    readonly property string play:     "󰐊"  // md-play U+F040A
    readonly property string pause:    "󰏤"  // md-pause U+F03E4
    readonly property string stop:     "󰓛"  // md-stop U+F04DB
    readonly property string end:      "󰘁"  // md-page_last U+F0601
    readonly property string refresh:  "󰑐"  // md-refresh U+F0450
    readonly property string restart:  "󰜉"  // md-restart U+F0709
    readonly property string load:     "󰷏"  // md-folder_open_outline U+F0DCF
    readonly property string upload:   "󰸇"  // md-upload_outline U+F0E07
    readonly property string download: "󰮏"  // md-download_outline U+F0B8F
    readonly property string trash:    "󰧧"  // md-delete_outline U+F09E7
    readonly property string save:     "󰠘"  // md-content_save_outline U+F0818
    readonly property string clear:    "󰅚"  // md-close_circle_outline U+F015A
    readonly property string close:    "󰅖"  // md-close U+F0156
    readonly property string plus:     "󰐕"  // md-plus U+F0415
    readonly property string minus:    "󰍴"  // md-minus U+F0374
    readonly property string search:   "󰍉"  // md-magnify U+F0349
    readonly property string copy:     "󰆏"  // md-content_copy U+F018F
    readonly property string tune:     "󰘮"  // md-tune U+F062E
    readonly property string eye:      "󰛐"  // md-eye_outline U+F06D0
    readonly property string camera:   "󰵝"  // md-camera_outline U+F0D5D
    readonly property string swap:     "󰓡"  // md-swap_horizontal U+F04E1
    readonly property string palette:  "󰸌"  // md-palette_outline U+F0E0C
    readonly property string edit:     "󰲶"  // md-pencil_outline U+F0CB6

    // ── printer ───────────────────────────────────────────────────
    readonly property string printer:     "󰐫"  // md-printer_3d U+F042B
    readonly property string nozzle:      "󰹜"  // md-printer_3d_nozzle_outline U+F0E5C
    readonly property string bed:         "󰂙"  // md-bed_outline U+F0099
    readonly property string thermometer: "󰔏"  // md-thermometer U+F050F
    readonly property string spool:       "󱅘"  // md-paper_roll_outline U+F1158
    readonly property string layers:      "󰽙"  // md-layers_triple_outline U+F0F59
    readonly property string target:      "󰆤"  // md-crosshairs_gps U+F01A4
    readonly property string move:        "󰵉"  // md-axis_arrow U+F0D49
    readonly property string home:        "󰚡"  // md-home_outline U+F06A1
    readonly property string gauge:       "󰊚"  // md-gauge U+F029A
    readonly property string chart:       "󰄪"  // md-chart_line U+F012A
    readonly property string grid:        "󰋁"  // md-grid U+F02C1
    readonly property string gcode:       "󱀫"  // md-file_code_outline U+F102B
    readonly property string file:        "󰧮"  // md-file_document_outline U+F09EE
    readonly property string folder:      "󰉖"  // md-folder_outline U+F0256

}
