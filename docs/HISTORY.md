# HISTORY.md — klipshell engineering log (archive)

Chronological log, 2026-09-20 → 2026-09-23, newest at the END of the file.
Superseded by definition: each entry is what was believed that day, and later
entries correct earlier ones. Nothing here was edited when it was split out of
the memory file on 2026-09-24.

Current truth is the project memory, `~/.pi/agent/projects-memory/klipshell/MEMORY.md`.
The 2026-09-24 entries live there too (under `CURRENT FACTS 2026-09-24`), not here.

Search it, do not read it: `grep -n 'keyword' docs/HISTORY.md`

Chronological engineering log, 2026-09-20 → 2026-09-23, newest at the END of the
file. Superseded by definition: each entry is what was believed that day, and
later entries correct earlier ones. Nothing here was edited during the split.

Current truth lives in `MEMORY.md`. The 2026-09-24 entries live there too (under
`CURRENT FACTS 2026-09-24`), not here.

Search it, do not read it: `grep -n 'keyword' docs/HISTORY.md`

## RENAMED 2026-09-23 (late) — QuickKlipshell → klipshell

Full rename, checkout dir included. `klipshell` (no hyphen, lowercase) is the
name, title, prose, AND every path/filename/TOML key/temp prefix — the old
two-form convention (capitalised name vs lowercase path) is gone.
- Repo dir: `~/dev/QuickKlipshell` → `~/dev/klipshell`. The running
  `quickshell -p .` instance EXITED when the dir moved (its watcher path
  vanished) — relaunch from the new path. Tooling cwd goes stale too: pass an
  explicit cwd, start new sessions in `~/dev/klipshell`.
- `~/.local/state/quickklipshell` → `~/.local/state/klipshell` (dashboard,
  presets, viewer — contents preserved, same files) and
  `~/.cache/quickklipshell` → `~/.cache/klipshell`.
- matugen: template + cache → `klipshell-colors.json`; the
  `[templates.quickklipshell]` block in `~/.config/matugen/config.toml` was
  REWRITTEN in place (section name + input/output paths), and the rendered
  palette was copied to the new cache name so colors survive until the next
  wallpaper change.
- Memory dir `~/.pi/agent/projects-memory/QuickKlipshell` → `.../klipshell`;
  brain `~/.pi/agent/brain/moonraker/mainsail-store-map.md` re-sed'd.
- **No pre-rename backup was taken** this time (unlike 17:31 — see below).
  Verified by the project suite and reversible by sed, but there is no tarball
  undo.
- This file was blanket re-sed'd FIRST, which also rewrote the 17:31 history
  into the current name; the sections below were then repaired by hand (both
tautological convention lines restored, rollback file names restored from disk
as `/tmp/QuickKlipshell-prename-backup-20260923-1731.tar.gz` and
`/tmp/QuickKlipshell-prename-matugen-config.toml.bak`).
- Still legitimately old-named — do NOT "fix": `quickklipshell-tweaks/` in the
  repo (historical patch bundle; its contents carry no old-name strings),
  `/tmp/QuickKlipshell-prename-*`, the stale
  `~/.cache/matugen/quickklipshell-colors.json` (superseded by the klipshell
  copy, left in place), the two `.pi/plans/*.md` archives, and pi's session dir
  `~/.pi/agent/sessions/--home-cwebb-dev-QuickKlipshell--` (left alone — it held
  the live session at rename time; rename it between sessions if wanted).
- The trap that still applies: `klippy` / `Klipper` / `Klippain` are
  Klipper-ecosystem names, NOT the project.

## RENAMED 2026-09-23 17:31 — klip-shell → QuickKlipshell (previous session)

Superseded the same evening by QuickKlipshell → klipshell (section above); the
names in this section are as they stood after the 17:31 rename.

Every old-name reference in this file was rewritten. Surviving `klip-shell`
strings name things that STILL carry the old name on disk — do not "fix" them:
`~/dev/templates/klip-shell` (pristine pre-SESSION-2.x revert snapshot, never
modify), `/tmp/klip-shell-audit-*.md`, `/tmp/klip-shell-shot/`,
`/tmp/klip-shell-pr2-backup/`, `~/.config/matugen/config.toml.klip-shell.bak`,
and the contents of `quickklipshell-tweaks/` (historical patch bundle).

Convention (the same shape both times): capitalised `QuickKlipshell` = name,
window title, prose; lowercase `quickklipshell` = paths, filenames, TOML keys,
temp prefixes. Migrated: repo dir → `~/dev/QuickKlipshell`;
`~/.local/state/quickklipshell` (dashboard, presets, viewer — contents
preserved); `~/.cache/quickklipshell`;
`~/.cache/matugen/quickklipshell-colors.json`; the matugen template file and its
`[templates.quickklipshell]` entry in `~/.config/matugen/config.toml`.

API/notification reference (distilled from Mainsail stores, for the WS swap
and later phases): `~/.pi/agent/brain/moonraker/mainsail-store-map.md`
(poll-equivalent for every WS notify + init sequence + console semantics).

## REVIEW PASS + RENAME 2026-09-23d — 2 regressions of my OWN fix pass found & fixed; project renamed

### The rename (done; the convention is load-bearing)
`QuickKlipshell` = name/title/prose/repo dir/memory dir. `quickklipshell` = paths, filenames,
TOML keys, temp prefixes. 30 replacements in 16 files + 6 in-repo renames; every replacement
asserted an exact occurrence count BEFORE writing, then the tree was diffed against a pre-rename
tarball (changed-lines diff == exactly the intended edits).
- Repo dir `~/dev/QuickKlipshell`; memory dir `~/.pi/agent/projects-memory/QuickKlipshell`.
- `~/.local/state/quickklipshell/{dashboard,presets,viewer}.json` and `~/.cache/quickklipshell/`
  MIGRATED, contents preserved (verified: presets loaded from the migrated file = 3 user presets,
  not the 5 defaults).
- matugen `quickklipshell-colors.json` (template + cache) and the `[templates.quickklipshell]`
  block in `~/.config/matugen/config.toml` — old block REPLACED, not duplicated.
- **ROLLBACK:** `/tmp/QuickKlipshell-prename-backup-20260923-1731.tar.gz` (whole pre-rename tree,
  incl. .pi) + `/tmp/QuickKlipshell-prename-matugen-config.toml.bak`. /tmp is ephemeral and there
  is STILL no git — after a reboot there is no undo for the rename.
- **The trap:** `klippy` / `Klipper` / `Klippain` / `Klippy` are Klipper-ecosystem names, NOT the
  project. A naive rename breaks the app. Confirmed absent from the whole changed-lines diff.
- `klip-tui` untouched (separate project: own repo, matugen template, memory dir).
- Still legitimately `klip-shell` — pointers stay valid, do NOT "fix" them:
  `~/dev/templates/klip-shell` (pristine pre-SESSION-2.x revert snapshot; never modify),
  `/tmp/klip-shell-{audit-*,shot,pr2-backup}`, `config.toml.klip-shell.bak`, and the CONTENTS of
  `quickklipshell-tweaks/` (historical patch bundle; only filenames were renamed).
- After the dir move the session cwd goes stale: exec needs an explicit cwd. Start new sessions in
  `~/dev/QuickKlipshell`.

### Two regressions my own (audited, "verified") fix pass had introduced
**Lesson: passing the audit and my own probes is not proof.** Both were in the F1-F11 "done" list.

1. **Enter committed twice.** `focus = false` inside `onEditingFinished` RE-ENTERS that handler:
   Qt emits `editingFinished` on focus-out — proven synchronously (releasing focus from a focused
   field = exactly 1 emission). Enter -> commit -> `focus = false` -> emission #2 -> commit again.
   Measured on a VISIBLE Dashboard input: one programmatic commit produced **2 `gcodeSent`**
   (2x M104/SET_VELOCITY_LIMIT POSTs + 2 transcript fetches; klippy logs the command twice).
   Fix: `property bool _committing` + `if (_committing) return` at the top, cleared at the end —
   both Dashboard sites (heater-target input, velocity-limit input). Re-measured: 1.
   History's search is unaffected (releases focus but has no `editingFinished` handler).
2. **Local gcode file + RELOAD loaded the wrong bytes.** F2 revived a dead code path and armed
   this: `reloadFile()` parsed the SERVER's last-fetched gcode body under the local path (or 404'd
   on the local path). Fix: `startParse(text, path, local)` records `_localSource`;
   `_readLocalFile(p)` is now the single place that reads from disk; `reloadFile()` routes local
   sources back to disk. Verified live: path kept, job rebuilt, same parse result, no error.
3. `tools/test-transport.py` had a FIXED port (7712) — a collision aborted it with a traceback.
   Now ephemeral: `ThreadingHTTPServer(("127.0.0.1", 0), Stub)` + `server_address[1]` into the
   generated printers.json + `server_close()`. Still 17/17.

### Probe traps that produced FALSE failures (do not misread)
- Collapsing the **CONFIG FILES** panel hides the Machine prompt's container, so the F3 watchdog
  correctly refuses focus to an invisible field -> a probe that collapses that panel first reports
  "prompt took focus = false". Not a bug; un-collapse or reorder.
- The viewer's `status` after a SUCCESSFUL parse is `"N segments from M lines"`, not `""`.
- Counting commits: use a VISIBLE input. An invisible one gets its focus stolen by the watchdog and
  that steal itself commits — confounding the count (cost one inconclusive experiment).
- The F3 watchdog is silent; to watch it work, log inside `_reclaimFocus` (harness copy only).

### Left alone on purpose (read the reasoning before "fixing")
- `MoonrakerService.loading` is written at 3 sites and read NOWHERE in the repo; on the
  zero-printer path the early return leaves it stuck `true`. Only a trap if a spinner is wired to it.
- With no printer configured `sendGcode` silently drops the command and never emits `gcodeSent`, so
  a "sending..." state would never resolve. One-line fix offered, not taken.
- A focused field COMMITS when it goes invisible (view switch / panel collapse / delegate rebuild):
  Qt turns that focus release into `editingFinished`. This is the mechanism the F3 watchdog relies
  on; ~200 ms of dead keys after a field closes is the accepted trade.
- Offered but not taken: instant focus recovery via window-level `Keys` + `Keys.BeforeItem`.
- **User declined git (twice, 2026-09-23): "not ready for git yet." Do not re-pitch unless asked.**

### Verified in this pass (all commands run from the new path)
qmllint exit 0 · `bash -n install.sh launch.sh` exit 0 · test-parse 16/16 · check-icons 62/62 clean ·
test-transport 17/17 · `install.sh` exit 0 with matugen config+template hashes UNCHANGED (idempotent
after the entry migration) · empty-printers boot 0 TypeErrors · live boot: title
`klipshell — Moonraker`, all 3 state paths resolve under `~/.local/state/klipshell/`,
presets loaded from the migrated file, matugen primary `#dfc0b4` loaded through the NEW cache path,
0 warnings/errors.
Harness: `/tmp/ks-live2` (rsync of `src/`; printers.json -> dead 127.0.0.1:7125 = demo mode, no stub
server needed). **Re-inject the aliases into the copied `MainWindow.qml` after EVERY rsync** (before
`function switchView(id) {`): `auditViewer: gcodeViewerView`, `auditDash: dashView`,
`auditKeyCatcher: keyCatcher`; plus `auditSearch: searchIn` in History. Handy handles:
`mw.presetStore._path()` (the `id: pstore` object), `dash._statePath()`, `viewer._statePath()`.
Probe output via `console.error` (console.log is filtered), filter with `grep -a KSR`. The old
`/tmp/ks-live` (pre-rename path) was removed.

## FULL AUDIT 2026-09-23b — 3 HIGHs, all runtime-verified (report /tmp/klip-shell-audit-20260923b.md)

**Harness that made this possible (REUSE IT):** `/tmp/ks-stub/moonraker-stub.py`
(python http.server on 127.0.0.1:7125 that mirrors Moonraker's REAL envelope
`{"result": …}`; POSTs always answer `{"result": "ok"}`) + a copy of the tree
(`rsync -a --exclude='*.tar.gz' --exclude='.pi' ./ /tmp/ks-live/`) whose
`src/config/printers.json` points at the stub, plus a probe `shell.qml` that drives
the app's own objects and logs with `console.error` (console.log is filtered).
Run `WAYLAND_DISPLAY=wayland-1 timeout 12 quickshell -n -p /tmp/ks-live`. This is
the only way to exercise the transport with no printer on. Add
`property alias auditX: someChildId` to the copy when a probe needs to reach a view.

**F1 HIGH — EVERY successful Moonraker POST is reported as a failure.**
`_action` (MoonrakerService.qml:1220-1229) and `sendGcode` (1243-1249) test
`ok = t === "" || t === "{}" || t === "ok"` — written for the transport's
`|| echo '{}'` fallback. Moonraker wraps every result
(`application.py:722-723 if self.wrap_result: result = {'result': result}`), so the
body is `{"result": "ok"}` and `ok` is false on success. Runtime:
`KSAUDIT gcodeSent ok=false err={"result": "ok"}` and
`KSAUDIT actionDone ok=false msg={"result": "ok"}`. Consequence: the console prints
`send failed: {"result": "ok"}` after EVERY command and stops refreshing the
transcript; PAUSE/RESUME/CANCEL/E-STOP/restart/update all report failure in the
Machine status line; post-action `refresh()` is skipped. FIX: parse and use the
`_fileResult` rule — `{error:…}` ⇒ fail, anything else (incl. `{}`) ⇒ ok.

**F2 HIGH — viewer LOAD LOCAL is a dead button.** `GcodeViewer.qml:169` does
`root._readProc.path = p` — Quickshell's `Process` has NO `path` property
(verified in `Quickshell/Io/quickshell-io.qmltypes`), so the assignment THROWS and
aborts `onStreamFinished` before `command`/`running` are set; line 183 then reads
the stash off the WRONG object (`_pickProc.path`). Runtime:
`WARN scene @src/views/GcodeViewer.qml[169:-1]: Error: Cannot assign to non-existent
property "path"` then `fileName=[] status=[] job=false readRunning=false` — nothing
loads, no message. Same lesson as `p0..p7`'s declared `_handler`/`_printerCfg`:
DECLARE the stash (`property string _pendingPath: ""` on the view), never expando.

**F3 HIGH — keyboard nav dies permanently after clicking any TextInput.**
`MainWindow.qml:578 focus: win.visible === true` is the ONLY focus owner; when a
`TextInput` takes active focus Qt writes `focus=false` on the keyCatcher and
nothing ever re-evaluates the binding (win.visible never changes) — so 1-8 /
arrows / h-j-k-l / Enter / Esc stop working for the rest of the session. TextInput
sites: History.qml:446, Dashboard.qml:1202 + 1529, Machine.qml:904 (its
`focus: promptKind !== ""` makes the file-manager RENAME prompt a trigger too).
Runtime in the app: `t0 activeFocus=true` → force focus on the History search →
`appKeyCatcher.focus=false activeFocus=false` and it stays false even after a view
switch. `Keys.onPressed` only fires for the item with active focus. FIX: re-assert
(`keyCatcher.forceActiveFocus()`) on view switch, dialog/prompt close and input
commit; a `focus:` binding alone cannot recover.

**F4 MED — Dashboard calls the printing file ERROR.** `Dashboard.qml:44-57` checks
`printing`/`paused` but Moonraker history says `in_progress` (History.qml:144-158
gets it right). Runtime: `KSAUDIT stateLabel(in_progress)=ERROR color=#4a4644`.
Also `fileStateOf` (MoonrakerService.qml:865-875) lets an OLDER `completed` job mask
the newest `in_progress` one — it should return the newest matching job's status.

**F5 MED — Machine panel collapse leaves dead space.** `Machine.qml:490, 625, 1141`
use `parent.collapsed`; `parent` is the Row/Column, which has no `collapsed`
(runtime: `KSAUDIT parent-collapsed=undefined`), so the chevron hides the body via
`bodyVisible` while the card keeps its full height. Use Panel's own `collapsed`.

**F6 LOW (also the 2026-09-23 audit's only finding) — `downloadLog()` skips `_sq`.**
MoonrakerService.qml:842-845 interpolates the URL into `curl -sf '<url>'`;
`encodeURIComponent` leaves `'` alone, so a log name with an apostrophe mangles the
command and admits a subshell break-out. Latent (caller passes literals). Fix:
`root._sq(url)`.

**F7 LOW** — MoonrakerService.qml:1129 `all[i].replace(" ", "%20")` replaces only
the FIRST space (`temperature_sensor hot end 1` ⇒ raw space in the URL ⇒ curl
rejects it ⇒ the single combined MCU query dies); :1059 doesn't escape fan names at
all. Use `.replace(/ /g, "%20")`.
**F8 LOW** — `deleteFile()` (:999-1001) posts to `/server/files/delete_file`, which
404s here, and has no callers. **F9 LOW** — GcodeViewer's `specular` toggle is
declared/persisted/offered and read by no painter. **F10 LOW** — with 0 printers +
demo, all 12 `_seedDemo(root._activeCfg())` sites throw `TypeError: Cannot read
property 'name' of null` (runtime-verified) because they lack the `if (!cfg) return`
guard the file fetchers have. **F11 INFO (dead code)** — `_fetch`'s ignored `slot`
param + the 8 `_nextSlot++` call sites, `machineOpenView`'s ignored `path`,
`install.sh`'s unread `~/.config/klipshell/config.json`, Dashboard's unreachable
customize dialog (`customizing` never set true, 1723-1810), `Gauge`'s
`anchors.fill`+`height`, `Chart.glowPulse` never changing, `_heatColor`'s first two
branches both `Colors.primary`, SettingsPopup:174 `anchors.leftMargin` on a Row.

**Verified clean by sweep:** 0 unknown `Metrics/Type/Colors/Icons` members, 0
malformed `\u` escapes, 0 `.hovered`-on-MouseArea, 0 Repeater delegates without
width, 0 `*Margin`-without-anchor, `on_AllNamesChanged` IS the right handler name
(`on_allNamesChanged` fails to load). Heightmap's `on_`-prefixed handler and
GcodeParse's relative-E arcs are fine (the parser's own test covers them).

## FIX PASS 2026-09-23c — every finding closed, 19/19 live probes + 17/17 transport asserts

All of F1–F10 fixed; F11's dead code removed except three deliberate keeps.
Static: qmllint 0, `bash -n` 0, parser 16/16, icons 62/0. Live harness (same stub
recipe, probe aliases `auditKeyCatcher/auditViewer/auditHist/auditMachine/auditDash`
+ `auditSearch` in History): F4 labels, F5 collapsed heights (34px), F9 gone,
F2 local load parses, F3's four focus transitions — all PASS, boot 0 warn.

**NEW committed regression test: `tools/test-transport.py`** (added to AGENTS.md's
Verification block). Inlines a stub Moonraker on 127.0.0.1:7712, copies `src/` to a
temp dir, writes a probe `shell.qml` that boots the real `MainWindow` and drives
`MoonrakerService`, and asserts `_postOk` (result-ok / empty / blank / error
envelope / non-json), `_sq` break-out, `_encPath`, `_seedDemo(null)` no-throw,
`fileStateOf` newest-wins, plus the live `gcodeSent`/`actionDone` paths. 17 asserts.
Needs `WAYLAND_DISPLAY` (exits 2 without it). Run:
`WAYLAND_DISPLAY=wayland-1 python3 tools/test-transport.py`. This is what would have
caught F1 and F2; F3's focus recovery is not covered (duck-typing into
`contentItem.children` was judged too fragile to commit — it lives in the probe).

**F3's fix — three dead ends, the working shape, and why.** Qt writes `focus=false`
on the keyCatcher when a TextInput takes focus, and the old `focus: win.visible`
binding never re-evaluated. Dead ends: (a) `focus: !editing` derived from
`Window.activeFocusItem` → `Binding loop detected for property "editing"`, and QML
BREAKS the binding on a loop, so focus never came back; (b) a synchronous
`forceActiveFocus()` inside `onFocusOwnerChanged` → `Binding loop detected for
property "focusOwner"` for the same reason (the write re-enters the binding being
read); (c) reading `Window.activeFocusItem` inside a `Timer` → `Window.window only
supports types derived from Item` AND the read yields garbage, so the guard stole
focus from the Machine prompt. Working shape (MainWindow.qml, keyCatcher):
`focus: true` constant + `_reclaimFocus()` declared on the Item (so `Window`
resolves) + ONE 200ms `Timer` calling it. The predicate is
`it && it.visible && it.enabled && it.acceptableInput !== undefined` → return.
Key facts: Qt keeps pointing `activeFocusItem` at a field whose view/prompt has just
been hidden and emits NOTHING, so a tick is required, not just a signal;
`forceActiveFocus()` works on an invisible item (so the History search took focus
while its view was hidden); the recovery lands within one tick (~200ms), which is
why the probes must check ~400ms after the action, never in the same tick.
Prompt focus: `onPromptKindChanged` + `Qt.callLater(() => fmPrompt.forceActiveFocus())`
in Machine.qml (the old `focus:` binding on the prompt TextInput was clobbered by Qt
on the first transition and never came back).

**Deliberate non-fixes (F11):** `_heatColor`'s first two branches (both
`Colors.primary` — `tempCool === accent === primary`; collapsing erases the intended
3-step ramp); `Chart.glowPulse` (a tuning knob, not dead code); Dashboard's
unreachable customize dialog + `movePanel`/`toggleVisible` (kept for the planned
settings menu). **`install.sh` no longer writes `~/.config/klipshell/config.json`**
(nothing ever read it) and no longer checks for `jq`.

## UPDATE MANAGER EMPTY = stale QML bindings + a missing anchor (2026-09-22 — lint 0, boot 0 warn, 3 captures, PROBE-verified)

**Root cause #1 — re-assigning the same object reference is NOT a property
change.** `data.machine` was assembled fetch by fetch as `var m = root.data
.machine || {}; m.update = r; root.data.machine = m` — same object identity every
time, so `data.machine` never emitted a change signal, the view's
`root.machine = moonraker.data.machine` assigned the same reference too, and
every binding that *calls a function* over it (`model: root._updateKeys()`,
`visible: ... _sysPkgs() === 0`) was evaluated ONCE — at view open, before the
responses landed — and never again. The data was there the whole time; the card
kept saying "no components reported". Proof probe in a /tmp copy:
`keys= 9 update? true vi= 10 sameObj= true syspkgs= 13` printed from a Timer
while the panel still rendered empty. Fix: `_patchMachine({proc|update|endstops|
sysinfo: …})` → `root.data.machine = Object.assign({}, root.data.machine, patch)`.
A `readonly property var x: (function(){…})()` binding (sysRows) is not affected
because it re-evaluates off other deps (ps), which is why the SYSTEM panel looked
live while the update card stayed dead. **Debug trick: a Timer calling the same
function the binding calls tells you whether the data or the binding is stale —
and `console.log` is filtered out of the Quickshell log, `console.error` is not.**

**Root cause #2 — a row's second line had `anchors.topMargin: 27` with no
`anchors.top`** (topMargin without its anchor is silently ignored → that line sat
at y=0 under the name line at y=7 → the doubled/overlapping rows seen once data
finally rendered). Same trap as the `anchors.rightMargin`-without-`right` chips in
the ENDSTOPS card. `anchors.<x>Margin` only means something with `anchors.<x>`.

**`/machine/update/status` facts:** 27 kB of `version_info` (git commit messages),
10 keys on this Voron (klipper, moonraker, mainsail, mainsail-config, sonar,
KlipperScreen, print_area_bed_mesh, cartographer_plugin, Klippain-ShakeTune, +
system) — Moonraker only lists what updaters are registered, so the card shows
exactly that list minus `system`, which renders as its own row from
`package_count`. `?refresh=false` is accepted. A cold call can wait on the
update check past the transport's 5 s `--max-time`, so the handler now ignores an
empty parse instead of overwriting the last good report with `{}`.

## ENDSTOPS LIVE + RAIL SIDE-BY-SIDE (2026-09-22 — lint 0, boot 0 warn, 2 captures)
SUPERSEDES the sync-icon / stacked-rail half of the LAYOUT PASS block below.

