// Pure settings logic, shared by the Settings singleton (imported from QML as
// a plain .js library) and its node self-check (src/config/test-settings.js).
// Plain data in, plain data out — no QML types — so the sanitiser rules below
// can be tested without a GUI. The `module` guard at the bottom is what lets
// node require this same file.

var MAX_STEPS = 12
var MAX_NAMES = 32

// The choices edited as one-of-a-few rather than typed: poll cadence, console
// scrollback, notification cap. Declared here so the sanitiser and the setter's
// validation cannot drift apart.
var RANGE = {
    pollMs: [250, 10000],
    consoleLines: [20, 1000],
    notifCap: [5, 500]
}

// Display units. Klipper speaks Celsius and millimetres no matter what — the
// chosen unit is presentation only, so every conversion here has an inverse used
// on typed input. Values are the strings stored in the file.
var ONE_OF = {
    temp: ["C", "F"],
    length: ["mm", "in"]
}
var MM_PER_IN = 25.4

// Values the store starts from, and what any unreadable or partial file falls
// back to field by field.
function defaults() {
    return {
        version: 1,
        jog: { toolhead: [0.1, 1, 10, 25, 50, 100], extruder: [5, 10, 50, 100],
               bedXY: 100, bedZ: 20 },
        macros: { order: [], hidden: [] },
        shell: { pollMs: 1000, consoleLines: 80, notifCap: 50 },
        units: { temp: "C", length: "mm" },
        confirm: { start: true, cancel: true, estop: true },
        ui: { maskIps: true },
        keys: {},
        defaultPrinter: ""
    }
}

function isObj(v) {
    return !!v && typeof v === "object" && !Array.isArray(v)
}

// Positive finite number, or null. 0 and negatives are rejected: every value
// that uses this is a distance, a feedrate or a step.
function num(v) {
    var n = Number(v)
    return (isFinite(n) && n > 0) ? n : null
}

function str(v) {
    return typeof v === "string" ? v : ""
}

// Ordered, de-duplicated, length-capped list of positive numbers. Order is
// honoured — a descending step set is legitimate.
function steps(v) {
    var out = []
    if (!Array.isArray(v)) return out
    for (var i = 0; i < v.length && out.length < MAX_STEPS; i++) {
        var n = num(v[i])
        if (n !== null && out.indexOf(n) < 0) out.push(n)
    }
    return out
}

// The JOG fields are edited as text, so "," is the separator and anything
// unparseable is dropped rather than stored. An empty result means "reject the
// edit" — the caller keeps the previous list.
function parseSteps(text) {
    return steps(String(text === null || text === undefined ? "" : text).split(","))
}

function names(v) {
    var out = []
    if (!Array.isArray(v)) return out
    for (var i = 0; i < v.length && out.length < MAX_NAMES; i++) {
        var s = str(v[i])
        if (s !== "" && out.indexOf(s) < 0) out.push(s)
    }
    return out
}

// Stored order first, then whatever else the printer reports. Names in the
// stored order that this printer does not have are skipped, which is what lets
// one ordering cover a whole fleet. Used for the settings list, where hidden
// macros still need a row to be re-shown from.
function ordered(all, order) {
    var src = Array.isArray(all) ? all.map(String) : []
    var out = []
    var pinned = names(order)
    for (var i = 0; i < pinned.length; i++)
        if (src.indexOf(pinned[i]) >= 0) out.push(pinned[i])
    for (var j = 0; j < src.length; j++)
        if (out.indexOf(src[j]) < 0) out.push(src[j])
    return out
}

// What the dashboard's MACROS card actually renders.
function visible(all, order, hidden) {
    var full = ordered(all, order)
    var hide = names(hidden)
    var out = []
    for (var i = 0; i < full.length; i++)
        if (hide.indexOf(full[i]) < 0) out.push(full[i])
    return out
}

function apiKeys(v) {
    var out = {}
    if (!isObj(v)) return out
    for (var k in v) {
        var s = str(v[k])
        if (s !== "") out[String(k)] = s
    }
    return out
}

function flag(v, fallback) {
    return typeof v === "boolean" ? v : fallback
}

// Rounded integer inside the range RANGE[key] declares, or null when the key is
// unknown or the value is out of range.
function ranged(key, v) {
    var r = RANGE[key]
    if (!r) return null
    var n = Number(v)
    if (!isFinite(n)) return null
    n = Math.round(n)
    return (n >= r[0] && n <= r[1]) ? n : null
}

// One of the strings ONE_OF[key] lists, or null.
function oneOf(key, v) {
    var a = ONE_OF[key]
    return (a && a.indexOf(String(v)) >= 0) ? String(v) : null
}

// Number(v) turns "" and null into 0, which would read as a real temperature.
function numOrNaN(v) {
    if (v === null || v === undefined || v === "") return NaN
    return Number(v)
}

function temp(c, unit) {
    var n = numOrNaN(c)
    return unit === "F" ? n * 9 / 5 + 32 : n
}

// Typed display value back to the Celsius the printer expects.
function tempBack(v, unit) {
    var n = numOrNaN(v)
    return unit === "F" ? (n - 32) * 5 / 9 : n
}

function length(mm, unit) {
    var n = numOrNaN(mm)
    return unit === "in" ? n / MM_PER_IN : n
}

// Stored file over defaults, field by field. Anything missing, mistyped or out
// of range keeps its default, so a hand-edited or truncated settings.json can
// never produce an unusable store.
function merge(raw) {
    var d = defaults()
    var s = isObj(raw) ? raw : {}
    var j = isObj(s.jog) ? s.jog : {}
    var m = isObj(s.macros) ? s.macros : {}
    var c = isObj(s.confirm) ? s.confirm : {}
    var sh = isObj(s.shell) ? s.shell : {}
    var un = isObj(s.units) ? s.units : {}
    var ui = isObj(s.ui) ? s.ui : {}

    var toolhead = steps(j.toolhead)
    if (toolhead.length > 0) d.jog.toolhead = toolhead
    var extruder = steps(j.extruder)
    if (extruder.length > 0) d.jog.extruder = extruder
    d.jog.bedXY = num(j.bedXY) || d.jog.bedXY
    d.jog.bedZ = num(j.bedZ) || d.jog.bedZ

    d.macros.order = names(m.order)
    d.macros.hidden = names(m.hidden)

    d.confirm.start = flag(c.start, d.confirm.start)
    d.confirm.cancel = flag(c.cancel, d.confirm.cancel)
    d.confirm.estop = flag(c.estop, d.confirm.estop)

    d.ui.maskIps = flag(ui.maskIps, d.ui.maskIps)

    d.keys = apiKeys(s.keys)
    d.defaultPrinter = str(s.defaultPrinter)

    for (var k in RANGE) {
        var rv = ranged(k, sh[k])
        if (rv !== null) d.shell[k] = rv
    }
    for (var u in ONE_OF) {
        var uv = oneOf(u, un[u])
        if (uv !== null) d.units[u] = uv
    }
    return d
}

if (typeof module !== "undefined") {
    module.exports = {
        MAX_STEPS: MAX_STEPS, defaults: defaults, steps: steps, parseSteps: parseSteps,
        names: names, ordered: ordered, visible: visible, RANGE: RANGE, ranged: ranged,
        ONE_OF: ONE_OF, oneOf: oneOf, temp: temp, tempBack: tempBack, length: length,
        merge: merge
    }
}
