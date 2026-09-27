pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"
import "../gcode/GcodeParse.js" as Gp

// GCODE VIEWER: Mainsail's Viewer tab. The feature set is the union of
// Mainsail's Viewer.vue plus the options it drives in @sindarius/gcodeviewer:
// load (current print file / local file / a server gcode), a byte-position
// scrubber with play, fast-forward and 1/2/5/10/20x, layer navigation, colour
// by extruder / feed rate / feature, five render qualities, the full options
// menu (toolhead, travels, code stream, object selection, HD, force line,
// transparency, voxel, CNC, axes), object exclusion and live
// toolhead tracking.
//
// The renderer is the same hand-rolled Canvas projection the HEIGHTMAP uses:
// gcodeviewer is three.js/WebGL, and QtQuick3D procedural geometry proved
// unreliable in this Qt/Quickshell combination (see Heightmap.qml), so the
// toolpath is projected and stroked in 2D. Two consequences, stated rather
// than hidden: there is no depth buffer (walls self-intersect visually) and
// extrusion is drawn as a flat line of varying width, not a swept volume.
//
// World axes: X = bed X, Y = up, Z = -bed Y, so the default camera looks at
// the bed's low-Y edge.
Item {
    id: root

    required property QtObject moonraker

    // ── Persisted options (Mainsail's gui.gcodeViewer store) ────────────
    property bool showCursor: true
    property bool showTravels: false
    property bool showGCode: false
    property bool showObjects: false
    property bool hdRendering: false
    property bool forceLines: false
    property bool transparency: false
    property bool voxelMode: false
    property bool cncMode: false
    property bool showAxes: true
    property int colorMode: 2
    property int quality: 3
    property real minFeed: 20
    property real maxFeed: 100
    property color minFeedColor: "#0000ff"
    property color maxFeedColor: "#ff0000"
    property color progressColor: "#ffffff"
    property color bedColor: "#b3b3b3"
    property var extruderColors: ["#ff6b35", "#4ea5d9", "#44cf6c", "#ffd23f"]

    // ── Camera ─────────────────────────────────────────────────────────
    property real camAlpha: 22
    property real camBeta: 38
    property real zoom: 1.35

    // ── Runtime ────────────────────────────────────────────────────────
    property var job: null
    property bool parsing: false
    property bool reloadRequired: false
    property string filePath: ""
    property string fileName: ""
    property int scrubLine: 0
    property bool playing: false
    property int playSpeed: 1
    property bool tracking: false
    property bool fileListOpen: false
    property string pendingObject: ""
    property string status: ""
    property int revision: 0

    readonly property var live: root.moonraker.active ?? null
    readonly property string printFile: String(root.live?.printFilename ?? "")
    readonly property bool printing: String(root.live?.printState ?? "") === "printing"
    readonly property bool trackingAvailable: root.printing && root.baseName(root.printFile) === root.fileName

    readonly property int railW: 322
    readonly property int codeW: 360
    readonly property int lineCount: root.job ? root.job.total : 0
    // `job` is a plain JS object mutated in place by the parser, so nothing
    // inside it emits a change signal: every binding that reads *into* the job
    // has to depend on `revision`, which the parse driver bumps each tick.
    // (Same trap as the update-manager stale bindings in MEMORY.md.)
    readonly property bool hasJob: {
        var r = root.revision
        return root.job !== null && root.job.done === true
    }
    readonly property bool busy: root.moonraker.gcodeLoading || root.parsing

    function baseName(p) {
        var s = String(p || "")
        var i = s.lastIndexOf("/")
        return i < 0 ? s : s.slice(i + 1)
    }

    // ── File loading ────────────────────────────────────────────────────
    function refresh() {
        if (!root.moonraker.data?.bedmesh) root.moonraker.fetchBedMesh()
        if (root.fileListOpen) root.moonraker.fetchGcodeFiles("")
    }

    function loadCurrent() {
        if (root.printFile === "") { root.status = "no print file reported"; return }
        root.moonraker.fetchGcodeFile(root.printFile)
    }

    function loadServer(p) {
        root.fileListOpen = false
        root.moonraker.fetchGcodeFile(p)
    }

    function chooseLocal() {
        root._pickProc.command = ["bash", "-c",
            "zenity --file-selection --title='Load G-code' "
            + "--file-filter='G-code | *.gcode *.g *.gco *.gc *.nc *.ngc *.tap' 2>/dev/null"]
        root._pickProc.running = false
        root._pickProc.running = true
    }

    function clearFile() {
        root.stopPlay()
        root.job = null
        root.filePath = ""
        root.fileName = ""
        root._localSource = false
        root.scrubLine = 0
        root.tracking = false
        root.reloadRequired = false
        root.status = ""
        view.requestPaint()
    }

    function startParse(text, path, local) {
        root.parsing = true
        root.revision = root.revision + 1
        var job = Gp.newJob(text, root.quality, root.cncMode)
        job.bytes = String(text).length
        root.job = job
        root.bytes = job.bytes
        if (path) { root.filePath = path; root.fileName = root.baseName(path) }
        root._localSource = local === true
        parseTimer.restart()
    }

    function cancelParse() {
        parseTimer.stop()
        root.parsing = false
        root.job = null
        root.status = "render cancelled"
    }

    function reloadFile() {
        root.reloadRequired = false
        if (root.filePath === "") return
        if (root._localSource) { root._readLocalFile(root._pendingPath); return }
        var g = root.moonraker.data?.gcode
        if (g && String(g.text || "").length > 0) root.startParse(g.text, root.filePath)
        else root.moonraker.fetchGcodeFile(root.filePath)
    }

    property real bytes: 1

    // Path of the file picked in the open dialog, held between the pick and the
    // read. Quickshell's Process is not a JS object: stashing this on it throws.
    // A locally loaded file also reloads from disk — the server's gcode bucket
    // holds whatever was fetched last, which is a different file.
    property string _pendingPath: ""
    property bool _localSource: false

    function _readLocalFile(p) {
        if (p === "") return
        root._pendingPath = p
        root._readProc.command = ["cat", p]
        root._readProc.running = false
        root._readProc.running = true
    }

    property var _pickProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._readLocalFile(String(text || "").trim())
        }
    }

    property var _readProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (String(text || "").length === 0) { root.status = "could not read that file"; return }
                root.startParse(text, root._pendingPath, true)
            }
        }
    }

    property var _saveProc: Process {
        command: []
        running: false
    }

    property var _loadProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(String(text || "").trim())
                    if (!d) return
                    root.showCursor = d.showCursor !== false
                    root.showTravels = d.showTravels === true
                    root.showGCode = d.showGCode === true
                    root.showObjects = d.showObjects === true
                    root.hdRendering = d.hdRendering === true
                    root.forceLines = d.forceLines === true
                    root.transparency = d.transparency === true
                    root.voxelMode = d.voxelMode === true
                    root.cncMode = d.cncMode === true
                    root.showAxes = d.showAxes !== false
                    root.colorMode = Number(d.colorMode ?? 2)
                    root.quality = Number(d.quality ?? 3)
                    root.minFeed = Number(d.minFeed ?? 20)
                    root.maxFeed = Number(d.maxFeed ?? 100)
                    root.minFeedColor = d.minFeedColor ?? "#0000ff"
                    root.maxFeedColor = d.maxFeedColor ?? "#ff0000"
                    root.progressColor = d.progressColor ?? "#ffffff"
                    if (Array.isArray(d.extruderColors)) root.extruderColors = d.extruderColors
                    root.camAlpha = Number(d.camAlpha ?? 22)
                    root.camBeta = Number(d.camBeta ?? 38)
                    root.zoom = Number(d.zoom ?? 1.35)
                    view.requestPaint()
                } catch (e) {}
            }
        }
    }

    function _statePath() {
        return (Quickshell.env("HOME") || "~") + "/.local/state/klipshell/viewer.json"
    }

    function saveSettings() {
        var f = root._statePath()
        var dir = f.slice(0, f.lastIndexOf("/"))
        var json = JSON.stringify({
            showCursor: root.showCursor, showTravels: root.showTravels, showGCode: root.showGCode,
            showObjects: root.showObjects, hdRendering: root.hdRendering, forceLines: root.forceLines,
            transparency: root.transparency, voxelMode: root.voxelMode,
            cncMode: root.cncMode, showAxes: root.showAxes, colorMode: root.colorMode,
            quality: root.quality, minFeed: root.minFeed, maxFeed: root.maxFeed,
            minFeedColor: String(root.minFeedColor), maxFeedColor: String(root.maxFeedColor),
            progressColor: String(root.progressColor), extruderColors: root.extruderColors,
            camAlpha: root.camAlpha, camBeta: root.camBeta, zoom: root.zoom
        })
        root._saveProc.command = ["bash", "-c",
            "mkdir -p '" + dir + "' && printf '%s' '" + json.replace(/'/g, "'\\''") + "' > '" + f + "'"]
        root._saveProc.running = false
        root._saveProc.running = true
    }

    function markDirty() { saveTimer.restart() }

    property var saveTimer: Timer {
        interval: 400
        repeat: false
        onTriggered: root.saveSettings()
    }

    Component.onCompleted: {
        root._loadProc.command = ["cat", root._statePath()]
        root._loadProc.running = true
        root.refresh()
    }

    Connections {
        target: root.moonraker
        function onBucketChanged(bucket) {
            if (bucket === "gcode") {
                var g = root.moonraker.data?.gcode
                if (!g) return
                root.startParse(g.text, g.path)
            } else if (bucket === "gcodes") {
                fileList.model = root.serverFiles()
            } else if (bucket === "bedmesh") {
                root.revision = root.revision + 1
            }
        }
        function onStateChanged() {
            if (root.moonraker.gcodeError !== "" && root.status !== root.moonraker.gcodeError)
                root.status = root.moonraker.gcodeError
            if (root.tracking && root.hasJob) {
                root.scrubLine = Math.max(0, Math.min(root.job.total,
                    Math.round(Number(root.live?.printProgress ?? 0) * root.job.total)))
                root.stopPlay()
            }
            view.requestPaint()
        }
    }

    // ── Parse driver ────────────────────────────────────────────────────
    property var parseTimer: Timer {
        interval: 16
        repeat: true
        onTriggered: {
            if (!root.job || root.job.done) { root.parsing = false; root.stop(); return }
            Gp.step(root.job, 2500)
            root.revision = root.revision + 1
            view.requestPaint()
            if (root.job.done) {
                root.parsing = false
                root.stop()
                root.scrubLine = root.job.total
                root.status = root.job.count + " segments from " + root.job.total + " lines"
                view.requestPaint()
            }
        }
    }

    function stop() { parseTimer.stop() }

    // ── Playback ────────────────────────────────────────────────────────
    // Mainsail advances 100 bytes per 200 ms tick, scaled by the speed
    // multiplier; mirrored here in lines so the two feel the same.
    property int playStep: {
        if (!root.hasJob) return 1
        var perLine = Math.max(1, root.bytes / Math.max(1, root.job.total))
        return Math.max(1, Math.round(100 * root.playSpeed / perLine))
    }

    property var playTimer: Timer {
        interval: 200
        repeat: true
        running: root.playing
        onTriggered: {
            if (!root.hasJob) { root.stopPlay(); return }
            if (root.tracking) { root.stopPlay(); return }
            root.scrubLine = Math.min(root.job.total, root.scrubLine + root.playStep)
            view.requestPaint()
            if (root.scrubLine >= root.job.total) root.stopPlay()
        }
    }

    function stopPlay() { root.playing = false }

    function togglePlay() {
        if (!root.hasJob) return
        root.tracking = false
        root.playing = !root.playing
        if (root.playing && root.scrubLine >= root.job.total) root.scrubLine = 0
        view.requestPaint()
    }

    function fastForward() {
        if (!root.hasJob) return
        root.stopPlay()
        root.scrubLine = root.job.total
        view.requestPaint()
    }

    function setScrubLine(v) {
        root.scrubLine = Math.max(0, Math.min(root.lineCount, Math.round(v)))
        view.requestPaint()
    }

    // ── Layers ──────────────────────────────────────────────────────────
    readonly property var layers: root.job ? root.job.layers : []
    readonly property int layerTotal: {
        var r = root.revision
        return root.layers.length
    }
    readonly property int currentLayer: {
        var r = root.revision
        var ls = root.layers
        var n = -1
        for (var i = 0; i < ls.length; i++) {
            if (ls[i].line <= root.scrubLine) n = i
            else break
        }
        return n < 0 ? 0 : n
    }
    readonly property int currentSeg: {
        var r = root.revision
        var seg = root.job ? root.job.seg : null
        if (!seg || seg.length === 0) return 0
        var lo = 0
        var hi = seg.length / Gp.S_STRIDE - 1
        var best = 0
        while (lo <= hi) {
            var mid = (lo + hi) >> 1
            if (seg[mid * Gp.S_STRIDE + Gp.S_LINE] <= root.scrubLine) { best = mid; lo = mid + 1 }
            else hi = mid - 1
        }
        return best
    }

    function gotoLayer(i) {
        if (!root.hasJob || root.layerTotal === 0) return
        var k = Math.max(0, Math.min(root.layerTotal - 1, i))
        root.stopPlay()
        root.tracking = false
        root.scrubLine = k === root.layerTotal - 1 ? root.job.total : root.layers[k].line
        view.requestPaint()
    }

    // ── Envelope / bed ─────────────────────────────────────────────────
    readonly property var env: {
        var rev = root.revision
        var bm = root.moonraker.data?.bedmesh
        var amin = bm?.axisMin
        var amax = bm?.axisMax
        if (amin && amax && amax[0] - amin[0] > 1) return { min: amin, max: amax, real: true }
        var b = root.job ? root.job.bounds : null
        if (b) return { min: [b.min[0] - 15, b.min[1] - 15, 0],
                        max: [b.max[0] + 15, b.max[1] + 15, Math.max(20, b.max[2] + 5)], real: false }
        return { min: [0, 0, 0], max: [350, 350, 350], real: false }
    }
    readonly property real envCx: (root.env.min[0] + root.env.max[0]) / 2
    readonly property real envCy: (root.env.min[1] + root.env.max[1]) / 2
    readonly property real envCz: (root.env.min[2] + root.env.max[2]) / 2
    readonly property real envSpan: Math.max(root.env.max[0] - root.env.min[0],
                                             root.env.max[1] - root.env.min[1],
                                             root.env.max[2] - root.env.min[2], 20)

    function serverFiles() {
        var f = root.moonraker.data?.gcodes?.files ?? []
        var out = []
        for (var i = 0; i < f.length; i++) out.push(String(f[i].filename ?? ""))
        return out
    }

    // ── Projection (same orbit camera as Heightmap.qml) ─────────────────
    function _world(x, y, z) {
        return [x - root.envCx, z, -(y - root.envCy)]
    }

    function _cross(a, b) {
        return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
    }

    function _norm(a) {
        var l = Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]) || 1
        return [a[0] / l, a[1] / l, a[2] / l]
    }

    function _camera(W, H) {
        var a = root.camAlpha * Math.PI / 180
        var b = root.camBeta * Math.PI / 180
        var ca = Math.cos(a)
        var sa = Math.sin(a)
        var dist = root.envSpan * root.zoom
        var eye = [dist * ca * Math.sin(b), dist * sa, dist * ca * Math.cos(b)]
        var fwd = _norm([-eye[0], -eye[1], -eye[2]])
        var up = Math.abs(sa) > 0.985 ? [0, 0, -1] : [0, 1, 0]
        var right = _norm(_cross(fwd, up))
        var upv = _cross(right, fwd)
        // Focal off the SHORTER side (Heightmap uses the viewport height)
        // because this window can be much taller than it is wide: a height-based
        // focal then pushes most of the bed out of frame sideways.
        return { eye: eye, fwd: fwd, right: right, up: upv,
                 focal: (Math.min(W, H) / 2) / Math.tan(45 * Math.PI / 360) }
    }

    function _screen(cam, p, W, H) {
        var dx = p[0] - cam.eye[0]
        var dy = p[1] - cam.eye[1]
        var dz = p[2] - cam.eye[2]
        var zc = Math.max(1, dx * cam.fwd[0] + dy * cam.fwd[1] + dz * cam.fwd[2])
        return [W / 2 + cam.focal * (dx * cam.right[0] + dy * cam.right[1] + dz * cam.right[2]) / zc,
                H / 2 - cam.focal * (dx * cam.up[0] + dy * cam.up[1] + dz * cam.up[2]) / zc,
                zc]
    }

    function setOrientation(name) {
        if (name === "leftFront") { root.camAlpha = 25; root.camBeta = -40 }
        else if (name === "front") { root.camAlpha = 25; root.camBeta = 0 }
        else if (name === "top") { root.camAlpha = 90; root.camBeta = 0 }
        else { root.camAlpha = 22; root.camBeta = 38 }
        root.markDirty()
        view.requestPaint()
    }

    function orientationName() {
        if (root.camAlpha === 90) return "top"
        if (root.camBeta === 0) return "front"
        return root.camBeta < 0 ? "leftFront" : "rightFront"
    }

    // ── Palette ─────────────────────────────────────────────────────────
    // Feature colours verbatim from @sindarius/gcodeviewer, union of its Prusa
    // (`;TYPE:`) and Orca (`; feature X`) tables; anything unseen is grey, which
    // is what its unknownFeatureColor does.
    readonly property var featureColors: ({
        "Outer wall": "#ffe64d", "Perimeter": "#ffe64d", "External perimeter": "#ff7d38",
        "Inner wall": "#ff7d38", "Overhang wall": "#2629bf", "Overhang perimeter": "#808080",
        "Sparse infill": "#b03029", "Internal infill": "#963029",
        "Solid infill": "#9630cc", "Internal solid infill": "#9630cc",
        "Top solid infill": "#f24040", "Top surface": "#b33838",
        "Bottom solid infill": "#665cc7", "Bottom surface": "#665cc7",
        "Bridge infill": "#4d80ba", "Bridge": "#4d80ba", "Internal Bridge": "#4d80ba",
        "Support material": "#00ff00", "Supported material": "#00ff00", "Support": "#00ff00",
        "Support material interface": "#1f6121", "Supported material interface": "#008000",
        "Support interface": "#1f6121",
        "Skirt": "#00876e", "Skirt/Brim": "#00876e",
        "Prime tower": "#b3e3ab", "Wipe tower": "#808080",
        "Gap fill": "#ffffff", "Custom": "#5eff95", "Unknown": "#808080"
    })

    function _lighten(c, k) {
        var r = Math.min(255, Math.round(c[0] + (255 - c[0]) * k))
        var g = Math.min(255, Math.round(c[1] + (255 - c[1]) * k))
        var b = Math.min(255, Math.round(c[2] + (255 - c[2]) * k))
        return "rgb(" + r + "," + g + "," + b + ")"
    }

    function _palette() {
        var out = []
        var i
        if (root.colorMode === 0) {
            for (i = 0; i < root.extruderColors.length; i++) out.push(String(root.extruderColors[i]))
            return out
        }
        if (root.colorMode === 1) {
            var lo = root._rgb(String(root.minFeedColor))
            var hi = root._rgb(String(root.maxFeedColor))
            for (i = 0; i < 16; i++) {
                var t = i / 15
                out.push("rgb(" + Math.round(lo[0] + (hi[0] - lo[0]) * t) + ","
                         + Math.round(lo[1] + (hi[1] - lo[1]) * t) + ","
                         + Math.round(lo[2] + (hi[2] - lo[2]) * t) + ")")
            }
            return out
        }
        var types = root.job ? root.job.types : ["Unknown"]
        for (i = 0; i < types.length; i++)
            out.push(String(root.featureColors[types[i]] ?? "#808080"))
        return out
    }

    function _rgb(s) {
        var h = String(s).replace("#", "")
        if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2]
        return [parseInt(h.substr(0, 2), 16), parseInt(h.substr(2, 2), 16), parseInt(h.substr(4, 2), 16)]
    }

    function bucketOf(key, feed) {
        if (root.colorMode === 0) return key >> 6
        if (root.colorMode === 1) {
            var lo = root.minFeed * 60
            var hi = root.maxFeed * 60
            var t = hi > lo ? (feed - lo) / (hi - lo) : 0
            return Math.max(0, Math.min(15, Math.floor(t * 16)))
        }
        return key & 63
    }

    // ── Painter ─────────────────────────────────────────────────────────
    function _strokeLine(ctx, cam, W, H, x0, y0, z0, x1, y1, z1) {
        var ex = cam.eye[0]
        var ey = cam.eye[1]
        var ez = cam.eye[2]
        var f0 = cam.fwd[0]
        var f1 = cam.fwd[1]
        var f2 = cam.fwd[2]
        var r0 = cam.right[0]
        var r1 = cam.right[1]
        var r2 = cam.right[2]
        var u0 = cam.up[0]
        var u1 = cam.up[1]
        var u2 = cam.up[2]
        var foc = cam.focal
        var cx = root.envCx
        var cy = root.envCy
        var ax = x0 - cx - ex
        var ay = z0 - ey
        var az = -(y0 - cy) - ez
        var zc = Math.max(1, ax * f0 + ay * f1 + az * f2)
        var px0 = W / 2 + foc * (ax * r0 + ay * r1 + az * r2) / zc
        var py0 = H / 2 - foc * (ax * u0 + ay * u1 + az * u2) / zc
        var bx = x1 - cx - ex
        var by = z1 - ey
        var bz = -(y1 - cy) - ez
        zc = Math.max(1, bx * f0 + by * f1 + bz * f2)
        var px1 = W / 2 + foc * (bx * r0 + by * r1 + bz * r2) / zc
        var py1 = H / 2 - foc * (bx * u0 + by * u1 + bz * u2) / zc
        if ((px0 < -8 && px1 < -8) || (px0 > W + 8 && px1 > W + 8)) return
        if ((py0 < -8 && py1 < -8) || (py0 > H + 8 && py1 > H + 8)) return
        ctx.moveTo(px0, py0)
        ctx.lineTo(px1, py1)
    }

    function paintToolPath(ctx, cam, W, H) {
        var job = root.job
        if (!job) return
        var seg = job.seg
        var n = seg.length
        var S = Gp.S_STRIDE
        var pal = root._palette()
        var ghost = root.transparency ? 0.2 : 0.28
        var solid = root.transparency ? 0.55 : 1.0
        var width = root.hdRendering ? 2.6 : (root.forceLines || root.cncMode ? 1.0 : 1.7)

        if (root.voxelMode) {
            ctx.lineWidth = 1
            var lastKey = -1
            for (var o = 0; o + S <= n; o += S) {
                var ok = root.bucketOf(seg[o + Gp.S_KEY], seg[o + Gp.S_FEED])
                var akey = seg[o + Gp.S_LINE] > root.scrubLine ? ok + 1000 : ok
                if (akey !== lastKey) {
                    ctx.fillStyle = pal[ok % pal.length]
                    ctx.globalAlpha = seg[o + Gp.S_LINE] > root.scrubLine ? ghost : solid
                    lastKey = akey
                }
                var pe = root._screen(cam, root._world(seg[o + 3], seg[o + 4], seg[o + 5]), W, H)
                ctx.fillRect(pe[0] - 1, pe[1] - 1, 3, 3)
            }
            ctx.globalAlpha = 1
            return
        }

        ctx.lineWidth = width
        ctx.lineCap = root.forceLines || root.cncMode ? "butt" : "round"
        ctx.globalAlpha = solid
        ctx.beginPath()
        lastKey = -1
        var pen = false
        for (o = 0; o + S <= n; o += S) {
            var key = root.bucketOf(seg[o + Gp.S_KEY], seg[o + Gp.S_FEED]) * 2
                + (seg[o + Gp.S_LINE] > root.scrubLine ? 1 : 0)
            if (key !== lastKey) {
                if (pen) ctx.stroke()
                ctx.beginPath()
                ctx.strokeStyle = pal[Math.floor(key / 2) % pal.length]
                ctx.globalAlpha = (key % 2) === 1 ? ghost : solid
                lastKey = key
                pen = false
            }
            root._strokeLine(ctx, cam, W, H, seg[o], seg[o + 1], seg[o + 2], seg[o + 3], seg[o + 4], seg[o + 5])
            pen = true
        }
        if (pen) ctx.stroke()
        ctx.globalAlpha = 1
    }

    function paintTravels(ctx, cam, W, H) {
        var job = root.job
        if (!job || job.trv.length === 0) return
        var trv = job.trv
        var T = Gp.T_STRIDE
        ctx.strokeStyle = Colors.surfaceVariantText
        ctx.globalAlpha = root.transparency ? 0.15 : 0.25
        ctx.lineWidth = 1
        ctx.beginPath()
        for (var o = 0; o + T <= trv.length; o += T) {
            if (trv[o + 6] > root.scrubLine) continue
            root._strokeLine(ctx, cam, W, H, trv[o], trv[o + 1], trv[o + 2], trv[o + 3], trv[o + 4], trv[o + 5])
        }
        ctx.stroke()
        ctx.globalAlpha = 1
    }

    function paintBed(ctx, cam, W, H) {
        var mn = root.env.min
        var mx = root.env.max
        var steps = 10
        ctx.strokeStyle = root.bedColor
        ctx.globalAlpha = 0.35
        ctx.lineWidth = 1
        ctx.beginPath()
        for (var i = 0; i <= steps; i++) {
            var x = mn[0] + (mx[0] - mn[0]) * (i / steps)
            var y = mn[1] + (mx[1] - mn[1]) * (i / steps)
            root._strokeLine(ctx, cam, W, H, x, mn[1], 0, x, mx[1], 0)
            root._strokeLine(ctx, cam, W, H, mn[0], y, 0, mx[0], y, 0)
        }
        var c = [[mn[0], mn[1], 0], [mx[0], mn[1], 0], [mx[0], mx[1], 0], [mn[0], mx[1], 0]]
        for (i = 0; i < 4; i++) {
            var a = c[i]
            var b = c[(i + 1) % 4]
            root._strokeLine(ctx, cam, W, H, a[0], a[1], 0, b[0], b[1], 0)
        }
        ctx.stroke()
        ctx.globalAlpha = 1
    }

    function paintAxes(ctx, cam, W, H) {
        var len = root.envSpan * 0.12
        var o = root._screen(cam, root._world(root.env.min[0], root.env.min[1], 0), W, H)
        var axes = [
            { v: root._screen(cam, root._world(root.env.min[0] + len, root.env.min[1], 0), W, H), c: "#ff5555" },
            { v: root._screen(cam, root._world(root.env.min[0], root.env.min[1] + len, 0), W, H), c: "#55ff55" },
            { v: root._screen(cam, root._world(root.env.min[0], root.env.min[1], len), W, H), c: "#5599ff" }
        ]
        ctx.lineWidth = 2
        for (var i = 0; i < axes.length; i++) {
            ctx.strokeStyle = axes[i].c
            ctx.beginPath()
            ctx.moveTo(o[0], o[1])
            ctx.lineTo(axes[i].v[0], axes[i].v[1])
            ctx.stroke()
        }
    }

    function objectBoxes() {
        var objs = root.live?.excludeObjects ?? []
        var excluded = root.live?.excludeExcluded ?? []
        var out = []
        for (var i = 0; i < objs.length; i++) {
            var poly = objs[i].polygon ?? []
            if (poly.length < 3) continue
            var minX = 1e9
            var maxX = -1e9
            var minY = 1e9
            var maxY = -1e9
            for (var j = 0; j < poly.length; j++) {
                minX = Math.min(minX, poly[j][0]); maxX = Math.max(maxX, poly[j][0])
                minY = Math.min(minY, poly[j][1]); maxY = Math.max(maxY, poly[j][1])
            }
            out.push({ name: String(objs[i].name ?? "?"), box: [minX, minY, maxX, maxY],
                       excluded: excluded.indexOf(objs[i].name) >= 0 })
        }
        return out
    }

    function paintObjects(ctx, cam, W, H) {
        var objs = root.objectBoxes()
        var top = root.job ? Math.max(1, root.job.bounds.max[2]) : 20
        ctx.lineWidth = 2
        for (var i = 0; i < objs.length; i++) {
            var b = objs[i].box
            var col = objs[i].excluded ? Colors.error : Colors.accent
            ctx.strokeStyle = col
            ctx.fillStyle = objs[i].excluded ? Colors.errorDim : Colors.accentDim
            var corners = [[b[0], b[1]], [b[2], b[1]], [b[2], b[3]], [b[0], b[3]]]
            ctx.beginPath()
            for (var k = 0; k < 4; k++) {
                var a = corners[k]
                var c = corners[(k + 1) % 4]
                root._strokeLine(ctx, cam, W, H, a[0], a[1], 0, c[0], c[1], 0)
                root._strokeLine(ctx, cam, W, H, a[0], a[1], top, c[0], c[1], top)
                root._strokeLine(ctx, cam, W, H, a[0], a[1], 0, a[0], a[1], top)
            }
            ctx.stroke()
            ctx.globalAlpha = 0.18
            var q = [root._screen(cam, root._world(b[0], b[1], top), W, H),
                     root._screen(cam, root._world(b[2], b[1], top), W, H),
                     root._screen(cam, root._world(b[2], b[3], top), W, H),
                     root._screen(cam, root._world(b[0], b[3], top), W, H)]
            ctx.beginPath()
            ctx.moveTo(q[0][0], q[0][1])
            for (k = 1; k < 4; k++) ctx.lineTo(q[k][0], q[k][1])
            ctx.closePath()
            ctx.fill()
            ctx.globalAlpha = 1
        }
    }

    function paintCursor(ctx, cam, W, H) {
        if (!root.showCursor || !root.live) return
        var x = Number(root.live.toolheadX ?? 0)
        var y = Number(root.live.toolheadY ?? 0)
        var z = Number(root.live.toolheadZ ?? 0) - Number(root.live.zOffset ?? 0)
        var p = root._screen(cam, root._world(x, y, z), W, H)
        ctx.fillStyle = Colors.accent
        ctx.globalAlpha = 0.25
        ctx.beginPath()
        ctx.arc(p[0], p[1], 11, 0, Math.PI * 2)
        ctx.fill()
        ctx.globalAlpha = 1
        ctx.beginPath()
        ctx.arc(p[0], p[1], 4.5, 0, Math.PI * 2)
        ctx.fill()
        ctx.strokeStyle = Colors.surfaceContainerLowest
        ctx.lineWidth = 1.5
        ctx.stroke()
    }

    function paintScrubMarker(ctx, cam, W, H) {
        var job = root.job
        if (!job || job.seg.length === 0 || root.tracking) return
        var o = root.currentSeg * Gp.S_STRIDE
        if (o + 5 >= job.seg.length) return
        var p = root._screen(cam, root._world(job.seg[o + 3], job.seg[o + 4], job.seg[o + 5]), W, H)
        ctx.fillStyle = root.progressColor
        ctx.beginPath()
        ctx.arc(p[0], p[1], 4, 0, Math.PI * 2)
        ctx.fill()
        ctx.strokeStyle = Colors.surfaceContainerLowest
        ctx.lineWidth = 1.5
        ctx.stroke()
    }

    // ── Object hit test (screen space, top and bottom faces) ────────────
    function objectAt(sx, sy, cam, W, H) {
        var objs = root.objectBoxes()
        var top = root.job ? Math.max(1, root.job.bounds.max[2]) : 20
        for (var i = 0; i < objs.length; i++) {
            var b = objs[i].box
            var corners = [[b[0], b[1]], [b[2], b[1]], [b[2], b[3]], [b[0], b[3]]]
            for (var face = 0; face < 2; face++) {
                var quad = []
                for (var k = 0; k < 4; k++) {
                    var c = corners[k]
                    quad.push(root._screen(cam, root._world(c[0], c[1], face === 0 ? 0 : top), W, H))
                }
                if (root._inQuad(quad, sx, sy)) return objs[i]
            }
        }
        return null
    }

    function _inQuad(q, x, y) {
        var inside = false
        var j = 3
        for (var i = 0; i < 4; i++) {
            if (((q[i][1] > y) !== (q[j][1] > y))
                && (x < (q[j][0] - q[i][0]) * (y - q[i][1]) / (q[j][1] - q[i][1]) + q[i][0]))
                inside = !inside
            j = i
        }
        return inside
    }

    // ── View ────────────────────────────────────────────────────────────
    Panel {
        anchors.fill: parent
        anchors.margins: Metrics.panelMargin
        title: "GCODE VIEWER" + (root.fileName !== "" ? ": " + root.fileName : "")
        icon: Icons.viewer
        collapsible: false

        Column {
            id: body
            anchors.left: parent.left
            anchors.leftMargin: Metrics.panelPadding
            anchors.right: parent.right
            anchors.rightMargin: Metrics.panelPadding
            anchors.top: parent.top
            anchors.topMargin: parent.bodyTop
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.panelPadding
            spacing: Metrics.sm

            // The window is not a fixed size (Hyprland tiles it, and it can end
            // up far taller than it is wide), so every width here is arithmetic
            // with a floor: the code stream only opens when the canvas would
            // still have room, and the controls row scrolls sideways rather
            // than pushing the layout negative.
            readonly property int bottomH: 30 + Metrics.sm + 30 + Metrics.sm + 22
            readonly property bool bottomVisible: root.hasJob || root.status !== ""
            readonly property int mainH: height - (bottomVisible ? bottomH + spacing : 0)

            Row {
                id: viewerRow
                width: parent.width
                height: body.mainH
                spacing: Metrics.lg

                readonly property int railSpace: width - rail.width - Metrics.lg
                readonly property bool codeOpen: root.showGCode && railSpace >= 620
                readonly property int codeW: Math.max(260, Math.min(420, railSpace - 312))

                Rectangle {
                    id: viewBox
                    width: parent.railSpace - (viewerRow.codeOpen ? viewerRow.codeW + Metrics.lg : 0)
                    height: parent.height
                    color: Colors.surfaceContainerLowest
                    radius: Metrics.radiusMedium
                    border.width: Metrics.borderWidth
                    border.color: Colors.outlineVariant
                    clip: true

                    Canvas {
                        id: view
                        anchors.fill: parent
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            var ctx = view.getContext("2d")
                            ctx.reset()
                            var W = view.width
                            var H = view.height
                            if (W < 4 || H < 4) return
                            var cam = root._camera(W, H)
                            root.paintBed(ctx, cam, W, H)
                            if (root.showAxes) root.paintAxes(ctx, cam, W, H)
                            if (root.showTravels) root.paintTravels(ctx, cam, W, H)
                            root.paintToolPath(ctx, cam, W, H)
                            if (root.showObjects && root.objectBoxes().length > 0) root.paintObjects(ctx, cam, W, H)
                            root.paintScrubMarker(ctx, cam, W, H)
                            root.paintCursor(ctx, cam, W, H)
                        }
                    }

                    MouseArea {
                        id: orbit
                        anchors.fill: parent
                        cursorShape: Qt.OpenHandCursor
                        property real lastX: 0
                        property real lastY: 0
                        property bool dragging: false
                        property real pressX: 0
                        property real pressY: 0
                        onPressed: function(e) {
                            dragging = true
                            lastX = e.x
                            lastY = e.y
                            pressX = e.x
                            pressY = e.y
                            cursorShape = Qt.ClosedHandCursor
                        }
                        onReleased: function(e) {
                            cursorShape = Qt.OpenHandCursor
                            if (Math.abs(e.x - pressX) < 4 && Math.abs(e.y - pressY) < 4)
                                root._click(e.x, e.y)
                        }
                        onPositionChanged: function(e) {
                            if (!dragging) return
                            root.camBeta = root.camBeta - (e.x - lastX) * 0.4
                            root.camAlpha = Math.max(5, Math.min(90, root.camAlpha + (e.y - lastY) * 0.4))
                            lastX = e.x
                            lastY = e.y
                            root.markDirty()
                            view.requestPaint()
                        }
                    }

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            root.zoom = Math.max(0.5, Math.min(4, root.zoom * (1 - event.angleDelta.y * 0.001)))
                            root.markDirty()
                            view.requestPaint()
                            event.accepted = true
                        }
                    }

                    Item {
                        visible: !root.job
                        anchors.centerIn: parent
                        width: parent.width * 0.7
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: root.busy
                                ? "Rendering the toolpath…"
                                : "No file loaded. Use LOAD CURRENT for the printing file, "
                                  + "LOAD LOCAL for a file on this machine, or SERVER to pick one "
                                  + "from the printer."
                            font.family: Type.family
                            font.pixelSize: Type.sizeSmall
                            color: Colors.textTertiary
                        }
                    }

                    Text {
                        visible: root.job !== null
                        anchors.right: parent.right
                        anchors.rightMargin: Metrics.md
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Metrics.sm
                        text: "drag to orbit · wheel to zoom · click an object to exclude it"
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        color: Colors.textTertiary
                    }

                    Rectangle {
                        visible: root.busy
                        anchors.fill: parent
                        color: Colors.alpha(Colors.surfaceContainerLowest, 0.82)
                        Column {
                            anchors.centerIn: parent
                            spacing: Metrics.sm
                            width: parent.width * 0.6
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.moonraker.gcodeLoading
                                    ? "DOWNLOADING " + (root.fileName !== "" ? root.fileName : "")
                                    : "RENDERING — " + Math.round((root.job?.progress ?? 0) * 100) + "%"
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                font.bold: true
                                color: Colors.textPrimary
                                elide: Text.ElideMiddle
                            }
                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Colors.selectedFill
                                Rectangle {
                                    height: parent.height
                                    radius: 2
                                    color: Colors.accent
                                    width: root.moonraker.gcodeLoading
                                        ? parent.width * 0.35
                                        : parent.width * (root.job?.progress ?? 0)
                                }
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Metrics.md
                                Button {
                                    height: 26
                                    text: "CANCEL"
                                    variant: "soft"
                                    onPressed: {
                                        if (root.moonraker.gcodeLoading) root.moonraker.cancelGcodeFetch()
                                        else root.cancelParse()
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: codeBox
                    visible: viewerRow.codeOpen
                    width: viewerRow.codeW
                    height: parent.height
                    color: Colors.surfaceContainerLow
                    radius: Metrics.radiusSmall
                    border.width: Metrics.borderWidth
                    border.color: Colors.outlineVariant
                    clip: true

                    ListView {
                        id: codeList
                        anchors.fill: parent
                        anchors.margins: Metrics.xs
                        clip: true
                        model: root.job ? root.job.lines : []
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Item {
                            id: codeRow
                            required property int index
                            required property string modelData
                            width: codeList.width
                            height: 16
                            Rectangle {
                                anchors.fill: parent
                                color: codeRow.index === root.scrubLine ? Colors.selectedFill : "transparent"
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: codeRow.modelData
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption - 1
                                color: codeRow.index === root.scrubLine ? Colors.accent : Colors.surfaceVariantText
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.stopPlay()
                                    root.tracking = false
                                    root.setScrubLine(codeRow.index)
                                }
                            }
                        }
                    }

                    Connections {
                        target: root
                        function onScrubLineChanged() {
                            if (root.showGCode && root.job)
                                codeList.positionViewAtIndex(root.scrubLine, ListView.Center)
                        }
                    }
                }

                Flickable {
                    id: rail
                    width: root.railW
                    height: parent.height
                    clip: true
                    contentHeight: railCol.height
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: railCol
                        width: rail.width
                        spacing: Metrics.sm

                        SectionHeader { text: "FILE"; icon: Icons.folder }

                        Text {
                            width: parent.width
                            text: root.fileName !== "" ? root.fileName : "— none —"
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            font.bold: true
                            color: root.fileName !== "" ? Colors.textPrimary : Colors.surfaceVariantText
                            elide: Text.ElideMiddle
                        }
                        KV {
                            key: "Showing"
                            labelWidth: 104
                            value: Math.min(root.scrubLine, root.lineCount) + "/" + root.lineCount + " lines"
                        }
                        KV {
                            key: "Layers"
                            labelWidth: 104
                            value: root.layerTotal + (root.layerTotal > 0
                                ? " (on " + (root.currentLayer + 1) + ")" : "")
                        }
                        KV {
                            key: "Segments"
                            labelWidth: 104
                            value: root.job ? (root.job.count + " → " + root.job.travelCount + " travels") : "—"
                        }

                        Flow {
                            width: parent.width
                            spacing: Metrics.sm

                            Button {
                                height: 26
                                text: "LOAD CURRENT"; icon: Icons.download
                                variant: "soft"
                                active: root.printFile !== ""
                                onPressed: root.loadCurrent()
                            }
                            Button {
                                height: 26
                                text: "LOAD LOCAL"; icon: Icons.load
                                variant: "soft"
                                onPressed: root.chooseLocal()
                            }
                            Button {
                                height: 26
                                text: "SERVER"; icon: Icons.server
                                variant: root.fileListOpen ? "primary" : "soft"
                                onPressed: {
                                    root.fileListOpen = !root.fileListOpen
                                    if (root.fileListOpen) {
                                        root.moonraker.fetchGcodeFiles("")
                                        fileList.model = root.serverFiles()
                                    }
                                }
                            }
                            Button {
                                height: 26
                                text: "CLEAR"; icon: Icons.clear
                                variant: "soft"
                                active: root.job !== null
                                onPressed: root.clearFile()
                            }
                            Button {
                                height: 26
                                text: "RELOAD CHANGES"
                                variant: "primary"
                                active: root.reloadRequired
                                onPressed: root.reloadFile()
                            }
                        }

                        ListView {
                            id: fileList
                            visible: root.fileListOpen
                            width: parent.width
                            height: Math.min(180, Math.max(24, model.length * 22))
                            clip: true
                            model: []
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: ListRow {
                                required property string modelData
                                width: fileList.width
                                height: 22
                                text: modelData
                                selected: modelData === root.fileName
                                onClicked: root.loadServer(modelData)
                            }
                        }

                        Separator { width: parent.width }
                        SectionHeader { text: "COLOUR MODE"; icon: Icons.palette }

                        Flow {
                            width: parent.width
                            spacing: Metrics.sm
                            Repeater {
                                model: [
                                    { v: 0, label: "EXTRUDER" },
                                    { v: 1, label: "FEED RATE" },
                                    { v: 2, label: "FEATURE" }
                                ]
                                delegate: Button {
                                    id: cmode
                                    required property var modelData
                                    height: 26
                                    text: cmode.modelData.label
                                    variant: root.colorMode === cmode.modelData.v ? "primary" : "soft"
                                    onPressed: {
                                        root.colorMode = cmode.modelData.v
                                        root.markDirty()
                                        view.requestPaint()
                                    }
                                }
                            }
                        }

                        Column {
                            visible: root.colorMode === 0
                            width: parent.width
                            spacing: Metrics.xs
                            Repeater {
                                model: root.extruderColors.length
                                delegate: Row {
                                    id: trow
                                    required property int index
                                    width: railCol.width
                                    height: 24
                                    spacing: Metrics.sm
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 52
                                        text: "T" + trow.index
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        color: Colors.surfaceVariantText
                                    }
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 90
                                        height: 16
                                        radius: Metrics.radiusSmall - 4
                                        color: root.extruderColors[trow.index]
                                        border.width: 1
                                        border.color: Colors.outlineVariant
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var arr = root.extruderColors.slice()
                                                arr[trow.index] = root._cycleColor(arr[trow.index])
                                                root.extruderColors = arr
                                                root.reloadRequired = true
                                                root.markDirty()
                                                view.requestPaint()
                                            }
                                        }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "click to cycle"
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption - 1
                                        color: Colors.textTertiary
                                    }
                                }
                            }
                        }

                        Column {
                            visible: root.colorMode === 1
                            width: parent.width
                            spacing: Metrics.xs
                            Slider {
                                width: parent.width
                                label: "MIN FEED"
                                minimum: 1
                                maximum: 300
                                step: 5
                                unit: " mm/s"
                                value: root.minFeed
                                onMoved: function(v) { root.minFeed = v }
                                onReleased: function(v) {
                                    root.minFeed = v
                                    if (root.maxFeed <= v) root.maxFeed = v + 1
                                    root.markDirty()
                                    view.requestPaint()
                                }
                            }
                            Slider {
                                width: parent.width
                                label: "MAX FEED"
                                minimum: 1
                                maximum: 600
                                step: 5
                                unit: " mm/s"
                                value: root.maxFeed
                                onMoved: function(v) { root.maxFeed = v }
                                onReleased: function(v) {
                                    root.maxFeed = Math.max(root.minFeed + 1, v)
                                    root.markDirty()
                                    view.requestPaint()
                                }
                            }
                            Row {
                                width: parent.width
                                spacing: Metrics.sm
                                Rectangle {
                                    width: 90
                                    height: 16
                                    radius: Metrics.radiusSmall - 4
                                    color: root.minFeedColor
                                    border.width: 1
                                    border.color: Colors.outlineVariant
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.minFeedColor = root._cycleColor(root.minFeedColor)
                                            root.reloadRequired = true
                                            root.markDirty()
                                            view.requestPaint()
                                        }
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "min colour"
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeCaption
                                    color: Colors.surfaceVariantText
                                }
                            }
                            Row {
                                width: parent.width
                                spacing: Metrics.sm
                                Rectangle {
                                    width: 90
                                    height: 16
                                    radius: Metrics.radiusSmall - 4
                                    color: root.maxFeedColor
                                    border.width: 1
                                    border.color: Colors.outlineVariant
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.maxFeedColor = root._cycleColor(root.maxFeedColor)
                                            root.reloadRequired = true
                                            root.markDirty()
                                            view.requestPaint()
                                        }
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "max colour"
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeCaption
                                    color: Colors.surfaceVariantText
                                }
                            }
                        }

                        Separator { width: parent.width }
                        SectionHeader { text: "OPTIONS"; icon: Icons.tune }

                        Flow {
                            width: parent.width
                            spacing: Metrics.sm
                            Repeater {
                                model: [
                                    { k: "showCursor", label: "TOOLHEAD" },
                                    { k: "showTravels", label: "TRAVELS" },
                                    { k: "showGCode", label: "CODE" },
                                    { k: "showObjects", label: "OBJECTS" },
                                    { k: "showAxes", label: "AXES" },
                                    { k: "hdRendering", label: "HD" },
                                    { k: "forceLines", label: "LINES" },
                                    { k: "transparency", label: "TRANSPARENT" },
                                    { k: "voxelMode", label: "VOXEL" },
                                    { k: "cncMode", label: "CNC" }
                                ]
                                delegate: Button {
                                    id: opt
                                    required property var modelData
                                    height: 26
                                    text: opt.modelData.label
                                    variant: root[opt.modelData.k] ? "primary" : "soft"
                                    onPressed: {
                                        root[opt.modelData.k] = !root[opt.modelData.k]
                                        if (opt.modelData.k === "showGCode" && root.showGCode && root.job)
                                            codeList.positionViewAtIndex(root.scrubLine, ListView.Center)
                                        if (opt.modelData.k === "cncMode") root.reloadRequired = true
                                        root.markDirty()
                                        view.requestPaint()
                                    }
                                }
                            }
                        }

                        Separator { width: parent.width }
                        SectionHeader { text: "RENDER QUALITY"; icon: Icons.gauge }

                        Flow {
                            width: parent.width
                            spacing: Metrics.sm
                            Repeater {
                                model: [
                                    { v: 1, label: "LOW" },
                                    { v: 2, label: "MEDIUM" },
                                    { v: 3, label: "HIGH" },
                                    { v: 4, label: "ULTRA" },
                                    { v: 5, label: "MAX" }
                                ]
                                delegate: Button {
                                    id: qual
                                    required property var modelData
                                    height: 26
                                    text: qual.modelData.label
                                    variant: root.quality === qual.modelData.v ? "primary" : "soft"
                                    onPressed: {
                                        root.quality = qual.modelData.v
                                        root.reloadRequired = true
                                        root.markDirty()
                                    }
                                }
                            }
                        }

                        Separator { width: parent.width }
                        SectionHeader { text: "CAMERA"; icon: Icons.camera }

                        Flow {
                            width: parent.width
                            spacing: Metrics.sm
                            Repeater {
                                model: [
                                    { id: "rightFront", label: "RIGHT FRONT" },
                                    { id: "leftFront", label: "LEFT FRONT" },
                                    { id: "front", label: "FRONT" },
                                    { id: "top", label: "TOP" }
                                ]
                                delegate: Button {
                                    id: orow
                                    required property var modelData
                                    height: 26
                                    text: orow.modelData.label
                                    variant: root.orientationName() === orow.modelData.id ? "primary" : "soft"
                                    onPressed: root.setOrientation(orow.modelData.id)
                                }
                            }
                        }

                        Slider {
                            width: parent.width
                            label: "ZOOM"
                            minimum: 0.5
                            maximum: 4
                            step: 0.05
                            integer: false
                            unit: "×"
                            value: root.zoom
                            onMoved: function(v) { root.zoom = v; view.requestPaint() }
                            onReleased: function(v) { root.zoom = v; root.markDirty(); view.requestPaint() }
                        }
                    }
                }
            }

            Column {
                id: bottomCol
                visible: body.bottomVisible
                width: parent.width
                height: body.bottomH
                spacing: Metrics.sm

                Item {
                    id: scrubRow
                    width: parent.width
                    height: 30

                    Slider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        label: "POSITION"
                        minimum: 0
                        maximum: Math.max(1, root.lineCount)
                        step: 1
                        unit: ""
                        value: root.scrubLine
                        onMoved: function(v) { if (!root.tracking) root.setScrubLine(v) }
                        onReleased: function(v) { if (!root.tracking) root.setScrubLine(v) }
                    }
                }

                // Sideways-scrolling control strip: this row is wider than a
                // narrow window, and a plain Row would silently overflow.
                Flickable {
                    id: controlsRow
                    width: parent.width
                    height: 30
                    contentWidth: playCol.width
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: playCol
                        height: parent.height
                        spacing: Metrics.sm

                        Button {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            width: 88
                            text: root.playing ? "PAUSE" : "PLAY"; icon: root.playing ? Icons.pause : Icons.play
                            variant: root.playing ? "primary" : "soft"
                            active: root.hasJob
                            onPressed: root.togglePlay()
                        }
                        Button {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            width: 96
                            text: "END"; icon: Icons.end
                            variant: "soft"
                            active: root.hasJob
                            onPressed: root.fastForward()
                        }
                        Button {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            width: 74
                            text: "PREV L"; icon: Icons.prev
                            variant: "soft"
                            active: root.layerTotal > 1
                            onPressed: root.gotoLayer(root.currentLayer - 1)
                        }
                        Button {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            width: 74
                            text: "NEXT L"; icon: Icons.next
                            variant: "soft"
                            active: root.layerTotal > 1
                            onPressed: root.gotoLayer(root.currentLayer + 1)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 118
                            text: Icons.layers + " LAYER " + (root.layerTotal > 0 ? (root.currentLayer + 1) : 0)
                                  + " / " + root.layerTotal
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            color: Colors.textPrimary
                        }
                        Repeater {
                            model: [1, 2, 5, 10, 20]
                            delegate: Button {
                                id: spd
                                required property int modelData
                                anchors.verticalCenter: parent.verticalCenter
                                height: 26
                                width: 46
                                text: spd.modelData + "x"
                                variant: root.playSpeed === spd.modelData ? "primary" : "soft"
                                onPressed: root.playSpeed = spd.modelData
                            }
                        }
                        Button {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            width: 120
                            text: "TRACK PRINT"; icon: Icons.target
                            variant: root.tracking ? "primary" : "soft"
                            active: root.trackingAvailable
                            onPressed: {
                                root.tracking = !root.tracking
                                root.stopPlay()
                                if (root.tracking && root.hasJob)
                                    root.setScrubLine(Number(root.live?.printProgress ?? 0) * root.job.total)
                                view.requestPaint()
                            }
                        }
                    }
                }

                Row {
                    id: statusRow
                    width: parent.width
                    height: 22
                    spacing: Metrics.md

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.status
                    font.family: Type.family
                    font.pixelSize: Type.sizeCaption
                    color: Colors.surfaceVariantText
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.filePath
                    font.family: Type.family
                    font.pixelSize: Type.sizeCaption
                    color: Colors.textTertiary
                    elide: Text.ElideMiddle
                    width: Math.min(420, implicitWidth)
                }
                Chip {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.tracking
                    pill: true
                    filled: true
                    text: "TRACKING"
                    color: Colors.accent
                }
                Chip {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.reloadRequired
                    pill: true
                    filled: true
                    text: "RELOAD REQUIRED"
                    color: Colors.tempWarm
                }
                    }
                }
            }
        }

    readonly property var colorCycle: ["#ff6b35", "#4ea5d9", "#44cf6c", "#ffd23f",
                                       "#ff5d8f", "#a0e548", "#c084fc", "#ffffff"]

    function _cycleColor(c) {
        var cur = String(c).toLowerCase()
        var i = root.colorCycle.indexOf(cur)
        return root.colorCycle[(i + 1) % root.colorCycle.length]
    }

    function _click(sx, sy) {
        if (!root.showObjects || !root.hasJob) return
        var cam = root._camera(view.width, view.height)
        var obj = root.objectAt(sx, sy, cam, view.width, view.height)
        if (obj && !obj.excluded) root.pendingObject = obj.name
    }

    ConfirmDialog {
        anchors.fill: parent
        opened: root.pendingObject !== ""
        message: "Exclude \"" + root.pendingObject + "\" from the current print?"
        confirmText: "Exclude"
        destructive: true
        onCanceled: root.pendingObject = ""
        onConfirmed: {
            root.moonraker.excludeObject(root.pendingObject)
            root.status = "excluded " + root.pendingObject
            root.pendingObject = ""
        }
    }
}