**The card was invisible, not just stale — missing `anchors.right`.** The
ENDSTOPS body Column had `anchors.left` + `anchors.rightMargin` but never
`anchors.right`, so the Column kept its implicit width and every child with
`width: parent.width` was 0 wide; the 48px icon (centerIn a 0-wide Item) drew at
x ≈ -24 and `Panel.clip` ate it. Same trap on the row `Chip` (it had
`anchors.rightMargin` with no `anchors.right`, so chips sat at the left edge).
Any "the card renders empty" report: check the anchors before the data.

**Live endstops = the klippy webhook, not the object.** `query_endstops`
`last_query` only moves when something runs M119 (it stays `{}`/stale forever
after a reboot), and `?endstops` is not a Klipper object at all. `GET
/printer/query_endstops/status` (verified live on 192.168.1.50, HTTP 200) queries
every registered endstop and answers `{stepper_x: "open", …}` — names and
state, no GCode command, and like M119 it never moves an axis. That is what
klip-tui uses (`printer.query_endstops.status` over WS) for its `e` query key.
Service: `fetchEndstops()` (called from `fetchMachine()`), polled 1s by a Timer
in Machine.qml gated on `root.visible && !demo`; `syncEndstops` /
`endstopTimer` / `_applyEndstops` / `_getQueryEndstops` / `endstopsOpen` are
DELETED, and `machine.endstops` is now `{name: bool}` (demo seed too).

**Rail geometry now:** `Row { height: railTopH }` holds ENDSTOPS | LOG FILES
side by side (each `(parent.width - lg) / 2`, both `height: parent.height` so
they always end level), UPDATE MANAGER full width below;
`railTopH = max(endstopPanelH, railCardH=150)`,
`endstopPanelH = 62 + 26 + sm + max(1, rows) * 34 + max(0, rows-1) * xs`
(62 = 34 header + 6 + 22 padding, 26 = the REFRESH row) ≈ 204 live with 3
endstops. ENDSTOPS carries the `REFRESH` button (84×26, variant soft, top-right)
and no icon; an empty list shows "no endstops reported". LOG FILES' 3 buttons
stretch to the same row height (~52px each). Still never bind a panel height to
a child-sized Column (0 / -162 cycle) — the row height stays arithmetic.

## LAYOUT PASS: endstops sync icon / square LOG FILES / content-sized cards (2026-09-23 — lint 0, boots 0 warn, 2 captures)

**MODIFIED column overlapped SIZE (real cause):** 14px monospace ≈ 8.4px/char,
so Mainsail's `"MMM d, yyyy h:mm AP"` ("Sep 15, 2025 6:54 PM", 20 chars ≈
168px) never fit the 112px right-aligned column and spilled left into SIZE.
Fix: `dateOf()` emits **"Sep 15 6:54 PM"** for the current year and
**"Sep 15, 2025"** for other years (year is noise on fresh edits, time is noise
on old ones), column widths are now `fmSizeW`/`fmDateW` = 62/132 shared by
header + rows, plus `elide: Text.ElideRight`. Do NOT reintroduce
`Qt.formatDateTime` here — and note `qml /tmp/x.qml` on this box prints nothing
(no console output at all, even offscreen), so Qt format strings cannot be
smoke-tested that way; format in plain JS instead.

**ENDSTOPS card was permanently "open" (silent, like the fans bug):** it polled
`/printer/objects/query?endstops` — **there is no `endstops` object in Klipper**
(it answers `{}` with no error, so it never showed up in the log). The real
object is **`query_endstops`**, and its payload is
`last_query: {stepper_x: 0, stepper_y: 0, stepper_z: 0}` (**stepper names, ints,
not x/y/z strings**) — and `last_query` **stays empty until something actually
queries the endstops**, which is why the card needs a sync button at all.
Implementation: poll `?query_endstops` every tick; the bold **U+F0450** icon
sends `QUERY_ENDSTOPS` (= M119, read-only, no motion) via `sendGcode`, reads
back immediately AND after 450ms (`endstopTimer`: Klipper's queue may not have
processed the script when the first read lands), and flips `endstopsOpen` so the
card expands. The expanded list is **dynamic `Object.keys()`** of whatever the
printer reports (→ "connected endstops", label = key minus `stepper_`,
uppercase; value != 0 → TRIGGERED) instead of the old hardcoded `["x","y","z"]`.

**QtObject has NO default property — child objects must be property-declared.**
A bare `Timer { id: ... }` inside `MoonrakerService.qml` fails at LOAD with
`Cannot assign to non-existent default property` (which surfaces as "Type
MoonrakerService unavailable" → "Type MainWindow unavailable" → the whole shell
dies, qmllint still exit 0). Any new Timer/Process there needs
`property var x: Timer { ... }` like `pollTimer`/`p0..p7`.

**Height grammar now:** `filesRowH` = 452 (collapsed) = ENDSTOPS 150 + lg 12 +
LOG 300; `endstopPanelH` = `endstopsOpen ? max(170, 124 + rows*52) : 150`;
expanding grows `filesRowH` (page scrolls, LOG stays exactly 300 → square at
~296 wide). LOG FILES = `parent.height - endstopsPanel.height - parent.spacing`
so it follows automatically, with 3 stacked full-width buttons sized
`(logCol.height - spacing*2) / 3` and the "saved to ~/.cache…" caption deleted.
UPDATE MANAGER is **content-measured** (`updateRowH` = 62 chrome + 30 header +
sm + n*40 [+ 46 for sys pkgs], min 150) ≈ 224 live instead of a fixed 340 — same
trick the SYSTEM panel uses; no Flickable needed, nothing clips.

**Glyph ground truth (`fc-list ":charset=<hex>" family`):** U+F0450 is native to
JetBrainsMono Nerd Font (21 faces). U+21BB/U+27F3/U+2699 are **not** in it (they
render only via Qt font fallback). A glyph pasted into this session's chat is
stored as literal dots (unrecoverable) — always ask or verify by codepoint.
Log downloads now report into the CONFIG FILES status line (`actionDone`).

## CONFIG FILES = MAINSail FILE MANAGER (2026-09-23 — lint 0 / boot 0 warn / endpoints + edit pipeline VERIFIED live)
Replaces the old single-line `.cfg` list (and its `fetchConfigFiles` /
`data.configFiles` bucket — deleted; `openConfigFile` deleted too, it edited a
stale cache copy that never went back to the printer).

**WHY THE OLD CARD WAS EMPTY (root cause, not a layout bug):** `_fetch()` picks
via `_freeSlot()`; when all 5 slots were busy the request was DROPPED silently
— and the view's `refresh()` bursts 8 requests (proc_stats + update + endstops +
objects/info/tempstore + fans×2 + mcus) the instant the Machine view opens, so
last-issued `fetchConfigFiles` died and the card stayed empty until the next
view switch. Fixes: **8 slots** (`p0..p7`, `_pick` = array lookup, `_freeSlot`
loops 8), **one shared object list** (`_syncObjects()` → `_allObjects`, every 25
ticks, consumed by both `fetchFans` and `fetchMcus`; `_mcuNames` gone), and
`fetchDir` never clears `data.dir` before the response (no blank frame).

**SECOND REAL BUG FOUND IN THE LIVE LOG:** Moonraker logs only error responses,
so `grep`ping /server/files/logs/moonraker.log for our IP shows exactly which of
our requests fail. It showed `404 GET /printer/objects/query&fan&hotend_fan…`
**once per second, for hours** — `fetchFans` built its query with a leading `&`,
so live fan speeds were silently always 0 (the object list still rendered).
FIXED (`?` on the first name, same trap as fetchMcus). Any "the card looks
frozen" report: check that log first — it is the only request-error evidence the
printer gives us.

**Moonraker 0.9 file-manager endpoints (all verified with curl on 192.168.1.50):**
- `GET /server/files/roots` → [{name,path,permissions}] (perms gate write ops)
- `GET /server/files/directory?path=<root>[/<dir>]` →
  `{dirs:[{dirname,size,modified,permissions}], files:[{filename,…}],
  disk_usage:{total,used,free}, root_info:{name,permissions}}` — folders+files
  are SEPARATE arrays, `modified` is epoch SECONDS, sizes are bytes.
- mkdir `POST /server/files/directory {path:"config/x"}`
- upload `POST /server/files/upload` multipart `-F file=@local -F root=config
  -F path=<dir rel to root, "."=root>` → reply `{action,item}` with **no
  `result` wrapper** (so a `result`-only check reads success as failure).
- move `POST /server/files/move {source,dest}`, copy
  `POST /server/files/copy {source,dest}` (Mainsail uses PUT/COPY methods; POST
  works on this build) — paths are `<root>/<path>` strings.
- delete FILE `DELETE /server/files/<root>/<path>`; delete DIR
  `DELETE /server/files/directory?path=<root>/<dir>&force=true` (without
  `force` a non-empty dir returns 400 Errno 39). `/server/files/delete_file`
  and `/delete_dir` DO NOT EXIST here → 404 (the old `deleteFile()` used the
  404 form).

**Service API added:** `fetchRoots()`, `fetchDir(root,path)`, `makeDir(path)`,
`moveEntry(src,dest)`, `copyEntry`, `removeEntry(path,isDir)`, `uploadLocal`,
`pickAndUpload` (zenity), `editRemoteFile`; helpers `_encPath` (encode per
segment, keeps `/`), `_sq` (`'`→`'\''`, the break-out guard for bash -c),
`_fileResult` (parses `{error}` → actionDone + refetch), `_lastDir`, `_roots`.

**Edit-in-place:** download → `kitty -e ${EDITOR:-nvim}` → `sha256sum` before/
after → upload back ONLY if changed (verified end-to-end via the exact bash
pipeline: remote content updated; unchanged run makes no request). The editor
runs INSIDE one pool slot (kitty blocks), hence the 8 slots.

