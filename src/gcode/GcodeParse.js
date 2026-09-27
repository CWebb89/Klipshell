// G-code toolpath parser for the GCODE VIEWER tab.
//
// Resumable: `newJob()` splits the body into lines, then the view drives
// `step(job, budget)` from a Timer so a multi-megabyte body neither blocks the
// Qt UI thread nor leaves the progress bar guessing — `job.progress` is real.
//
// Output is one flat numeric array of extruding segments with a fixed stride,
// which is what a Canvas painter wants to iterate:
//
//   seg[o + 0..2]  start point x, y, z            (mm, bed frame)
//   seg[o + 3..5]  end point x, y, z
//   seg[o + 6]     feed rate                      (mm/min, F as written)
//   seg[o + 7]     key = featureIdx | tool << 6
//   seg[o + 8]     source line index
//
// Travels are a second flat array, stride 7 (start xyz, end xyz, line).
//
// Decimation is the reason a 150k-move file can be repainted on Canvas: while
// the direction stays inside the quality's angle budget the points are folded
// into one chord (capped at maxLen so a long straight wall still breaks up).
// At angle 2.5 deg / 2 mm the corner error stays under 0.05 mm — invisible at
// any zoom this view offers.

var S_FEED = 6
var S_KEY = 7
var S_LINE = 8
var S_STRIDE = 9
var T_STRIDE = 7

// Low -> Max: Mainsail's five renderQuality entries plus the SBC fallback.
var QUALITY = {
    1: { ang: 8.0, maxLen: 4.0 },
    2: { ang: 5.0, maxLen: 3.0 },
    3: { ang: 2.5, maxLen: 2.0 },
    4: { ang: 1.2, maxLen: 1.2 },
    5: { ang: 0.5, maxLen: 0.8 },
    6: { ang: 0.15, maxLen: 0.5 }
}

function newJob(text, quality, cnc) {
    var body = String(text || "")
    var job = {
        lines: body.split("\n"),
        total: 0,
        i: 0,
        done: false,
        progress: 0,
        quality: quality || 3,
        g1AsExtrusion: cnc === true,

        x: 0, y: 0, z: 0, e: 0, f: 0,
        absMove: true, absE: true, scale: 1,
        tool: 0, feature: "Unknown", featureIdx: 0,
        layerNumber: -1, layerZ: 0, pendingLayer: false, seenLayerComment: false,

        seg: [],
        trv: [],
        layers: [],
        types: ["Unknown"],

        ax: 0, ay: 0, az: 0, alen: 0, adx: 0, ady: 0, adz: 0,
        afeat: 0, atool: 0, aok: false,

        minX: 1e9, minY: 1e9, minZ: 1e9,
        maxX: -1e9, maxY: -1e9, maxZ: -1e9,
        feedMin: 1e9, feedMax: 0,
        moves: 0
    }
    job.total = job.lines.length
    return job
}

function step(job, budget) {
    if (job.done) return job
    var lines = job.lines
    var end = Math.min(job.total, job.i + (budget || 3000))
    var q = QUALITY[job.quality] || QUALITY[3]
    while (job.i < end) {
        parseLine(job, lines[job.i], job.i, q)
        job.i++
    }
    job.progress = job.total > 0 ? job.i / job.total : 1
    if (job.i >= job.total) finish(job)
    return job
}

function finish(job) {
    flush(job, job.i)
    job.done = true
    job.progress = 1
    var end = job.seg.length
    for (var i = job.layers.length - 1; i >= 0; i--) {
        job.layers[i].segEnd = end
        end = job.layers[i].segStart
    }
    if (job.layers.length === 0)
        job.layers.push({ z: job.z, index: 0, line: 0, segStart: 0, segEnd: end })
    var hasBounds = job.minX <= job.maxX
    job.bounds = {
        min: hasBounds ? [job.minX, job.minY, job.minZ] : [0, 0, 0],
        max: hasBounds ? [job.maxX, job.maxY, job.maxZ] : [0, 0, 0]
    }
    job.count = job.seg.length / S_STRIDE
    job.travelCount = job.trv.length / T_STRIDE
    job.feedRange = job.feedMax > job.feedMin ? [job.feedMin, job.feedMax] : [1, 100]
    return job
}

function featureIndex(job, name) {
    for (var i = 0; i < job.types.length; i++)
        if (job.types[i] === name) return i
    if (job.types.length < 63) {
        job.types.push(name)
        return job.types.length - 1
    }
    return 0
}

function beginLayer(job, z, index) {
    job.layerNumber = index >= 0 ? index : job.layers.length
    job.layerZ = z
    var n = job.seg.length
    var last = job.layers[job.layers.length - 1]
    if (last && last.segStart === n && last.index === job.layerNumber) return
    job.layers.push({
        z: z,
        index: job.layerNumber,
        line: Math.max(0, job.i),
        segStart: n,
        segEnd: n
    })
}

