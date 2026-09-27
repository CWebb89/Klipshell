# klipshell

**A Moonraker control surface for Klipper printers — a native Quickshell desktop
shell, not a browser tab.**

klipshell talks straight to [Moonraker](https://moonraker.readthedocs.io/)'s HTTP
JSON-RPC API and renders eight keyboard-driven views over it: a live dashboard,
a GCode console, print-file management, history, bed-mesh visualisation, a GCode
viewer, machine health, and diagnostics. One process, one window, no web server,
no Python service, no account.

It's the graphical descendant of `klip-tui`, a Rust terminal UI for the same
printers, and it deliberately follows **Mainsail's feature model** —
most views are parity ports of a specific Mainsail tab (`Heightmap.vue`,
`Viewer.vue`, the machine and history tabs), rebuilt natively rather than
embedded.

<p>
  <img alt="license" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <img alt="Quickshell" src="https://img.shields.io/badge/Quickshell-0.3.1-6c9cd6.svg">
  <img alt="Qt" src="https://img.shields.io/badge/Qt-6-41cd52.svg">
  <img alt="QML" src="https://img.shields.io/badge/QML-13.5k%20lines-41cd52.svg">
</p>

---

## Why build this

Mainsail and Fluidd are excellent, and they're already on every Klipper host.
klipshell exists for the case where you want the printer in your desktop's own
vocabulary:

- **Native, not embedded.** No WebKit, no tab to hunt for, no page reload. The
  whole UI is QML in one process, with no browser engine to spin up.
- **Zero new services.** The only runtime dependencies are `quickshell` and
  `curl`. Nothing to install on the printer — Moonraker is already there.
- **Keyboard-first.** Eight views on `1`–`8`, `H/J/K/L` and the arrows to walk
  the sidebar, `Enter` to refresh, `Esc` back to the dashboard. Pause/resume,
  cancel and **E-STOP** sit in the header band, always one click away.
- **It wears your wallpaper.** Colours come from
  [matugen](https://github.com/InioX/matugen)'s Material You palette through the
  same 36-key contract as the author's main shell, so the printer UI is *the
  same colour as everything else* on the desktop.
- **Honest about state.** Live data, an offline/demo mode that says it's in demo
  mode, and confirmations in front of the three irreversible actions.

## Views

| # | View | Source | What it is |
|---|------|--------|------------|
| 1 | **Dashboard** | — | Eight live cards: print status, temperatures, toolhead jog, fans/limits, extruder, macros, host health, console |
| 2 | **Console** | `/server/gcode_store` | Scrolled GCode transcript with a keyboard-driven input row |
| 3 | **G-CODE FILES** | `/server/files/directory` | Browse `gcodes` and inspect a print's full metadata — slicer, estimated time, filament, layer height, temps — in a sideways-scrolling sortable table |
| 4 | **History** | `/server/history/list` | Session statistics, a job-status donut and filament/print-time bars over a searchable, sortable job table |
| 5 | **Heightmap** | `/printer/objects/query?bed_mesh` | Mainsail's bed-mesh tab: three stacked surfaces, Z-colour ramp, orbitable camera |
| 6 | **GCODE VIEWER** | local or server `.gcode` | Mainsail's Viewer: scrubber, layer navigation, toolhead/travel/feature colouring, five render qualities |
| 7 | **MACHINE** | `/machine/*`, `/server/files/*` | Host load rings, network, endstops, update manager, and the `config`/`gcodes`/`docs` file browsers |
| 8 | **LAYERMIND** | local JSON | The [LayerMind](#related-projects) daemon's per-printer diagnostic snapshot |

### Dashboard

Eight cards, each with its own live data, laid out in two independent columns:

`STATUS` (pinned) · `TEMPERATURE` · `TOOLHEAD` · `MISC` · `EXTRUDER` ·
`MACROS` · `MACHINE` · `CONSOLE`

- **Status** — the printer's name behind a live indicator (plus a `DEMO` chip
  when the host is unreachable), `STATE` / `PROGRESS` / `ELAPSED` / `LEFT`
  readouts over a progress wash rising up the card, then the five most recent
  GCode files with thumbnails and per-file state. Clicking one asks for
  confirmation and starts the print.
- **Temperature** — nozzle and bed gauges, direct target entry, and swappable
  material presets (PLA/PETG/ABS/TPU/ASA by default, editable).
- **Toolhead** — six jog chips, a Z-offset dial with a large readout, endstop
  and probe save buttons, speed factor, home/motors-off/`QUAD_GANTRY_LEVEL`
  actions.
- **Extruder** — extrude and retract at a per-printer step, pressure advance,
  smooth time, filament used.
- **MISC** — a slider per fan object the printer exposes, plus flow.
- **MACROS** — every `gcode_macro` the printer exposes, ordered and hidden from
  the settings popup.
- **Machine** — host CPU/MCU/memory and `endstops`.
- **Console** — the last *N* GCode lines plus a send row, so the console is on
  the dashboard too.

Cards reorder, hide and collapse through the dashboard layout dialog
(*Settings → INTERFACE → LAYOUT*), and that state persists.

The window header carries the printer switcher, the view strip, the
PAUSE/RESUME · CANCEL · E-STOP transport, and a notification bell whose panel
is modal over the dashboard — so `Esc` dismisses it rather than switching views.

### Console, files, history, machine

- **Console** reads `/server/gcode_store` and sends via
  `POST /printer/gcode/script`. Prompt glyph per command, dimmed output, blinking
  block cursor, `Esc` clears the pending buffer without leaving the view.
- **G-CODE FILES** is one request per view:
  `/server/files/directory?extended=true` returns slicer metadata inline, and
  print/total durations are joined from the history bucket already being polled —
  so there's no per-row fetch behind the table. Every column is sortable, the
  table scrolls sideways, and directory navigation moves between `gcodes`
  subdirectories. It's a reader: the mutating operations live in MACHINE.
- **History** pairs a statistics card with the job table; every row carries its
  full metadata snapshot, so thumbnails and estimates come free.
- **MACHINE** is Mainsail's machine tab: load rings reading inside, label under
  the ring, update manager with per-component dirty/behind detection, and file
  browsers scoped to Moonraker's `config`, `gcodes` and `docs` roots — the one
  place upload, download, rename, copy, new folder and delete live. Editing a
  remote file downloads it and hands it to `$EDITOR`.

### Heightmap and GCODE VIEWER

Both are Canvas 2D renderers written from scratch — no echarts, no
`@sindarius/gcodeviewer`:

- **Heightmap** projects each mesh cell the way Mainsail's echarts-gl surface
  series does: probed / computed mesh / flat plane stacked, colour keyed on Z
  through a visual ramp, framed inside the motion envelope, with an orbitable
  camera and a vertical colour legend.
- **GCODE VIEWER** parses the file with `src/gcode/GcodeParse.js` (pure JS, so
  `node` tests it independently) and draws the toolpath on a Canvas: a
  byte-position scrubber, play/fast-forward at 1/2/5/10/20×, layer navigation,
  colouring by extruder / feed rate / feature, five render qualities, and the
  usual option set (toolhead, travels, code stream, object selection). It can
  open the file the printer is printing, a local file, or any GCode on the
  server.

## Screenshots

<!-- Screenshot grid — uncomment once the images are in docs/screenshots/.
     The filenames this README expects are listed in docs/screenshots/README.md.

<p align="center">
  <img src="docs/screenshots/dashboard.png" width="49%" alt="Dashboard">
  <img src="docs/screenshots/console.png" width="49%" alt="Console">
</p>
<p align="center">
  <img src="docs/screenshots/gcode-viewer.png" width="49%" alt="GCode viewer">
  <img src="docs/screenshots/heightmap.png" width="49%" alt="Bed mesh">
</p>
<p align="center">
  <img src="docs/screenshots/history.png" width="49%" alt="History">
  <img src="docs/screenshots/machine.png" width="49%" alt="Machine">
</p>
-->

Captures and a short demo video are being added. Drop files named as listed in
[`docs/screenshots/README.md`](docs/screenshots/README.md) and the section above
picks them up.

## Architecture

```
shell.qml                  ShellRoot hosting MainWindow — no logic of its own
src/views/                 MainWindow (chrome, sidebar, the one Keys owner),
                           Dashboard, Console, GcodeFiles, GcodeViewer, Heightmap,
                           History, Layermind, Machine, SettingsPopup
src/components/            17 grammar components + qmldir — Card, Panel,
                           SectionHeader, Separator, Slider, ListRow, Gauge,
                           Ring, Donut, Bars, Chart, TempGraphCard, KV, Chip,
                           Button, Hero, ConfirmDialog
src/theme/                 Colors (matugen MD3 roles, watched file), Metrics,
                           Type, Icons — singletons
src/moonraker/             MoonrakerService — the only networking in the project
src/config/                Settings singleton, pure settings logic, printers
src/gcode/                 GcodeParse.js — pure parser, node-tested
assets/matugen/            the 36-key MD3 colour template
tools/                     verify.sh, snapshot.sh, check-icons.py, test-transport.py
docs/HISTORY.md            dated engineering log, 2026-09-20 onward
```

**Data flow.** `MoonrakerService` is a singleton that polls a fixed set of
Moonraker endpoints on a timer (default 1 s, tunable 250 ms – 10 s) using a pool
of `curl` processes, and normalises the replies into buckets — `active` for the
core printer state, plus `files`, `history`, `machine`, `dir` and `roots`, each
announced by its own `bucketChanged` signal. Views never touch the network; they
bind to the buckets and call methods like `pause()`, `sendGcode()` or
`setTemp()`. The transport is deliberately confined to that one file: swapping
the poll for a WebSocket (Quickshell 0.3.1 has no QML WebSocket type) means
rewriting its fetch internals and nothing else.

**No hardcoded palette outside the theme.** `Colors.qml` is the only file allowed
to contain a colour literal; everything else reads role names. Geometry is
tokenised in `Metrics.qml` and the type scale in `Type.qml`.

## Requirements

| | |
|---|---|
| **Quickshell** | 0.3.1 or newer (built against 0.3.1), Qt 6 — `quickshell` in the Arch repos |
| **curl** | the transport |
| **JetBrainsMono Nerd Font Mono** | required — every icon is a Nerd Font glyph |
| **matugen** | optional; generates the palette from your wallpaper. Without it klipshell renders a baked-in warm scheme |
| **python3** + fonttools, **node** | optional, for the dev tooling and test suites |
| **A compositor** | developed on Hyprland (Wayland). Quickshell handles the rest |

## Install

```fish
git clone git@github.com:CWebb89/Klipshell.git
cd Klipshell
./install.sh
```

`install.sh` is idempotent, needs no root and installs no packages. It does two
things:

1. Registers klipshell's template with matugen so the palette lands in
   `~/.cache/matugen/klipshell-colors.json` (which `Colors.qml` watches). Your
   `matugen/config.toml` is backed up first and only appended to.
2. Seeds `src/config/printers.json` from `printers.example.json` if it doesn't
   exist yet.

Then **edit `src/config/printers.json`** and give it your own Moonraker hosts:

```json
{
  "printers": [
    { "name": "Voron V2.4", "host": "192.168.1.50", "port": 7125 }
  ]
}
```

That file is gitignored on purpose — it's machine-local, the printer editor
writes it back in place, and real addresses never belong in a public repo.
You can also add and edit printers at runtime from *Settings → PRINTERS*, which
includes a **TEST** button that reports the HTTP status of a candidate host.

## Run

```fish
./launch.sh
```

`launch.sh` is `quickshell -n -p "$(dirname $0)"` — the `-n` makes a second
launch a no-op instead of a second window. To bind it to a Hyprland key (the Lua
config form — `exec_cmd` needs an absolute path, there's no inherited `PATH`):

```lua
-- ~/.config/hypr/binds.lua
hl.bind("SUPER + P", hl.dsp.exec_cmd(os.getenv("HOME") .. "/dev/Klipshell/launch.sh"))
```

## Keybindings

The window has exactly one key handler (`MainWindow`'s `Keys` owner), so these
work from anywhere unless a modal or a text field has focus.

| Key | Action |
|---|---|
| `1` – `8` | Jump to a view |
| `↑` `↓` / `H` `J` | Previous / next view |
| `←` `→` / `K` `L` | Previous / next view |
| `Enter` | Refresh the active view |
| `Esc` | Dismiss the confirm dialog → else close settings → else leave the dashboard console input → else dismiss notifications → else leave layout mode → else clear the console command → else back to Dashboard |

Inside the **Console** view, printable characters accumulate into the input
buffer, `Backspace` edits it, and `Enter` sends the command.

## Configuration

Every store is a plain JSON file that a human can read and hand-edit. Nothing is
written to a checkout path except the printer list.

| File | Contents |
|---|---|
| `src/config/printers.json` | printer names, Moonraker hosts and ports — **gitignored** |
| `~/.local/state/klipshell/settings.json` | jog steps, bed feedrates, macro order/visibility, per-printer API keys, default printer, poll cadence, console scrollback, notification cap, display units, confirmation flags |
| `~/.local/state/klipshell/dashboard.json` | card order, visibility and collapse state |
| `~/.local/state/klipshell/presets.json` | material temperature presets |
| `~/.local/state/klipshell/viewer.json` | GCode viewer toggles |
| `~/.local/state/layermind/<printer>.json` | LayerMind's snapshot, read-only, written by its daemon |

Two notes worth knowing:

- **Display units convert presentation, never commands.** Switching to °F or
  inches converts readouts (axis positions, Z-offset, mesh Z, layer heights) and
  converts typed input back to Celsius, but G-code values — jog steps, extrude
  amounts, feedrates, Z-offset buttons — stay in the printer's own units.
- **API keys are stored per printer and sent as `X-Api-Key`** only when one is
  set, and are written by passing the payload through the process environment
  rather than a command line.

## Design language

klipshell follows the **Omarchy** shell grammar so it sits next to the rest of a
Hyprland desktop without looking grafted on:

- Solid-fill cards on a dim background, `outlineVariant` borders at 2px, three
  radii. Header bar is first-class chrome: solid surface plus a hairline.
- Section headers are dim bold captions, not accent and not ALL-CAPS.
- Separators are 1px rules at 12% alpha.
- Selection is accent text on an 8% foreground fill (hover 8%, pressed 22%).
- Sliders and gauges use PanelSlider proportions — track 5px, knob 19px, fill and
  knob animated 140 ms `OutCubic`.

Colour comes from **matugen's Material You roles** through a 36-key contract
(`assets/matugen/klipshell-colors.json`) identical in shape to the author's main
shell, so a wallpaper change re-themes this app too, with no palette of its own.

`tools/check-icons.py` verifies every icon glyph against the *installed* Nerd
Font rather than trusting the codepoint — a glyph the font lacks renders as a
tofu box, so `Icons.qml` is generated, not hand-written.

## Development

```fish
./tools/verify.sh
```

The whole gate in one command. It runs each check, prints PASS / FAIL / SKIP per
step, exits 1 on any blocking failure, and finishes with the qmllint **warnings**
that `--silent` hides (advisory, they don't fail the gate):

| Step | Command |
|---|---|
| QML errors (blocking) | `qmllint --silent shell.qml src/**/*.qml` |
| Shell syntax | `bash -n install.sh launch.sh` |
| GCode parser | `node src/gcode/test-parse.js` |
| Settings logic | `node src/config/test-settings.js` |
| Icon glyphs | `python3 tools/check-icons.py` |
| Transport | `python3 tools/test-transport.py` |

The transport suite is worth knowing about: it boots the **real** `MoonrakerService`
against a stub Moonraker on a loopback port and asserts the JSON-RPC envelope
handling and the signals the views listen to. It needs a Hyprland seat and skips
(exit 2) without one.

A clean `qmllint --silent` says nothing about warnings, so the gate always runs a
second, visible pass. Note also that **`qmllint` is not the finish line for UI
work** — it checks syntax and type resolution, not whether the row you built fits
its card. `docs/HISTORY.md` records the arithmetic for that.

`./tools/snapshot.sh [label]` writes a timestamped tar of the whole checkout to
`~/.local/state/klipshell/snapshots/` (newest 20 kept) and prints its sha256 —
useful before a risky multi-file pass.

`docs/HISTORY.md` is the dated engineering log: what was believed, what was
measured, what turned out to be wrong, and the numbers that settled it. It's the
most useful file here when a layout or an endpoint misbehaves.

## Status

Feature-complete against its own scope and in daily use against Voron V2.4 /
V1.8 / V0.2 printers. Known issues, stated plainly:

- **Dashboard drag-to-reorder doesn't work.** `_gridRects()` reads
  `globalPosition` off a `Column`, where it doesn't exist, so the gesture throws
  and no drag starts. The layout dialog is the working reorder path.
- **The GCode viewer is slow to load and its progress readout sticks at 0%** for
  the whole load. Reported, not yet reproduced.
- **A wrong API key degrades to demo mode silently** — two 401s in a row are
  treated as an unreachable printer. Use *Settings → PRINTERS → TEST* to check a
  key.
- **Transport is polled HTTP, not a WebSocket.** Quickshell 0.3.1 has no QML
  WebSocket type; this is a ~1 s data latency, not a correctness problem.

Planned: folding klipshell into the author's main shell as a plugin, so the
printer UI can be summoned as a panel rather than living in its own window. That
work is deferred until the polish items above are closed.

## Related projects

- [**LayerMind**](https://github.com/webbwerkx/LayerMind) — the print diagnostics
  daemon whose per-printer snapshots the LAYERMIND view renders.
- [`klip-tui`](#lineage) — the Rust terminal UI this is a graphical descendant of.
  Same Moonraker API, same printers, no window.

### Lineage

klipshell began as **Phase 1 of a `klip-tui` port** — polled Moonraker HTTP
JSON-RPC, a dashboard, a console — and grew past it into a full control surface
with bed-mesh and GCode visualisation. It was called `klip-shell` and then
`QuickKlipshell` before settling on `klipshell`; `QuickKlipshell` survives in
older commit messages and screenshots.

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 webbwerkx.
