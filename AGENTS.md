# AGENTS.md — klipshell

Standalone Quickshell app: a Moonraker control surface for Voron printers
— dashboard, GCode console, file list and viewer, history, machine control —
built in the Omarchy/webb-shell design language. Started as the Phase 1 port
of klip-tui; structured to fold into webb-shell as a plugin later.

## Ground truth

- Current code is authoritative. The design brief: Omarchy shell grammar
  (shell/Ui components: PanelSectionHeader, PanelSeparator, PanelSlider,
  Menu selected-row) + matugen Material-You colors via the same 36-key MD3
  contract webb-shell consumes (`assets/matugen/klipshell-colors.json`,
  rendered to `~/.cache/matugen/klipshell-colors.json`, watched by `Colors`).
- klip-tui (Rust TUI) is the feature reference: Moonraker WebSocket JSON-RPC,
  printers, temps, print state, GCode console. The original Phase 1 scope
  (polled HTTP JSON-RPC service + Dashboard + Console) is long since passed.
- Project history — the engineering log 2026-09-20 → 2026-09-23, chronological,
  newest last — is `docs/HISTORY.md`. Grep it; it records what was believed on
  the day. Current truth is the project memory
  (`~/.pi/agent/projects-memory/klipshell/MEMORY.md`), not that log.

## Architecture

- `shell.qml`: `ShellRoot` hosting `MainWindow`. No logic of its own.
- `src/views/MainWindow.qml`: `FloatingWindow` (`Metrics.windowWidth/Height`),
  sidebar view switcher, header chrome, and the single `Keys` owner
  (`Keys.BeforeItem`; Enter switches views, Esc returns to Dashboard).
- `src/views/`: `Dashboard`, `Console`, `GcodeFiles`, `GcodeViewer`,
  `Heightmap`, `History`, `Layermind`, `Machine`, `SettingsPopup`.
- `src/components/`: 17 grammar components (Card, Panel, SectionHeader,
  Separator, Slider, ListRow, Gauge, Ring, Donut, Bars, Chart, TempGraphCard,
  KV, Chip, Button, Hero, ConfirmDialog) + `qmldir`.
- `src/theme/`: `Colors` (matugen MD3 roles, watched file), `Metrics`, `Type`,
  `Icons` singletons. Hardcoded palette hex belongs only in `Colors.qml`.
- `src/moonraker/MoonrakerService.qml`: polled HTTP JSON-RPC client
  (curl Process slot pool on a `Settings.pollMs` timer, Transport-agnostic
  state so a QtWebsockets swap later touches only this file).
- `src/config/`: `Settings.qml` singleton (`settings-logic.js` for the pure
  logic) and `printers.json` (printer names + Moonraker endpoints).
- `src/gcode/GcodeParse.js`: GCode parser, pure JS so `node` can test it.
- Paths: `Quickshell.shellDir` reaches checkout-relative files — today only
  `MoonrakerService`'s `src/config/printers.json`, which the printer editor
  also writes back in place. Everything else persists outside the checkout:
  settings, dashboard layout, presets and viewer state under
  `~/.local/state/klipshell/<store>.json`, Layermind under
  `~/.local/state/layermind/<printer>.json`. Never a fixed checkout path.

## Omarchy grammar (as implemented)

- Cards: solid fill (`Card` defaults to `surfaceContainer`; callers pass
  `surfaceContainerLow`/`Lowest` per context), `outlineVariant` border at
  `Metrics.cardBorderWidth` (2px), radius `Metrics.radiusLarge/Medium/Small`.
- Section headers: bold, `Colors.textTertiary` (surfaceVariantText @ 70%,
  5.6:1 against the 14.3:1 of textPrimary), `Type.sizeCaption` — not accent,
  not ALL-CAPS (PanelSectionHeader).
- Separators: 1px rule, `Colors.separator` = textPrimary @ 12% alpha
  (PanelSeparator).
- Selection: accent text on `Colors.selectedFill` (textPrimary @ 8% fill),
  subtle border — hover 8%, pressed 22% (Menu selected-row / shell.toml
  control tokens).
- Sliders/gauges: track `Metrics.gaugeTrack` (5px) filled with
  `Colors.accent`/textPrimary, knob `Metrics.gaugeKnob` (19px), fill width and
  knob x animated 140ms OutCubic, knob hover scale 110ms (PanelSlider).
- Header = the Omarchy bar idea: solid surface, first-class chrome.

## Verification

```bash
./tools/verify.sh
```

`tools/verify.sh` is the whole gate in one command: it runs every check below,
reports PASS / FAIL / SKIP per step, exits 1 on any blocking failure, and ends
with the qmllint warnings that `--silent` hides (advisory — they do not fail the
gate). Individual steps, when you need just one:

```bash
bash -O globstar -c 'qmllint --silent shell.qml src/**/*.qml'
bash -n install.sh
bash -n launch.sh
node src/gcode/test-parse.js
node src/config/test-settings.js
python3 tools/check-icons.py
python3 tools/test-transport.py
```

`--silent` plus the repo's `.qmllint.ini` (which disables the `UncreatableType`
and `MissingProperty` warnings) means the qmllint gate reports errors only — a
clean run says nothing about warnings. `tools/verify.sh` therefore always runs a
second, non-silent pass and prints it.

`tools/check-icons.py` validates the `Icons` singleton's glyphs.
`src/config/test-settings.js` covers the settings store's pure logic in
`settings-logic.js`.

`tools/test-transport.py` boots the app against a stub Moonraker on a loopback
port and asserts the JSON-RPC result envelope handling (POST replies are wrapped
in `{"result": …}`), path/quote escaping, and the signals the views listen to.
It needs a Hyprland seat; without one it exits 2 and skips.

`quickshell -p .` is a nonterminating visual run on a Hyprland seat — not a
pass/fail check; runtime validation needs a live session.

## Rollback

There is no version control here (by user choice), and `/tmp` backups do not
survive. `tools/snapshot.sh` writes a timestamped tar of the whole checkout to
`~/.local/state/klipshell/snapshots/` (newest 20 kept) and prints its sha256 —
run it before any risky multi-file pass.

```bash
./tools/snapshot.sh pre-refactor
```

## Instance discipline

Never more than one klipshell instance at a time. Every launch is preceded by
an instance check, and a second instance is a defect — not a convenience.

```fish
quickshell list -p /home/cwebb/dev/klipshell
quickshell kill -p /home/cwebb/dev/klipshell
quickshell -n -p /home/cwebb/dev/klipshell
```

- Always pass the absolute repo path to `list`/`kill`/`-p`. A relative `-p .`
  is only valid when cwd is the repo root, and instance lookup is by resolved
  config path — a check with the wrong path reports nothing and lets a second
  instance through.
- `-n` is a backstop, not a licence to skip the check. Run `list` first, every
  time, including for `shot app` one-shot captures.
- Never `pkill quickshell`: webb-shell runs under the same binary. Scope kills
  with `-p <dir>` so only the klipshell config dies.

## API sources

Installed `.qmltypes` first (`/usr/lib/qt6/qml/Quickshell`), webb-shell repo
patterns, quickshell.org docs matching version 0.3.1, doc.qt.io/qt-6.