// Hold a point back until it is worth emitting, then push the chord.
function emit(job, x, y, z, feed, line, q) {
    var dx = x - job.ax
    var dy = y - job.ay
    var dz = z - job.az
    var len = Math.sqrt(dx * dx + dy * dy + dz * dz)
    var turn = 0
    if (job.alen > 1e-6 && len > 1e-6) {
        var la = Math.sqrt(job.adx * job.adx + job.ady * job.ady + job.adz * job.adz) || 1
        var lb = len || 1
        var dot = (job.adx * dx + job.ady * dy + job.adz * dz) / (la * lb)
        if (dot > 1) dot = 1
        else if (dot < -1) dot = -1
        turn = Math.acos(dot) * 180 / Math.PI
    }
    var broke = !job.aok || job.featureIdx !== job.afeat || job.tool !== job.atool
        || len >= q.maxLen || turn >= q.ang
    if (!broke) return
    if (job.aok && len > 1e-6)
        pushSeg(job, job.ax, job.ay, job.az, x, y, z, feed, job.afeat, job.atool, line)
    job.ax = x; job.ay = y; job.az = z
    job.adx = dx; job.ady = dy; job.adz = dz
    job.alen = len; job.afeat = job.featureIdx; job.atool = job.tool
    job.aok = true
}

function pushSeg(job, x0, y0, z0, x1, y1, z1, feed, feat, tool, line) {
    var s = job.seg
    s.push(x0, y0, z0, x1, y1, z1, feed, feat | (tool << 6), line)
    job.moves++
    if (x0 < job.minX) job.minX = x0
    if (x0 > job.maxX) job.maxX = x0
    if (y0 < job.minY) job.minY = y0
    if (y0 > job.maxY) job.maxY = y0
    if (z0 < job.minZ) job.minZ = z0
    if (z0 > job.maxZ) job.maxZ = z0
    if (x1 < job.minX) job.minX = x1
    if (x1 > job.maxX) job.maxX = x1
    if (y1 < job.minY) job.minY = y1
    if (y1 > job.maxY) job.maxY = y1
    if (z1 < job.minZ) job.minZ = z1
    if (z1 > job.maxZ) job.maxZ = z1
    if (feed > 0) {
        if (feed < job.feedMin) job.feedMin = feed
        if (feed > job.feedMax) job.feedMax = feed
    }
}

function flush(job, line) {
    if (job.aok && job.alen > 1e-6)
        pushSeg(job, job.ax, job.ay, job.az, job.x, job.y, job.z, job.f, job.afeat, job.atool, line)
    job.alen = 0
}

function parseLine(job, raw, index, q) {
    var s = raw
    var ci = s.indexOf(";")
    if (ci === 0) { comment(job, s.slice(1)); return }
    var note = ""
    if (ci > 0) { note = s.slice(ci + 1); s = s.slice(0, ci) }
    s = s.replace(/^\s+/, "").replace(/\s+$/, "")
    if (s !== "") {
        var m = /^([GMT])(\d+(?:\.\d+)?)/i.exec(s)
        if (m) command(job, m[1].toUpperCase() + m[2], params(s, m.index + m[0].length), index, q)
    }
    if (note !== "") comment(job, note)
}

function params(s, from) {
    var re = /([XYZEFIJKRSP])\s*(-?\d*\.?\d+)/gi
    re.lastIndex = from
    var out = {}
    var m
    while ((m = re.exec(s)) !== null) out[m[1].toUpperCase()] = parseFloat(m[2])
    return out
}

function comment(job, c) {
    if (c.length < 4) return
    if (c.indexOf("TYPE:") === 0) {
        job.feature = c.slice(5).trim()
        job.featureIdx = featureIndex(job, job.feature)
        return
    }
    if (c.indexOf("LAYER_CHANGE") === 0) {
        job.seenLayerComment = true
        job.pendingLayer = true
        return
    }
    if (c.indexOf("LAYER:") === 0) {
        var n = parseInt(c.slice(6).trim(), 10)
        job.seenLayerComment = true
        beginLayer(job, job.layerZ, isNaN(n) ? -1 : n)
        return
    }
    if (c.indexOf("Z:") === 0) {
        var z = parseFloat(c.slice(2).trim())
        if (isNaN(z)) return
        if (job.pendingLayer) {
            job.pendingLayer = false
            beginLayer(job, z, -1)
        }
        job.layerZ = z
        return
    }
    if (c.indexOf("FEATURE:") === 0) {
        job.feature = c.slice(8).trim()
        job.featureIdx = featureIndex(job, job.feature)
        return
    }
    if (c.charCodeAt(0) === 32 && c.indexOf(" feature ") === 0) {
        job.feature = c.slice(9).trim()
        job.featureIdx = featureIndex(job, job.feature)
        return
    }
    if (c.indexOf("TOOL:") === 0) {
        var t = parseInt(c.slice(5).trim(), 10)
        if (!isNaN(t)) job.tool = Math.max(0, t)
    }
}

