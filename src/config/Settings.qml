pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "settings-logic.js" as Logic

// User settings that outlive the app: jog steps and bed feedrates, which macros
// the MACROS card shows and in what order, whether the destructive actions ask
// first, the default printer, per-printer Moonraker API keys, the IP-mask
// toggle, and the shell knobs (poll cadence, console scrollback, notification
// cap).
//
// Stored in ~/.local/state/klipshell/settings.json (the same per-store pattern
// dashboard.json and viewer.json use) and NOT in src/config/printers.json: that
// file describes the printers and is the one you copy to another machine or
// check in — an API key belongs in per-user state. (klipshell is not actually
// under git today; the rule is written so it stays true if it ever is.) Every write replaces the whole `data` object so bindings on nested
// fields re-evaluate — mutating in place would leave them stale.
// The sanitising rules live in settings-logic.js and are covered by
// `node src/config/test-settings.js`.
QtObject {
    id: root

    property var data: Logic.defaults()
    // Set once settings.json has been read (or found missing), so consumers that
    // start before it lands — the printer list, the first poll — can react.
    property bool loaded: false

    readonly property var toolheadSteps: root.data.jog.toolhead
    readonly property var extruderSteps: root.data.jog.extruder
    readonly property real bedXYRate: root.data.jog.bedXY
    readonly property real bedZRate: root.data.jog.bedZ
    readonly property bool confirmStart: root.data.confirm.start
    readonly property bool confirmCancel: root.data.confirm.cancel
    readonly property bool confirmEStop: root.data.confirm.estop
    readonly property string defaultPrinter: root.data.defaultPrinter
    readonly property int pollMs: root.data.shell.pollMs
    readonly property int consoleLines: root.data.shell.consoleLines
    readonly property int notifCap: root.data.shell.notifCap
    readonly property string tempUnit: root.data.units.temp
    readonly property string lengthUnit: root.data.units.length
    readonly property bool maskIps: root.data.ui.maskIps

    // All macro names, pinned order first — the settings list needs the hidden
    // ones too so they can be re-shown.
    function macroOrder(all) { return Logic.ordered(all, root.data.macros.order) }
    // What the dashboard card renders.
    function macrosVisible(all) {
        return Logic.visible(all, root.data.macros.order, root.data.macros.hidden)
    }
    function isMacroHidden(name) {
        return root.data.macros.hidden.indexOf(String(name)) >= 0
    }
    function apiKey(printer) {
        return root.data.keys[String(printer)] || ""
    }

    function _commit(d) {
        root.data = Logic.merge(d)
        root._save()
    }

    // Both return false when the edit did not parse, so the field can say so
    // instead of silently keeping the old value.
    function setSteps(kind, text) {
        var v = Logic.parseSteps(text)
        if (v.length === 0) return false
        var d = Logic.merge(root.data)
        d.jog[kind] = v
        root._commit(d)
        return true
    }
    function setRate(kind, text) {
        var n = Number(String(text).trim())
        if (!isFinite(n) || n <= 0) return false
        var d = Logic.merge(root.data)
        d.jog[kind] = n
        root._commit(d)
        return true
    }
    function setConfirm(name, value) {
        var d = Logic.merge(root.data)
        d.confirm[name] = value === true
        root._commit(d)
    }
    function toggleMacro(name) {
        var d = Logic.merge(root.data)
        var n = String(name)
        var i = d.macros.hidden.indexOf(n)
        if (i >= 0) d.macros.hidden.splice(i, 1)
        else d.macros.hidden.push(n)
        root._commit(d)
    }
    function moveMacro(all, name, dir) {
        var d = Logic.merge(root.data)
        var full = Logic.ordered(all, d.macros.order)
        var i = full.indexOf(String(name))
        var j = i + dir
        if (i < 0 || j < 0 || j >= full.length) return
        var swap = full[i]
        full[i] = full[j]
        full[j] = swap
        d.macros.order = full
        root._commit(d)
    }
    function setApiKey(printer, key) {
        var d = Logic.merge(root.data)
        var p = String(printer)
        if (String(key) === "") delete d.keys[p]
        else d.keys[p] = String(key)
        root._commit(d)
    }
    function setDefaultPrinter(name) {
        var d = Logic.merge(root.data)
        var n = String(name)
        d.defaultPrinter = d.defaultPrinter === n ? "" : n
        root._commit(d)
    }

    function setMaskIps(value) {
        var d = Logic.merge(root.data)
        d.ui.maskIps = value === true
        root._commit(d)
    }

    // Every stored value back to Logic.defaults(), API keys included — hence the
    // confirmation in front of it.
    function reset() {
        root.data = Logic.defaults()
        root._save()
    }

    // One of the chip choices in the INTERFACE tab. Rejects a value outside the
    // range settings-logic.js declares rather than storing nonsense.
    function setShell(key, value) {
        var v = Logic.ranged(key, value)
        if (v === null) return false
        var d = Logic.merge(root.data)
        d.shell[key] = v
        root._commit(d)
        return true
    }

    // A display unit. Same shape as setShell: reject anything not listed.
    function setUnit(key, value) {
        var v = Logic.oneOf(key, value)
        if (v === null) return false
        var d = Logic.merge(root.data)
        d.units[key] = v
        root._commit(d)
        return true
    }

    // ── Display units ──────────────────────────────────────────────
    // Klipper is Celsius either way; these are presentation, and tempBack() is
    // the inverse for anything the user types into a field.
    function tempValue(v) {
        return Logic.temp(v, root.data.units.temp)
    }
    function tempText(v, digits) {
        var t = root.tempValue(v)
        if (!isFinite(t)) return "—"
        var d = digits === undefined ? (t > 100 ? 0 : 1) : digits
        return t.toFixed(d) + "°"
    }
    function tempSuffix() {
        return root.data.units.temp === "F" ? "°F" : "°C"
    }
    function tempBack(v) {
        return Logic.tempBack(v, root.data.units.temp)
    }
    // Lengths have no inverse yet: nothing types one. The jog steps, extrude
    // amounts and Z-adjust buttons stay millimetres on purpose — they are the
    // machine's own numbers (and the JOG tab edits the same values in mm), so
    // only measurements convert.
    function lengthValue(v) {
        return Logic.length(v, root.data.units.length)
    }
    // `digits` matters here: a Z offset is hundredths of a millimetre, so the
    // caller decides precision per unit or inches round everything to 0.0.
    function lengthText(v, digits) {
        var n = root.lengthValue(v)
        if (!isFinite(n)) return "—"
        var d = digits === undefined ? (n > 100 ? 0 : 1) : digits
        return n.toFixed(d) + root.lengthSuffix()
    }
    function lengthSuffix() {
        return root.data.units.length === "in" ? "in" : "mm"
    }

    // ── Persistence ────────────────────────────────────────────────
    function path() {
        return (Quickshell.env("HOME") || "~") + "/.local/state/klipshell/settings.json"
    }

    property var loadProc: Process {
        command: ["bash", "-c", "cat '" + root.path() + "' 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var t = String(text || "").trim()
                if (t !== "") {
                    try {
                        root.data = Logic.merge(JSON.parse(t))
                    } catch (e) {
                        console.error("klipshell settings parse failed:", e)
                    }
                }
                root.loaded = true
            }
        }
    }

    // The payload rides in the environment, never in argv — an API key sitting
    // in a command line is readable by anything that can list processes.
    property var saveProc: Process {
        command: ["true"]
        running: false
    }
    function _save() {
        var f = root.path()
        var dir = f.slice(0, f.lastIndexOf("/"))
        root.saveProc.environment = { KLIPSHELL_SETTINGS: JSON.stringify(root.data) }
        root.saveProc.command = ["bash", "-c",
            "mkdir -p '" + dir + "' && printf '%s' \"$KLIPSHELL_SETTINGS\" > '" + f + "'"]
        root.saveProc.running = false
        root.saveProc.running = true
    }
}
