// Self-check for settings-logic.js. Plain node, no framework:
//   node src/config/test-settings.js
// Covers the two rules that fail silently in the UI: a hand-edited or partial
// settings.json must still produce a usable store, and macro order/hide must
// survive names a given printer does not have.

const L = require("./settings-logic.js")

let checks = 0
let failures = 0
function check(name, cond, detail) {
    checks++
    if (!cond) {
        failures++
        console.log("FAIL " + name + (detail === undefined ? "" : " — " + detail))
    }
}
function eq(name, got, want) {
    check(name, JSON.stringify(got) === JSON.stringify(want),
        "got " + JSON.stringify(got) + ", want " + JSON.stringify(want))
}

// ── Text -> step list (the JOG fields) ─────────────────────────────────────
eq("parse spaces and duplicates", L.parseSteps(" 0.1, 1, 10 ,25, 25 "), [0.1, 1, 10, 25])
eq("parse keeps descending order", L.parseSteps("100, 50, 10"), [100, 50, 10])
eq("parse drops junk", L.parseSteps("abc, 5, , -3, 0, 7"), [5, 7])
eq("parse empty is empty", L.parseSteps(""), [])
eq("parse null is empty", L.parseSteps(null), [])
check("parse caps length", L.parseSteps("1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20").length === L.MAX_STEPS,
    "got " + L.parseSteps("1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20").length)

// ── Stored file over defaults ─────────────────────────────────────────────
const d0 = L.defaults()
eq("merge(null) is the defaults", L.merge(null), d0)
eq("merge(truncated json) is the defaults", L.merge({}), d0)
eq("merge keeps a valid list", L.merge({ jog: { toolhead: [1, 2] } }).jog.toolhead, [1, 2])
eq("merge rejects an empty list", L.merge({ jog: { toolhead: [] } }).jog.toolhead, d0.jog.toolhead)
eq("merge rejects a mistyped list", L.merge({ jog: { toolhead: "nope" } }).jog.toolhead, d0.jog.toolhead)
eq("merge rejects a zero step", L.merge({ jog: { toolhead: [0, -2] } }).jog.toolhead, d0.jog.toolhead)
eq("merge keeps a feedrate", L.merge({ jog: { bedXY: 250 } }).jog.bedXY, 250)
eq("merge rejects a bad feedrate", L.merge({ jog: { bedXY: "fast" } }).jog.bedXY, d0.jog.bedXY)
eq("merge reads confirm flags", L.merge({ confirm: { estop: false } }).confirm.estop, false)
eq("merge keeps other confirm defaults", L.merge({ confirm: { estop: false } }).confirm.cancel, true)
eq("merge ignores a non-boolean flag", L.merge({ confirm: { cancel: "off" } }).confirm.cancel, true)
eq("merge keeps the ip mask flag", L.merge({ ui: { maskIps: false } }).ui.maskIps, false)
eq("merge ignores a non-boolean ip mask", L.merge({ ui: { maskIps: "no" } }).ui.maskIps, true)
eq("merge drops empty api keys", L.merge({ keys: { a: "", b: "k" } }).keys, { b: "k" })
eq("merge keeps the default printer", L.merge({ defaultPrinter: "V0.2" }).defaultPrinter, "V0.2")
check("merge never aliases the defaults",
    L.merge({}).jog.toolhead !== d0.jog.toolhead, "returns the same array instance")
check("merge output is sanitised again",
    L.merge(L.merge({ jog: { toolhead: [3] } })).jog.toolhead.length === 1)

// ── Macro ordering / hiding ───────────────────────────────────────────────
const all = ["PRINT_START", "CANCEL_PRINT", "PAUSE", "RESUME", "G32"]
eq("order: unset keeps printer order", L.ordered(all, []), all)
eq("order: pinned first", L.ordered(all, ["G32", "PAUSE"]), ["G32", "PAUSE", "PRINT_START", "CANCEL_PRINT", "RESUME"])
eq("order: other printer's macro is skipped", L.ordered(["A", "B"], ["ZZZ", "B"]), ["B", "A"])
eq("order: null order is safe", L.ordered(all, null), all)
eq("order: null list is safe", L.ordered(null, ["A"]), [])
eq("visible hides names", L.visible(all, [], ["PAUSE", "RESUME"]), ["PRINT_START", "CANCEL_PRINT", "G32"])
eq("visible hides in pinned order", L.visible(all, ["G32"], ["G32"]), ["PRINT_START", "CANCEL_PRINT", "PAUSE", "RESUME"])
eq("visible keeps a stale hidden name harmless", L.visible(all, [], ["NOT_THERE"]), all)
eq("hidden survives a round trip", L.merge({ macros: { order: ["G32"], hidden: ["PAUSE"] } }).macros.hidden, ["PAUSE"])