function command(job, code, p, index, q) {
    switch (code) {
    case "G0":
    case "G1":
        move(job, p, index, q)
        return
    case "G2":
    case "G3":
        arc(job, p, index, q, code === "G2")
        return
    case "G90": job.absMove = true; return
    case "G91": job.absMove = false; return
    case "G20": job.scale = 25.4; return
    case "G21": job.scale = 1; return
    case "G92":
        if (p.E !== undefined) { job.e = p.E; flush(job, index) }
        if (p.X !== undefined) job.x = p.X * job.scale
        if (p.Y !== undefined) job.y = p.Y * job.scale
        if (p.Z !== undefined) job.z = p.Z * job.scale
        return
    case "M82": job.absE = true; return
    case "M83": job.absE = false; return
    }
    if (code.charCodeAt(0) === 84) {
        var t = parseInt(code.slice(1), 10)
        if (isNaN(t) || p.X !== undefined) return
        flush(job, index)
        job.tool = Math.max(0, t)
    }
}

function move(job, p, index, q) {
    var sc = job.scale
    var nx = p.X !== undefined ? (job.absMove ? p.X * sc : job.x + p.X * sc) : job.x
    var ny = p.Y !== undefined ? (job.absMove ? p.Y * sc : job.y + p.Y * sc) : job.y
    var nz = p.Z !== undefined ? (job.absMove ? p.Z * sc : job.z + p.Z * sc) : job.z
    if (p.F !== undefined && p.F > 0) job.f = p.F
    var extruding = false
    if (p.E !== undefined) {
        if (job.absE) {
            extruding = p.E > job.e + 1e-9
            job.e = p.E
        } else {
            extruding = p.E > 0
            job.e += p.E
        }
    } else if (job.g1AsExtrusion) {
        extruding = true
    }
    var moved = nx !== job.x || ny !== job.y || nz !== job.z
    if (!moved) return
    if (extruding) {
        if (job.pendingLayer) {
            job.pendingLayer = false
            beginLayer(job, nz, -1)
        } else if (!job.seenLayerComment && (job.layerNumber < 0 || nz !== job.layerZ)) {
            beginLayer(job, nz, job.layerNumber < 0 ? 0 : job.layerNumber + 1)
        }
        emit(job, nx, ny, nz, job.f, index, q)
    } else {
        flush(job, index)
        travel(job, job.x, job.y, job.z, nx, ny, nz, index)
        job.ax = nx; job.ay = ny; job.az = nz
        job.adx = 0; job.ady = 0; job.adz = 0; job.alen = 0
        job.afeat = job.featureIdx; job.atool = job.tool
        job.aok = true
    }
    job.x = nx; job.y = ny; job.z = nz
}

// Flattened arc (G2/G3): 5-degree chords, I/J centre or R radius.
function arc(job, p, index, q, cw) {
    var sc = job.scale
    var ex = p.X !== undefined ? (job.absMove ? p.X * sc : job.x + p.X * sc) : job.x
    var ey = p.Y !== undefined ? (job.absMove ? p.Y * sc : job.y + p.Y * sc) : job.y
    var cx
    var cy
    if (p.I !== undefined || p.J !== undefined) {
        cx = job.x + (p.I || 0) * sc
        cy = job.y + (p.J || 0) * sc
    } else if (p.R !== undefined) {
        var dx = ex - job.x
        var dy = ey - job.y
        var d = Math.sqrt(dx * dx + dy * dy) || 1e-6
        var r0 = Math.abs(p.R) * sc
        var off = Math.sqrt(Math.max(0, r0 * r0 - d * d / 4))
        var sign = (p.R < 0) !== cw ? -1 : 1
        cx = job.x + dx / 2 + sign * off * (-dy / d)
        cy = job.y + dy / 2 + sign * off * (dx / d)
    } else {
        move(job, p, index, q)
        return
    }
    var a0 = Math.atan2(job.y - cy, job.x - cx)
    var sweep = Math.atan2(ey - cy, ex - cx) - a0
    if (cw && sweep >= 0) sweep -= Math.PI * 2
    else if (!cw && sweep <= 0) sweep += Math.PI * 2
    var steps = Math.max(2, Math.ceil(Math.abs(sweep) / (5 * Math.PI / 180)))
    var r = Math.sqrt((job.x - cx) * (job.x - cx) + (job.y - cy) * (job.y - cy))
    var startE = job.e
    var targetE = p.E
    for (var i = 1; i <= steps; i++) {
        var a = a0 + sweep * (i / steps)
        var step = { X: cx + r * Math.cos(a), Y: cy + r * Math.sin(a) }
        if (p.Z !== undefined && i === steps) step.Z = p.Z
        if (targetE !== undefined) step.E = startE + (targetE - startE) * (i / steps)
        if (p.F !== undefined) step.F = p.F
        move(job, step, index, q)
    }
}

function travel(job, x0, y0, z0, x1, y1, z1, line) {
    job.trv.push(x0, y0, z0, x1, y1, z1, line)
}
