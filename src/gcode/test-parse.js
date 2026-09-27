// Self-check for GcodeParse.js. Plain node, no framework:
//   node src/gcode/test-parse.js
// The parser is the one piece of this tab qmllint cannot see, and a wrong
// segment/layer count silently renders a plausible-but-wrong toolpath.
const fs = require("fs")
const path = require("path")

const src = fs.readFileSync(path.join(__dirname, "GcodeParse.js"), "utf8")
const P = new Function(src + ";return { newJob: newJob, step: step, S_STRIDE: S_STRIDE, S_LINE: S_LINE, S_KEY: S_KEY, S_FEED: S_FEED };")()

let failures = 0
function check(name, cond, extra) {
    if (!cond) { failures++; console.log("FAIL " + name + (extra === undefined ? "" : " — " + extra)) }
    else console.log("ok   " + name)
}

function parse(text, quality, cnc) {
    const job = P.newJob(text, quality, cnc)
    let guard = 0
    while (!job.done && guard++ < 10000) P.step(job, 500)
    return job
}

// ── Layer + feature + travel handling, in the demo's own grammar ──────────
const layered = [
    "G90", "M83", "G28", "G1 Z0.25 F600", ";TYPE:Skirt",
    "G0 X80 Y80 F9000", "G1 X120 Y80 E0.5", "G1 X120 Y120 E1.0",
    ";LAYER_CHANGE", ";Z:0.50",
    "G1 Z0.50 F600", ";TYPE:External perimeter",
    "G0 X90 Y90 F9000", "G1 X110 Y90 E1.6 F2400", "G1 X110 Y110 E2.2",
    "G1 Z0.75 F600", "G1 X90 Y110 E2.8"
].join("\n")
const j1 = parse(layered, 3)
check("layers from the LAYER_CHANGE comments", j1.layers.length === 2, "got " + j1.layers.length)
check("segments emitted", j1.count > 0, "got " + j1.count)
check("feature table captured both names",
    j1.types.indexOf("Skirt") > 0 && j1.types.indexOf("External perimeter") > 0, j1.types.join(","))
check("travels recorded (includes the two Z-only moves)", j1.travelCount === 5, "got " + j1.travelCount)
check("bounds inside the printed area",
    j1.bounds.min[0] === 80 && j1.bounds.max[0] === 120
    && j1.bounds.min[2] === 0.25 && j1.bounds.max[2] === 0.75,
    JSON.stringify(j1.bounds))
const bogus = (() => {
    for (let o = 0; o < j1.seg.length; o += P.S_STRIDE) {
        const d = Math.hypot(j1.seg[o + 3] - j1.seg[o], j1.seg[o + 4] - j1.seg[o + 1])
        if (d > 60) return d
    }
    return 0
})()
check("no extrusion chord bridges a travel", bogus === 0, "longest " + bogus.toFixed(1) + "mm")

// ── Absolute E, G92 reset, relative moves, tool change ───────────────────
const absE = [
    "G90", "M82", "G1 X0 Y0 F6000", "G1 X10 Y0 E1 F1800", "G92 E0",
    "G1 X20 Y0 E1", "T1", "G1 X30 Y0 E2", "G91", "G1 X5 E3"
].join("\n")
const j2 = parse(absE, 6)
check("absolute-E + G92 reset keeps extruding", j2.count >= 3, "got " + j2.count)
check("tool 1 tagged on its own segments", (() => {
    for (let o = 0; o < j2.seg.length; o += P.S_STRIDE) if ((j2.seg[o + P.S_KEY] >> 6) === 1) return true
    return false
})())
check("relative move (G91) applied", j2.bounds.max[0] === 35, JSON.stringify(j2.bounds.max))

// ── Arcs ─────────────────────────────────────────────────────────────────
const arcText = ["G90", "M83", "G1 X10 Y0 F3000", "G3 X0 Y10 I-10 J0 E5 F1200"].join("\n")
const j3 = parse(arcText, 6)
const arcRadius = (() => {
    const o = j3.seg.length - P.S_STRIDE
    const last = [j3.seg[o + 3], j3.seg[o + 4]]
    return Math.hypot(last[0], last[1] - 10)
})()
check("G3 arc lands on its endpoint", arcRadius < 0.2, "radius error " + arcRadius.toFixed(3))
check("arc flattened into several chords", j3.count > 5, "got " + j3.count)

// ── Decimation ───────────────────────────────────────────────────────────
const straight = ["G90", "M83", "G1 Z0.2 F600", "G0 X0 Y0 F9000", "G1 X0 Y0 E0.01 F1800"]
for (let i = 1; i <= 400; i++) straight.push("G1 X" + (i * 0.4).toFixed(2) + " Y0 E" + (0.01 + i * 0.02).toFixed(3))
const low = parse(straight.join("\n"), 1)
const max = parse(straight.join("\n"), 6)
check("decimation collapses a straight wall", low.count > 1 && low.count <= 45, "got " + low.count)
check("max quality keeps detail", max.count > low.count * 3, "low " + low.count + " max " + max.count)

// ── CNC mode treats G1 without E as cutting ──────────────────────────────
const cnc = parse(["G90", "G1 X0 Y0 F1000", "G1 X50 Y0", "G1 X50 Y50"].join("\n"), 3, true)
check("cnc mode extrudes plain G1", cnc.count === 2, "got " + cnc.count)

// ── Progress is monotonic and reaches 1 ──────────────────────────────────
const big = ["G90", "M83"].concat(Array.from({ length: 5000 }, (_, i) => "G1 X" + (i % 200) + " Y0 E1 F1800"))
const job = P.newJob(big.join("\n"), 3)
let prev = -1
let monotonic = true
while (!job.done) {
    P.step(job, 500)
    if (job.progress < prev) monotonic = false
    prev = job.progress
}
check("progress monotonic to 1", monotonic && job.progress === 1)

// ── Z-change layer inference when the file carries no layer comments ─────
const noComments = ["G90", "M83", "G1 Z0.2 F600", "G0 X0 Y0 F9000", "G1 X10 Y0 E1 F1800",
    "G1 Z0.4 F600", "G1 X20 Y0 E2 F1800", "G1 Z0.6 F600", "G1 X30 Y0 E3 F1800"].join("\n")
const j4 = parse(noComments, 3)
check("layers inferred from Z changes", j4.layers.length === 3, "got " + j4.layers.length)

console.log(failures === 0 ? "\nall checks passed" : "\n" + failures + " check(s) failed")
process.exit(failures === 0 ? 0 : 1)