**`actionDone` had NO listener anywhere in the tree** — every existing "updating…
/restarting…" message went nowhere. The Machine view now listens
(`onActionDone` → `status()` → 5 s message in the card's path row).

**Card (Machine.qml):** root chips (Flow of Buttons, accent = active, `active:
false` for read-only roots), `↑` + `/config/<path>` + `22.1 GB free` (or the
status message), Separator, sortable header (NAME/SIZE/MODIFIED with ▴▾ +
full-row MouseArea splitting at width-112 / width-174), Flickable of 28px rows
(checkbox · `▸ name` · size · `Qt.formatDateTime(…, "MMM d, yyyy h:mm AP")`),
footer that swaps between create/upload/refresh (no selection),
RENAME/COPY/DELETE + "N selected" (1+ selected; rename/copy need exactly 1),
and a prompt mode (TextInput pre-filled with the remote path — typing another
directory IS the move; DELETE asks for confirmation). Whole-dir scroll, no
pagination (user's call). No bulk DOWNLOAD (not requested).

**GOTCHA — anchors inside a positioner are a RUNTIME warn:** a child with
`anchors.fill: parent` inside a `Row` prints "QML Row … Cannot specify left,
right, horizontalCenter, fill or centerIn anchors for items inside Row" (4× at
boot) while qmllint stays silent. Wrap the Row in an `Item` and make the
overlay MouseArea a sibling. **Always read the boot log, not just qmllint.**
Left open: the card is 62% of the FILES row (~465 px) so 3 columns are tight —
promoting it to a full-width row is the fix if the user says it feels cramped.

## SYSTEM PANEL = MAINSail ROWS (2026-09-22 late — lint 0 / boot 0 warn / 1 instance)
SUPERSEDES the "MACHINE TAB REDO — 5 STAT BOXES" block below: the 5 boxes are
gone; the square box survives as each ROW's indicator on the right.
User: "same info as Mainsail's System Loads card; CPU+MEM are the HOST (Pi), not
Voron/Moonraker; drop the sub-captions + the KV text block; square boxes not
rings; 1s poll; no REFRESH; titles bigger + brighter."
- Machine.qml SYSTEM panel = `root.sysRows` (array of {title, chip, lines[],
  boxes[{label,value,ratio}]}) → one Repeater, one row delegate: text Column
  (title sizeBody bold Colors.accent, chip caption dim, lines sizeSmall
  surfaceVariantText) left, boxes Row right — 76px square, "N%" inside,
  gradient fill via _heatColor, caption under the box only for CPU/MEM —
  Separator between rows. Panel height is now MEASURED (`Math.round(sysBody.y +
  sysBody.height + Metrics.panelPadding)`) — never re-hardcode it.
- Row 1 = Host (was the Voron-name card; MOONRAKER card gone entirely), then
  `ps.mcus` in discovery order. CPU box = round(system_cpu_usage.cpu), MEM box =
  round(system_mem_used / system_mem_total * 100). REFRESH button DELETED.
- Deleted: statBoxes, mcuLabel, pct/tempFmt/memFmt/uptimeFmt,
  cpuNow/memNow/tempNow/*Ratio, the HOST/DISTRO/UPTIME/CORES/PYTHON/KLIPPY/
  TRANSPORT/CONNECT KV rows, and the service's moonraker_stats →
  moonraker_cpu/mem normalization (its last consumer). Nothing shows klippy
  state or connection now except the red banner card.
- **MCU temp (Mainsail getMcuTempSensors/getMcuTempSensor):** config objects with
  `sensor_type: temperature_mcu` + `sensor_mcu: <x>`; an mcu matches when its
  NAME ENDS WITH sensor_mcu. Live 192.168.1.50: `temperature_sensor BTT-MCU` →
  sensor_mcu `mcu` (28°C), `temperature_sensor cartographer` → `cartographer`
  (38°C), nothing for `mcu EBBCan` → Mainsail prints NO Temp segment at all
  (blank, not "—"). GOTCHA: config keys are LOWERCASED
  (`temperature_sensor btt-mcu`) while the live object name keeps case
  (`temperature_sensor BTT-MCU`) → `_liveObject()` resolves case-insensitively
  against `root._allObjects` (/printer/objects/list) before building the query;
  response status keys keep the live case.
- New poll: `/printer/objects/query?configfile=settings` is only ~61 keys on
  this config (cheap) — fetched while null + every 100 ticks; the resolved
  sensor objects are appended to the existing MCU query (spaces → %20, `?` on
  the FIRST name only). MCU fields now add `version` (`mcu_version`;
  cartographer = "CARTOGRAPHER V3 6.1.0"), `temp` (null when no sensor),
  `awake` = mcu_awake/5 (ratio, .toFixed(2)) — `awakePct` gone.
- Host fields: `softwareVersion` (/printer/info), `distribution.name` (0.9 has
  no pretty_name; `name` holds "Debian GNU/Linux 11 (bullseye)"),
  cpu_info.processor + bits → "(aarch64, 64bit)", proc.network can0/wlan0
  {bandwidth, rx_bytes, tx_bytes} + system_info.network ip_addresses (first
  non-link-local ipv4). filesize() = Mainsail formatFilesize: 1024-based,
  1 decimal (986.9 MB). Host Temp still cpu_temp, not the temperature_host
  sensor (both round to 40°C here).
- pollTimer 2000 → **1000 ms**. Tick cadences scaled: objects list 25 ticks
  (~25 s), configfile 100 (~100 s), demo re-probe 15 (~15 s).
- BUG TRAP (repeat of the KV surgery): the native edit that removed the REFRESH
  Item swallowed the sysBody Column's closing brace → qmllint "Expected token
  `}`" one line off EOF. The balance script (per-line depth + stack, strings and
  //-comments stripped) found it instantly — run that after any brace surgery,
  never trust qmllint's reported line.
- Capture trick (no input injection on this box): `rsync -a --exclude='*.tar.gz'
  repo/ /tmp/klip-shell-shot/` + sed `activeView: "dash"` → `"machine"` + launch
  the COPY → `shot onws <ws> <out.png>`; kill the copy, then relaunch the real
  tree. Same code, one changed default view.

## MACHINE TAB REDO — 5 STAT BOXES (2026-09-22 — VERIFIED lint 0 / boot 0 warn / 1 instance)
User: "LOG FILES card too long, make square like ENDSTOPS; cpu/mem/temp still
don't fill; redo as 5 boxes — HOST (Pi CPU/MEM), mcu EBBCan, MCU cartographer,
MCU; look at Mainsail's code + use live printer".

**Mainsail reference (cloned to /tmp/pi-github-repos/...mainsail during the
session):** SystemPanel.vue = ONE panel 'SYSTEM LOAD': rows of MCUs + HOST,
each a 55px circular ring. MCU data = printer objects keyed 'mcu'/'mcu X'.
**MCU load formula (store/printer/getters.ts getMcus):**
`load = last_stats.mcu_task_avg + (3 * mcu_task_stddev) / 0.0025` (loop-
period seconds; tiny values ~0.4-3%). awake = mcu_awake/5*100. cortex:
freq, chip = mcu_constants.MCU.
**HOST (server/getters.ts getHostStats):** load = klippy system_stats.sysload
/ loadPercent = load/cpu_count; mem from proc memory; temp from cpu_temp.

**Service changes:** (1) poll query now includes &system_stats → ps.sysload
+ ps.memAvailHost (memavail kB→B). (2) fetchMachine normalizes
moonraker_stats (list) → proc.moonraker_cpu / proc.moonraker_mem (kB→B).
(3) NEW fetchMcus(): discovers 'mcu'/'mcu X' objects from
/printer/objects/list every 25th refresh (else cached), then one
/printer/objects/query?mcu&mcu%20EBBCan&… (note: ? on FIRST name, & after;
spaces → %20) → state.mcus[{name,chip,load,loadPct,awakePct,freq,state}].
Demo seed has 3 mcus. **BUG TRAP:** `query&mcu` (missing ?) makes the whole
curl return {} silently — ? goes on the FIRST name only.

**Machine view:** SYSTEM panel rings row → statBoxes Repeater: 5 × ~182×170
square cards, one ring each (fill-rect + big % + 2 caption subs), labels
HOST (printer name) / MOONRAKER (proc stats, RSS) / MCU / MCU EBBCAN /
MCU CARTOGRAPHER (mcuLabel uppercases). Live (192.168.1.50): mcu 0.4%
(stm32f446xx), EBBCan 1.9% (stm32g0b1xx), cartographer 2.9% (stm32f042x6).
Files grid: Row{ CONFIG FILES 62% ×352 | Column 38%{ ENDSTOPS ×210,
LOG FILES ×130 } } → LOG FILES is now a square card (3 soft buttons +
caption 'saved to ~/.cache/klipshell/<printer>/logs'), not full-width.
UPDATE MANAGER moved to its own full-width row below (340).
Layout failure mode: brace-surgery during restructure — verify with the
brace-depth script, not by eye.

## DASHBOARD POLISH ROUND (2026-09-22 post-mainsail — VERIFIED lint 0 / boot 0 warn / 1 instance)
Live-truth fixes against 192.168.1.50 (Moonraker 0.9):
1. **Temp graph frozen-looking**: /server/temperature_store IGNORES the count
   param on this build (returns 1200 samples ≈ 40 min) → each 2s poll moved the
   line ~0.3px → "doesn't update fast enough". FIX: `_handleTempStore` trims to
   last 180 (~6 min) client-side → ~1.8px/sample, visibly moving.
2. **Extruder temp color was BACKWARDS**: tempColor used |cur-target| with
   close-to-target=cool → cold extruder showed RED tempHot, at-target showed
   blue. Flipped: d<8=tempHot, d<25=tempWarm, else tempCool → heat-up ramp
   reads blue→amber→red. Temps were already live (2s poll, status.extruder
   .temperature). Tool-changer 2.4: live extruder 23.4° / heater_bed 23.6°.
3. **Extrude amount chips stacked vertically**: old Repeater {width:242} of
   4×56px chips rendered as a stack (Repeater flow vs anchors conflict).
   Replaced with a Row of 3 fixed chips (5/10/50, 52px, selectedFill+border)
   right-aligned UNDER the RETRACT/EXTRUDE row; dropped the 25mm option.
4. **STATUS card**: panel title now = live klipper print state (STANDBY /
   PRINTING / PAUSED / … via panelTitle(), falls back to "STATUS") — the
   label was static "STATUS". Added a "G-CODE FILES" caption above the top-5
   list (recentFiles = top 5 by modified, works live: 20 gcode files incl.
   CJK names). Status pinned card: draggable false still.
5. **MISC/FANS**: _miscHeight 82→106 + n*40 (fan rows get +24px headroom;
   live objects: fan + hotend_fan + 2× controller_fan). If the /ss still
   clips, next lever is content-driven height from a measured body.

## MAINSaIL PARITY ROUND (2026-09-22 night — VERIFIED lint 0 / boot 0 warn; ONE live instance)
1. **Machine tab stats fix (real bug)** — live `/machine/proc_stats` on
   Moonraker 0.9 (voron 192.168.1.50) returns `system_memory: {total, available,
   used}` in **kB**; the shell read top-level `system_mem_total/available`
   (0.8-era, bytes) → undefined → MEM ring forever 0. FIX: normalize in
   `fetchMachine` — if `system_memory` present, copy to
   system_mem_total/available (×1024 → bytes) so view + demo stay unchanged.
   CPU (`system_cpu_usage.cpu`) + `cpu_temp` paths already matched 0.9
   (verified live: 9.3% / 42.8°). KV rows ALSO 0.9-broken: `hostname` and
   `distribution.pretty_name` dropped → HOST now shows cfg.name, DISTRO reads
   `distribution.name` (cpu_count still right).
2. **CONFIG FILES + LOG FILES cards** — FILES title → "CONFIG FILES"; new
   LOG FILES panel (96px) with KLIPPY/MOONRAKER/CROWSNEST buttons → new
   `MoonrakerService.downloadLog(name)` → `/server/files/logs/<name>`
   downloaded to `~/.cache/klipshell/<printer>/logs/` (name whitelisted to
   [A-Za-z0-9._-], URL via encodeURIComponent — same injection guard as
   openConfigFile). All 3 live endpoints verified 200.
3. **Settings view → gear popup** — settings REMOVED from nav/ordered;
   sidebar gear chip (⚙ SETTINGS, above printer selector) sets
   `win.settingsOpen` → `SettingsPopup` (z 90, scrim, centered 640×544 card,
   tabs PRINTERS/APPEARANCE/PRESETS via `tab` int; pages are Flickables).
   Key routing moved: `win.settingsOpen` → settingsPopup.handleKey (Esc
   closes). number keys shifted: 5 = layermind (was settings), no Key_6.
   Preset editor rows compacted to fit 640 popup width. Settings.qml DELETED.
4. **SINGLE INSTANCE** — new `launch.sh`: `quickshell -n -p $REPO`
   (-n/--no-duplicate confirmed in 0.3.1). Repeated `quickshell -p .`
   launches each stage a new window — that's how 5 instances piled up.
   USE ./launch.sh. Cleanup: `quickshell kill -p <dir>` kills ONE instance
   per call — loop until `quickshell list -p` shows 0 (skill's claim that it
   kills all is WRONG on this box). NEVER pkill quickshell (webb-shell).
5. **GOTCHA — qmldir breaks the whole import on file add/remove** —
   src/views/qmldir lists types explicitly; deleting Settings.qml without
   updating it → "SettingsPopup is not a type" at the referenced site while
   qmllint stays quiet (loader silently drops the broken dir). After any
   view file add/remove: sync qmldir + `quickshell -p src/views/X.qml` to
   surface per-file compile errors. Other dirs' qmldirs verified consistent.


## MACHINE + DASHBOARD CARD ROUND (2026-09-22 late evening — VERIFIED lint 0 / boot 0 warn)
Machine view rework + dashboard resize-by-drag:
1. **FILES card** — shows ALL config files (removed top-5 `.slice(0,5)`); deleted the
   "top N by modified" caption, "FREE <disk>", size/date columns, and the
   "CONFIG FILES" header; rows = single-line name (34px) in a Flickable; card fixed at
   220px (ENDSTOPS = 250) so it stays shorter than ENDSTOPS regardless of file count.
   Dead code removed: fetchFiles call, filesData, size(), ago(), _diskFree.
2. **SYSTEM card** — CPU/MEM/TEMP values now sizeLarge (20) + Colors.error (the
   TRIGGERED-chip red), previously sizeHeading + heat color.
3. **Collapse chevron on every dashboard card** — `collapsible: pid !== "status"` →
   `collapsible: true` (status was the only card without it). pHeight already returned
   34 for any collapsed panel, so no other changes needed.
4. **Drag-header-to-move (manual gesture, NO Drag/DropArea machinery)** — Quickshell
   Drag/DropArea NEVER verified working on this seat (user never saw a card move in ANY
   build; no input injection available to test). REWRITTEN move on the ONLY proven
   interaction: MouseArea press-grab motion (round-1 resize proved motion + release
   keep firing outside the area). Panel.qml headerMouse: manual 6px threshold from press
   point, then emits dragMoved(gx,gy)/dragEnded(gx,gy) with GLOBAL coords = local
   mouse + headerMouse.globalPosition (Item.globalPosition exists, window-space,
   includes Flickable scroll). Dashboard owns ALL hit-testing via pure layout math
   (no leg registry, no stale state): _gridRects() mirrors the Column/Row geometry —
   left col x=body.globalPosition.x, right col +colW+lg, y cumulative pHeight+lg
   from body.globalPosition.y — _rectAt() keeps LAST enclosing rect (z-order), hoverId
   + hoverBefore drive the accent indicator, dropReorder(target, src, ly) unchanged.
   Ghost: dashboard-level Item (z 40, surfaceContainerLow + accent border, x/y/w/h
   bound to dragGhostX/Y/W/H props) + source panel fades to 0.45 while dragId set.
   COLLAPSE: separate chevronArea MouseArea (right 84px zone, onClicked); header title
   zone = drag only (drag + onClicked on ONE MouseArea was unreliable).
   GOTCHAS: chevron glyph sits at rightMargin 56 — click zone MUST cover it (was 28px
   wide → clicks landed in the drag zone → "wont collapse"). No wtype/ydotool on this
   machine; no programmatic Drag.start (QQuickDrag has NO methods in installed 6.x);
   QQuickDragAttached.active IS writable (propagates). qmllint: my bindings use
   leg.pid qualified; pre-existing unqualified delegate access (dragId/hoverId/pid/
   modelData) warns but qmllint --silent exits 0.
5. **⚙ LAYOUT button removed** (floated at Dashboard x=width-96,y=2; opened `customizing`
   dialog). Dialog + movePanel/toggleVisible kept intentionally — layout functions move
   into a future global settings menu.

## AUDIT+FIX ROUND (2026-09-22 evening — pre-change audit, 3 bugs + 1 latent, ALL FIXED)
Full project-auditor pass (no git; mtime scope). Live boot with all printers OFF
immediately exposed a bug the "verified 0-warn" claim missed: demo-mode WARN spam + dead feature.
Fixes applied to working tree (NOT in template copy), verified lint 0 + boot 0 warn/err:
1. **`_demoProbe` undeclared** (MoonrakerService.qml) — `root._demoProbe = (…)+1` threw
   "Cannot assign to non-existent property" on a SINGLETON (JS dynamic props don't work on
   singletons; Dashboard's declared `property real _demoFill` works) every 2s in demo,
   aborting refresh() BEFORE `_seedDemo` and the %15 auto-exit probe → demo stale forever +
   WARN spam (92 in 40s measured). FIX: `property int _demoProbe: 0`.
2. **Shell injection on save** — `printf '%s' '<json>' > '<f>'` with raw JSON; a `'` in a
   printer name/host (`_persistPrinters`) or preset name (`presetStore.save` in MainWindow)
   breaks out → arbitrary cmd exec (REPRODUCED via /tmp test). FIX: `.replace(/'/g, "'\\''")`
   on the stringified JSON at both sites (the `_jsonEscape` pattern `_post` already used).
   Dashboard._save is safe (validated ids only).
3. **Remote filename → local RCE** — `openConfigFile` sanitized only `/`+`\` from the
   Moonraker-supplied name building the `-o '<out>'` path; name with balanced quote pair
   (`x'$(cmd)'y.cfg`) escaped → executed (REPRODUCED). FIX: name filtered to `[A-Za-z0-9._-]`.
4. **Moonraker error bodies read as success** — `data.result || data`; `{"error":…}`
   (e.g. 502 klippy-down) → status={} → connected=true + all zeros + misses reset → demo
   never engaged while Moonraker up/klippy down. FIX: `data.error || !data.result` (or
   !status for objects) → `_miss()` in all three handlers (objects/info/tempstore).
5. **Process-slot kill race (risk)** — `_pick(slot%5)` reused a slot whose curl was still
   in flight (up to 5s max-time vs 2s poll), killing it; empty late stream-finished could
   hit the new handler (-> `_miss`). FIX: `_freeSlot()` — never kill, DROP the request if
   all 5 busy (demo then engages slower offline, ~12s, acceptable).
6. **Settings.qml missing `refresh()`** — `MainWindow.refreshView("settings")` threw
   TypeError (found as 1 WARN in post-fix boot). FIX: `function refresh() {}`.
Boot verification: 0 warn/err with all printers OFF (demo path incl. probe counter).
Injection retests (exact command shapes, /tmp targets): both neutralized.

## CURRENT STATE (2026-09-22 — machine/settings/lint round) — SUPERSEDED by START HERE; kept for geometry/vocabulary history
Read the SESSION 9 + 9b + ROUND 2/3 blocks for current view set, behaviors and
card geometry. Earlier "SESSION 2.x" geometry notes below are SUPERSEDED (heights
changed in every later round). Verified after every batch: `qmllint --silent
shell.qml src/**/*.qml` exits 0 with ZERO unqualified warnings + `bash -n
install.sh` OK + per-view boot loaded=1 warn/err=0. Not a git repo. Template
copy `~/dev/templates/klip-shell` is byte-identical/pristine — DO NOT MODIFY;
it is a REVERT SOURCE ONLY for pre-SESSION-2.x work (drifted on card heights).

## ROUND 2 APPLIED (2026-09-22 — claude handoff quickklipshell-tweaks/, VERIFIED)
Originals of the 7 patched files backed up at /tmp/klip-shell-pr2-backup/ before
apply (only revert source for round2 — templates dir has drifted, see above).
- history job key `state`→`status` in MoonrakerService demo seed + fileStateOf
  (real Moonraker field; History.qml already read .status)
- `.hovered`→`containsMouse` on all 10 MouseArea sites (Button×3, ListRow,
  Dashboard rf, MainWindow nav, Files rch/up/drow/frow — all have
  hoverEnabled:true). Card/Panel HoverHandler.hovered untouched (real prop).
- Dashboard._macroVariant(name): CANCEL/ABORT/ESTOP→danger,
  PRINT_START/RESUME→primary, else soft (user printer.cfg names = loose match)
- Layermind visual pass: printer+live-dot status row, KV rows, diagnostic list
  with keyword-guessed color (error/fail/critical→error, warn/caution/clog→
  tempWarm, " ok"/pass/good/complete→tertiary) + dot + tinted row
- in_progress vocab fix (real API says "in_progress", not "printing"): demo seed,
  Files badgeLabel/badgeColor (+"in_progress"), History.statusColor→accent
- null-ps guard in Dashboard MACHINE card message Text (?? "" pattern) — kills
  boot warnings "Cannot read property 'printMessage' of null"
- VERIFICATION: qmllint glob + bash -n pass; per-view boot cycle (console/files/
  history/machine/settings/layermind all Configuration Loaded, 0 warn/err);
  activeView restored to "dash".

## ROUND 3 (2026-09-22 — view audit round, VERIFIED same as round 2)
- Console VIEW key bug: view-switch keys (1-7, h/j/k/l, arrows) ran BEFORE
  console input, so digits/G-code letters were unsendable from the Console
  view (Dashboard's own console routed first — proof of intent). keyCatcher
  now routes console first; Esc clears pending, second Esc → dash (regression
  caught on review: first pass swallowed empty-pending Esc → dash).
- Console scrollback: lines move inside a Flickable (Machine/Files pattern,
  contentHeight = lines*20, wheel scroll). Pin-to-bottom auto-scroll:
  `_stickBottom` flag set in onContentYChanged (true when within 8px of
  bottom); `_stickToBottom()` called after store fetch/send; Flickable has
  writable `contentY` (verified in QtQuick plugins.qmltypes).
- Files keyboard nav: cursor state + handleKey (j/k + arrows move,
  Enter/Right/l opens, Backspace/Left/h up-dir) routed from keyCatcher via
  filesView.handleKey + event.accepted check; click pick() aligns cursor;
  cursor highlight on up/dir/file rows (`_rowIndex`), distinct from
  selName's selectedFill; cursor reset on enterDir/upDir/pickRoot/reload.
- Settings palette hover now live: swatch MouseArea (hoverEnabled) +
  onHoveredChanged → root.hoverRole; label shows "role: <name>", border
  brightens; was dead UI ("hover the palette dots for role names").
- History: header "JOBS · N" + empty-state line. Machine: UPTIME KV via
  uptimeFmt (proc.system_uptime; demo lacks the key → "—").
- KEYS CONVENTION (round 3): console owns ALL keys while active (Esc clears
  pending / dash on empty); files owns j/k/h/l/arrows/Enter/Backspace;
  numbers 1-7 switch views everywhere else. Settings editing + ConfirmDialog
  still preempt everything.

### Card heights (dynamic fns in Dashboard.qml; panelDefs h = fallback only)
- status 292+26n (n = recentFiles, ≤5) — REVERTED here on user request; do NOT shrink
- temperature 400 (TempGraphCard fills card via anchors.top+bottom)
- toolhead 428
- misc 82+40n (n = fans; 38 when none)
- extruder 448
- macros 160
- machine 196
- console 110+26n (n = consoleLines, ≤5)

### Toolhead card (order top→bottom)
Jog 3-col X/Y/Z (− value +, row height 68) → MOVE label + 0.1/1/10mm chips
(label ABOVE chips, both centered) → HOME ALL/XY/Z + MOTORS OFF → Z-OFFSET
(label centered over the −0.0mm value) → SAVE Z (ENDSTOP)/(PROBE) → separator →
SPEED drag-slider (M220, speedRow). NO flow slider here — the only FLOW slider is
the extruder card's (flowDrag, M221); the toolhead flowRow duplicate was deleted.

### Extruder card (order top→bottom)
HOTEND/BED rows (live temp → target TextInput — velocity-limits pattern, commit
sends SET_HEATER_TEMPERATURE HEATER=<name> TARGET=<n>, ° suffix) → FLOW slider →
PRESSURE ADVANCED ±0.01 → SMOOTH TIME ±0.01 → separator → ONE 38px band:
presets LEFT + RETRACT/EXTRUDE RIGHT (same height, Item-wrapped) →
5/10/25/50mm chips right-aligned UNDER the buttons (Item-wrapped).

### Machine card
Message Text (visible ONLY when displayMessage/printMessage non-empty — no "idle"
fallback) → separator → 4 editable limit rows (VELOCITY / SQUARE CORNER /
ACCELERATION / MIN CRUISE RATIO, SET_VELOCITY_LIMIT on edit). User wants the
ROWS kept; only the "VELOCITY LIMITS" heading + idle text were to go (first pass
over-cut the rows — page 2.16).

### Panel.qml header
Full-width accent band (fill alpha(accent,0.12), 2px border alpha(accent,0.40)
running ON the card's own border path → header + card read as one frame),
centered accent title on top; grip/chevron/collapse untouched. Replaced the old
floating centered chip.

### Demo mode (MoonrakerService) — temporary, REMOVE entirely after v1 (user)
No manual toggle. Auto-on after 2 missed polls (_miss). Auto-exit: every 15th
demo refresh calls _probeDemo → direct _fetch of /printer/info bypassing _get's
demo guard; parse success → demo=false + refresh(); failure → stays demo.
reconnect() and selectPrinter() also set demo=false. DEMO chip = pill+filled
tempWarm on the STATUS progress card. Probe = 1 curl / 30s cost at work.

### Sheen/gradient recipe (cards)
3-stop vertical gradient: alpha(surfaceText,0.05) @0.0 → 0.0 @0.45/1.0. Applied on
Card.qml root, MainWindow bodyCard Rectangle (Console view has zero Cards), and
Panel.qml body rectangle. User confirmed good.

### Other current facts
- Review tar klipshell-review.tar.gz (repo root, 84K) REGENERATED 2026-09-21
  evening from the final tree: `tar czf klipshell-review.tar.gz --exclude='*.tar.gz'
  --exclude='.pi' --exclude='info' AGENTS.md install.sh shell.qml .qmllint.ini
  assets src klipshell-tweaks -C ~/.pi/agent/projects-memory/klipshell MEMORY.md`
  (project memory stitched in as MEMORY.md; verified byte-identical on extract).
  Regenerate again before any future handoff — it captures tree state at creation.
- activeView = "dash". Views: Dashboard / Console / History / Machine / Settings /
  Layermind (Files view DELETED 2026-09-22 — Machine FILES card is the only files
  surface). Num keys: 1 dash, 2 console, 3 history, 4 machine, 5 settings, 6 layermind.
- presetStore QtObject in MainWindow → ~/.local/state/klipshell/presets.json;
  dashboard.json persistence {order, panels}; demo probe hits real Moonraker.
- Deferred backlog unchanged: mouse.hovered→containsMouse (~9 sites), UPLOAD
  button in Files, accel_to_decel (printer omits the key), SESSION 3 nav views.


# Omarchy visual overhaul + Mainsail parity (done, verified all 9 views boot)
- Type rescaled (kept old token NAMES, only values): caption 10 / small 12 / body 13 / title 14 / heading 16 / large 20 / medium 24 / xlarge 28.
- Metrics: controlHeight 28, rowHeight 30, panelPadding 18, radiusSmall/Med/Large 6/10/14, gaugeTrack 4, gaugeKnob 14.
- Colors: +hoverFill(0.08), pressedFill(0.22), separator(0.12), urgent(=error), `function alpha(c,a)`.
- New components: Button (variant primary|danger|plain|soft; use `active:` NOT `enabled`, and MouseArea uses `enabled`); Slider (PanelSlider port: animated fill/knob 140ms OutCubic off while dragging, knob scale 1.15 hover, drag+wheel, moved/released; trackArea members knob/thumbStart/usable — never name a member `left`, shadows anchors.left); ConfirmDialog (scrim alpha(bg,0.7), centered card, keyboard handleKey); Hero (title+detail pill+upper meta; `titleRightMargin` to clear a side % readout); Chip gained `pill:true` variant.
- Service core query: +display_status,gcode_move,heater_generic,fan → normalizes fanPower, speedFactor, flowFactor, displayMessage, heaters[]. Added fetchFileMetadata, deleteFile, `_fileUrl` (encodeURIComponent per segment, keeps "/").
- Dashboard: Hero print card, big % (right-reserved), 8px gauge, action row (CANCEL/E-STOP → ConfirmDialog), FAN/SPEED/FLOW, animated thermal gauges + presets, TOOLHEAD+part-cooling, KIPPER pill+display_message.
- Controls: 5 tabs incl TUNE (Slider SPEED=M220, FLOW=M221, FAN=M106 S{v*2.55}); MACROS via Flow.
- Machine: SYSTEM+sysinfo(HOST/DISTRO/CORES), ENDSTOPS, UPDATE MANAGER Flow (version_info chips + dirty ⚠ + is_valid).
- Files: two-pane (root chips + list select→fetchFileMetadata + DETAILS panel + PRINT/DELETE w/ confirm).
- Queue: confirm on delete, j/k/h/l keys, state pill.
- MainWindow: ONE ConfirmDialog (z:100) + confirmBridge QtObject ask(msg,{confirm,destructive,onConfirm}); views get `confirmDialog: win.confirmBridge`; keyCatcher `Keys.priority: Keys.BeforeItem`, routes keys to dialog when open, vim h/j/k/l/x.

## Gotchas (new)
- **shot app CANNOT verify quickshell config loads.** `shot app ... -- quickshell -p .` produced logs with NO "Launching config"/"Configuration Loaded" INFO lines and near-identical ~979KB PNGs for every view — the config never loaded in that context. ALL earlier "0 errors, all views boot" claims built on it were VOID. User's live `quickshell -p .` is ground truth.
- **WORKING VERIFICATION (no screenshots):** `WAYLAND_DISPLAY=wayland-1 timeout 7 quickshell -p . > /tmp/qs.log 2>&1 &` + sleep + `pkill -x quickshell` (NOT `pkill -f "quickshell -p"` — that substring matches your own shell and kills it, exit 143) + grep the log for `Configuration Loaded`/WARN/ERROR. Runtime warnings only appear when the offending view is the active one — cycle `activeView` to exercise each.
- **Rectangle has NO `padding` property** in this Quickshell (`Cannot assign to non-existent property "padding"` at boot). Use `anchors.*Margin` on the child Column instead. (Item-derived types vary per build — check the qmltypes before using Item-ish sugar.)
- **qmldir FORMAT IS `Type 1.0 File.qml` PER LINE** — bare type names (`Card`) fail the whole components import with "a component declaration requires two or three arguments, but 1 were provided" at the import site. webb-shell format: `AppText 1.0 AppText.qml`.
- **`qmllint --silent shell.qml src/**/*.qml` LINTS NOTHING** — bash needs globstar for `**`. ALWAYS `qmllint --silent $(find . -name '*.qml' -not -path './.pi/*')`. Even so, qmllint does NOT catch unknown-property/runtime issues (padding bug passed lint) — the direct-run boot check is the real gate.
- qmlls "component declaration requires two or three arguments" on components were REAL (qmldir), not phantom.
- PER-VIEW SED TARGET: `src/views/MainWindow.qml:23` (`property string activeView: "dash"`), NOT shell.qml.
- Anchor arithmetic illegal: `anchors.left: parent.left + 170` → `x: 170` (this exact one was in Dashboard thermal Gauge, produced "Unable to assign QString to QQuickAnchorLine").
- Stale Metrics token bug: Console used `Metrics.sectionSpacing` (doesn't exist; it's `sectionGap`) → "[undefined] to double" warning.
- Use `grep -ci error`/`-ci WARN` (case-insensitive) or you miss `ERROR:`.
- vision-gate: screenshot `read` returned only the "switched to deepseek vision-exp" text this session; observations never delivered into context. Could not pixel-verify; verified structurally. Montage: /tmp/ks-rework-montage.png.
# Temp graph milestone (Mainsail parity round 2) — verified boot, lint clean
- New view Temp (key `2`, was Queue; Layermind moved to `0`). Sidebar list height now
  `win.ordered.length * 32`. Temperature_store rides the CORE 2s poll (3rd slot).
- Service: `_handleTempStore` parses `result.temperatures/targets/speeds` (dicts of
  float arrays, oldest→newest, default 1200 pts) into `state.tempStore.series`
  [{name, temp[], target[]}]. Verified shape from moonraker readthedocs external_api.
- Chart.qml (new component): Canvas vectors + Text OVERLAYS (canvas context has NO
  fillText in this QtQuick — labels are Items bound to computed geometry).
  Auto y-scale (niceStep 1/2/5×10ⁿ gridlines), glow strokes (0.14 w6 / 0.3 w3 / core 1.8),
  dashed targets (no setLineDash — hand-rolled moveTo/lineTo segment loop), hover
  crosshair via MouseArea.mouseX/mouseY + onMouseXChanged/onMouseYChanged/
  onContainsMouseChanged (all exist; containsMouse notify is onContainsMouseChanged).
- Gotchas hit this round:
  - `required property var x: []` is a SYNTAX ERROR — required props take no initializer.
  - Item BASE has a `scale` property — chart's y-scale was renamed yScale.
  - Placeholder Text with `anchors.centerIn` INSIDE a Column → runtime WARN "Column will
    not function" (4x). Column ban is on vertical anchors; use horizontalCenter + explicit y.
  - Delegate nested children: easiest zero-warning pattern is `id: leg` on the delegate
    Item + `leg.chipLabel`/`leg.modelData` refs (BOUND pragma); unqualified modelData in
    delegates is the accepted pre-existing warning class, but id-qualifying keeps per-file
    LSP clean too.
- ponytail: target drawn as ONE dashed line from latest target value (targets array has
  per-point history; stepped targets later if ramp display needed).
- Mainsail gap backlog (verified API shapes ready): Power view
  (GET /machine/device_power/devices, POST /machine/device_power/device {device,action} —
  batch POST /on|/off {dev:null}; states on|off|init|error, locked_while_printing), Sensors
  view (GET /server/sensors/list[?extended], values, parameter_info units), WLED
  (/machine/wled/strips, /status, /on|/off|/toggle|/strip), webcam (snapshot polling),
  console suggestions/history, macro prompts, object exclusion, config file editing.

# CRITICAL Quickshell gotcha (found via live shot-app capture) — Repeater + 0-width delegate
- Repeater delegate of type `Item` or `Rectangle` with `height` but NO `width` renders
  NOTHING (0-width collapse, invisible + unclickable). Item/Rectangle do NOT auto-size to
  children (unlike Column/Row). Fix: `width: parent.width` on the delegate.
- This was the root cause of "can't select printers" AND "views not listed": the sidebar
  nav Repeater + printer Repeater (and Dashboard thermal rows, Files list, Machine
  endstops, Queue rows, History rows) all used bare `Item` delegates with no width → all
  invisible. One-line-per-delegate fix (7 delegates across 7 files).
- Verified with isolated repro /tmp/ks-test: delegate Item NO width = empty; +`width:
  parent.width` (or explicit width) = renders. Dashboard preset chips rendered only
  because `delegate: Button { width: 58 }` set explicit width.
- VERIFICATION PATH THAT WORKS: `shot app /tmp/x.png -- quickshell -p .` — config loads
  ("Configuration Loaded" NOT phanton here) AND captures a real PNG. Earlier memory note
  that shot app "cannot verify" was WRONG/void — it works now. Live `read` of PNG via
  vision-gate shows real layout. USE THIS for pixel-verification (much better than the
  pkill+grep log-only ritual).
- MOUSEAREA has NO `hovered` property (internal name only) — QML uses `containsMouse`.
  `mouse.hovered` used ~9x across src (Button, ListRow, Files, Queue, Controls,
  MainWindow) is BROKEN (always falsy → hover highlight never shows). Cosmetic; fix later
  with `containsMouse`.
- Window opens FULL-WIDTH (~1920) not implicitWidth 1000 — sideStrip 166 + huge body
  (cards stretch). Fine for a shell; note for layout polish later.

# CONNECTION BUG ROOT CAUSES (found 2026-09-20 with V2.4 on at 192.168.1.50:7125)
TWO separate bugs kept the app showing off-placeholders (0.0°, "connecting…") even
though the printer was reachable and curls returned real data:
1. `_dispatch` called handlers as `handler(printerName, raw)` passing a STRING, but every
   handler is `function(cfg, raw)` reading `cfg.name`. String has no `.name` → cfg.name
   undefined → `_commit` skipped persisting (`if (state.name)` false) → `active` stayed null.
   FIX: store the cfg OBJECT on the process (`property var _printerCfg`) and pass it.
2. `_commit` reassigned `active` to the SAME shared object reference (mutated in place by
   handlers). QML `property var` + same-reference reassignment does NOT fire bindings, so
   nested-field reads (`ps.extruderTemp`, `ps.connected`) that were cached at first bind
   (before the field existed) stayed undefined forever. Fields present at first bind
   (klippyState) showed; later-added fields didn't.
   FIX: `root.active = Object.assign({}, dict[activePrinter])` — a FRESH object each commit
   → identity changes → bindings re-fire → all nested fields re-read.
LESSON: In QML, mutating a JS object's fields in place is INVISIBLE to bindings. If a JS
object feeds bindings, reassign `property var` with a NEW object (shallow copy) each time.
(Symptom signature: some fields show real data, others stay at stale/undefined from the
same `ps` object.)

# CONNECT UX (added same day)
- MoonrakerService: `readonly property bool connected: active?.connected === true`;
  `function reconnect()` (resets _missCount + refresh; selects printers[0] if none).
- MainWindow: global "NO PRINTER CONNECTED" body overlay (z:10, above bodyCard, below
  confirmDialog), `visible: !MoonrakerService.connected`, with msg + RECONNECT Button.
  Sidebar printer column has a CONNECT/RECONNECT Button + clickable printer rows (selectPrinter).
- Overlay hides automatically on reconnect (2s poll auto-connects). Verified both states:
  connected (real temps/X/Y/Z) and all-off (overlay). V2.4 active shows green ● ready dot.
- We only poll the ACTIVE printer, so "all off" ≈ "active printer unreachable". If another
  printer is on but not active it won't be detected until selected. (ponytail: acceptable now;
  multi-printer polling is a later feature.)

# klipper-mcp servers (voron-02/18/24) ARE real + reachable; V2.4 = 192.168.1.50:7125 (BTT-CB1)
- MCP servers voron-02/18/24 connect to the three printers. Use to query live state:
  voron-24_get_server_info (klippy_ready etc), voron-24_get_printer_status (temps/position).
  MCP connects via its own bridge; klipshell itself polls Moonraker HTTP directly.
- V2.4 PRINTER IS NOW ON: klippy state "ready", hostname BTT-CB1, moonraker v0.11.0.
  curl http://192.168.1.50:7125/printer/info & /printer/objects/query?extruder&heater_bed work
  from harness. temps ~25°C (room temp). Useful for VERIFYING live data rendering.

# Verification path that works reliably (as of this session)
Run bg + capture settled: `WAYLAND_DISPLAY=wayland-1 quickshell -p . & QPID=$!; sleep 6;
WS=$(hyprctl clients -j | jq -r '[.[]|select((.class//"")|test("quickshell";"i"))]|
map(.workspace.id)|unique|.[0]'); shot onws $WS /tmp/x.png; kill $QPID`.
THEN read the PNG with vision — pixel-verifies real rendering. Use `pkill -x quickshell`
(never `pkill -f 'quickshell -p .'` — that matches your own ctx_shell cmdline and SIGTERMs it,
exit 143).

# Debug trace method that worked
console.log with a distinctive prefix (e.g. "KS OBJ") > quickshell log.log
(`/run/user/1000/quickshell/by-id/*/log.log`) — grep `-a "KS "` there. QML console.log lands
in log.log (not stdout).

# BLANK-VIEW BUGS — three parsed-shape mismatches with Moonraker (found 2026-09-20)
With V2.4 reachable, several views rendered empty because the per-view fetchers parsed the
Moonraker response shape wrong. NEVER assume `.result` is an object with the expected wrapper
— check the live shape first (curl -s HOST/path | jq '.result').
1. `GET /server/files/list?root=gcodes|config` → `.result` is a BARE ARRAY of {path,modified,size,...}.
   Old handler did `r.file_response||r.files||r.gcodes||r.dirs` on the array → all undefined → [].
   FIX: `var res = Array.isArray(r) ? r : ((r&&(r.files||r.gcodes||r.dirs))||[])`.
2. `GET /server/temperature_store?include_monitors=false` → `.result` is an OBJECT keyed by sensor
   name ({extruder:{temperatures:[...],targets:[...]}, "heater_bed":{...}, "temperature_sensor X":{...}, ...}).
   Old handler read `r.temperatures` (undefined) → empty series → "no temperature history yet".
   FIX: iterate `r` (the sensor map), read `obj.temperatures`/`obj.targets` per name. The live printer
   reports 6 series (extruder, heater_bed, BTT-MCU, BTT-PI, cartographer, cartographer_coil).
3. `GET /server/job_queue/status` → `.result` keys are `queued_jobs` + `queue_state` (not `state`).
   queue_state was parsed as `r.state` (undefined). FIX: `r.queue_state || r.state`.
+ `proc_stats` returns `{moonraker_stats[], system_cpu_usage, system_memory, cpu_temp, network}` —
  NOT `{cpu:{...}, mem:{...}}`. Machine view should read system_cpu_usage/system_memory.
NOTE: gcode_store is EMPTY (0) on this printer and there are 0 gcode_macro objects — so Console
history + the MACROS tab are genuinely sparse, not bugs. Queue queued_jobs is empty (standby).

# REWORKS shipped 2026-09-20
- Printer selection: REMOVED the bottom-left sidebar printer Column. Added a header chip
  (top-right, "● <activePrinter> ▾") that opens a popup (`win.printerMenuOpen` → Rectangle z:70,
  list of printers, click=selectPrinter+close). Click-away overlay z:65 closes it.
- Temp graph moved INTO the Dashboard: new reusable `src/components/TempGraphCard.qml`
  (legend chips + TARGET toggle + Chart + empty text), driven by `store` prop
  ({name,temp[],target[]}). Used in Dashboard's "TEMPERATURE" card. Temp tab + Temp.qml removed.
- Dashboard body is now a scrollable Flickable (cards: Hero / Thermals+Toolhead Row / TEMPERATURE).
  Row height fixed to 260 (was `parent.height - 150 - lg`, which breaks inside a Flickable).
- Chart.qml: ADDED gradient area fill under each series (vertical LinearGradient color@30%→0%),
  drawn before the glow strokes. This is the "amazing graph" recipe (Canvas gradient + glow).

# Reusable component lesson
Card.qml children are NOT auto-offset below the header — wraps content with
`Column { anchors.top: parent.top; anchors.topMargin: panelPadding+6; ... }` (see other cards).

# Dashboard→Mainsail parity roadmap (klip-tui/src/ui/views + MAINSAIL_GAP_ANALYSIS.md are the reference)
Dashboard still missing vs Mainsail: settable temps, fan/speed/flow sliders (TUNE tab in klip-tui),
macros panel (gcode_macro list + run), more readouts (filament %, layer, live speed/flow, ETA,
Busy state, print_stats.message), toolbar buttons (exclude-obj, pause-at-layer, reprint,
clear-stats, cancel confirm), job queue badge, power devices. See klip-tui's controls.rs/tuning.rs
for how klip-tui built these (pressure_advance, can_extrude, babystep, etc.).

# CONTROLS VIEW — was ALSO "showing nothing" (0-height Item) [found 2026-09-20]
The Controls tab content was empty for the SAME class of bug as the other views, but never
diagnosed (summary mislabeled it "genuinely sparse"). Root cause: each per-tab wrapper was a
bare `Item { width: parent.width; visible: tab===N; Column{anchors.left;anchors.top;...} }`.
A bare Item has implicitHeight 0 → the Column gives it 0 space, top-anchored children never
lay out → empty body. FIX for all 5 tabs: wrapper Item → auto-height Column:
  Column { width: parent.width; visible: tab===N; spacing:0; Column { width: parent.width; spacing:X; ...content } }
LESSON: an `Item` with only top/left-anchored children contributes 0 height in a Column/positioner.
Wrap tab/panel content in a `Column` (auto-height), never a bare `Item`. Same bug as Repeater
delegates needing explicit width — the "Item needs explicit size" family.

# MAINSAIL SETTERS added to MoonrakerService (all via sendGcode/gcode_script)
setHeaterTemp(name,target)→SET_HEATER_TEMPERATURE HEATER=<name> TARGET=<t>
setFanPercent(pct)→M106 S<=pct*2.55> (M107 at 0); setSpeedFactor→M220 S; setFlowFactor→M221 S
jog(axis,dist,speed)→G91\nG1 <axis><dist> F<speed*60>\nG90
moveHomeAll/XY/Z→G28 / G28 X Y / G28 Z; motorsOff→M84
zAdjust(delta)→SET_GCODE_OFFSET Z_ADJUST=<d> RELATIVE=1; zOffsetApply("endstop"|"probe")→Z_OFFSET_APPLY_* / SET_GCODE_OFFSET Z=0
extrude(amount,speed)→M83\nG1 E<amt> F<speed*60>\nM82
ADDED state.zOffset = status.gcode_move?.homing_origin?.[2] ?? 0 (previously unparsed).

# CONTROLS TABS now (Mainsail-faithful)
MOTION = Mainsail toolhead: POS x·y·z + Z-offset readout; MOVE distance presets 0.1/1/10mm (root.dist);
X/Y/Z jog rows [− value +] (X/Y @100mm/s, Z @20mm/s); HOME ALL/XY/Z; MOTORS OFF; Z BABYSTEP ±0.05/±0.01
(root.moonraker.zAdjust); SAVE Z (ENDSTOP)/(PROBE). EXTRUDE = extruder temp setter (−5°/+5°/OFF, root.setExtruderTemp)
+ AMOUNT presets 5/10/25/50 (root.extAmount) + EXTRUDE/RETRACT via moonraker.extrude.
TUNE holds speed/flow/fan sliders (M220/M221/M106). MACROS auto-discovers gcode_macro objects.

# WAYLAND-1 path quirk
`shot onws` path uses WAYLAND_DISPLAY=wayland-1 for quickshell. When the agent terminal sits on the
active WS, `shot` copies the terminal — use `shot onws`. Session is detachable; pkill -x quickshell.

# ─── MAINSAIL DASHBOARD PARITY — 3-SESSION PLAN (authoritative, pending) ───────────
Status: PLAN, not yet started. Start Session 1 next (new session). User explicitly
requested this be broken into 3 sessions and recorded here.

# MANSAIL REPO
Cloned at ~/dev/mainsail (Vue 2.7, git c1fe3e5, ~9.5MB, --depth 1). KEY FILES for reference:
- src/store/gui/types.ts: GuiStateDashboard = {viewport}Layout{N} arrays; `GuiStateLayoutoption {name, visible}`.
- src/store/variables.ts: `allDashboardPanels` = [afc, toolhead-control, extruder-control, macros,
  led-effects, machine-settings, miniconsole, miscellaneous, spoolman, mmu, temperature, webcam].
- src/store/gui/getters.ts: `getAllPossiblePanels` (base list + conditional removal: kinematics none
  → drop toolhead/machine-settings; extruderCount<1 → drop extruder; sensors<1 → drop temperature;
  no webcam → drop webcam; no spoolman/mmu/afc/led_effect → drop those). `getPanels(viewport,column,onlyVisible)`
  composes a column: takes saved order, appends any missing possible panel with visible:true, filters by visible.
- src/pages/Dashboard.vue: responsive viewport (mobile=1col/tablet=2/desktop=2/widescreen=3). ALWAYS renders
  StatusPanel pinned at top of col 1, then `<component :is="name-panel">` per entry (name_x → id x).
  Panel components registered in this file (StatusPanel, TemperaturePanel, ToolheadControlPanel,
  ExtruderControlPanel, MiniconsolePanel, MacrosPanel, MachineSettingsPanel, MiscellaneousPanel, …).
- src/components/ui/Panel.vue: the card shell — v-card + v-toolbar (title/icon/collapse button) + expand-transition.
  In klipshell this is the model for a reusable `Panel.qml`.
- src/components/settings/SettingsDashboardTab.vue: the customize dialog — toggle {name,visible}, reorder;
  order persists via Vuex → localStorage.
- src/components/Temperature/*.vue: TemperaturePanel + ListItem + Presets + settings + chart series edit (
  the temp panel Mainsail has: per-sensor target entry, presets, chart, add/remove additional sensors).
- src/components/mixins/dashboard.ts: getPanelName (i18n headline) + convertPanelnameToIcon.
- src/routes/index.ts: sidebar nav routes — / (dashboard), /console, /heightmap, /files, /viewer, /history,
  /timelapse, /config, /settings/machine. The user's target nav: Dashboard, Console, Heightmap, Gcodefiles,
  3D GCode Viewer, History, Machine.

# GOAL (from user)
klipshell Dashboard = Mainsail-style cards (standby/status, temperatures, toolhead, extruders, console,
macros, machine, misc) that are individually MOVABLE + SHOW/HIDE-customizable. Keep the current TempGraphCard
as the Temperature card (graph stays as-is).

# SESSION 1 — Reorderable/customizable Dashboard card system (FOUNDATION)
- Reusable `src/components/Panel.qml` card shell (header/icon + collapsible) modeled on Mainsail Panel.vue.
- Dashboard panel model: ordered `[{name,visible}]` + registry (all possible panels). Keep it simple: a
  property/model on the Dashboard, or a small settings store if it needs persistence.
- Dashboard → 2-column grid (Mainsail desktopLayout). Col1: Status(print hero, pinned/non-removable) + Temperature
  (TempGraphCard). Col2: Toolhead, Extruder, Macros, Machine, Console, Misc — each wrapped in Panel.qml.
- Customize dialog (gear on dashboard): toggle each visible, reorder. Persist order to config so it survives restarts
  (via MoonrakerService or a settings store; klipshell has no global store yet).
- Reorder: LAZY — "up/down" pill per card in the dialog (skip fancy drag unless it feels lacking).
- Reuse existing cards: Dashboard hero (Status), TempGraphCard (Temperature), Machine.qml content (Machine),
  Console.qml (MiniConsole), Controls.qml toolhead/extruder (Toolhead/Extruder cards), MACROS tab (Macros card).

# SESSION 2 — Mainsail-parity panel CONTENT
- Status: busy/printing/paused/error/complete + filename + progress + time/ETA + print_stats.message + filament
  used/remaining + layer.
- Temperature: per-sensor settable target (click + steppers + presets) — we have presets + TempGraphCard; add
  per-sensor target entry (Mainsail TemperaturePanelListItem behaviour).
- Toolhead: bars/cross jog + position + home + Z-offset (move Controls toolhead into a card, keep Controls page).
- Extruder: temp set + retract/extrude + amount/speed presets (Mainsail ExtruderControlPanel).
- Macros: auto-discovered gcode_macro grid → run; card + full Macros view.
- Machine/Console/Misc: readouts, mini console, misc actions.

# SESSION 3 — New nav views + full settings
- Heightmap view (bed_mesh grid + stats; refs: klip-tui heightmap.rs, Mainsail HeightmapPanel).
- 3D GCode Viewer (start: Klipper gcode thumbnail + live pos; later real path preview).
- Nav realignment to Mainsail: Dashboard, Console, Heightmap, Gcodefiles, Viewer, History, Machine; refold/keep
  klip-tui extras (Queue, Controls, Layermind) deliberately.
- Settings (Mainsail Settings tab equiv): panel card config, printer, macros, general — persisted.
- Final polish pass.

# DONE THIS SESSION (2026-09-20, before the plan)
- TempGraphCard legend overlap FIXED: added `shortName(name)` (last space token, e.g. "temperature_sensor BTT-MCU3"→"BTT-MCU3");
  legend Row{height:26;clip:true} → `Flow{id:legend}` (wraps, no clip/overlap); Chart height now
  `Math.max(120, parent.height - legend.height - Metrics.lg)`. Graph unchanged. Verified render, 2 wrapped chip rows.
- Mainsail repo pulled + architecture mapped (above).

# REMAINDER: current klipshell state (context for a fresh session)
- Views/nav: Dashboard, Queue, Console, Files, Controls, History, Machine, Settings, Layermind (no Temp tab —
  temp graph embedded in Dashboard). Printer selector = header chip "● <printer> ▾" → popup.
- MoonrakerService has Mainsail setters (setHeaterTemp, setFanPercent, setSpeed/FlowFactor, jog, moveHome*,
  motorsOff, zAdjust, zOffsetApply, extrude) + state.zOffset. Controls view has MOTION(toolhead)+EXTRUDE tabs.
- Reusable components: Chart.qml, TempGraphCard.qml, Card.qml, Button/Chip/Gauge/Slider/KV/ListRow/PanelSectionHeader.

# SESSION 1 DONE (2026-09-20pm) — Reorderable/customizable Dashboard (Mainsail foundation)
Implemented exactly per the 3-session plan's Session 1. Verified: lint exit 0, boot clean
(zero WARN/ERROR) on 3 layouts: default, customized seed (console first, machine collapsed,
toolhead hidden), corrupt-file (recovered to defaults, one intentional error log from the catch).
Files: src/components/Panel.qml (new), src/views/Dashboard.qml (rewrite), MainWindow.qml (keys).

## Model (the part that took two bug rounds)
- panelDefs registry `[{id,label,h,pinned,fixed}]`; `panels` = [{id,visible,collapsed}] full list;
  `col2Ids` = ordered ids of non-pinned panels. COL2 rendering + dialog BOTH use `col2Ids`.
- **Critical design**: panels reassigns on every toggle (fires pVisible/pHeight/pCollapsed bindings
  WITHOUT rebuilding col2 — col2Ids identity unchanged). col2Ids reassigns ONLY on movePanel/load
  (rebuild needed for reorder). Decoupling these two is what kills the nested-Repeater
  null-parent warnings.
- Persistence: ~/.local/state/klipshell/dashboard.json (Layermind-style path). Save: Process
  bash -c `mkdir -p <dir> && printf '%s' '<json>' > <file>` — safe because JSON.stringify emits no
  single quotes / $ / backticks. Load: cat 2>/dev/null, skip pinned + unknown ids (hasDef guard),
  merge missing defs, `_syncCol2Ids()`.
- status = pinned+fixed (col1, always, not in dialog); temperature = pinned (col1, not in dialog);
  col2 = toolhead/extruder/macros/machine/console, all hideable/collapsible/reorderable.
- Panel.qml (calls contract): title required, collapsible/collapsed props, toggled() signal,
  `bodyTop`/`bodyVisible` readonlys. Caller sets `height: root.pHeight(id)` + content Column
  `visible: parent.bodyVisible && leg.modelData === "<id>"`, anchored topMargin: parent.bodyTop.

## Gotchas hit (runtime, found via boot log)
- **Repeater delegate `width: parent.width` crashes with "Cannot read property 'width' of null"
  during Repeater REBUILD frames** (teardown/instantiation). Guard: `width: parent ? parent.width : 0`.
  Three sites guarded (X/Y/Z thirds, extruder rows, console lines). This fires whenever col2Ids
  reassigns (reorder/load) — nested Repeaters inside the col2 delegate are the trigger.
- **Row children may not use horizontal anchors** ("Row will not function") — Z-OFFSET row originally
  had a right-anchored Text inside a Row; wrapped as Item with left+right anchored Texts instead.
- Missing `visible: root.pVisible(id)` binding on the col2 delegate Panel = hide did nothing visually.
- pCollapsed/pHeight/pVisible must exist before binding (TypeError at bind time → fix = define them).
- StdioCollector with empty cat output → `JSON.parse("")` throws (guarded `if (!t) return`).
- Dashboard needs `import Quickshell.Io` for Process/StdioCollector (not just Quickshell).

## Session 1 UI
- Gear "⚙ LAYOUT" button top-right (Dashboard root, y:2, above Flickable — Flickable shifted down 30
  so the gear never overlaps col2's first chevron). Dialog: scrim z60 + popup z70 (▲▼/HIDE/SHOW/DONE),
  click-away to close. Modal closes only via DONE/click-away (no Esc — keyCatcher untouched).
- Status panel: Hero + % + gauge + PAUSE/RESUME/CANCEL/E-STOP (buttons shrunk to 88/84/84 to fit 390px
  col; FAN/SPEED/FLOW readouts moved to Toolhead panel). Toolhead panel adds Z-OFFSET row.
- Console panel = last 6 gcode-store lines + "OPEN CONSOLE" (needs `openView` fn prop from MainWindow).
- MainWindow keys: 1-9 now = dash,queue,console,files,controls,history,machine,settings,layermind
  (Key_2 was dead "temp"); Key_0 alias removed.

## NOT verified (injection unavailable)
- Click-through of customize dialog (no ydotool on box). Read the dialog code; save/load round-trip
  proven (same JSON shape, load consumed seeded files). First real click test = user smoke: gear →
  HIDE one panel → DONE, confirm dashboard + ~/.local/state/klipshell/dashboard.json both change,
  then restart quickshell and confirm the layout survives.
- Panel heights are hardcoded per def `h` (col2H sums them). Extruder 232 fits hotend+bed+1 heater;
  3+ heaters will clip. ponytail: revisit in Session 3 polish.

# SESSION 2 (pending) — Mainsail-parity panel CONTENT (per plan)

# GOTCHA (found 2026-09-20pm, REVERTED a "clean boot" false-positive): BLANK dashboard
The FIRST ship of Session 1 rendered a COMPLETELY BLANK dashboard body (sidebar + gear +
printer chip + clock all fine) while the boot log was ZERO-WARN and qmllint exited 0.
Fix: add `width: parent.width` to every Panel.qml instance (status, temperature, and the
col2 Repeater delegate Panel).
ROOT CAUSE: Panel.qml root is an `Item` (implicitWidth 0). A Column/positioner does NOT
stretch children to its width — an Item child keeps implicitWidth 0 → renders NOTHING
(0 width, invisible, unclickable). The OLD cards all set `width: parent.width` explicitly;
my Panels only had `height`. Same bug family as the Repeater-delegate-Item-null-width note.
LESSON (this is the important one): **zero-width/zero-height Items are SILENT — the boot-log
zero-WARN gate and qmllint do NOT catch them.** A blank-but-clean boot must be pixel-verified.
For this project that means `shot app /tmp/x.png -- quickshell -p .` + `read` the PNG (vision)
OR at least ImageMagick `-colorspace Gray` pixel stats (median + count of bright>140 px —
a real dashboard has thousands of bright px; a blank body has ~50). Median ~27 + tiny bright
count = blank. 9000+ bright = content present. NEVER trust "Configuration Loaded + no WARN"
as proof the dashboard rendered.
Also: `Flickable` must NOT mix `y` with `anchors.bottom` (vertical-axis conflict). Use
`anchors.fill: parent; anchors.topMargin: N` to reserve a top strip below a floating button.

# SESSION 2 DONE (2026-09-20pm) — Mainsail-parity panel CONTENT
Per the 3-session plan's Session 2. All 6 bullets implemented, verified: lint exit 0, boot
zero WARN/ERROR on default AND customized persisted layout, corrupt-file recovers to defaults.
Files touched: src/moonraker/MoonrakerService.qml (3 new state fields), src/views/Dashboard.qml.

## Service additions (_handleObjects)
- state.filamentUsed = print_stats.filament_used (mm); state.layerCurrent/layerTotal =
  print_stats.info.current_layer/total_layer (need the print_stats object queried — it already is;
  info is a sub-object, no query change). layer hides when layerTotal==0 (standby/gcode-less file).
- reuse setHeaterTemp(name,target) → SET_HEATER_TEMPERATURE HEATER=name TARGET=t. For hotend the
  Moonraker name is "extruder"; bed is "heater_bed". heater_generic keys are full names and pass
  straight through. Root.ps.heaters[i].name is the RAW heater_generic key (good for setHeaterTemp).

## Dashboard rework
- STATUS (h 196): statusMeta() helper (printing/paused/complete/error/cancelled/standby meta line)
  + stats Row (layer x/total, fil <m>, print_menu message elided) + % + gauge + actions. Existing
  stateColor() handles the state hues. fil(mm)= mm/1000 2dp + "m".
- TOOLHEAD (h 238): position + Z-offset readouts + a Mainsail 3-axis JOG (Row of 3 columns
  [X/Y/Z], each [label][− pos +], root.jog(a,sign,feed)→moonraker.jog(a, sign*jogDist, feed)) +
  HOME ALL/XY/Z + PART COOLING/SPEED/FLOW. Removed the old big X/Y/Z readout (jog shows position
  inline). jogDist=1.0, jogFeed=40 (Z 20).
- EXTRUDER (h 300): per-sensor heater rows now have ±5 target steppers (root.setHeaterTarget(key,
  target, delta)) — the "per-sensor settable target" from the plan. Model uses {key(raw heater),
  label(shortName), temp, target}. + presets (PLA…) + AMOUNT presets [5/10/25/50mm] + RETRACT/
  EXTRUDE (root.extrudeRetract(sign)→moonraker.extrude(±extAmount, extSpeed)). Removed the
  redundant standalone HOTEND ±5 row (covered by per-row steppers).
- ADAPTATION vs plan: "Temperature per-sensor settable target" lives in the EXTRUDER sensor rows
  (the Temperature card is the graph; putting a full sensor list there too would bloat col1). The
  settable-target FEATURE is delivered; if the user wants it literally in the Temperature card,
  add a compact hotend/bed stepper strip above the TempGraphCard.
- MACROS: Flow grid exists (empty on this printer because 0 gcode_macro objects — environmental,
  not a bug). CONSOLE: last-6 gcode store + OPEN CONSOLE (empty on this printer, same reason).

## Gotchas
- New jog Repeater delegate `width: parent.width` → same transient null-parent on rebuild; guard
  `width: (parent ? parent.width - Metrics.md*2 : 0) / 3` (note the paren — 0 branch must yield 0,
  not -8; `parent ? w : 0 - x` groups as `parent ? w : (0-x)` → negatives).
- `font: Type.{...}` object literal is INVALID — tu "font.family"/"font.pixelSize" separately.
- Button `active:` is ENABLE (grey-out), NOT selection — can't use it for a selected-state highlight.
- TempGraphCard fills its parent (anchors.fill) and auto-sizes Chart to remainder — put the sensor
  target list OUTSIDE it; don't put content inside TempGraphCard (it's a reusable graph component).
- shot app grab issue: on some runs it captured the Moonraker browser window instead of quickshell.
  RELIABLE capture here: launch quickshell in bg (WAYLAND_DISPLAY=wayland-1 ... &), then
  `hyprctl clients -j | jq '.[]|select(.class=="org.quickshell")|.workspace.id'`, then
  `shot onws $WS out.png`. quickshell is a normal client (class org.quickshell, title
  "klipshell — Moonraker") on WS 3 here; `hyprctl activewindow` may return the terminal (ws 1).

# SESSION 3 (pending) — New nav views + full settings (per plan)

# SESSION 2.5 (2026-09-20) — full-grid drag + z-offset + text + temp-graph
User-requested features. Verified: lint 0; boot zero WARN/ERROR on default AND reordered/collapsed/
hidden layout; corrupt-file recovers to defaults; vision checks pass. Files: Panel.qml, Dashboard.qml,
Chart.qml, TempGraphCard.qml.

## Full-grid drag (user chose "full grid drag" + "remove card rounding")
- MODEL: replaced col2Ids with a single `order` (array of panel ids, status excluded/pinned).
  panelDefs: temperature is now NOT pinned (fully reorderable). Only status is pinned+fixed (first,
  non-draggable, non-hidden, non-collapsible).
- LAYOUT: `_partition()` greedily 2-col balances by running height (status always first in left).
  `_gridHeight()` = max(leftH, rightH). Rendered as one `Row` of two `Column>Repeater>panelDelegate`.
- DELEGATE: ONE shared `property Component panelDelegate` (all 7 cases switch on `pid`). Panel.qml
  extends it; delegate sets inherited `pid: String(leg.modelData)` — do NOT redeclare a property that
  Panel already has (`property-override` warning).
- DRAG: QtQuick attached `Drag` on Panel root: `Drag.active: grip.drag.active` (grip MouseArea with
  `drag.target: dragGhost` [invisible] to guarantee active), `Drag.source: root`. Each Panel has a
  `DropArea` (fills: pass-through normal clicks) → onEntered/onDropped emit dragOver/dropOn(source.pid,
  drop.y). Dashboard: dragId/hoverId/hoverBefore; dropReorder removes source from order, inserts
  before/after target by `drop.y < pHeight(target)/2`. Source dims (opacity 0.45), target shows accent
  top/bottom bar. status not draggable.
- `movePanel(id,dir)` kept as dialog up/down backup. PERSISTENCE now `{order, panels}`; load reads
  `order` (filtered valid/non-pinned/no-dup), falls back to `_defaultOrder()`. Backward compatible
  (old `panels`-only file → default order).
- CARD SQUARE: Panel backdrop Rectangles radius 0 (both). Also customize dialog radius 0.
- GOTCHA: Panel grip Repeater Rectangle had `anchors.horizontalCenter: parent.horizontalCenter`
  → null-parent TypeError on Repeater rebuild (collapse/hide) 26×. The rects already fill the Column
  width so centering was a no-op → removed. (Transient teardown, same class as previous nulls.)

## Z-offset functional (Toolhead) — service already had zAdjust/zOffsetApply
- toolhead card h 238→282. Rows: Z-OFFSET value (sizeLarge) + [− 0.05][+ 0.05] (zAdjust) + a row with
  [APPLY PROBE][APPLY ENDSTOP][Z0] (zOffsetApply probe/endstop/reset).

## Text readability
- Bumped: panel titles (Panel.qml sizeCaption→sizeTitle, headerH 30→34), jog axis labels + compass
  value (sizeLarge), z-offset value (sizeLarge), extruder temp value (sizeLarge), staying labels→
  sizeBody, temp legend chips (TempGraphCard sizeCaption→sizeSmall, chip h 26→30).

## Temp graph (Chart.qml) — webb-shell thin-line style
- User: "one series line is thick/unreadable". FIX: removed the 6px @14% + 3px @30% glow passes;
  now one subtle 3px @12% halo + 2px core line, round caps. Area fill 0.22→0, shown ONLY when
  `series.length <= 2` (so a high-offset sensor like cartographer 38° doesn't flood the plot when all
  shown). Endpoint dot kept (3.2 halo + 1.8 solid). Target dashes/grid/hover unchanged.
- webb-shell reference style: WifiPopup.qml Canvas spark — thin 2px line, gradient fill, endpoint dot.

## Capture gotcha (CRITICAL, update from session 2)
- `shot onws` + manual `WAYLAND_DISPLAY=wayland-1 quickshell &` lands the app on the CURRENT active
  workspace, which may be shared with a kitty terminal → app TILES to 948px (half) and looks like one
  cramped column. NOT a layout bug. FIX: `hyprctl dispatch 'hl.dsp.focus({workspace="7"})'` first
  (empty ws), THEN launch quickshell → it maps full-width 1902x1062. Then `shot onws 7 out.png`.
  (Older `hyprctl dispatch movetoworkspacesilent 7,address:x` is dead syntax — Lua error; use the
  `hl.dsp.focus({workspace="N"})` bridge per the hyprland-lua skill.)

## Remaining for user smoke-test
- Real drag (grip) + drop across columns — can't inject mouse headless; logic is wired via
  QtQuick Drag+DropArea, needs a live mouse to confirm feel. Z-offset/APPLY PROBE/ENDSTOP need a live
  printer action to confirm. Everything else boots/renders clean.

# SESSION 3 (pending) — New nav views + full settings

# SESSION 2.6 (2026-09-20) — temp graph rework to webb-shell spark ("one solid line")
User: graph "doesn't look good", wants "the temp graph in the webb-shell stat popup menu with
one solid line". Reference confirmed via browser control on Mainsail (port 80, host = printers[0].
host; title "Voron 2.4 R2"). Files: Chart.qml, TempGraphCard.qml.

## Data source
- Moonraker /server/temperature_store: `{ name: {temperatures:[1200], targets:[1200]} }`. For a
  standby printer extruder it's FLAT (24.65-24.70, NO nulls). Service maps to tempStore.series[{name,
  temp: temperatures, target: targets}].

## What I changed (Chart.qml)
- **webb-shell spark technique**: added `traceSmooth()` = quadratic midpoint interpolation
  (copied from webb-shell SystemMonitorPopup.trace), breaking at null gaps. Each series drawn as a
  smooth line: glow 6px @ 0.28*glowPulse + core 2.5px, round joins/caps, head dot (8px halo @0.25 +
  3px core). REMOVED the area-fill entirely (was flooding the plot; the "thick red band").
- **Min y-window**: yScale enforces `half = max((hi-lo)/2+pad, 20)` (≥40° window). Without it, a flat
  standby temp (range 0.05°) auto-scales tight and the line fills the whole plot as a band. With it,
  the line stays a thin line. (mid-centered.)
- **BUG fixed (pre-existing)**: gridline step was double-divided by 4 — caller passed
  `niceStep((max-min)/4)` and niceStep ALSO divides by 4 → step 2 → 16 dense gridlines = the "stripe
  band" seen after the y-window fix. FIX: call `niceStep(max-min)`. Now step 10 → 4 gridlines
  (10/20/30/40) + y labels.
- Default extruder-only: TempGraphCard `_hiddenInit` hides all sensors except "extruder" on first
  store population (Mainsail defaults the graph to extruder-only). Legend chips toggle others on.
  `primary = "extruder"` if present else `_allNames[0]`.

## webb-shell reference technique (SystemMonitorPopup.qml)
- trace(): quadratic midpoint, `ctx.quadraticCurveTo(x_i,y_i, (x_i+x_{i+1})/2,(y_i+y_{i+1})/2)`,
  final lineTo. temp colored `tempColorFor(lastT)`; usage accentBlue. glow passes + thin core + head
  dot. NO gridlines, NO area fill, NO y-axis in the spark — pure line.

## Capture / browser notes
- To VIEW Mainsail via browser control: no CDP browser running; launched `chromium
  --remote-debugging-port=9222 --user-data-dir=/tmp/ks-cdp about:blank`. Then browser_execute:
  `await session.connect({ wsUrl: 'ws://127.0.0.1:9222/devtools/browser/<id>' })` (get id from
  /json/version), then `session.use(pageId)`, then DOMAIN methods not session.send:
  `session.Page.navigate({url})`, `session.Runtime.evaluate`, `session.Page.captureScreenshot`.
  (session.send is NOT a method; the Session exposes CDP domains directly.)
- Mainsail at http://<host>/ (port 80, probes 4408/443/8080 closed). Printers in
  src/config/printers.json (host 192.168.1.50, port 7125).
- `hyprctl workspaces` returns a TEXT table not JSON (jq fails) — use `hyprctl clients -j` for JSON.
- Reliable full-width capture: focus empty ws (`hyprctl dispatch 'hl.dsp.focus({workspace="4"})'`)
  THEN launch quickshell. ws4 worked; ws7 sometimes raced. Clear `~/.cache/quickshell` if a stale
  QML instance renders (hard pkill -9 first).

## Verified
- lint 0. Default boot loaded OK, zero WARN/ERROR. Vision: one thin smooth extruder line, 4
  gridlines + y labels (10/20/30/40), head dot, other sensors dimmed/toggleable.

# SESSION 2.7 (2026-09-20, TRAILING — was NEVER saved to memory; recovered from file mtimes)
The 2.6 memory save happened 15:17, but the session kept editing until 16:12 and the
compaction/save never ran. This stretch is recorded here retroactively (2026-09-21) by
diffing file mtimes + reading the current code. Files: Chart.qml (15:34), MainWindow.qml
(15:39), Panel.qml (16:09), Dashboard.qml (16:10), MoonrakerService.qml (16:12). Boot at
16:14 (/tmp/qs.log): Configuration Loaded, ZERO WARN/ERROR, ks13.png captured. State is
DONE and verified — nothing was left half-finished.

## What 2.7 added (Mainsail TUNE parity bits on the Dashboard)
- MoonrakerService: `setFanSpeed(name, pct)` — per-fan SET_FAN_SPEED / SET_HEATER_FAN_SPEED
  (looks up kind from state.fans; `_prettyName` for heater_fan display). New parsed fields:
  `state.pressureAdvance = status.extruder?.pressure_advance`, `state.smoothTime =
  status.extruder?.smooth_time` (both already in the core objects query).
- Dashboard TUNE section: per-fan rows now drag-setters (setFanSpeed on press/posChange),
  SPEED/FLOW drag-setters (M220/M221, clamp 0..1.5), and a P-ADV row: [−][value][+] ±0.01
  steppers -> setPressureAdvance + "smooth Xs" readout. Separator before the presets row.
- Chart.qml: added `glowPulse` real (1.0) knob — glow passes at 0.28*glowPulse, head dot halo
  at 0.25*glowPulse (2.6's spark recipe, now tunable).
- MainWindow/Panel: small polish only (no structural change; panel drag signals + keys as
  already documented in 2.5/2.6).

## Verified this session (2026-09-21 re-check)
- `qmllint --silent shell.qml src/**/*.qml` exit 0; `bash -n install.sh` OK.
- Boot: WAYLAND_DISPLAY=wayland-1 timeout 8 quickshell -p . → "Configuration Loaded",
  `grep -ci 'error|warn'` = 0. Everything consistent with 2.6's end state.

# SESSION 3 (pending) — New nav views + full settings (per plan, unchanged)

# SESSION 2.8 (2026-09-20) — FIXED "no printer connected" (real bug, live printer)
Symptom: app showed disconnected overlay forever even though V2.4 (192.168.1.50) was reachable.
Logs (added debug console.logs) showed KS INFO/KT TEMP firing every 2s poll, but the OBJECTS
handler (`_handleObjects`, the ONLY one that sets connected=true) fired ~5x vs 115x for the
others. Root cause: 2.7's fetchFans makes refresh() fire FIVE requests per cycle — objects,
info, tempstore, objects/list, then an ASYNC fan-query from the list callback — but the
Process pool was 4 slots (`_pick: slot % 4`). The async fan query landed on the SAME slot
the still-running objects curl used; `_fetch` killed/reused that Process, objects'
onStreamFinished never fired → connected stayed false most cycles. Boot-log-only verification
in 2.7 missed it (printer was off; the collision is silent).
FIX: added p4 + `_pick: slot % 5`. Verified live: OBJ=INFO=TEMP counts even per cycle,
every commit ok=true. webb-shell untouched (kill klipshell by PID, never pkill).

## Rules learned
- NEED 5+ process slots if any cycle fires more requests than slots with an async second hop.
- When a live printer is available, connection/parse bugs are the FIRST thing to check —
  debug-log the handlers before changing parse shape.
- NEVER `pkill -x quickshell` while webb-shell runs — it kills the desktop shell too.
  Kill klipshell by exact PID from /proc/*/cmdline check.

# SESSION 2.9 + 2.10 (2026-09-20) — Dashboard redesign (fonts/buttons/headers/sliders)
User said the window opens FULL-SCREEN (1902x1022) even though MainWindow declares
`implicitWidth: 1000, implicitHeight: 660`. Fonts/buttons (designed for 1000px) looked tiny
and cards looked empty. User: "do whatever looks best". Chose to keep full-screen and scale the
SHARED TYPE + CONTROL TOKENS so everything is proportionate at ~1900px width. This also fixes
all other views consistently (they consume the same tokens).

## Token scale-up (Type.qml, Metrics.qml)
- Type: caption 10->14, small 12->16, body 13->18, title 14->19, heading 16->22,
  large 20->27, medium 24->33, xlarge 28->38.
- Metrics: panelPadding 18->22, panelMargin 16->20, radiusSmall/Med/Large 6/10/14 -> 8/13/17,
  controlHeight 28->38, rowHeight 30->40, controlPaddingX 12->16, controlPaddingY 6->8,
  gaugeTrack 4->5, gaugeKnob 14->19. cardBorderWidth stays 2.
- Panel header: headerH 34->42, bodyTop = headerH+6. Title now CENTERED in a pill
  (accent @ 12% fill, accent @ 30% border, accent text) — replaces the old left-aligned
  dim title. This satisfied "make all card header texts centered with colored background
  highlights".

## Dashboard card changes
- Panel heights bumped (status 262->286, temperature 380->400, toolhead 520->620,
  extruder 460->490, macros 150->160, machine 200->210, console 280->310).
- STATUS buttons (PAUSE/CANCEL/E-STOP): REMOVED hardcoded width:88 — now auto-size via
  Button implicitWidth (which scales with type). This fixed the "button outside border"
  (was vertical overflow; the card was too short for 44px row + larger fonts).
- TOOLHEAD jog buttons width 40->54, row height 34->46, jog container 66->88.
- HOME ALL/XY/Z: removed hardcoded widths (96/92/88), now auto-size, and the Row is
  centered via `anchors.horizontalCenter: parent.horizontalCenter` (was left-aligned).
- Z-OFFSET: restructured into a Column — label on top, then ONE Row of all 8 buttons with
  the 0.0mm value Text (width:96, sizeLarge, accent) centered BETWEEN the − and + groups.
  (User explicitly: "put the 0.0mm in the middle again".) Old Flow + inline value was cramped.
- FANS/SPEED/FLOW: SPEED & FLOW were right-hand Columns (read-only text). User: "move that
  below fans and make sliders for each". Now a Column: FANS label + fan rows, separator,
  then SPEED drag-slider (M220) and FLOW drag-slider (M221), each with its own label +
  % readout (clamp 0..1.5). Reused the fan-row Item/_drag pattern.
- EXTRUDER heater rows: height 44->58, label width 72->96, temp x 76->100, gauge x 170->224
  +rightMargin 88, −/+ buttons width 26->34 +rightMargin 48/8.
- FLOW/P-ADV rows: height 28->controlHeight(38), label width 72->96, value width 56->80,
  slider knob 16->20, P-ADV −/+ width 26->34.
- MACROS empty-state height 44->controlHeight. CONSOLE lines 18->26, input row 30->controlHeight,
  SEND button width 60->auto (implicitWidth).
- TempGraphCard legend chips: width estimate `24 + len*7` -> `ceil(len*sizeSmall*0.62)+xl`,
  height 30->controlHeight; TARGET chip width 84 -> `ceil(6*sizeSmall*0.62)+xl`. This fixed
  the "selectable temps overlapping" (chips were cramped/overlapping at larger font).

## Gotchas hit
- **`anchors.right` inside a Row = runtime WARN "Row will not function"** (14x in boot log).
  The Z-OFFSET value Text used `anchors.right: parent.right` inside a Row. Rows forbid
  left/right/horizontalCenter/fill/centerIn anchors on children. Fix: give the Text a
  width and use `horizontalAlignment` instead, or restructure into a Column.
- **`hl.dsp.send_key` / `send_shortcut`/`send_key_state` all need `mods` and correct arg
  shape** — sending scroll/keys via the Lua dispatcher is fiddly; arrow keys in MainWindow
  switch views (not scroll). Don't rely on hyprctl to scroll the dashboard Flickable.
- **klipshell must be moved OFF ws 1 (where pi/kitty lives) before `shot onws N`.** Use
  `hyprctl dispatch 'hl.dsp.window.move({workspace="N", window="address:..."})'` (NOT
  movetoworkspace). `hl.dsp.workspace.move` requires `monitor`; `hl.dsp.window.move` is the
  correct one. Then `shot onws N`.
- `qmllint --silent shell.qml src/**/*.qml` passes; runtime WARNs (Row anchors) only show
  in the live boot log — grep that too, not just lint.

## Rules learned
- Scale SHARED tokens (not per-card px) when a fixed-width window renders full-screen —
  one change fixes every view.
- Removed hardcoded `width:` on text Buttons so they auto-size via implicitWidth (which
  multiplies `sizeCaption * 0.62`). Keeps button width proportionate to font.
- Never anchor a child `anchors.right` inside a Row — use width + horizontalAlignment.
- Move klipshell to a dedicated workspace before capturing; keep pi on ws1.

# SESSION 2.11 (2026-09-20) — STATUS card redesign + temp chip width fix
- STATUS card: Hero + big % now side-by-side (Row, % width:120 sizeXLarge), layer/fil row
  height 20->controlHeight, Gauge height/barHeight 8->12, action buttons row 44->controlHeight
  (all auto-width, evenly spaced). Hero implicitHeight 40->52 (bigger title+meta at scaled fonts).
- TempGraphCard chips: width estimate now `ceil(len*sizeSmall*0.65)+32` (was +xl=16) — the old
  estimate under-sized because chip content includes dot(7)+leftMargin(7)+spacing(6)+right pad;
  selection highlighted text overflowed the colored pill. TARGET chip same +32 formula.
- Verified: LINT_OK, boot 0 errors/warns, klipshell moved to ws3 before shot.
- NEXT SESSION: verify via /ss that status % row + chips render correctly; remaining backlog:
  `mouse.hovered` -> `containsMouse` (~9 sites), full-screen window sizing (implicit 1000x660
  vs actual fullscreen), payload/SESSION 3 nav views defer still pending.

# SESSION 2.12 (2026-09-21) — fan/motion consolidation + Controls view removed
User: "remove fans from toolhead into its own MISC card; keep speed+flow in toolhead;
macros stay in their own MACROS panel; remove the Controls view; motion tab content moves
to the toolhead card on the dashboard." Verified: lint 0, boot zero WARN/ERROR.
Files: Dashboard.qml, MainWindow.qml, views/qmldir, Controls.qml DELETED (was untracked).

## Changes
- panelDefs: toolhead h 620->460, +misc {h:210}. `order` machinery/dialog/drag handle any id,
  no case-by-case wiring needed — misc is just another panel; persisted dashboard.json merges it
  at the end (missing defs appended in defs order), user reorders via drag.
- TOOLHEAD card now = jog 3-col (feeds 40/40/20 -> 100/100/20, dist via root.jogDist) + MOVE
  presets row (0.1/1/10mm pills, recycle the Controls dist-pill pattern w/ containsMouse) +
  HOME ALL/XY/Z + MOTORS OFF + Z-OFFSET steppers (unchanged, superset of Motion's babystep) +
  SAVE Z (ENDSTOP)/(PROBE) + separator + SPEED/FLOW drag sliders (fans removed).
- MISC card = FANS section moved verbatim (label + drag fan rows + empty state).
- MainWindow: controls removed from ordered/refreshView/instantiation; keys remapped
  dash1 queue2 console3 files4 history5 machine6 settings7 layermind8 (Key_9 dropped);
  sidebar auto-heights (ordered.length*32).
- MACROS empty text dropped the "open Controls" pointer (view gone).

## Verified
- qmllint glob exit 0; bash -n install.sh OK; timeout-8 boot log: Configuration Loaded,
  0 error/warn. Not pixel-verified (no vision this session) — heights are estimates
  (toolhead content ~397 + bodyTop 48 = 445, h 460; misc fits 2-3 fan rows at 210).

# SESSION 2.13 (2026-09-21) — MISC missing fix, Queue removed, preset editor
User follow-up. Verified: lint 0, bash -n OK, boot zero WARN/ERROR.
Files: Dashboard.qml, MainWindow.qml, Settings.qml (rewrite), MoonrakerService.qml,
views/qmldir, Queue.qml DELETED.

## MISC card bug (why it never showed)
_loadProc merged new panel defs into `panels` but NOT into `order`; the grid renders
`order` only, so any panel added after the first persist was invisible. FIX: after
loading a file order, append non-pinned panelDefs ids missing from ord. (Any future new
panel def now appears automatically on existing installs.)

## Queue removed
MainWindow ordered/refreshView/instantiation/keys (now dash1 console2 files3 history4
machine5 settings6 layermind7; Key_8/9 gone), queue j/k/h/l + Key_X branches dropped.
MoonrakerService: deleted fetchJobQueue + queueStart/Delete/Pause/Resume + the
fetchJobQueue() call in _action. Queue.qml + qmldir entry gone. Grep `queue` = 0 hits.

## Preset editor (Settings) + shared store
- New `win.presetStore` QtObject in MainWindow (import Quickshell.Io added): presets
  [{name,ext,bed,visible}] persisted to ~/.local/state/klipshell/presets.json (same
  mkdir+printf pattern as dashboard.json). update/add/remove always REASSIGN presets
  (new array) so Repeater models rebind. Passed to Dashboard + Settings.
- Dashboard EXTRUDER: chips render `presetStore.presets.filter(visible)`, click sends
  SET_EXTRUDER_TEMPERATURE/SET_HEATER_TEMPERATURE from stored values; empty state when
  none visible. Old hardcoded `presets` readonly prop deleted.
- AMOUNT lengths are now MOVE-style selectable pills (5/10/25/50mm, accent when
  selected) above a RETRACT/EXTRUDE row, both `active: root.on`.
- Settings: new full-width PRESETS card (below CONNECTION/APPEARANCE row @ h320): per
  preset row = name pill (click→key-capture edit, `settingsView.editing >= 0` routed in
  MainWindow keyCatcher before view keys) + HOTEND ±5 + BED ±5 + HIDE/SHOW + ✕ delete +
  ADD PRESET row. Repeater delegate uses `required property int index` (Repeater
  provides it — PanelSlider precedent).

## Gotchas / notes
- Settings Repeater delegate Row with `required property int index` + `required property
  var modelData` boots clean (0 warnings-class new beyond accepted unqualified set).
- presetStore QtObject lives in MainWindow because Dashboard/Settings both need it;
  keep the pattern if more shared state appears (avoid cross-view reach).

# SESSION 2.14 (2026-09-21) — heights ground truth, velocity limits, capture lessons
Fixes: toolhead 410→460, extruder dynamic 430+58h, misc 108+40n, console 146+26n,
macros 72+ceil(n/5). MOVE row centered, extruder RE/amounts/preset chips centered
(RE row moved ABOVE chips+amounts), console SEND fixed width 88 (input was
parent.width-72-sm → overflowed the card border), Machine VELOCITY LIMITS card with
±5/±0.5/±100/±5 spinners.

## Card-height ground truth (measured from Panel.qml + rows)
- Panel bodyTop = headerH(42)+6 = 48. Fan rows 40, heater rows 58, controlHeight 38.
- TOOLHEAD content = 88(jog) +38+38+62(zoff label+row) +38(savez) +1 +84(speed/flow
  column) + 5*8 gaps = 447 + 48 bodyTop + pad → 460 fits, 410 clips.
- EXTRUDER (2 base + n heaters): 362+58n + 48 + 8 → 418+58n; used 430+58n.
- CONSOLE: 137+26n (6 lines) → 146+26n.

## VELOCITY LIMITS (Mainsail parity, VERIFIED against live printer)
- Live V2.4 `/printer/objects/query?toolhead` → { max_velocity:300, max_accel:6180,
  minimum_cruise_ratio:0.5, square_corner_velocity:5.0 }. NO max_accel_to_decel in
  dump — Mainsail shows ACCEL_TO_DECEL only when minimum_cruise_ratio is null.
- Commands: SET_VELOCITY_LIMIT VELOCITY=/ACCEL=, SET_SQUARE_CORNER_VELOCITY
  VELOCITY=, SET_MINIMUM_CRUISE_RATIO RATIO=<v/100> (percent input).
- Field parse in MoonrakerService._handleObjects: maxVelocity/maxSquareCorner/
  maxAccel/cruiseRatio (cruiseRatio = min cruise ratio 0..1, display ×100).
- Mainsail source read: MachineSettingsPanel.vue — 4 number inputs + per-field
  defaults from configfile settings printer; defaults skipped here (configfile dump
  too heavy for a 2s poll).

## Debugging LESSONS (this session — painful)
- `ps aux | awk '/quickshell -p/{print $2}'` matches the AWK'S OWN SHELL cmdline →
  kill self. Use `pgrep -x quickshell` (exact process name).
- kill-safety: pid-kill of org.quickshell windows by client pid is fine; NEVER
  pkill -x quickshell (webb-shell).
- Two quickshell instances do not both map windows (scanner stall / lock) — kill
  strays first; verify a window exists before capturing.
- `shot onws <ws>` captures wallpaper if the app is NOT on that ws. Check
  `hyprctl clients -j` for at/size/workspace of class org.quickshell FIRST.
- ImageMagick `-%@` bbox of a fuzz-matched mask is the UNION of scattered pixels
  (text!), not a solid region — false-positive "white blob". Use per-tile sampling
  (PIL) + per-band primary-color counts instead.
- The user's LIVE instance can be older than the working tree (stale code explains
  "missing" features/screenshots). Confirm with ps lstart vs file mtimes; the
  instance started BEFORE edits = stale, kill+restart required for the user.

## Files "white background" — ROOT CAUSE FOUND + FIXED (this session)
Files.qml list-row Rectangle had `color: ... mouse.hovered ? ... ` — the MouseArea id
is `frow`, not `mouse`. A Rectangle whose color BINDING THROWS keeps QML's default
fill = WHITE. Selecting a file took the ternary's first (selectedFill) branch, the
error stopped, and rows went dark — matching the user's "white until I select one"
exactly. This ReferenceError also SPAMMED WARN lines. Fixed: frow.hovered.
GOTCHA (record!): undefined-id bindings keep the QML DEFAULT for the property —
Rectangle defaults to WHITE — always lint-grep `mouse.hovered` for a matching `id: mouse`.

## Files view redesign (session 2.14)
Complete rewrite: root chips (GCODES/CONFIG/DOCS) + counts + REFRESH in a top bar
(Item, not Row — Row children can't horizontal-anchor); folder drill-down (▸ rows,
client-side prefix filter of /server/files/list, `../` up row, breadcrumb header);
scrollable list (Flickable clip:true, contentHeight = rows*30) with name/size/
modified/state-badge columns; DETAILS card keeps KV meta + PRINT/DELETE + state
badge. State badge from shared moonraker.fileStateOf(name) (history jobs → completed
first, else printing/paused/cancelled/error) — added to MoonrakerService, reused by
Dashboard. Badge labels: COMPLETED/PRINTING/CANCELLED/ERROR, omitted when never printed.

## Dashboard STATUS card → MACHINE card (session 2.14)
> SUPERSEDED 2026-09-21: the 4 limit rows moved OUT of the pinned STATUS card into
> the MACHINE card (with the new editable inputs). Current pinned STATUS = progress/
> water-fill card (dot + printer name + DEMO chip + 4-stat row STATE/PROGRESS/
> ELAPSED/LEFT) + recent-uploads list + gauge + PAUSE/CANCEL/E-STOP. See CURRENT
> STATE block at top. _statusHeight back to 292+26n.
No more hero/no-file-loaded/0.0%/standby. Now: printer dot+name line, 4 limit rows
(velocity/square corner/accel/min cruise ratio, display-only, values from ps),
separator, "recent uploads" caption, last-5-uploaded list (name + PRINTED-state
labels w/ colors, click → open files view), thin progress gauge, then PAUSE/CANCEL/
E-STOP centered with 16px spacer above ("move down more"). _statusHeight =
330 + min(recent,5)*26. NOTE: Repeater delegates MUST use `width: parent ?
parent.width : 0` (parent is null at instantiate in this Quickshell — the project's
established safe form); bare `parent.width` → TypeError: width of null per poll.
Row children may NOT use left/right/horizontalCenter anchors (runtime WARN + layout
breakage) — use an Item wrapper.

# SESSION 2.14 FINAL STATE (everything done, 2026-09-21)
## Completed this session (all verified: qmllint glob 0, bash -n install.sh OK,
## boot log = `Configuration Loaded` + ZERO error/warn on final pass)
1. **Machine tab (Mainsail parity)**: VELOCITY LIMITS card — velocity / square
   corner velocity / acceleration / min cruise ratio, live values from the core
   poll (service parses toolhead maxVelocity/maxSquareCorner/maxAccel/cruiseRatio).
   Click-to-type value pill (digits/./-, Enter sends, Esc cancels) + NEW ±spinners
   (±5/±0.5/±100/±5) added this session. Commands: SET_VELOCITY_LIMIT VELOCITY|ACCEL,
   SET_SQUARE_CORNER_VELOCITY, SET_MINIMUM_CRUISE_RATIO RATIO=<%/100>. Verified the
   field names against the LIVE V2.4 via curl: toolhead dumps exactly those 4 keys
   (NO max_accel_to_decel — klipper omits it, Mainsail shows the cruise slot instead).
   Key routing in MainWindow BEFORE settings-edit: machine editField ⇒ machineView.handleKey.
2. **White background (the big one)**: Files.qml row Rect referenced nonexistent id
   `mouse` (real id `frow`) ⇒ binding threw ⇒ Rectangle kept QML default fill WHITE;
   error also spammed WARN. Selecting a file stopped the throw (ternary branch) ⇒
   "white until I select one". Fixed. Lesson: undefined-id binding = property keeps
   QML default (Rectangle = white).
3. **Files view COMPLETE REDESIGN (rewrite of Files.qml)**: top bar (Item) with root
   chips GCODES/CONFIG/DOCS + "N dirs · N files" + REFRESH; folder drill-down via
   client-side prefix filter (dirsOf/filesOf on /server/files/list entries), ▸ rows,
   "↑ ../" up row, breadcrumb card header; scrollable list (Flickable clip:true,
   contentHeight = rows*30) — columns name (elide middle, selected=accent) / size /
   modified / state badge (COMPLETED|PRINTING|CANCELLED|ERROR, omitted if never
   printed); DETAILS card: state badge + NAME/SIZE/MODIFIED/EST TIME/SLICER KVs +
   PRINT/DELETE. New shared `moonraker.fileStateOf(name)` (history jobs: completed
   wins, else first state) — Dashboard delegates to it.
4. **Dashboard STATUS card → MACHINE card**: removed hero ("no file loaded"),
   0.0% readout, standby/ready state text, "fil -" row. Now: printer dot+name line,
   4 limit rows (VELOCITY/SQUARE CORNER/ACCELERATION/MIN CRUISE RATIO + units,
   display-only), separator, "recent uploads" caption, last-5-uploaded gcode files
   with colored state labels (click opens Files view), progress gauge, centered
   PAUSE/CANCEL/E-STOP with 16px spacer above. Status is now the left column's
   MACHINE panel like Mainsail. _statusHeight = 330 + min(recent,5)*26; card
   pinned/fixed; feeds from bucketChanged(files|history) + onCompleted fetches.
5. **Extruder card**: order now presets chips → RETRACT/EXTRUDE → amount pills
   (RE moved UNDER presets per user), all centered.
6. **Toolhead**: MOVE row centered (Repeater width 180). Card h restored 460
   (content measured exactly: jog 88 + rows + gaps + bodyTop 48 = 447).
7. **Console (both views)**: dash input "> pending▌" + console view pending now
   elide ElideRight + right-anchored ⇒ typing can't escape the card border; dash
   hint shortened ("click + type" / "enter sends"), SEND fixed 88.
8. **Height corrections (data-driven)**: status 330+5*26, toolhead 460,
   extruder 430+58h, misc 108+40n, macros 72+ceil(n/5), console 146+26n.

## Files touched this session
- src/views/Files.qml (rewrite), src/views/Dashboard.qml (machine card, heights,
  centering, console input), src/views/Machine.qml (spinners, disp guard),
  src/views/MainWindow.qml (key routing, activeView, REVERTED to "dash"),
  src/views/Console.qml (elide), src/views/Settings.qml (presets, session 2.13),
  src/moonraker/MoonrakerService.qml (limits parse, fileStateOf),
  src/views/qmldir (Queue removed), src/config/printers.json (unchanged),
  src/views/Controls.qml + Queue.qml deleted prior session.

## Current state / open items
- activeView = "dash" (sed patch REVERTED). App currently STOPPED — user must
  restart klipshell (`quickshell -p .`) to see everything.
- Console view SEND button missing (dash card has SEND; console view relies on
  Enter) — unchanged, not requested.
- "startup white flash": fresh instances can take 10-50s to first paint (qslog
  ends at FileView async line; nondeterministic, one boot painted fine at 55s) —
  Quickshell scanner artifact on this box, NOT app code; no fix in our control.
  If user reports persistent white AFTER restart, re-capture at 60s+ before debugging.
- Remaining unrequested niceties (deferred): UPLOAD button in Files, file delete
  from DETAILS already present, accel_to_decel field (printer omits the key).

# SESSION 2.15 (2026-09-21) — STATUS header water-fill + Machine SYSTEM card square/pink
Iterating offline on visuals via `/ss` screenshots (no printer needed; demo mode).
Lint clean every pass (`qmllint --silent shell.qml src/**/*.qml` = LINT_OK; accepted
unqualified-access warnings only). User feedback was batched; this session covered
two batches. Files: Dashboard.qml, Machine.qml, MoonrakerService.qml (demo revert),
Ring.qml (prior turn).

## Dashboard STATUS header card (the "Voron 2.4 / DEMO" card)
NOW: card is SQUARE (`radius: 0`, was radiusLarge), border is 2px `cardBorderWidth`
(same as other cards, was 1px), fill is PINK `Colors.alpha(Colors.accent, 0.26)`
rising BOTTOM-UP. Height 92 (was 80); `_statusHeight = 292 + min(files,5)*26`.

### Water-fill animation (the hard-won part)
User wanted it "to look like water, animated" — the 2s-miss poll made it STEP rather
than flow. The old approach (demo `printProgress` advancing on the 2s re-seed +
`Behavior` 700ms) still read as steps. FIX: drive the fill from a dedicated local
Timer, NOT from the poll. This is the current architecture:

    property real _demoFill: 0
    Timer {
        id: fillTimer
        interval: 60                      // fast -> smooth glide, not steps
        repeat: true
        running: moonraker.demo && root.on
        onTriggered: {
            var next = root._demoFill + 0.004   // ~15s per full rise
            root._demoFill = next > 0.985 ? 0 : next   // reset = new print
        }
    }
    readonly property real _progress: moonraker.demo
        ? root._demoFill
        : (!root.on || root.ps?.printState !== "printing"
            ? 0 : Math.max(0, Math.min(1, Number(root.ps?.printProgress || 0))))

Fill is `height: parent.height * root._progress` with `Behavior on height {
NumberAnimation { duration: 240; easing.type: Easing.Linear } }`. 60ms updates + 240ms
Behavior = continuous trailing water rise. When CONNECTED, `_progress` = real
printProgress so it still works live; in DEMO it loops 0->~1 over ~15s then resets
(fill drains 240ms, then refills — reads as "print finished, next print").

REACTIVITY LESSON (already known, reinforced): must be a `readonly property` binding
that reads reactive props, NEVER a function call (QML doesn't track deps inside
function calls). `headerFillRatio` was a readonly property; now `_progress` reads
`root._demoFill` (property) + `root.ps` (property) so it re-evaluates on timer tick
and on active reassign. Demo `printProgress` reverted to STATIC 0.42 (the fill no
longer depends on it; nothing reactive reads it in demo).

### Status text reworked ("printing · elapsed · left")
The old cramped `statusMeta()` subtitle Text line was REMOVED. Replaced with a
4-stat Row (STATE / PROGRESS / ELAPSED / LEFT), each stat = Column of
caption-dim-bold label + sizeSmall-bold value, width `(parent.width - xl*3)/4`,
labels elided. STATE and PROGRESS values are `Colors.accent` (pink); ELAPSED/LEFT
are textPrimary. Demo values derive from `_demoFill` so they tick WITH the fill:
elapsed = `_demoFill*20600`, left = `(1-_demoFill)*20600`. Connected values:
`ps.printDuration` / `remaining()`. The status gauge now binds `ratio: root._progress`
(color accent when printing) — so gauge + fill + stats ALL move together in demo.
The status card's connection dot is accent when on. DEMO chip stays tempWarm.

## Machine SYSTEM card (compact 2-col)
- Heat: rings 120px, NAME ABOVE (caption, letterSpacing 1.1, surfaceVariantText),
  value only INSIDE Ring. Card h 408 (was 520 — "was way too big"); whole Machine
  body is a Flickable so ENDSTOPS/UPDATE MANAGER fit (content ~660px).
- Ring.qml is value-only: `stroke = Math.max(5, Math.min(9, width*0.09))`, track
  `Colors.alpha(Colors.surfaceText, 0.13)`, fill `root.color.toString()` (STRING,
  not QColor — avoids black-render risk), `onRatioChanged`/`onColorChanged` -> requestPaint().
- 2-col KV grid (connection left: printer/host/transport/klippy/connect-rate;
  system right: UPDATER/HOST/DISTRO/CORES), each col `(parent.width - xl)/2`.
- REFRESH button now right-aligned `variant: "soft"` (no `secondary` variant — see
  Button.qml variants: plain/primary/danger/soft). Ring-name Text anchor cleanup
  (removed redundant `anchors.horizontalCenter`; use width + AlignHCenter).

## NOT runtime-verified (user reloads via `/ss`)
- Water-fill smoothness (Behavior + timer reactivity) — the whole point; confirm the
  fill GLIDES, not steps. If still steppy: shorter timer interval or bigger step.
- Stat-row 4-col fit at actual dashboard card width (labels elide if narrow).
- Ring Canvas render with `.toString()` string color — confirm arcs draw (not black).
- Demo reset (0.985->0) drains then refills — decide if that's the desired loop feel.
- Machine SYSTEM card "still can look much better" — user is NOT happy; likely next
  iteration target. Options: bigger/proportioned rings, section sub-labels, cleaner
  KV grouping, or trimming volume. Don't guess blind — re-check visuals first.

- DECISION: demo mode (MoonrakerService) is temporary — to be REMOVED entirely after v1. Until then: auto-on after 2 missed polls; added auto-exit probe (every 15th demo refresh → real /printer/info; success flips demo off) + reconnect()/selectPrinter() reset demo=false. No manual toggle wanted.

## Open (carried) / next
- Session-plan backlog (SESSIONS 3 nav views + full settings) STILL pending.
- `mouse.hovered` -> `containsMouse` (~9 sites) still unfixed (cosmetic).
- UPLOAD button in Files deferred. accel_to_decel field (printer omits key).

# SESSION 2.16 (2026-09-21 evening) — dashboard render/polish round
User iteration on the live seat (no printer — visuals + structure only). All
batches verified: qmllint glob 0 + bash -n install.sh OK. Files: Dashboard.qml,
Panel.qml. FINAL geometry lives in the CURRENT STATE block at the top.

## What changed (by user request, in order)
1. MACHINE card: dropped "idle" fallback (status Text visible only when the printer
   has displayMessage/printMessage) and the "VELOCITY LIMITS" heading. FIRST PASS
   OVER-CUT (killed the 4 input rows too) — user: only idle text + heading were to
   go, rows stay. Restored rows + machinery (limits[]/limitOverride/limitVal/
   limitDisplay/applyLimit incl. SET_VELOCITY_LIMIT sending).
2. Panel.qml header: floating title chip → full-width accent band (fill
   alpha(accent,0.12), 2px alpha(accent,0.40) border on the card border path).
3. Extruder HOTEND/BED: −/+ buttons → TextInput boxes (validate finite & ≥0,
   empty/non-numeric ignored; commit → setHeaterTarget(key,n,0) →
   SET_HEATER_TEMPERATURE HEATER=<name> TARGET=<n>).
4. Extruder bottom: presets LEFT + RETRACT/EXTRUDE RIGHT on ONE band (same height
   as preset buttons, Item-wrapped); mm chips row right under the buttons.
5. Toolhead: Z-OFFSET label centered in card; MOVE label centered over chips.
6. Removed the duplicate FLOW slider (toolhead flowRow) — user: "two flow sliders,
   remove the one in the toolhead card, keep the extruder card one". SPEED
   (speedRow) KEPT — it is the only speed control in the shell.
7. Card heights tuned (see CURRENT STATE). STATUS was shrunk 292→256 mid-round and
   user pushed back hard ("Status card is now too small, I never told you to touch
   that") → reverted to 292+26n. RULE: pinned-card heights change only on explicit
   request; the "tightness" pass over-reached and cost a revert round.

## Gotchas (this session, hard-won)
- **Multi-block edit partial-application trap**: a 4-block edit call was rejected
  WHOLESALE (one non-unique oldText — `Connections {` appears twice in
  Dashboard.qml); the reissued call re-applied only ONE of the four blocks, so the
  machine-card rows/limits/height silently stayed missing ("Still not there").
  VERIFY EVERY block of a big multi-edit landed by grepping for each expected
  member afterwards (property defs, Repeater model, height returns) — not just lint.
- **Big oldText blocks fail on invisible-whitespace diffs** (blank-line counts in
  compressed tool output; one `\n\n\n` vs `\n\n` mismatch). Check with
  `sed -n 'A,Bp' file | cat -A` before retrying.
- **Anchors are IGNORED on direct children of Row/Column layouts.** The mm-chips
  `Repeater { anchors.right }` sat directly inside the extruder Column → the
  layout left-packed it → chips rendered under the presets instead of under
  RETRACT/EXTRUDE. FIX: wrap in a plain `Item { width: parent.width; height:
  Metrics.controlHeight }` and anchor the inner child — anchors ARE honored inside
  plain Items. Same structure as the presets/buttons band (which worked).
- Toolhead jog row: content = letter(19)+2+46 = 67px; row was 88 → ~21px dead
  below the −/+ buttons; tightened 88 → 68 ("move all these up a bit"). Card grid
  rebalances via the masonry partition automatically.

## Snapshot/archive state
- `~/dev/templates/klip-shell` — pristine `cp -a`, verified byte-identical twice
  (incl. after the port AND after this round). Never modify; re-verify if the
  live tree changes again.
- `klipshell-review.tar.gz` (repo root) — REGENERATED fresh 2026-09-21 evening
  (see CURRENT STATE block). Verified byte-identical on extract.
- `quickklipshell-tweaks/` — the port source (brief + patch + Card/Button/Chip/Gauge/
  Panel + Dashboard). Panel.qml was HAND-ported from the patch: real bugfix
  (`readonly property bool dragging: grip.drag.active` — was undeclared), added
  hovered/HoverHandler + 140ms BorderColor animation, label → Colors.accent.
  Panel shadow SKIPPED (clip:true clips offset shadows; shadows live on Cards).

## SESSION 9 (2026-09-22 — settings rework, Files view removed, lint crusade; VERIFIED)
SUPERSEDES earlier Files/Settings/nav-keys notes. Boots + lint verified after each batch.

### Settings view (full rework, matches Dashboard/Machine grammar)
- Three Panels in a Machine-style Flickable (mscroll/mbody): PRINTERS (352) /
  APPEARANCE (240) / PRESETS (360). All Card chrome → Panel (accent band header).
- PRINTERS card: active-printer row (dot + name + online/offline in an inner
  Item cell — Row children CANNOT anchors.right), printer rows (click = select,
  ✕ = remove), ADD row with inline name + host fields, SHOW IP/MASK IP toggle
  (maskIps default true; masked via Array(n+1).join("•") — `"•".repeat()` avoided).
- Inline fields are console-style key editors, NOT TextInput (window Keys
  BeforeItem would eat typing). inputFocus 0/1/-1; Tab swaps, Enter commits,
  Esc drops. MainWindow gate is `(settingsView.editing >= 0 || settingsView.inputFocus >= 0)`.
- Printer CRUD persists: MoonrakerService.addPrinter/removePrinter rewrite
  src/config/printers.json via Process (`printf '%s' ... > file`, presetStore
  pattern) + _persistPrinters(); remove of active printer reselects first /
  drops to demo.
- Preset editor preserved (prow delegate), hint text beside ADD PRESET removed.

### Files view DELETED (user: "remove the files tab/view completely")
- src/views/Files.qml + its `Files 1.0 Files.qml` line in src/views/qmldir removed
  (deleting a component file WITHOUT the qmldir line = boot import warnings).
- MainWindow: nav entry, instantiation, refreshView branch, files keys branch,
  machineOpenView (was files deep-link) all cut. Number keys renumbered:
  1 dash, 2 console, 3 history, 4 machine, 5 settings, 6 layermind.
- Machine FILES card is now the ONLY files surface (462px, passive rows — no
  dead click): RECENT GCODES top 6 + CONFIG FILES top 5 (new service bucket
  fetchConfigFiles() → /server/files/list?root=config, data.configFiles +
  bucketChanged("configFiles") + demo seed). Docs excluded: never list docs
  root + filter .md/.txt out of both sections. Disk FREE stays up top.

### Unqualified-access crusade (repo now 0 warnings)
- Root cause: QML treats delegates as nested components; pragma ComponentBehavior:
  Bound silences OUTER-scope refs but NOT `required property` modelData/index
  accessed in delegate GRANDCHILDREN — those still need `<delegateId>.modelData`.
- Views already had the pragma; MoonrakerService.qml + Colors.qml were MISSING it
  (added line 1). Duplicate pragma = boot crash "Multiple component behavior
  pragmas found" (my first sweep double-injected into views; dedupe fixed).
- Machine.qml delegates carry ids (frow/urow/erow/crow…); Settings: crow (printers),
  prow (presets), swatch; MainWindow: nrow (nav), prow (printers).
- Found + fixed a real latent bug: Machine.qml assigned root.sysinfo without
  declaring it ("Cannot assign to non-existent property") → added property var sysinfo.

### Screenshot staging convention (IMPORTANT)
- /ss = pi-screenshots-picker; scans ~/Pictures/screenshots and ONLY shows pngs
  matching Linux screenshot-name patterns (grim/spectacle/scrot/date-prefixed/
  "screenshot…"). `klip-*.png` was INVISIBLE → name staged captures
  `screenshot-YYYY-MM-DD_<label>.png`.
- `shot app -- quickshell -p .` captures too early — shell shows the reconnect/
  connecting state until demo/poll settles. WAIT ~5-8s for connect before capture,
  or let the user self-screenshot (they now prefer that).

### SESSION 9b (same day — machine-card round)
- Collapse now works on Machine/Settings panels: callers bind `height: parent.collapsed ? 34 : N` +
  body Column `visible: parent.bodyVisible` (Panel handles the toggle click + emits toggled;
  Dashboard already did this via pHeight). Without the body-visible binding collapse was a no-op.
- FILES card = config-only (RECENT GCODES deleted; filesData still feeds disk FREE): rows
  clickable → MoonrakerService.openConfigFile(name): downloads /server/files/config/<name> to
  ~/.cache/klipshell/<printer>/ then `kitty -e ${EDITOR:-nvim} <file>`. Dead _fileLabel/_fileColor/
  recentFiles removed.
- ENDSTOPS panel: + RELOAD button (calls fetchMachine, which refetches endstops too).
- Panel.qml collapse chevron color surfaceVariantText → textPrimary (brighter, all views).

### SESSION 10 (Machine layout: rail + Mainsail file/update cards)
- **The size-cycle class is the #1 klipshell layout bug.** A container sized from its parent while
  that parent's size derives from the container resolves to garbage:
  - LOG FILES `height: parent.height - endstops.height - spacing` inside a height-less Column →
    logged `log=-162@162` with the Column at `height=0` → BOTH cards invisible ("missing").
  - `Column { id: fmCol; width: parent.width }` inside a Flickable (parent = contentItem, whose
    width is contentWidth) → the whole page resolved to **1696px**: mbody=1696, fmHead=882, FM
    columns at x=686 inside a 402px card. Fix: bind to the explicit sibling (`width: fmList.width`).
  - Rule: a panel/column inside a Flickable or positioner must never use `parent.width/height`
    when its own size feeds the parent — bind to the scroller id.
- **Geometry probe = eyes for QML layout.** Append a `Timer` to the throwaway /tmp copy that
  console.logs x/y/w/h plus a recursive walk() of Texts; quickshell writes console.log to the
  launch log. Both bugs above were found this way, not by looking at pixels.
- **Font metrics measured (PIL, exact):** JetBrainsMono Nerd Font @14px = 8.406 px/char.
  "1023.9 MB"=75.7 → SIZE box 78; "Sep 15 12:54 PM"=126.1, "Sep 15, 2025"=101 → MODIFIED 106.
  dateOf() now prints 24h ("Sep 15 18:54", 12 chars) to stay narrow. fmSizeW/fmDateW are shared by
  header + rows so they cannot drift apart.
- **Native glyphs** (fc-list ':charset=<hex>' family): U+2713 ✓, U+F0450 (sync), U+F00C, U+2192 ✓;
  U+27F3 ⟳ is NOT native to JetBrainsMono Nerd Font.
- **Machine tab layout:** SYSTEM (full) → manage Row = CONFIG FILES (55%, height = row height) +
  rail Column (45% = the update card's width) holding ENDSTOPS (329×150) / LOG FILES (329×150,
  3 stacked buttons) / UPDATE MANAGER (content height; 10 components ≈ 662). manageRowH =
  max(fmPanelH, railH); railH = endstopPanelH + lg + railCardH + lg + updateRowH.
- UPDATE MANAGER = Mainsail rows: bold `version_info[k].name` + version under it
  ("v0.13.0-745 > v0.13.0-770" in accent), `✓ UP-TO-DATE` chip or `⟳ UPDATE`, System row
  ("13 packages can be upgraded"), footer `⟳ UPDATE ALL COMPONENTS` (updateClient per stale
  component + updateSystem), all gated on canUpdate (not printing/paused, !busy).
  `version_info[k].name` is the display name (cartographer_plugin → "Cartographer Plugin").
- **Launch/instance hygiene:** instances run as `quickshell -p .` (cwd = repo). `quickshell kill
  -p <dir>` kills ONE instance per call; precise kill is `--pid`/`-i` (NOT `-c`, which reads a
  config path). Launching while an instance lives silently refuses ("An instance of this
  configuration is already running") and stacks duplicate windows. Check `quickshell list --all`
  filtered on `Config path: .../klipshell`.

### RESOLVED after SESSION 10 — rail layout + UPDATE MANAGER sizing (2026-09-22)
The side-by-side question in (a)-(d) below was settled by building it: ENDSTOPS | LOG FILES share
one 45%-wide row (each `(parent.width - lg) / 2`, `height: parent.height`), UPDATE MANAGER spans the
rail's full width under them, CONFIG FILES fills the left at `manageRowH`. LOG FILE buttons now
stretch to the card. User has not re-raised (a)-(d).

### UPDATE MANAGER height: charge the body Column's spacing PER ROW (2026-09-22)
The card clipped its own last row (`Panel.clip: true`) because the height formula counted the body
Column's `spacing: Metrics.sm` once instead of once per gap. Measured live: 10 rows →
`colImplicit = 610` = header 30 + System 52 + 9 components × 52 + **10 × 6 of gaps**; body starts at
`bodyTop` 40, so the card needs `40 + 610 + panelPadding 22 = 672`. The old `98 + rows × 52 = 618`
sliced 32px off the bottom row. Correct form:
`updateRowH = max(180, 62 + 30 + updateRows * (52 + Metrics.sm))` — same shape as `endstopPanelH`
(`62 + 26 + sm + rows*34 + (rows-1)*xs`). Any new row-per-component card must include its gap.

### Headless layout verification (use this instead of screenshots)
`console.log` is filtered out of the Quickshell log, `console.error` is NOT. To verify geometry
without a capture: copy the tree to /tmp, append a `Timer { interval: 9000; repeat: true; ... }`
inside the view's root Item that prints heights (`panel.height`, `col.implicitHeight`, `col.y`,
`mapToItem(null,0,0).y`, `mscroll.height`, `mscroll.contentHeight`, and a loop over
`mbody.children` printing each `child.height`/`child.y`), launch with `nohup quickshell -n -p`,
`grep -o "PROBE.*"`. Give any element you need an `id` in the COPY only. Invisible Column children
are skipped by the positioner, so their `y` stays 0 — read the visible ones' `y` to find the gaps.
Measured on this box (window 1902×1022, viewport 1022): SYSTEM 565 + 12 + manage row 888 = 1465
content / 1505 page → the Machine tab scrolls ~483px with 10 update rows. Not a bug; the tab simply
exceeds the window. Freeing ~500px would need: SYSTEM rows ~130 → ~90 each (~200), single-line
update rows (~120), CONFIG FILES cap 14 → 10 rows (~112).

### One-shot view buckets must retry (2026-09-22)
`_freeSlot()` drops a request when all 8 slots are busy, and the Machine view's open burst is 6 at
once — so any single drop left a card blank or lying: CONFIG FILES empty / stuck on the
`config,gcodes,logs` fallback, UPDATE MANAGER "no components reported", SYSTEM "OS: —", 0 B mem.
Fixed by retrying from the 1 s tick while a bucket has never landed (each guard clears itself):
`if (!data.roots) fetchRoots()`, `if (!data.dir && _lastDir) fetchDir(...)`,
`if (!data.machine?.proc) fetchProcStats()`, `?.sysinfo`, `?.update`. `fetchMachine()` now just
calls `fetchProcStats()` + `fetchUpdateInfo()` + `fetchEndstops()`; the update handler still ignores
an empty parse so a cold/timed-out call can't blank the last good report.

### CONFIG FILES: backups hidden behind a toggle (2026-09-22)
Klippain writes `printer-YYYYMMDD_HHMMSS.cfg` before every config change plus loose `*.bkp`/`*.bak`
copies (~80 rows in /config). `isBackupFile()` = `/^printer-\d{8}_\d{6}\.cfg$/i` or
`/\.(bkp|bak)(-|$)/i`; `showBackups` (default false) is toggled by a BACKUPS button in the root
chip row and re-runs `_rebuildRows()`.

### Root chips: selectable ≠ writable (2026-09-22)
Chips used `active: <root permissions contains w>`, which disabled the click for read-only roots
(logs, docs, config_examples) — `Button.active: false` also disables its MouseArea. Chips are now
always clickable (variant shows the current root); the root's `w` bit gates only the write actions
(OK/RENAME/COPY/DELETE/NEW FOLDER/UPLOAD) via a `writable` readonly derived from `rootChips`.

### One klipshell instance at a time — kill before launching (2026-09-22)
User rule, stated directly: "always close klipshell before re checking". Two instances of
`/home/cwebb/dev/klipshell` were found stacked (duplicate windows on their workspaces) because
launches were never preceded by a kill of the *real* tree. `quickshell kill -p <dir>` kills ONE
instance per call, so loop until the count is zero:

```bash
for i in 1 2 3 4 5; do
  n=$(quickshell list --all 2>/dev/null | grep -c "klipshell/shell.qml")
  [ "$n" -eq 0 ] && break
  quickshell kill -p /home/cwebb/dev/klipshell >/dev/null 2>&1
  sleep 1.2
done
```

Then launch once and confirm `hyprctl clients` shows a single `org.quickshell` window. A stale
duplicate also explains "it still looks the same" reports — always count instances before believing
a capture.

### QML: `anchors.leftMargin` is a no-op inside a Row (2026-09-22)
The CONFIG FILES header's NAME sat 6px left of the file names because it carried
`anchors.leftMargin: Metrics.sm` while living in a `Row` — positioners set `x` directly, so anchor
margins do nothing there. Use `leftPadding` (Text padding) instead. Same trap as
`rightMargin`-without-`right`: the header columns are packed by the Row, so the SIZE/MODIFIED gap
is `fmColGap` (Metrics.lg) applied as a `rightMargin` on the row's SIZE text + widened MODIFIED
header box, and the sort MouseArea's hit zones carry the same gap.

### G-CODE FILES tab = a full-tab file table (2026-09-22)
`src/views/History.qml` is gone: the tab labelled G-CODE FILES was rendering the history cards
(JOBS + SUMMARIES). It is now `src/views/GcodeFiles.qml` — the CONFIG FILES card at full-tab size,
11 columns, sideways scrollable. View id renamed `history` -> `files` (4 spots in MainWindow:
`ordered`, `refreshView`, the component line, `Qt.Key_3`), `src/views/qmldir` retargeted, and
`fetchHistory`/`fetchTotals` kept (`Dashboard.qml` reads `data.history.jobs`; totals now ride the new
view's toolbar line instead of a SUMMARIES card). Columns: NAME (absorbs leftover width, floor 320),
SIZE, MODIFIED, LAST PRINTED, PRINT TIME, FILAMENT, LAYER H, OBJECT H, NOZZLE, FILAMENT, SLICER.
Header and rows are built from ONE `fixedCols` array so they cannot drift; the header Row's x is
bound to `-gtable.contentX` to stay in step with horizontal scroll.

v2 (same day, after "not as many columns as Mainsail and not scrollable"): 18 columns — NAME (fixed
340) | SIZE | MODIFIED | LAST PRINTED | EST TIME | PRINT TIME | TOTAL TIME | FILAMENT | WEIGHT |
LAYER H | 1ST LAYER | OBJECT H | NOZZLE | 1ST TEMPS | TYPE | FILAMENT NAME | SLICER | UUID.
PRINT TIME/TOTAL TIME are the ACTUAL durations joined from the `history` bucket by filename
(`_applyHist()` -> `hist` map, newest-first, matched on `path + "/" + name`) — the extended metadata
only has the estimate. **A width-absorbing NAME column is why it did not scroll**: it grew to eat the
leftover viewport, so tableW == viewW and there was nothing to scroll. NAME is now a fixed 340 and
the table is 2668px against a 1652px viewport (~1000px overflow), always scrollable. A Flickable has
no wheel handling of its own (Qt6 has no built-in horizontal wheel), so a `WheelHandler` maps the
plain wheel to `contentX` (clamped to `tableW - width`; vertical only when contentHeight > height),
plus a 4px scrollbar whose thumb is `width * viewW/tableW` — without the visible bar a wide table
just reads as broken. Row 30px, header 24px, all table text `Type.sizeCaption + 1` (15).

### `extended=true` is the whole trick for a metadata table (2026-09-22)
`GET /server/files/directory?path=gcodes&extended=true` returns "all available metadata fields"
inline per file (docs: moonraker.readthedocs.io external_api/file_manager) — slicer,
slicer_version, estimated_time, filament_total (mm), layer_height, object_height, nozzle_diameter,
filament_type, first_layer_*_temp, **print_start_time**, job_id, uuid. One request feeds the entire
G-CODE FILES table. `GET /server/files/metadata?filename=` is ONE FILE PER REQUEST (klip-tui only
ever calls it for the currently printing file) — never build a table on it with an 8-slot pool.
`/server/files/list?root=gcodes` has no extended form and only returns path/modified/size.
Service side: `fetchGcodeFiles(path)` -> `data.gcodes` (`{path, dirs, files, disk}`) +
`bucketChanged("gcodes")`, `_lastGcodePath` gates a tick retry, demo seed carries the metadata fields.

### HISTORY tab (new, 2026-09-22)
Sidebar is now Dashboard / Console / G-CODE FILES / **HISTORY** / Machine / Layermind — `id: "hist"`,
`src/views/History.qml`, registered in `src/views/qmldir`. Keys shifted: 4=hist, 5=machine, 6=layermind.
Mainsail's history page: a STATISTICS card (5 KV rows + a job-status donut + a filament/print-time bar
chart over the last 19 jobs) over a searchable PRINT HISTORY card (status glyph | thumbnail+FILENAME |
START TIME (sortable, newest first) | EST TIME | PRINT TIME | FILAMENT USED | SLICER). Every column is
free: `/server/history/list` job entries carry `metadata` (the full gcode metadata screenshot minus
job_id/print_start_time) — slicer, slicer_version, estimated_time, thumbnails — inline, so no per-row
fetch. Thumbnails load straight from Moonraker over HTTP (`baseUrl` + `/server/files/gcodes/` +
dir(filename) + `thumbnails[].relative_path`) via QtQuick Image, gated on `!demo` because a failing
Image retried ~2/s and flooded the log with "Network unreachable" (50 warnings in 26 s).
New components: `Donut.qml` (multi-segment Canvas ring) and `Bars.qml` (Canvas bars + 5 gridlines +
nice 1/1.5/2/3/5/7.5/10 axis; Chart.qml's rule holds — vectors in Canvas, all text as Item overlays).

### `fetchTotals` never unwrapped `job_totals` (fixed 2026-09-22)
`/server/history/totals` returns `{job_totals: {...}, auxiliary_totals: [...]}` and the service stored
the whole envelope, so `data.totals.total_print_time` and friends were ALWAYS undefined — the old
SUMMARIES card and every KV that read them had been rendering "—" since it was written. Store
`r.job_totals || r` (accepts both shapes). The demo seed also had no `data.totals` at all, so the stats
card read empty in demo mode too; it now seeds job_totals-shaped numbers and fires the bucket.

### A Row/Column with no bottom anchor sizes to its tallest child (2026-09-22)
The STATISTICS card's body was `Row { anchors.top: parent.top + 28 }` with no bottom anchor, so its
height came from the tallest child (`kvs`, 5 rows = 132) — and `chartBox.height: statBody.height` then
starved the bar chart to ~96px of a 250px slot. Anchor the row to `parent.bottom` and let each section
centred itself (`anchors.verticalCenter: parent.verticalCenter`) or fill (`height: statBody.height`).
Measured after: statBodyH 310, chartH 310, kvsY 76 (exactly centred), donut stack 291 with 10px slack.
`statsH: 360` is chosen so the donut(172) + caption + 4-row legend(291) stack fits `statsH - 50`.

### HEIGHTMAP research (2026-09-22) — references, exact spec, 3D feasibility
**Mainsail's bed mesh is ECharts GL, not hand-rolled 3D.** `package.json` has `echarts` + `echarts-gl`
(no three.js); `src/components/charts/HeightmapChart.vue` is a `surface` series from
`echarts-gl/charts` + `Grid3DComponent` + `VisualMapComponent`, canvas renderer.
Reference pages: https://docs.mainsail.xyz/features/bed-mesh (annotated overview image
`https://docs.mainsail.xyz/images/features/bedmesh-overview.webp`) and
https://docs.mainsail.xyz/settings/heightmap (orientation + colour-scheme pickers). All image URLs 200.
Extracted spec (ground truth for our build):
- THREE stacked surface series, independently toggled: `probed` (raw `probed_matrix`), `mesh`
  (computed `mesh_matrix`), `flat` (z=0 plane, white @ 0.5). Z values spread over `mesh_min` ->
  `mesh_max`; `dataShape: [yCount, xCount]`.
- The axis BOX spans the whole motion envelope: `toolhead.axis_minimum[0..1]` -> `axis_maximum`, with
  `boxWidth/boxDepth = 100 * range / min(rangeX, rangeY)` so the bed keeps its aspect in the box.
- `zAxis3D` is symmetric: `min = -scaleZMax, max = +scaleZMax` (the Z-scale slider) — deviation is
  always centred on 0.
- visualMap: `dimension: 2` (Z), range `[-0.1, 0.1]` by default, or the mesh's own min/max when
  `scaleGradient` is on; vertical bar left, ~550 tall, `precision: 3`.
- Palettes (verbatim): portland(default) `#313695 #4575b4 #74add1 #abd9e9 #e0f3f8 #ffffbf #fee090
  #fdae61 #f46d43 #d73027 #a50026`; spring `#ff00ff #ffff00`; hot `#000000 #ff0000 #ffff00 #ffffff`;
  hsv `#0000ff #00ffff #00ff00 #ffff00 #ff0000`; grayscale `#ffffff #000000`.
- viewControl: `distance: 200`; orientations alpha/beta = rightFront 25/40, leftFront 25/-40,
  front 25/0, top 90/0.
- Wireframe = per-series `wireframe: {show}`. Tooltip = series + X/Y (1dp) + Z (3dp) mm.
- Mesh density: `mesh_matrix` dims are `(probe_count - 1) * mesh_pps + probe_count` (Klipper
  bed_mesh.py:1350) — 5x5 probes at default `mesh_pps 2,2` -> 13x13 mesh vs 5x5 probed.
**QtQuick3D WORKS in Quickshell here** (verified 2026-09-22): `import QtQuick3D` and
`import QtQuick3D.Helpers` both resolve, a `View3D` + `OrbitCameraController` + `PerspectiveCamera`
instantiated and the FloatingWindow mapped (probe config, `renderMode=0`, no errors). Qt 6.11.2,
qt6-quick3d installed. Caveats found: `PrincipledMaterial` on this Qt has NO vertex-colour property
(ql-lookup: only `lighting`/`baseColor`) — a Z->colour ramp needs a `CustomMaterial` (shadertools is
installed) or the shorthand of a Geometry with UV = normalised Z + a gradient `baseColorMap`
(`Texture.sourceItem`). No GL-style wireframe. A View3D exposes no pixel readback, so a 3D render can
only be confirmed by eye; a Canvas projection can be checked by numeric probe.

### HEIGHTMAP tab implementation (2026-09-22) — QtQuick3D ground truth
Built in `src/views/Heightmap.qml` + `fetchBedMesh()` in MoonrakerService. Durable API facts:
- Geometry: `ProceduralMesh` lives in **QtQuick3D.Helpers** (6.6+), properties `positions`/`normals`/
  `tangents`/`binormals`/`uv0s`/`uv1s`/`colors` (QVector4D)/`joints`/`weights`/`indexes`/`primitiveMode`.
  `PrimitiveMode` has Points/LineStrip/**Lines**/TriangleStrip/TriangleFan/Triangles — that is how the
  wireframe is done (QtQuick3D has no GL wireframe mode).
- **`vertexColorsEnabled` is on DefaultMaterial, NOT on PrincipledMaterial** (PrincipledMaterial has
  `VertexColorMask`/`VertexColorMaskFlags` instead, and ql-lookup's grep hides it — read the .qmltypes
  block past the first ~30 properties). **`alphaMode` is on PrincipledMaterial, NOT on DefaultMaterial.**
  Enum scoping: `PrincipledMaterial.Blend` (AlphaMode declared there), `Material.NoCulling` (CullMode on
  Material — `DefaultMaterial.NoCulling` still works but isn't where it's declared),
  `DefaultMaterial.FragmentLighting|NoLighting` (Lighting is declared on both materials).
- `OrbitCameraController` (a QML file in Helpers, so ql-lookup finds nothing) needs `origin` to be a
  **Node that you rotate** with the camera as its child at +z: `Node { eulerRotation: (-alpha, beta, 0)
  PerspectiveCamera { z: dist } }`. Rotating the camera node itself orbits around the camera, flinging
  the bed out of frame. It works as a sibling overlay Item over the View3D (not only inside it).
- World axes used: X = bed X, Y = height, Z = **-bed Y**, so the default camera sits in front of the
  bed's low-Y edge. Heights are baked already exaggerated: `±zScaleMax` maps to `±zHalf`
  (`envSpan * 0.25`), so the Z-scale slider changes geometry (169 verts — cheap) and normals stay true.
- Winding `[a, b, e, b, d, e]` per cell yields +Y face normals (verified: every vertex normal y > 0);
  vertex normals from `cross(t1, t2)` with t1 along +i and t2 along +j.
- The `mesh_min`/`mesh_max` grid is placed inside the `toolhead.axis_minimum/axis_maximum` envelope,
  centred on the envelope centre — that framing is what Mainsail does.
- Demo mesh: `_demoMesh(rows, cols, min, max, scale)` samples a centre dish + slight Y tilt so the demo
  has real variance per profile; the mesh is sampled at 13x13 (the pps-expanded size) and the probed at 5x5.
- Verified by probe, not by eye: 169 verts / 288 tris / 312 wire segments for the 13x13 demo, all normals
  up, ramp `[-0.049, 0.075]`, `colorOf(lo)=stops[0]`, orientation and z-scale writes reactive.
  **A View3D exposes no pixel readback — a 3D render can only be confirmed by screenshot.**

### The half-black surface was a WINDING bug, not a shading bug (2026-09-22)
First screenshot of the HEIGHTMAP tab showed the mesh as alternating coloured / black triangles. Vertex
normals were all +Y (I probed that and it passed) but **half the triangles were wound the other way**,
so `gl_FrontFacing` was false for them and the renderer flipped their normal into the light → unlit.
Per-cell pair must be `(a, b, e)` + `(b, e, d)`, both counter-clockwise seen from above; `(b, d, e)` is
the mirror of the pair. **Probe FACE normals, not just vertex normals** — a per-triangle
`cross(B-A, C-A).y > 0` check over `idx` steps of 3 is the test that catches it (0 down faces after the
fix, 144 down before). Same trap applies to any ProceduralMesh surface.
Surface material is now `DefaultMaterial { lighting: NoLighting; vertexColorsEnabled: true }`: shading
multiplies the legend colours by the light, so one height read as two colours depending on slope, and
the user asked for the gradient to be the information. FLAT now defaults off — with a mesh that spans
both signs, the translucent z=0 plane interpenetrates the surface and dithers.

### Colour scheme labels are gradient-descriptive (2026-09-22)
Internal keys stay Mainsail's (`portland`/`spring`/`hot`/`hsv`/`grayscale` — they are the palette data),
but the UI labels are "BLUE → RED", "MAGENTA → YELLOW", "FIRE", "RAINBOW", "GRAY" per the user's pick.
Palette buttons are 164 wide (Button.implicitWidth for 16 chars at `controlPaddingX 16`) so the longest
label does not overflow, + a 130px gradient swatch = 300 of the 322 rail.

### Heightmap data plumbing + tab wiring (2026-09-22)
`MoonrakerService.fetchBedMesh()` — one request, `/printer/objects/query?bed_mesh&toolhead=axis_minimum,axis_maximum`
(comma list = sub-keys; `toolhead` rides along because the view frames the motion envelope). Stored as
`data.bedmesh` = `{meshMatrix, probedMatrix, min, max, profile, profiles, params, axisMin, axisMax}`,
bucket `bedmesh`, one-shot + `_bedMeshWanted` flag so the 1s tick retries until it lands. Demo seed
builds a 350mm dish+tilt: `_demoMesh(rows, cols, min, max, scale)` sampled at 13x13 (the `mesh_pps`-expanded
size) and 5x5 (probed), three profiles differing only in dish depth so the variance column has values.
Sidebar: labels are ALL CAPS, `HEIGHTMAP` (key 5) and `GCODE VIEWER` (key 6) sit after HISTORY, so
MACHINE moved to 7 and LAYERMIND to 8. `MainWindow.refreshView()` dispatches `heightmap` ->
`heightmapView.refresh()`.

### G-CODE VIEWER — starting points for next session (2026-09-22)
Tab already exists as an empty `Panel` (`src/views/GcodeViewer.qml`, id `gcodeview`, registered in
`views/qmldir`, instantiated in MainWindow, has `required property QtObject moonraker`).
Mainsail's viewer is the npm package **`@sindarius/gcodeviewer`** (in its package.json) — a three.js
WebGL renderer, i.e. the same class of thing as the heightmap's echarts-gl surface. Feature reference:
toolpath render, layer slider + layer navigation, print/travel move filters, colour by feature type or
feedrate, progress marker, live toolhead marker.
Data: Moonraker serves the raw file at `/server/files/gcodes/<path>`; parsing happens client-side. The
service already has `data.gcodes` / `data.dir` (file listings) and `print_stats` / `virtual_sdcard`
progress for the live marker. **Printer was offline all session** (http_code 000 at 192.168.1.50:7125), so
add a generated demo gcode body to `_seedDemo` to develop against.
Known hard part: toolpaths are 100k+ segments — a Canvas repaint per frame will not hold. Plan for
layer-scoped rendering and/or caching, and measure before committing to an approach. Reuse the Heightmap
Canvas projection rather than QtQuick3D (see the block above); that will be the second call site, which
is when extracting a shared projection helper is justified.

### HEIGHTMAP surface is a Canvas projection, NOT QtQuick3D (2026-09-22)
The QtQuick3D version was abandoned after it kept dropping part of the surface. Verified cause with a
reliable metric (see below): **1 procedural Model = solid (1.42% enclosed holes); several Models =
12-18% holes**, regardless of material (plain PrincipledMaterial vs vertex-coloured DefaultMaterial),
whether `indexes` were used at all (non-indexed was worse), or whether the extra Models were emptied.
`Model.visible: false` does nothing inside this View3D either (literal `false` on three Models still
rendered their pixels). Geometry itself was proven correct: 288 triangles, 0 degenerate, correct
vertex positions, every face normal +Y, `primitiveMode=5` (Triangles). So: QtQuick3D procedural
geometry in the Qt 6.11.2 / Quickshell 0.3.1 combination is unreliable — reach for Canvas instead.
`src/views/Heightmap.qml` now projects the mesh itself: eye on a sphere (elevation camAlpha, azimuth
camBeta, `zoom`), `fwd/right/up` basis, 45° vertical fov, `_screen()` perspective divide, cells sorted
far-to-near and painted with a `createLinearGradient` between each cell's lowest and highest corner,
plus a 1px matching stroke to kill anti-aliased seams. Flat z=0 reference quad is just another quad in
the same sort. Wireframe strokes the grid after the fill. Drag rotates (MouseArea), wheel zooms.
`requestPaint()` must be called by every control that changes what is drawn — Canvas does not
repaint on property changes.

### Verifying a rendered surface without eyes: grabToImage + flood-fill (2026-09-22)
`viewBox.grabToImage(cb)` works on Quickshell items **including a View3D's output**, and saves from QML
via `res.saveToFile(path)`. The trustworthy hole metric is **flood-fill**: classify background by
`max(r,g,b) <= 40`, flood-fill from the image border, then any background pixel never reached is an
enclosed hole. Row-span heuristics are useless here — a concave silhouette and the 2D legend overlay
both inflate them badly (a legend-contaminated run scored 66% for a solid surface).
Projection sanity checks used: top view (alpha 90) must give equal depths and an axis-aligned square
centred on the viewport; `colorOf(ramp[0])` must equal the palette's first stop.

### What Mainsail's heightmap has that we still do not (2026-09-22)
Title-bar actions — CALIBRATE (`BED_MESH_CALIBRATE`), HOME (`G28`), CLEAR MESH (`BED_MESH_CLEAR`),
and SAVE CONFIG (which appears only after a calibration). Profile actions — click the loaded profile
name to rename, delete a profile, and LOAD a profile (`BED_MESH_PROFILE LOAD=`). Hover tooltip
(X/Y/Z readout, Z to 3 decimals). All of these are G-code, so they belong behind the confirm-dialog
bridge, not inline. The hover readout is easy now that the Canvas owns the projection (hit-test cells).
Already covered: current-mesh panel (profile/size/range/variance/grid), profiles list with per-profile
variance, PROBED/MESH/FLAT toggles, wireframe, Z scale, scale-to-profile, orientation, colour schemes.

### Card vs Panel headers — they are NOT the same chrome (2026-09-22)
Machine and Dashboard cards are `Panel { title: ... }`: square, flat `surfaceContainerLow`, no rounded
corners/shadow, and a 34px header band (`accent@12%` fill, `accent@40%` 2px border) with the title
CENTRED in `Type.sizeSmall` bold `Colors.accent`, plus a chevron unless `collapsible: false`. Body
children anchor to `parent.bodyTop` (= headerH 34 + 6) with `visible: parent.bodyVisible`.
`Card { header: ... }` is different chrome: rounded, soft shadow, header text LEFT-aligned at
`panelPadding`, `Type.sizeCaption` (14) bold bright `textPrimary` — which is why the HISTORY tab's
cards looked off until they were switched to Panel. Panel has no outer border (only the header band
carries one).

### Ring/legend/chart polish (2026-09-22)
Ring: stroke `min(18, w*0.105)` (was `min(22, w*0.15)` — too fat at 150px), and a 2° gap between
segments clamped to `sweep*0.3` so thin slices survive. Live matugen palette ≠ the defaults in
Colors.qml (tertiary resolved to #e7beae, not the file's #d3c78f) and tertiary/tempWarm are adjacent
hues, so status colours are: completed tertiary, cancelled tempWarm, interrupted `outline` (gray),
error `tempHot` (#dc2626 saturated — `error` #ffb4ab is too close to the peach primary). Bars: width
cap 28 -> 44 (`slotW*0.62`) so 4-19 bars do not read as hairline slivers.

### QML: nested Repeater delegates have no parent at creation (2026-09-22)`delegate: Text { anchors.verticalCenter: parent.verticalCenter }` inside a Repeater that is itself
inside the row's Row threw `TypeError: Cannot read property 'verticalCenter' of null` **900 times in
22 s** — the Repeater creates its delegate parentless and assigns `parent` afterwards, so every
layout pass re-evaluates the binding against null while declared children (parent set at creation)
are fine. Anchor to an id ('growRow.verticalCenter') instead. Geometry probe caught it; a screenshot
would have looked perfect.

### OPEN at end of SESSION 10 — Machine layout "still not correct" (UNRESOLVED)
The user's ask sequence, verbatim (they are ground truth; each supersedes my reading of the last):
  1. "I want the CONFIG FILES and UPDATE MANAGER side by side not stacked."
  2. "The LOG FILES and ENDSTOP card can each be the size to they match the width of the UPDATE
     MANAGER then the CONFIG FILES can take up the rest of that space."
  3. "This should be easy, the ENDSTOP and LOG FILES cards will end up being the same size in the
     right column with the CONFIG FILES taking up rest of space."
  4. "this is still not correct" — no detail given yet.

Implemented and measured live (qmllint 0, boot clean, geometry verified by console.log probe):
  SYSTEM (full) → one Row = [ CONFIG FILES 55%, height = row height ] + [ rail Column 45%:
  ENDSTOPS 329×150, LOG FILES 329×150 (3 stacked full-width buttons), UPDATE MANAGER 329 × content
  (≈662 with 10 components) ]. manageRowH = max(fmPanelH, railH);
  railH = endstopPanelH + lg + railCardH(150) + lg + updateRowH.

Most likely mismatches — ASK before changing anything, do not guess-fix:
  a) The rail cards are stacked. Ask (2) and (3) both say the two small cards are "side by side,
     not stacked"; (2) also says each should be the UPDATE MANAGER's width. Those two are only
     compatible if the small pair sits in its own row (2×45% ≈ 90% of the width) — confirm which
     constraint wins.
  b) "the same size" may mean all three right-column cards share a HEIGHT, not just a width
     (railCardH is 150 for ENDSTOPS/LOG, 662 for UPDATE MANAGER).
  c) With data loaded the row is ~986px tall (UPDATE MANAGER 662), so CONFIG FILES stretches to
     986 and the tab scrolls a long way; pre-data it is 504 → a visible jump on tab entry.
  d) LOG FILES buttons are only 25px tall in a 150px card — possibly too small.
Next step: get ONE concrete statement of what looks wrong (a staged screenshot via /ss is ideal),
fix only that. Do not re-ask the entire layout question from scratch.

### Theme separation pass — text ladder + verified icon set (2026-09-23)
The live matugen scheme is **tonal and monochrome**: primary/secondary/tertiary/onSurface all land
within 1% of the same luminance (10.86–10.89:1 on surface) and the containers span just 1.04–1.50:1.
Accent-as-text (KV labels, panel titles) is therefore *unfixable* by application code — it reads as
body text no matter where it is used. Separation now comes from a derived lightness ladder in
Colors.qml (textPrimary 14.3:1 = surfaceText, textSecondary 10.9:1 = surfaceVariantText, textTertiary
~5.6:1 = 70% composite, textMuted ~2.9:1 for disabled/placeholder only) plus weight, spacing and
icons. Grammar to hold: **accent = interaction/selection, textPrimary = data, textSecondary = labels,
textTertiary = caps labels/units/meta/hints, textMuted = disabled/placeholder**. `success` (#4ade80)
and `edge`/`edgeStrong` were added; the old 61 ad-hoc `Colors.alpha(...)` text calls are swept and
`Colors.tertiary` no longer appears anywhere (it was beige — used as a "good/ready" signal it was
invisible). If hue separation is ever wanted, that is a matugen scheme-variant change, not code.

### Icons: Nerd Font, generated not hand-typed (2026-09-23)
`src/theme/Icons.qml` (62 glyphs) is GENERATED by `tools/check-icons.py --write` from the installed
`JetBrainsMonoNerdFont-Regular.ttf` cmap; the same script verifies in CI mode (codepoint present,
literal matches the comment, glyph has contours + non-zero advance, name not a QML reserved/global
word). Glyphs are supplementary-plane (+U+F0000), which `\uXXXX` **cannot** express — they must stay
literal characters; Machine.qml had 5 pre-existing `\uF0450` escapes that rendered `U+F045` + a
literal `0`. Edit the GROUPS table, re-run `--write`; never hand-add a glyph.

### qmllint's three silent killers (2026-09-23, all hit in one session)
1. Assigning `implicitWidth/implicitHeight` on a **positioner** (Row/Column/Flow) — read-only; the
   whole config fails to load with "Type X unavailable". Use `height:`.
2. `anchors.left/right/horizontalCenter/fill/centerIn` on a **direct child of a positioner** — scene
   warning, the Row stops functioning. Wrap in an Item.
3. A property named after a **QML global** (`console` is the trap; also `eval`, `window`, `parent`) —
   "Illegal property name" at load, and qmllint says nothing.
None are lint errors. A real launch is the only detector; `tools/check-icons.py` now guards (3) for
icon names.

### Pixel-verifying visual work: grabToImage is unreliable in proxy windows (2026-09-23)
`item.grabToImage()` inside a Quickshell `FloatingWindow` returns wrong sizes and phantom content
(the window is a ProxyWindow; a window-sized grab came back 1736×1022 for a 1570 px item, and a
body grab showed a 50 px light band that does not exist on screen). Small item grabs (a canvas)
were trustworthy; large/window-relative ones were not. Use the sanctioned path instead:
`shot focus-empty` → launch → `hyprctl clients -j` for the exact `{at,size}` rect → `shot onws <ws>`
→ crop to the rect → `shot restore-ws`. That produced clean evidence for both the dashboard and the
viewer.

### Large g-code bodies: measured, and the reason they hurt (2026-09-23)
`GcodeParse.js` is plain JS, so it can be benched outside QML: a synthetic 1.2M-line / 32.6 MB body
→ parse 1.3 s, 181k segments, **366 MB heap / 532 MB rss**; a 5.4 MB body → 80 MB / 186 MB. The body
is held three times (service `data.gcode.text`, `job.lines`, plus the segment arrays) and nothing
caps input size. Growing the ceiling means dropping the bucket text after parse and/or refusing
bodies above a cap.

### Audit: encodeURIComponent does not escape the quote (2026-09-23)
`downloadLog()` in MoonrakerService is the one shell-composing site missing `root._sq()`; JS's
`encodeURIComponent` leaves `'` (and `! * ( )`) intact while encoding `; | $ \` space /`, so a
filename like `it's.log` breaks the single-quoted command (`bash -n` → syntax error, download fails)
and the break-out admits a subshell expression. Every other site escapes. Full audit report:
`/tmp/klip-shell-audit-20260923.md`.

### Dashboard card heights: the Repeater pitch trap (2026-09-23, user-reported clipping)
The user reported the STATUS card as "too short, buttons at the bottom cut off". Geometry probe (not
pixels) found TWO independent under-sizes:
  - **Panel**: `_statusHeight()` was `292 + n*26`, but a `Repeater` inside a `Column` is transparent
to the positioner — its **delegates become Column children**, so they carry the column's `spacing`.
File-row pitch is **26 + 8 = 34**, not 26. Panel was 422 for 428 of content → the Panel's `clip: true`
cut the last row by 6px.
  - **Inner print card**: a hardcoded 92px held two rows of 30 + 8 + 43 = 81 plus 12px top/bottom
margins = 105 → the read-out row (STATE/PROGRESS/ELAPSED/LEFT) was clipped by 13px.
Fix pattern now in use: one shared constant for the card (`statusCardH = 24 + 30 + Metrics.md + 43`)
consumed by BOTH the card's `height` and the panel formula, and the panel formula counts real pitch
(`n*26 + (n-1)*Metrics.md`). Post-fix probe: panel 417, content 355+40, exactly `Metrics.panelPadding`
(22) of bottom padding, card 105 for 105 needed. **When a Repeater sits inside a Column/Row, count the
spacing per delegate — and never trust a height constant that predates the content.**

### Row top-aligns its children: dots and small glyphs look off (2026-09-23)
The printer-select chip's 7px status dot had NO vertical anchor and sat high against the 16px name —
a `Row` positions children itself and leaves y alone, so a small child reads as top-aligned. Fix: put
the children in an anchored `Item` (or add `anchors.verticalCenter` to each child; vertical anchors
are allowed inside a positioner, horizontal ones are what trigger the scene warning). Fixed in the
sidebar chip and in the printer-menu rows; verified by measuring dot centre 982.0 vs chip centre 983.0.

### Button variants: `danger` vs `solid` (2026-09-23)
`variant: "danger"` = error TEXT on a 16% error wash (unchanged everywhere). The user wanted a genuinely
red E-STOP, so Button gained `solid: true` → `errorContainer` fill + `errorContainerText` label, and
only the E-STOP sets it. Verified on-screen: `#93000a` appears on exactly 2008px, all inside the header
button (x 1780–1880, y 3–26). Deliberate choice: do NOT make every danger button solid — macro
CANCEL/ABORT and FIRMWARE RESTART keep the tinted treatment. The status card's PAUSE/CANCEL/E-STOP
buttons now live in a 26px bar at the TOP RIGHT of the dashboard (in the 30px band the Flickable
reserves with `anchors.topMargin: 30`), not in the card.

### Sidebar nav: icons yes, key numbers no (2026-09-23)
Nav rows are icon (18px, textTertiary / accent when active) + label. The 1–8 key-hint numbers were
added then removed at the user's request — do not re-add them. With the numbers gone the longest
labels (G-CODE FILES, GCODE VIEWER) reach x≈150 inside a 158px inner edge, so there is no room for a
right-aligned hint anyway.

### Dashboard chrome band vs the Flickable clip (2026-09-23)
The transport buttons (PAUSE/CANCEL/E-STOP) + bell are siblings declared BEFORE `scroll`, and
`scroll` is a Flickable with `clip: true` — later siblings paint on top. With `anchors.topMargin:
30` the clip boundary sat 20px above the cards' rest position (cards start at the full band,
`chromeBand = 30 + panelMargin = 50`), so scrolling slid cards up through the 30–50 strip and
PAINTED OVER the bottom of the buttons ("scroll cuts off the button"). Fix: the Flickable's
`anchors.topMargin` IS `root.chromeBand` (clip below the whole band) and `body.y` went `panelMargin`
→ `0` with `contentHeight` padding `*2` → `*1`, keeping card rest positions byte-identical. Any
tweak to the band height must move the Flickable clip with it, not a bare literal.

### Fan speeds read 0% — object query needs the FULL Klipper key (2026-09-23)
Live bug, user report: "controller fans spinning full but show 0%". Root cause: `fetchFans` stripped
the `heater_fan ` prefix and queried the bare config name. Klipper matches object queries by the
FULL object key, so `?controller_fan` returns `{}` (no error) and every `heater_fan` read 0 — the
plain `fan` object is the only one whose config name equals its object key, so it was the only one
that ever looked alive. Verified live: `?hotend_fan&controller_fan&controller_fan2` → `{}` for all
three, while `?heater_fan%20hotend_fan&heater_fan%20controller_fan&heater_fan%20controller_fan2` →
`{"speed":0.5}`. This user's fans are `[fan]`, `[heater_fan hotend_fan]`, `[heater_fan
controller_fan]`, `[heater_fan controller_fan2]`. **Fan shape is now two fields**: `name` = the
Klipper config name (what `SET_FAN_SPEED`/`SET_HEATER_FAN_SPEED FAN=` take), `object` = the full
object key used for the query and the status-response lookup. Do NOT collapse them back into one.
Same family as the `?`-on-first-name-only and `&`-leading bugs — object queries fail silently.

### Card height arithmetic must count the Column's 8px gaps (2026-09-23)
A Column puts `Metrics.md` (8) between every pair of children, so a row's pitch is height+8, not
height. Live-measured fixes (probe logged `Column.implicitHeight`): CONSOLE was `106 + 26n` (ignored
the gaps, so the bottom transcript row was always cut). Current, matching the measurement exactly:
- `_miscHeight()` = `40 (bodyTop) + 22 (caption line) + md + rows + panelPadding + xxl`, `rows = n*40
  + (n-1)*md` or 38 for the empty state. → 296 at 4 fans, rows end at y=214, clearance 20. The extra
  bottom room was a user ask (twice). **Before growing it again, read the next paragraph.**
- console content = `38 (input) + 1 (rule) + 8 + 8 (gaps) + transcript + 22 (pad)`, so
  `consoleChromeH = 117` and `consoleBaseH = 109 + 34 * max(1, min(lines, 5))`.
The 22 is the real rendered height of a `Type.sizeSmall` (16px) line — do not assume 16 or 20.
A `Column` DOES skip invisible children (the fans empty-state Item contributes nothing when fans
load) — confirmed by the 22+8+184=214 measurement.

### "Text is cut off" was never vertical — measure before inflating (2026-09-23)
The `ControllerFan2` complaint burned three rounds. Ground truth, measured in the live tree: the fan
name Text paints **134px in a 140px column with `Text.truncated === false`** — Qt never clipped or
elided it, and the fan rows end at y=214 in a 266–296px card, so there was never a vertical clip
either. The real problem was that 6px of slack + a 10px gap to the slider made the name and the
slider track read as touching, so it *looks* clipped. Fix: name column 140 → **190**, slider `x` 150
→ **200** (`width: parent.width - 200 - 52`). Two lessons: (1) `Text.truncated`/`paintedWidth` vs
`width` settles "is it cut?" in one probe — reach for it instead of inflating a box; (2) **the
staged screenshot was from a build 30px shorter than the live tree** — derive the build's real size
from the image scale (known slider track ≈596px wide) before trusting that the user is seeing what
you just changed. They were not.

### Macro chips: the Row is icon + label, and the label has `letterSpacing` (2026-09-23)
User: some macro labels "too big for buttons", "no icons on these buttons". Both were ONE bug:
`_macroChipW` sized the chip from `len * sizeCaption * 0.62` only, capped at 200. But `Button`'s
content Row is `icon (iconInline + xs) + label`, and the label sets `font.letterSpacing: 0.8` — so the
real need is `len * (sizeCaption*0.62 + 0.8) + controlPaddingX*2 + iconInline + xs`. Measured:
`_TOOLHEAD_PARK_PAUSE_CANCEL` needed **285px in a 200px chip**, so the label spilled out both sides
and the centred Row pushed the `Icons.gcode` glyph into the 6px gutter between chips — it was set all
along, just shoved outside the chip. Now 306 vs 262 content, cap raised 200 → 400 (the old cap alone
clipped the long names). `_macroVariant` (danger/primary/soft by name) was deleted — user wanted one
highlight colour, so every chip is `variant: "plain"`. **Any chip whose width is computed away from
Button must add both the icon prefix and the 0.8/char letterSpacing.**

### Macros were empty — no bare `gcode_macro` object + a dropped one-shot (2026-09-23)
`fetchMacros` queried `/printer/objects/query?gcode_macro`, which Klipper answers with
`{"gcode_macro": {}}` and no error — there is no bare `gcode_macro` object, each macro is its own
`gcode_macro <NAME>` (16 on this printer). Names now come from the object list, filtered on the
`gcode_macro ` prefix and stripped with `.slice(12)`, sorted. It is published from `_syncObjects`'
callback (`_publishMacros`) rather than a request of its own: `fetchMacros` runs once at dashboard
open, and that lone request was DROPPED by `_freeSlot()` behind the connect burst — proved by
re-probing (still 0 with a dedicated fetch, 16 the moment it hung off the shared object sync).
**General trap: any request fired exactly once at a view open can vanish silently — hang it off a
repeating fetch or expect it to lose to the connect burst.**

### Control panel + CONSOLE fills its column and scrolls (2026-09-23)
The console is always the last card in its column; anything below it up to the taller column /
viewport bottom was dead space. `_consoleHeight()` = `consoleBaseH + max(0, max(otherColumnH,
scroll.height - panelMargin) - ownColumnH)`. The oscillation trap: growing the console changes
`pHeight`, which the balancer reads — so `_partition()` balances on `_balanceH(id)`, which pins the
console at `consoleBaseH` (and 34 when collapsed). Without that pin the fill and the balance feed
each other. The transcript is now a `Flickable` (`consoleScroll`) sized `_consoleHeight() -
consoleChromeH`, holding ALL `consoleLines` — no more `slice(-n)`; it pins to the bottom on new
content (`pinBottom`, released when the user scrolls up) and ScrollBar-less wheel scrolls. Removing
the slice means macros loading grows the MACROS card, which shrinks the console fill (live 433 →
319 once macros went from 0 → 16) — that is the fill working, not a regression.
Live: columns level at grid 1408, `scroll = 972`.
SUPERSEDED 2026-09-24: that window was sized ~1736×1022 by the seat, NOT by `implicitWidth/Height`
(1000×660 at the time). Geometry is now the implicit pair itself (1900×1060, no Hyprland rule) — see
the GEOMETRY section at the top. Read `scroll.height` for the body; never derive layout from a
hardcoded window size.

### Button content nudge (2026-09-23) — REMOVED 2026-09-24
`Button` used to expose `contentNudge` (offsets the centred content Row via `anchors.verticalCenterOffset`),
`iconOffsetX` (`anchors.horizontalCenterOffset` on the glyph) and `iconOffsetY` (added on top of
`Type.iconGlyphNudge`); the dashboard transport buttons (PAUSE/CANCEL/E-STOP) set
`contentNudge: 1; iconOffsetX: -1; iconOffsetY: -1`. **All four are deleted as of 2026-09-24** —
JetBrainsMono Nerd Font Mono draws glyphs one cell wide and centred, so the compensations were
compensating for the non-Mono variant only. `grep` for the names returns nothing; do not reintroduce
them for a glyph that "sits high". PAUSE/RESUME is still `variant: "plain"`, not `"primary"` —
the user wanted it to match CANCEL's flat treatment, no accent fill.
Card chip rows: the EXTRUDER amount chips (5/10/50/100) sit in a 242px right-anchored zone centred
under RETRACT/EXTRUDE (same zone width the button pair uses), and TOOLHEAD's MOVE chips are
0.1/1/10/25/50/100 in a centred row (6×56+5×6=366, fits the ~430px card inner width).