// ── Shell knobs (chip choices) ────────────────────────────────────────────
check("shell defaults are in range", L.RANGE.pollMs[0] <= d0.shell.pollMs && d0.shell.pollMs <= L.RANGE.pollMs[1]
    && L.RANGE.consoleLines[0] <= d0.shell.consoleLines
    && L.RANGE.notifCap[0] <= d0.shell.notifCap, JSON.stringify(d0.shell))
eq("ranged accepts a value in range", L.ranged("pollMs", 2000), 2000)
eq("ranged rounds a float", L.ranged("pollMs", 1500.6), 1501)
eq("ranged rejects below the floor", L.ranged("pollMs", 10), null)
eq("ranged rejects above the ceiling", L.ranged("consoleLines", 99999), null)
eq("ranged rejects junk", L.ranged("notifCap", "lots"), null)
eq("ranged rejects an unknown key", L.ranged("bogus", 5), null)
eq("merge keeps a shell value", L.merge({ shell: { pollMs: 5000 } }).shell.pollMs, 5000)
eq("merge rejects an out-of-range shell value", L.merge({ shell: { pollMs: 1 } }).shell.pollMs, d0.shell.pollMs)
eq("merge ignores an unknown shell key", L.merge({ shell: { bogus: 1 } }).shell.bogus, undefined)
check("merge output carries every shell key",
    Object.keys(d0.shell).every(function(k) { return typeof L.merge({}).shell[k] === "number" }),
    JSON.stringify(L.merge({}).shell))

// ── Display units ─────────────────────────────────────────────────────────
check("temp conversion is exact at the anchors",
    L.temp(0, "F") === 32 && L.temp(100, "F") === 212 && L.temp(37, "C") === 37)
check("temp round-trips through Fahrenheit",
    Math.abs(L.tempBack(L.temp(215, "F"), "F") - 215) < 1e-9,
    "got " + L.tempBack(L.temp(215, "F"), "F"))
check("tempBack is a no-op in Celsius", L.tempBack(210, "C") === 210)
check("temp of junk is NaN, not 0",
    Number.isNaN(L.temp("", "F")) && Number.isNaN(L.temp(null, "C")) && Number.isNaN(L.temp("warm", "C")))
eq("oneOf accepts a listed value", L.oneOf("temp", "F"), "F")
eq("oneOf rejects an unlisted value", L.oneOf("temp", "K"), null)
eq("oneOf rejects an unknown key", L.oneOf("weight", "kg"), null)
eq("merge keeps a unit", L.merge({ units: { temp: "F" } }).units.temp, "F")
eq("merge rejects a bad unit", L.merge({ units: { temp: "kelvin" } }).units.temp, "C")
eq("merge rejects a mistyped units block", L.merge({ units: "F" }).units.temp, "C")

check("length conversion is exact at the anchor", Math.abs(L.length(25.4, "in") - 1) < 1e-12,
    "got " + L.length(25.4, "in"))
check("length is a no-op in mm", L.length(12.5, "mm") === 12.5)
check("length of junk is NaN, not 0",
    Number.isNaN(L.length("", "in")) && Number.isNaN(L.length(null, "mm")) && Number.isNaN(L.length("far", "mm")))
eq("oneOf accepts a listed length value", L.oneOf("length", "in"), "in")
eq("merge keeps a length unit", L.merge({ units: { length: "in" } }).units.length, "in")
eq("merge rejects a bad length unit", L.merge({ units: { length: "furlong" } }).units.length, "mm")
eq("merge keeps the temp unit when only length is set",
    L.merge({ units: { length: "in" } }).units.temp, "C")

console.log(checks - failures + "/" + checks + " checks passed")
console.log(failures === 0 ? "\nall checks passed" : "\n" + failures + " check(s) failed")
process.exit(failures === 0 ? 0 : 1)
