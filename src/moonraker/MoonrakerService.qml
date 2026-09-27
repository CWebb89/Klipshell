pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Moonraker client for klipshell. Transport is polled HTTP JSON-RPC (curl
// Process slots) — no extra deps, PrintService-proven. All views read the
// normalized `data` bucket + the core polled `active` state; a later
// QtWebsockets swap only replaces the fetch internals below.
QtObject {
    id: root

    property var printers: []
    property var printerData: ({})
    property string activePrinter: ""
    property bool loading: false
    property var active: null
    readonly property bool connected: active?.connected === true
    signal stateChanged()

    property var _missCount: ({})

    // Per-view normalized data buckets (files/history/machine/...).
    property var data: ({})
    signal bucketChanged(string bucket)

    // ── Notifications: the event log behind the dashboard bell ──────────
    // Mainsail's notification centre, fed only by what the poll already
    // observes — poll misses and print/klippy state transitions — plus
    // error lines out of /server/gcode_store. No extra transport, and no
    // persistence: this is a session log, not printer history.
    property var notifications: []
    property int unread: 0

    function note(type, title, detail) {
        root.notifications = [{ type: type, title: title, detail: String(detail || ""),
                                time: Date.now() }].concat(root.notifications).slice(0, Settings.notifCap)
        root.unread = root.unread + 1
    }
    function markNotificationsRead() {
        if (root.unread !== 0) root.unread = 0
    }
    function clearNotifications() {
        root.notifications = []
        root.markNotificationsRead()
    }
    // Diffs one commit against the previous snapshot. Returns early on the
    // first commit (no `prev`), on a printer switch, and in demo mode, so a
    // fresh window or a demo session never fabricates history.
    function _observe(prev, next) {
        if (!prev || !next || !next.name || prev.name !== next.name) return
        if (prev.printState !== next.printState) {
            var file = String(next.printFilename || "").trim()
            if (next.printState === "error")
                root.note("error", "PRINT ERROR", next.printMessage || file || "unknown error")
            else if (next.printState === "cancelled")
                root.note("warning", "PRINT CANCELLED", file)
            else if (next.printState === "paused")
                root.note("info", "PRINT PAUSED", file)
            else if (next.printState === "complete")
                root.note("info", "PRINT COMPLETE", file)
            else if (next.printState === "printing" && prev.printState !== "paused")
                root.note("info", "PRINT STARTED", file)
        }
        if (prev.klippyState !== next.klippyState && next.klippyState) {
            if (next.klippyState === "shutdown" || next.klippyState === "error")
                root.note("error", "KLIPPY " + next.klippyState.toUpperCase(), next.klippyMessage)
            else if (next.klippyState === "ready")
                root.note("info", "KLIPPY READY", "")
        }
    }
    // gcode_store lines carry a float `time`, so the newest one seen is the
    // whole dedupe: every poll re-serves the same ring. -1 means "first
    // fetch" — its backlog is baseline, not news.
    property real _storeTime: -1
    function _scanStore(list) {
        if (!list || list.length === undefined) return
        var newest = root._storeTime
        for (var i = 0; i < list.length; i++) {
            var e = list[i]
            var t = Number(e?.time ?? 0)
            if (t > newest) newest = t
            if (root._storeTime < 0 || t <= root._storeTime || e?.type !== "error") continue
            root.note("error", "KLIPPER ERROR", String(e.message || "").replace(/^!!\s*/, ""))
        }
        root._storeTime = newest
    }

    // Demo mode: when the active printer is unreachable, serve realistic
    // normalized data so the UI stays populated (dev/offsite). Short-circuits
    // the transport below; `demo` flips on after repeated poll misses.
    property bool demo: false
    property var _demoLines: []
    property var _demoTempSeries: null
    property int _demoProbe: 0
    property string _demoGcodeText: ""

    // ── Core poll (active printer only) ────────────────────────────────
    property var _configLoader: Process {
        command: ["sh", "-c", "cat \"" + Quickshell.shellDir + "/src/config/printers.json\" 2>/dev/null || echo '{\"printers\":[]}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    if (data.printers && data.printers.length > 0) {
                        root.printers = data.printers
                        root.activePrinter = root._preferredPrinter()
                        root.refresh()
                    }
                } catch (e) {
                    console.error("printer config parse failed:", e)
                }
            }
        }
    }

    property var pollTimer: Timer {
        interval: Settings.pollMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    property bool _printerChosen: false

    // Settings' stored default wins over printers[0] while that printer is
    // still configured — a printer removed from printers.json must not strand
    // the app on nothing.
    function _preferredPrinter() {
        var want = Settings.defaultPrinter
        for (var i = 0; i < root.printers.length; i++)
            if (String(root.printers[i].name) === want) return want
        return root.printers.length > 0 ? String(root.printers[0].name) : ""
    }

    function selectPrinter(name) {
        root._printerChosen = true
        root._activatePrinter(name)
    }

    // settings.json and printers.json are two independent `cat`s at startup, so
    // the stored default can land either side of the printer list; apply it
    // once it is known. A default chosen mid-session never overrides a pick.
    function applyStoredDefault() {
        if (root._printerChosen) return
        var want = root._preferredPrinter()
        if (want !== "" && want !== root.activePrinter) root._activatePrinter(want)
    }

    // QtObject has no default property, so every child object has to be a named
    // property (same reason pollTimer/loadProc are declared this way).
    property var _defaultWatcher: Connections {
        target: Settings
        function onLoadedChanged() { if (Settings.loaded) root.applyStoredDefault() }
    }

    function _activatePrinter(name) {
        if (!name) return
        root.activePrinter = name
        root.demo = false
        for (var k in root.data) delete root.data[k]
        root.refresh()
        root.stateChanged()
    }

    function _persistPrinters() {
        var f = Quickshell.shellDir + "/src/config/printers.json"
        var json = JSON.stringify({ printers: root.printers }).replace(/'/g, "'\\''")
        root._printersSave.command = ["bash", "-c", "printf '%s' '" + json + "' > '" + f + "'"]
        root._printersSave.running = false
        root._printersSave.running = true
    }
    function addPrinter(name, host, port) {
        var n = String(name || "").trim()
        var h = String(host || "").trim()
        if (!n || !h) return
        var arr = JSON.parse(JSON.stringify(root.printers))
        for (var i = 0; i < arr.length; i++) if (String(arr[i].name) === n) return
        arr.push({ name: n, host: h, port: Number(port) || 7125 })
        root.printers = arr
        root._persistPrinters()
        if (!root.activePrinter) {
            root.activePrinter = n
            root.refresh()
            root.stateChanged()
        }
    }
    function removePrinter(i) {
        var arr = JSON.parse(JSON.stringify(root.printers))
        if (i < 0 || i >= arr.length) return
        var removed = String(arr[i].name)
        arr.splice(i, 1)
        root.printers = arr
        root._persistPrinters()
        if (removed === root.activePrinter) {
            root.activePrinter = arr.length > 0 ? String(arr[0].name) : ""
            if (root.activePrinter === "") root.demo = true
            root.refresh()
            root.stateChanged()
        }
    }
    property var _printersSave: Process {
        command: ["true"]
        running: false
    }

    function reconnect() {
        if (!root.activePrinter && root.printers.length > 0)
            root.activePrinter = root.printers[0].name
        root._missCount = {}
        root.demo = false
        for (var k in root.data) delete root.data[k]
        root.refresh()
    }

    function refresh() {
        var cfg = root._activeCfg()
        if (!cfg) return
        if (root.demo) {
            // Periodically probe the real printer so demo exits on its own
            // the moment Moonraker answers again (printer powered back on).
            root._demoProbe = (root._demoProbe || 0) + 1
            // Retry on wall-clock, not on a tick count: at a slow cadence a fixed
            // tick count would stretch demo recovery out to minutes.
            if (root._demoProbe % Math.max(1, Math.round(15000 / Math.max(1, Settings.pollMs))) === 0)
                root._probeDemo(cfg)
            root._seedDemo(cfg)
            return
        }
        root.loading = true
        root._syncObjects()
        root._get("/printer/objects/query?display_status&extruder&gcode_move&heater_bed&heater_generic&print_stats&toolhead&virtual_sdcard&fan&system_stats&exclude_object",
                  root._handleObjects, cfg)
        root._get("/printer/info", root._handleInfo, cfg)
        root._get("/server/temperature_store?include_monitors=false", root._handleTempStore, cfg)
        root.fetchFans()
        root.fetchMcus()
        // Keeps the console panel fresh and is the only live source of
        // Klipper errors for the notification log — gcode responses are the
        // one thing a poll can catch that a status query cannot. Fired last,
        // so `_freeSlot()` starvation drops this before a core poll.
        root.fetchGcodeStore(80)
        // The dashboard's standby card reads the gcode listing; re-poll it so
        // slicer uploads show up without reloading. Dropped by `_freeSlot()`
        // before a core poll, like the store above.
        root.fetchFiles("gcodes")
        // The roots list, the directory listing and the machine report are
        // otherwise one-shots from the Machine view. `_freeSlot()` drops a
        // request when all 8 are busy (the view's open burst is 6 at once), so a
        // dropped fetch left the card on the config/gcodes/logs fallback, blank,
        // or reading "printer unreachable" until the next view open. Retry while
        // a bucket has never landed — each guard clears itself.
        if (!root.data.roots) root.fetchRoots()
        if (!root.data.dir && root._lastDir) root.fetchDir(root._lastDir.root, root._lastDir.path)
        if (!root.data.gcodes && root._lastGcodePath !== null) root.fetchGcodeFiles(root._lastGcodePath)
        if (!root.data.machine?.proc) root.fetchProcStats()
        if (!root.data.machine?.sysinfo) root.fetchSysInfo()
        if (!root.data.machine?.update) root.fetchUpdateInfo()
        if (!root.data.bedmesh && root._bedMeshWanted) root.fetchBedMesh()
    }

    function _activeCfg() {
        for (var i = 0; i < root.printers.length; i++)
            if (root.printers[i].name === root.activePrinter)
                return root.printers[i]
        return null
    }

    function _handleObjects(cfg, raw) {
        var t = raw.trim()
        if (!t || t === "{}") { root._miss(); return }
        try {
            var data = JSON.parse(t)
            if (data.error || !data.result || !data.result.status) { root._miss(); return }
            var result = data.result
            var status = result.status
            root._missCount[cfg.name] = 0
            var state = root.printerData[cfg.name] || {}
            state.name = cfg.name
            state.connected = true
            state.extruderTemp = status.extruder?.temperature ?? 0
            state.extruderTarget = status.extruder?.target ?? 0
            state.bedTemp = status.heater_bed?.temperature ?? 0
            state.bedTarget = status.heater_bed?.target ?? 0
            state.printState = status.print_stats?.state ?? "standby"
            state.printMessage = status.print_stats?.message ?? ""
            state.printProgress = status.virtual_sdcard?.progress ?? 0
            state.printFilename = status.print_stats?.filename ?? ""
            state.printDuration = status.print_stats?.print_duration ?? 0
            state.printTotal = status.print_stats?.total_duration ?? 0
            state.toolheadX = status.toolhead?.position?.[0] ?? 0
            state.toolheadY = status.toolhead?.position?.[1] ?? 0
            state.toolheadZ = status.toolhead?.position?.[2] ?? 0
            state.fanPower = status.fan?.power ?? 0
            state.speedFactor = status.gcode_move?.speed_factor ?? 1
            state.flowFactor = status.gcode_move?.extrude_factor ?? 1
            state.pressureAdvance = status.extruder?.pressure_advance ?? 0
            state.smoothTime = status.extruder?.smooth_time ?? 0
            state.maxVelocity = status.toolhead?.max_velocity ?? 0
            state.maxSquareCorner = status.toolhead?.square_corner_velocity ?? 0
            state.maxAccel = status.toolhead?.max_accel ?? 0
            state.cruiseRatio = status.toolhead?.minimum_cruise_ratio ?? 0
            state.zOffset = status.gcode_move?.homing_origin?.[2] ?? 0
            state.filamentUsed = status.print_stats?.filament_used ?? 0
            state.layerCurrent = status.print_stats?.info?.current_layer ?? 0
            state.layerTotal = status.print_stats?.info?.total_layer ?? 0
            state.excludeObjects = status.exclude_object?.objects ?? []
            state.excludeExcluded = status.exclude_object?.excluded_objects ?? []
            state.displayMessage = status.display_status?.message ?? ""
            state.sysload = Number(status.system_stats?.sysload ?? 0)
            state.heaters = []
            var hg = status.heater_generic || {}
            for (var h in hg)
                state.heaters.push({ name: h, temp: hg[h]?.temperature ?? 0, target: hg[h]?.target ?? 0 })
            root._commit(state)
        } catch (e) { root._miss() }
    }

    function _handleInfo(cfg, raw) {
        try {
            var data = JSON.parse(raw.trim())
            if (data.error || !data.result) { root._miss(); return }
            var result = data.result
            var state = root.printerData[cfg.name] || {}
            state.name = cfg.name
            state.klippyState = result.state || ""
            state.klippyMessage = result.state_message || ""
            state.softwareVersion = result.software_version || ""
            root._commit(state)
        } catch (e) {}
    }

    function _handleTempStore(cfg, raw) {
        try {
            var data = JSON.parse(raw.trim())
            if (data.error || !data.result) { root._miss(); return }
            var r = data.result
            var series = []
            for (var name in r) {
                var obj = r[name]
                if (!obj || !Array.isArray(obj.temperatures)) continue
                // Server ignores count and returns ~1200 samples (40 min at
                // 2s); keep the last 180 (~6 min) so the chart visibly moves.
                var max = 180
                var t = obj.temperatures.length > max ? obj.temperatures.slice(obj.temperatures.length - max) : obj.temperatures
                var g = obj.targets && obj.targets.length > max
                    ? obj.targets.slice(obj.targets.length - max) : (obj.targets || [])
                series.push({ name: name, temp: t, target: g })
            }
            var state = root.printerData[cfg.name] || {}
            state.name = cfg.name
            state.tempStore = { series: series }
            root._commit(state)
        } catch (e) {}
    }

    function _miss() {
        var cfg = root._activeCfg()
        if (!cfg) return
        var misses = (root._missCount[cfg.name] || 0) + 1
        root._missCount[cfg.name] = misses
        if (misses >= 2) {
            if (misses === 2) root.note("error", "PRINTER UNREACHABLE",
                cfg.name + " — Moonraker not answering at " + root._url(cfg, ""))
            root.demo = true
            root._seedDemo(cfg)
        }
    }

    function _commit(state) {
        var prev = root.active
        var dict = {}
        for (var k in root.printerData) dict[k] = root.printerData[k]
        if (state.name) dict[state.name] = state
        root.printerData = dict
        root.active = root.activePrinter ? Object.assign({}, dict[root.activePrinter]) : null
        root.loading = false
        root.stateChanged()
        root._observe(prev, root.active)
    }

    // ── Demo seed ──────────────────────────────────────────────────────
    function _demoTemps(base, amp) {
        var out = []
        for (var i = 0; i < 30; i++)
            out.push(base + Math.sin(i / 5) * amp * 0.5 + (Math.random() * 2 - 1))
        return out
    }
    // Demo bed mesh: a 350mm Voron with a gentle centre dish and a slight Y
    // tilt, sampled at probe resolution (5x5) and at the resolution Klipper
    // actually compensates with — `(probe - 1) * mesh_pps + probe` = 13x13 at
    // the default mesh_pps 2,2. Profile entries differ only by how pronounced
    // the dish is, so the variance column has something to show.
    function _demoMesh(rows, cols, minP, maxP, scale) {
        var s = scale === undefined ? 1.0 : scale
        var m = []
        for (var j = 0; j < rows; j++) {
            var row = []
            for (var i = 0; i < cols; i++) {
                var x = minP[0] + (i / (cols - 1)) * (maxP[0] - minP[0])
                var y = minP[1] + (j / (rows - 1)) * (maxP[1] - minP[1])
                var cx = (x - 175) / 175
                var cy = (y - 175) / 175
                var v = (0.062 * (cx * cx + cy * cy) - 0.030 * cx + 0.012 * cy - 0.045) * s
                row.push(Math.round(v * 1000) / 1000)
            }
            m.push(row)
        }
        return m
    }

    // Demo toolpath: two square parts, 40 layers of 0.25 mm, a skirt, two
    // perimeters and solid infill per layer, with the same comment grammar a
    // slicer emits (`;LAYER_CHANGE` / `;Z:` / `;TYPE:`) so the offline viewer
    // exercises layer detection, feature colouring, travels and arc-free moves.
    function _demoGcode() {
        if (root._demoGcodeText !== "") return root._demoGcodeText
        var out = []
        var ex = 0
        function seg(x0, y0, x1, y1, f) {
            var len = Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
            ex += len * 0.033
            out.push("G1 X" + x1.toFixed(3) + " Y" + y1.toFixed(3)
                     + " E" + ex.toFixed(5) + " F" + f)
        }
        function travel(x, y) {
            out.push("G0 X" + x.toFixed(3) + " Y" + y.toFixed(3) + " F9000")
        }
        function ring(cx, cy, hw, f) {
            var pts = [[cx - hw, cy - hw], [cx + hw, cy - hw],
                       [cx + hw, cy + hw], [cx - hw, cy + hw], [cx - hw, cy - hw]]
            for (var i = 1; i < pts.length; i++)
                seg(pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1], f)
        }
        var objs = [{ x: 100, y: 100, r: 18 }, { x: 220, y: 210, r: 13 }]
        out.push("; klipshell demo toolpath \u2014 two parts, 40 layers")
        out.push("G90")
        out.push("M83")
        out.push("G28")
        out.push("G1 Z0.25 F600")
        out.push(";TYPE:Skirt")
        travel(100 - 42, 100 - 42)
        ring(100, 100, 42, 1800)
        var layers = 40
        for (var l = 0; l < layers; l++) {
            var z = Math.round((l + 1) * 25) / 100
            out.push(";LAYER_CHANGE")
            out.push(";Z:" + z.toFixed(2))
            out.push("G1 Z" + z.toFixed(2) + " F600")
            for (var o = 0; o < objs.length; o++) {
                var ob = objs[o]
                travel(ob.x - ob.r, ob.y - ob.r)
                out.push(";TYPE:External perimeter")
                ring(ob.x, ob.y, ob.r, 2400)
                out.push(";TYPE:Perimeter")
                ring(ob.x, ob.y, ob.r - 0.6, 3600)
                out.push(l === layers - 1 ? ";TYPE:Top solid infill" : ";TYPE:Solid infill")
                var step = ob.r * 2 / 5
                for (var k = 0; k < 5; k++) {
                    var yk = ob.y - ob.r + step * (k + 0.5)
                    travel(ob.x - ob.r + 1, yk)
                    seg(ob.x - ob.r + 1, yk, ob.x + ob.r - 1, yk, 4800)
                }
            }
        }
        root._demoGcodeText = out.join("\n")
        return root._demoGcodeText
    }

    function _seedDemo(cfg) {
        if (!cfg) return
        if (!root._demoTempSeries)
            root._demoTempSeries = [
                { name: "extruder", temp: root._demoTemps(210, 40), target: [] },
                { name: "heater_bed", temp: root._demoTemps(58, 12), target: [] }
            ]
        var now = Date.now()
        var state = {
            name: cfg.name,
            connected: true,
            demo: true,
            klippyState: "ready",
            extruderTemp: 210.4, extruderTarget: 215,
            bedTemp: 58.1, bedTarget: 60,
            printState: "printing", printMessage: "",
            printProgress: 0.42, printFilename: "voron_25mm_cube.gcode",
            printDuration: 8640, printTotal: 20600,
            toolheadX: 125.0, toolheadY: 88.5, toolheadZ: 0.2,
            fanPower: 0.4, speedFactor: 1.0, flowFactor: 0.95,
            pressureAdvance: 0.045, smoothTime: 0.04,
            maxVelocity: 350, maxSquareCorner: 5.0, maxAccel: 3000, cruiseRatio: 0.5,
            zOffset: -0.03, filamentUsed: 2.15,
            layerCurrent: 32, layerTotal: 76, displayMessage: "",
            excludeObjects: [
                { name: "Demo_Cube", polygon: [[82, 82], [118, 82], [118, 118], [82, 118]] },
                { name: "Demo_Tower", polygon: [[207, 197], [233, 197], [233, 223], [207, 223]] }
            ],
            excludeExcluded: [],
            heaters: [ { name: "heater_bed", temp: 58.1, target: 60 } ],
            fans: [
                { name: "fan", object: "fan", display: "Fan", kind: "fan", speed: 0.4 },
                { name: "part_cooling", object: "heater_fan part_cooling", display: "Part Cooling", kind: "heater_fan", speed: 0.8 }
            ],
            tempStore: { series: root._demoTempSeries },
            mcus: [
                { name: "mcu", chip: "stm32f446xx", version: "v0.13.0-745-gf0892d82",
                  load: 0.021, loadPct: 2, awake: 0.008, freq: 180000000, temp: 28.4, state: "ready" },
                { name: "mcu EBBCan", chip: "stm32g0b1xx", version: "v0.13.0-180-g6773ab07",
                  load: 0.019, loadPct: 2, awake: 0.006, freq: 64000000, temp: null, state: "ready" },
                { name: "mcu cartographer", chip: "stm32f042x6", version: "v0.13.0-745-gf0892d82",
                  load: 0.029, loadPct: 3, awake: 0.01, freq: 48000000, temp: 38.5, state: "ready" }
            ],
            softwareVersion: "v0.13.0-745-gf0892d82-dirty",
            sysload: 0.75
        }
        root.printerData[cfg.name] = state
        root.active = state

        root.data.files = { root: "gcodes", disk: { total: 320e9, used: 198e9, free: 122e9 }, entries: [
            { path: "voron_25mm_cube.gcode", modified: now - 2*3600e3, size: 4810000 },
            { path: "voron_0_2_belt_tensioner.gcode", modified: now - 26*3600e3, size: 3220000 },
            { path: "calibration_flow_cube.gcode", modified: now - 50*3600e3, size: 2100000 },
            { path: "stealthburner_toolhead.gcode", modified: now - 4*86400e3, size: 8120000 },
            { path: "voron_logo_plate.gcode", modified: now - 9*86400e3, size: 15700000 }
        ] }
        root.data.history = { jobs: [
            { filename: "voron_25mm_cube.gcode", status: "in_progress", start_time: now/1000 - 1800,
              end_time: 0, print_duration: 1200, total_duration: 1260, filament_used: 4300,
              metadata: { slicer: "OrcaSlicer", slicer_version: "2.1.1", estimated_time: 7320,
                  thumbnails: [ { width: 32, height: 32, size: 1551, relative_path: ".thumbs/voron_25mm_cube-32x32.png" },
                                { width: 300, height: 300, size: 31819, relative_path: ".thumbs/voron_25mm_cube.png" } ] } },
            { filename: "voron_0_2_belt_tensioner.gcode", status: "completed",
              start_time: now/1000 - 86400 - 4620, end_time: now/1000 - 86400,
              print_duration: 4380, total_duration: 4620, filament_used: 18400,
              metadata: { slicer: "OrcaSlicer", slicer_version: "2.1.1", estimated_time: 4380,
                  thumbnails: [ { width: 32, height: 32, size: 1490, relative_path: ".thumbs/voron_0_2_belt_tensioner-32x32.png" } ] } },
            { filename: "calibration_flow_cube.gcode", status: "completed",
              start_time: now/1000 - 172800 - 900, end_time: now/1000 - 172800,
              print_duration: 840, total_duration: 900, filament_used: 2600,
              metadata: { slicer: "PrusaSlicer", slicer_version: "2.7.4", estimated_time: 900 } },
            { filename: "stealthburner_toolhead.gcode", status: "cancelled",
              start_time: now/1000 - 604800 - 4620, end_time: now/1000 - 604800,
              print_duration: 4380, total_duration: 4620, filament_used: 11200,
              metadata: { slicer: "PrusaSlicer", slicer_version: "2.7.4", estimated_time: 5430 } }
        ] }
        root.data.totals = { total_jobs: 953, total_time: 4007900, total_print_time: 4002760,
                             total_filament_used: 12361600, longest_job: 50100, longest_print: 49920 }
        var dMin = [30, 30]
        var dMax = [320, 320]
        var dParams = { min_x: 30, max_x: 320, min_y: 30, max_y: 320, x_count: 5, y_count: 5,
                        mesh_x_pps: 2, mesh_y_pps: 2, algo: "bicubic", tension: 0.2 }
        root.data.bedmesh = {
            meshMatrix: root._demoMesh(13, 13, dMin, dMax, 1.0),
            probedMatrix: root._demoMesh(5, 5, dMin, dMax, 1.0),
            min: dMin,
            max: dMax,
            profile: "default",
            profiles: {
                "default": { points: root._demoMesh(5, 5, dMin, dMax, 1.0), mesh_params: dParams },
                "adaptive-2026-09-18": { points: root._demoMesh(5, 5, dMin, dMax, 0.72), mesh_params: dParams },
                "PEI-smooth": { points: root._demoMesh(5, 5, dMin, dMax, 1.38), mesh_params: dParams }
            },
            params: dParams,
            axisMin: [0, 0, 0],
            axisMax: [350, 350, 330]
        }
        root.data.macros = ["PRINT_START", "PRINT_END", "PAUSE", "RESUME", "CANCEL",
                            "BED_MESH_CALIBRATE", "QGL", "HEAT_SOAK", "UNLOAD_FILAMENT", "LOAD_FILAMENT"]
        root.data.machine = {
            proc: { system_cpu_usage: { cpu: 12.3 }, cpu_temp: 39.5,
                    system_mem_used: 343400000, system_mem_total: 1034891264,
                    network: {
                        can0: { rx_bytes: 2629112, tx_bytes: 271054, bandwidth: 371.32 },
                        wlan0: { rx_bytes: 77388166, tx_bytes: 777404277, bandwidth: 95367.15 }
                    } },
            update: { busy: false, version_info: {
                klipper: { version: "v0.12.0", remote_version: "v0.12.0", is_valid: true, dirty: false },
                moonraker: { version: "v0.8.1", remote_version: "v0.8.2", is_valid: true, dirty: false },
                system: { version: "debian 12", package_count: 3 }
            } },
            endstops: { stepper_x: false, stepper_y: false, stepper_z: false },
            sysinfo: { system_info: {
                hostname: "voron",
                cpu_info: { cpu_count: 4, bits: "64bit", processor: "aarch64", total_memory: 1010636 },
                distribution: { name: "Debian GNU/Linux 11 (bullseye)" },
                network: { wlan0: { ip_addresses: [
                    { family: "ipv4", address: "192.168.1.50", is_link_local: false }
                ] } }
            } }
        }
        root.data.roots = [
            { name: "config", path: "/home/biqu/printer_data/config", permissions: "rw" },
            { name: "gcodes", path: "/home/biqu/printer_data/gcodes", permissions: "rw" },
            { name: "logs", path: "/home/biqu/printer_data/logs", permissions: "r" }
        ]
        root.data.dir = {
            root: "config", path: "", permissions: "rw",
            dirs: [ { dirname: "ShakeTune_results", size: 4096, modified: now / 1000 - 20 * 86400, permissions: "rw" } ],
            files: [
                { filename: "printer.cfg", size: 25004, modified: now / 1000 - 8 * 86400, permissions: "rw" },
                { filename: "moonraker.conf", size: 1891, modified: now / 1000 - 12 * 86400, permissions: "rw" },
                { filename: "macro.cfg", size: 6795, modified: now / 1000 - 30 * 86400, permissions: "rw" },
                { filename: "clean_nozzle.cfg", size: 10783, modified: now / 1000 - 400 * 86400, permissions: "rw" }
            ],
            disk: { total: 30758981632, used: 7003475968, free: 23738728448 }
        }
        root.data.gcodes = {
            path: "",
            dirs: [ { dirname: "calibration", size: 4096, modified: now / 1000 - 9 * 86400, permissions: "rw" } ],
            files: [
                { filename: "Voron_Cube.gcode", size: 4926481, modified: now / 1000 - 2 * 86400, permissions: "rw",
                  slicer: "OrcaSlicer", slicer_version: "2.1.1", estimated_time: 7320, filament_total: 31240,
                  filament_weight_total: 38.6, layer_height: 0.2, object_height: 42.6, nozzle_diameter: 0.4,
                  filament_type: "ABS", filament_name: "Generic ABS", first_layer_height: 0.25,
                  first_layer_extr_temp: 250, first_layer_bed_temp: 110, print_start_time: now / 1000 - 2 * 86400,
                  uuid: "1e0e4f2a-9c73-4b18-8f52-6ad3c1b90e77" },
                { filename: "stealthburner_toolhead.gcode", size: 1204866, modified: now / 1000 - 14 * 86400, permissions: "rw",
                  slicer: "PrusaSlicer", slicer_version: "2.7.4", estimated_time: 4380, filament_total: 18400,
                  filament_weight_total: 22.7, layer_height: 0.25, object_height: 31.2, nozzle_diameter: 0.6,
                  filament_type: "ASA", filament_name: "Generic ASA", first_layer_height: 0.3,
                  first_layer_extr_temp: 260, first_layer_bed_temp: 100, print_start_time: now / 1000 - 604800,
                  uuid: "7c1f4a92-2b0e-4d63-9a11-58d0c2e4b7a0" }
            ],
            disk: { total: 30758981632, used: 7003475968, free: 23738728448 }
        }
        if (root._demoLines.length === 0)
            root._demoLines = [
                { type: "command", message: "M117 Starting print", time: 0 },
                { type: "command", message: "G28", time: 0 },
                { type: "message", message: "// Klipper state: Ready", time: 0 },
                { type: "message", message: "// 42% — layer 32/76", time: 0 },
                { type: "message", message: "// 2.15m of filament used", time: 0 }
            ]
        root.bucketChanged("files")
        root.bucketChanged("dir")
        root.bucketChanged("gcodes")
        root.bucketChanged("roots")
        root.bucketChanged("history")
        root.bucketChanged("totals")
        root.bucketChanged("macros")
        root.bucketChanged("machine")
        root.bucketChanged("bedmesh")
        root.gcodeStoreFetched(true, root._demoLines)
        root.loading = false
        root.stateChanged()
    }

    function _probeDemo(cfg) {
        var safeUrl = root._url(cfg, "/printer/info").replace(/'/g, "'\\''")
        root._fetch(["bash", "-c",
            "curl -s --max-time 5 '" + safeUrl + "' 2>/dev/null || echo '{}'"], cfg,
            function(pcfg, raw) {
                try {
                    if (JSON.parse(raw.trim()).result) {
                        root.demo = false
                        root.refresh()
                        root.note("info", "PRINTER BACK ONLINE", pcfg.name)
                    }
                } catch (e) {}
            })
    }

    // ── Generic transport ──────────────────────────────────────────────
    function _url(cfg, path) {
        return "http://" + cfg.host + ":" + cfg.port + path
    }

    // Base URL for the active printer, for views that load things straight out
    // of Moonraker over HTTP (gcode thumbnails) rather than through a slot.
    readonly property string baseUrl: {
        var c = root._activeCfg()
        return c ? root._url(c, "") : ""
    }

    // Never kill an in-flight curl: pick a free slot or drop the request.
    function _freeSlot() {
        for (var i = 0; i < 8; i++)
            if (!root._pick(i).running) return root._pick(i)
        return null
    }

    function _fetch(command, cfg, handler) {
        var proc = root._freeSlot()
        if (!proc) return
        proc.command = command
        proc._handler = handler
        proc._printerCfg = cfg
        proc.running = false
        proc.running = true
    }

    // Moonraker only asks for the key when it runs [authorization] and treats
    // this client as untrusted, so the header is sent only when one is stored.
    // NOTE: QML's Image cannot attach headers, so a printer that *requires* a
    // key falls back to the thumbnail placeholder box.
    // ponytail: fetch thumbs through curl into a cache if a keyed printer ever
    // needs previews.
    function _authHeader(c) {
        var k = Settings.apiKey(c && c.name ? String(c.name) : root.activePrinter)
        return k === "" ? "" : "-H 'X-Api-Key: " + root._sq(k) + "' "
    }

    function _get(path, handler, cfg) {
        var c = cfg || root._activeCfg()
        if (!c) return
        if (root.demo) return
        var safeUrl = root._url(c, path).replace(/'/g, "'\\''")
        root._fetch(["bash", "-c",
            "curl -s --max-time 5 " + root._authHeader(c)
            + "'" + safeUrl + "' 2>/dev/null || echo '{}'"], c, handler)
    }

    function _post(path, body, handler, cfg) {
        var c = cfg || root._activeCfg()
        if (!c) return
        if (root.demo) return
        var safeUrl = root._url(c, path).replace(/'/g, "'\\''")
        var payload = body ? root._jsonEscape(body) : "{}"
        root._fetch(["bash", "-c",
            "curl -s --max-time 5 " + root._authHeader(c)
            + "-X POST -H 'Content-Type: application/json' "
            + "-d '" + payload + "' '" + safeUrl + "' 2>/dev/null || echo '{}'"], c,
            handler || function(cfg, raw) {})
    }

    // Settings' Test button. /server/info is the cheapest endpoint that proves
    // host, port and — when one is stored — the API key all work.
    //
    // Runs on its own Process (pTest) rather than the poll's 8-slot pool,
    // because _freeSlot() drops a request outright when every slot is busy and a
    // button that silently does nothing is worse than a slower test. It also
    // deliberately ignores demo mode: a printer that just went offline is
    // exactly when pressing TEST is worth it.
    function testPrinter(name, cb) {
        var c = null
        for (var i = 0; i < root.printers.length; i++)
            if (String(root.printers[i].name) === String(name)) c = root.printers[i]
        if (!c) { cb(false, "not configured"); return }
        var url = root._url(c, "/server/info").replace(/'/g, "'\\''")
        root.pTest._handler = function(cfg, raw) {
            var t = String(raw || "").trim()
            if (t === "" || t === "{}") { cb(false, "unreachable"); return }
            var d = null
            try { d = JSON.parse(t) } catch (e) {}
            if (!d || d.error || !d.result) {
                // Moonraker answers a bad or stale API key with 401 while a
                // keyless client on the same host is let through, so the code
                // is worth surfacing rather than flattening to "unreachable".
                cb(false, (d && d.error && d.error.code) ? "HTTP " + d.error.code : "unreachable")
                return
            }
            cb(true, "ok")
        }
        root.pTest.command = ["bash", "-c",
            "curl -s --max-time 5 " + root._authHeader(c)
            + "'" + url + "' 2>/dev/null || echo '{}'"]
        root.pTest.running = false
        root.pTest.running = true
    }

    function _jsonEscape(s) {
        return JSON.stringify(s).replace(/'/g, "'\\''")
    }

    // Moonraker wraps every HTTP result: `{"result": …}` on success,
    // `{"error": {"message": …}}` on failure (application.py). The transport
    // appends `|| echo '{}'` when curl itself fails, so an empty body means
    // "no answer" rather than "bad answer" and is taken as success.
    function _postOk(raw) {
        var t = String(raw).trim()
        if (t === "" || t === "{}" || t === "ok") return { ok: true, err: "" }
        var d = null
        try { d = JSON.parse(t) } catch (e) {}
        if (!d) return { ok: false, err: t.slice(0, 80) }
        if (d.error) return { ok: false, err: String(d.error.message || "error").slice(0, 80) }
        return { ok: true, err: "" }
    }

    // ── Per-view fetchers → data buckets ───────────────────────────────
    // Bed mesh is one-shot: `mesh_matrix` is only rewritten by a calibration,
    // so it does not ride the 2s object poll. `toolhead.axis_minimum/maximum`
    // come along because the heightmap frames the bed inside the whole motion
    // envelope (Mainsail does the same), and it is one request instead of two.
    function fetchBedMesh() {
        root._bedMeshWanted = true
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._get("/printer/objects/query?bed_mesh&toolhead=axis_minimum,axis_maximum",
                  function(cfg, raw) {
            try {
                var res = JSON.parse(raw.trim()).result
                var st = res && res.status
                if (!st || !st.bed_mesh) return
                var bm = st.bed_mesh
                var th = st.toolhead || {}
                root.data.bedmesh = {
                    meshMatrix: bm.mesh_matrix || [],
                    probedMatrix: bm.probed_matrix || [],
                    min: bm.mesh_min || [0, 0],
                    max: bm.mesh_max || [0, 0],
                    profile: bm.profile_name || "",
                    profiles: bm.profiles || {},
                    params: bm.mesh_params || {},
                    axisMin: th.axis_minimum || [0, 0, 0],
                    axisMax: th.axis_maximum || [0, 0, 0]
                }
                root.bucketChanged("bedmesh")
            } catch (e) {}
        })
    }

    function fetchFiles(rootName) {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        var name = rootName || "gcodes"
        // Re-polled every tick; only blank the listing when the root itself
        // changes, so a dropped or failed request never wipes the card.
        if (!root.data.files || root.data.files.root !== name) {
            root.data.files = { root: name, entries: [] }
            root.bucketChanged("files")
        }
        // `extended=true` carries the per-file slicer metadata (thumbnails,
        // estimated_time) inline; `list` returns path/size/modified only, which
        // is why the standby card had no previews. Entries come back keyed
        // `filename` here, so each one gets the `path` its callers already read.
        // ponytail: the whole directory's metadata on every poll — move to
        // /server/files/metadata per visible file with a modified-time cache if
        // the gcodes root ever grows past a couple hundred files.
        root._get("/server/files/directory?root=" + name + "&extended=true", function(cfg, raw) {
            try {
                var r = JSON.parse(raw.trim()).result
                var res = (r && Array.isArray(r.files)) ? r.files : []
                for (var i = 0; i < res.length; i++) res[i].path = res[i].filename ?? ""
                root.data.files = { root: name, entries: res,
                                    disk: (r && r.disk_usage) || null }
                root.bucketChanged("files")
            } catch (e) {}
        })
    }

    // ── File manager (Mainsail config-files parity) ────────────────────
    // All remote paths are "<root>[/<dir>[/<file>]]" (e.g. "config/printer.cfg").
    property var _lastDir: ({ root: "config", path: "" })
    property var _roots: []
    // G-CODE FILES tab (null until that view opens, which is what gates the
    // tick retry below).
    property var _lastGcodePath: null
    // The heightmap tab asks for the mesh once; the 1s tick retries until it
    // lands, because a dropped fetch would otherwise leave the tab empty until
    // the view is reopened.
    property bool _bedMeshWanted: false

    function _encPath(path) {
        return String(path).split("/").map(encodeURIComponent).join("/")
    }
    // Largest thumbnail that is not absurd, else the first one recorded. A
    // history job nests the metadata under `metadata`, a directory listing
    // spreads it flat, so both shapes are read. Shared by the History table and
    // the dashboard standby card — the previews must agree.
    function thumbSource(j) {
        var t = (j?.metadata?.thumbnails ?? j?.thumbnails) ?? []
        var best = null
        for (var i = 0; i < t.length; i++) {
            var w = Number(t[i].width || 0)
            if (w > 0 && w <= 96 && (best === null || w > Number(best.width || 0))) best = t[i]
        }
        if (best === null && t.length > 0) best = t[0]
        if (best === null || root.baseUrl === "" || root.demo) return ""
        var fn = String(j.filename ?? j.path ?? "")
        var cut = fn.lastIndexOf("/")
        var dir = cut < 0 ? "" : fn.slice(0, cut + 1)
        return root.baseUrl + "/server/files/gcodes/" + root._encPath(dir + String(best.relative_path ?? ""))
    }
    // quote a value being embedded in a bash -c string ('' break-out guard)
    function _sq(v) {
        return String(v).replace(/'/g, "'\\''")
    }
    function _fileResult(raw, okMsg, failMsg) {
        var d = null
        try { d = JSON.parse(String(raw).trim()) } catch (e) {}
        if (d && d.error) {
            root.actionDone(false, failMsg + ": " + String(d.error.message || ""))
            return
        }
        root.actionDone(true, okMsg)
        root.fetchDir(root._lastDir.root, root._lastDir.path)
    }

    // G-CODE FILES table: `extended=true` makes /server/files/directory include
    // every metadata field inline per file (slicer, estimated_time,
    // filament_total, print_start_time, layer_height, object_height, ...) — one
    // request for the whole table, where /server/files/metadata would be one
    // request per row and 8 slots do not survive a directory of 90 prints.
    function fetchGcodeFiles(path) {
        var cfg = root._activeCfg()
        if (!cfg) return
        var p = String(path || "")
        root._lastGcodePath = p
        if (root.demo) { root._seedDemo(cfg); return }
        var q = "/server/files/directory?extended=true&path=" + root._encPath(p ? "gcodes/" + p : "gcodes")
        root._get(q, function(cfg2, raw) {
            try {
                var res = JSON.parse(raw.trim()).result
                if (!res) return
                root.data.gcodes = {
                    path: p,
                    dirs: res.dirs || [],
                    files: res.files || [],
                    disk: res.disk_usage || null
                }
                root.bucketChanged("gcodes")
            } catch (e) {}
        }, cfg)
    }

    function fetchRoots() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._get("/server/files/roots", function(cfg, raw) {
            try {
                var res = JSON.parse(raw.trim()).result
                if (!res) return
                root._roots = res
                root.data.roots = res
                root.bucketChanged("roots")
            } catch (e) {}
        })
    }

    function fetchDir(rootName, path) {
        var cfg = root._activeCfg()
        if (!cfg) return
        var r = String(rootName || "config")
        var p = String(path || "")
        root._lastDir = { root: r, path: p }
        if (root.demo) { root._seedDemo(cfg); return }
        root._get("/server/files/directory?path=" + root._encPath(p ? r + "/" + p : r), function(cfg2, raw) {
            try {
                var res = JSON.parse(raw.trim()).result
                if (!res) return
                root.data.dir = {
                    root: r, path: p,
                    dirs: res.dirs || [], files: res.files || [],
                    disk: res.disk_usage || null,
                    permissions: String(res.root_info?.permissions || "")
                }
                root.bucketChanged("dir")
            } catch (e) {}
        })
    }

    function makeDir(path) {
        if (root.demo) { root.actionDone(true, "created " + path); return }
        root._post("/server/files/directory", { path: String(path) }, function(cfg, raw) {
            root._fileResult(raw, "created " + path, "create failed")
        })
    }
    function moveEntry(src, dest) {
        if (root.demo) { root.actionDone(true, "moved to " + dest); return }
        root._post("/server/files/move", { source: String(src), dest: String(dest) }, function(cfg, raw) {
            root._fileResult(raw, "moved to " + dest, "move failed")
        })
    }
    function copyEntry(src, dest) {
        if (root.demo) { root.actionDone(true, "copied to " + dest); return }
        root._post("/server/files/copy", { source: String(src), dest: String(dest) }, function(cfg, raw) {
            root._fileResult(raw, "copied to " + dest, "copy failed")
        })
    }
    // Files: DELETE /server/files/<root>/<path>. Directories need the directory
    // route with force=true (plain DELETE refuses a non-empty dir).
    function removeEntry(path, isDir) {
        var cfg = root._activeCfg()
        if (!cfg || root.demo) { root.actionDone(true, "deleted " + path); return }
        var target = isDir
            ? "/server/files/directory?path=" + root._encPath(path) + "&force=true"
            : "/server/files/" + root._encPath(path)
        root._fetch(["bash", "-c", "curl -s --max-time 30 -X DELETE '"
            + root._sq(root._url(cfg, target)) + "' 2>/dev/null || echo '{}'"], cfg,
            function(cfg2, raw) { root._fileResult(raw, "deleted " + path, "delete failed") })
    }

    // Local file → printer: path is relative to the root, "." = root itself.
    function uploadLocal(localPath, rootName, dir) {
        var cfg = root._activeCfg()
        if (!cfg || root.demo) { root.actionDone(true, "uploaded"); return }
        var url = root._url(cfg, "/server/files/upload")
        root._fetch(["bash", "-c",
            "curl -s --max-time 120 -F 'file=@'" + root._sq(localPath)
            + " -F 'root=" + root._sq(rootName) + "' -F 'path=" + root._sq(dir || ".")
            + "' '" + root._sq(url) + "' 2>/dev/null || echo '{}'"], cfg,
            function(cfg2, raw) {
                root._fileResult(raw, "uploaded " + String(localPath).split("/").pop(), "upload failed")
            })
    }

    function pickAndUpload(rootName, dir) {
        var cfg = root._activeCfg()
        if (!cfg || root.demo) { root.actionDone(true, "uploaded"); return }
        root._fetch(["bash", "-c", "zenity --file-selection --title='"
            + root._sq("Upload to " + rootName + "/" + (dir || "")) + "' 2>/dev/null"], cfg,
            function(cfg2, out) {
                var local = String(out).trim()
                if (local === "") return
                root.uploadLocal(local, rootName, dir)
            })
    }

    // Edit the printer's own copy: download, open in $EDITOR (nvim) inside
    // kitty, and upload back only when the file actually changed.
    function editRemoteFile(path) {
        var cfg = root._activeCfg()
        if (!cfg || root.demo) return
        var parts = String(path).split("/")
        if (parts.length < 2) return
        var rootName = parts[0]
        var base = parts[parts.length - 1]
        var relDir = parts.length > 2 ? parts.slice(1, parts.length - 1).join("/") : "."
        var dir = Quickshell.env("HOME") + "/.cache/klipshell/"
            + String(cfg.name).replace(/[^A-Za-z0-9_-]+/g, "_") + "/edit"
        var local = dir + "/" + base.replace(/[^A-Za-z0-9._-]+/g, "_")
        var dl = root._url(cfg, "/server/files/" + root._encPath(path))
        var up = root._url(cfg, "/server/files/upload")
        var q = root._sq(local)
        var cmd = "mkdir -p '" + root._sq(dir) + "' && curl -sf '" + root._sq(dl) + "' -o '" + q + "' || exit 1; "
            + "b=$(sha256sum '" + q + "' | cut -d' ' -f1); "
            + "kitty -e ${EDITOR:-nvim} '" + q + "'; "
            + "a=$(sha256sum '" + q + "' | cut -d' ' -f1); "
            + "[ \"$a\" = \"$b\" ] && exit 0; "
            + "curl -s --max-time 60 -F 'file=@'" + q + " -F 'root=" + root._sq(rootName)
            + "' -F 'path=" + root._sq(relDir) + "' '" + root._sq(up) + "'"
        root.actionDone(true, "opening " + base + " in ${EDITOR:-nvim}")
        root._fetch(["bash", "-c", cmd], cfg, function(cfg2, raw) {
            var t = String(raw).trim()
            if (t === "") { root.actionDone(true, base + " closed, no changes"); return }
            root._fileResult(t, "saved " + base, "saving " + base + " failed")
        })
    }

    // Download a log file (klippy.log etc.) to ~/.cache/klipshell/<p>/logs.
    // Filename is white-listed to [A-Za-z0-9._-] for the local output path;
    // the URL still uses the original name via encodeURIComponent.
    function downloadLog(name) {
        var cfg = root._activeCfg()
        if (!cfg || root.demo) return
        var dir = Quickshell.env("HOME") + "/.cache/klipshell/"
            + String(cfg.name).replace(/[^A-Za-z0-9_-]+/g, "_") + "/logs"
        var safe = String(name).replace(/[^A-Za-z0-9._-]+/g, "_")
        var out = dir + "/" + safe
        var url = root._url(cfg, "/server/files/logs/" + encodeURIComponent(String(name)))
        root.actionDone(true, "saving " + safe + "…")
        root._fetch(["bash", "-c", "mkdir -p '" + dir + "' && curl -sf '"
            + root._sq(url) + "' -o '" + out + "' && echo ok"], cfg, function(cfg2, text) {
                if (String(text).indexOf("ok") >= 0)
                    root.actionDone(true, safe + " → ~/.cache/klipshell/logs")
                else
                    root.actionDone(false, "download failed: " + safe)
            })
    }

    function fetchHistory() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._get("/server/history/list?limit=40&order=desc", function(cfg, raw) {
            try {
                var r = JSON.parse(raw.trim()).result || {}
                var jobs = r.jobs || []
                root.data.history = { jobs: jobs }
                root.bucketChanged("history")
            } catch (e) {}
        })
    }

    function fileStateOf(name) {
        var jobs = root.data?.history?.jobs ?? []
        // The list arrives newest-first (order=desc), so the first match is the
        // job that owns the file right now — an older `completed` run must not
        // mask a print that is currently in progress.
        for (var i = 0; i < jobs.length; i++)
            if (jobs[i].filename === name) return String(jobs[i].status || "")
        return ""
    }

    function fetchTotals() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._get("/server/history/totals", function(cfg, raw) {
            try {
                // The endpoint wraps its numbers in `job_totals`; storing the raw
                // envelope left every consumer reading undefined and rendering "—".
                var r = JSON.parse(raw.trim()).result || {}
                root.data.totals = r.job_totals || r
                root.bucketChanged("totals")
            } catch (e) {}
        })
    }

    function fetchMachine() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root.fetchProcStats()
        root.fetchUpdateInfo()
        root.fetchEndstops()
    }

    function fetchProcStats() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._get("/machine/proc_stats?refresh=true", function(cfg, raw) {
            try {
                var r = JSON.parse(raw.trim()).result
                if (!r) return
                if (r.system_memory && r.system_mem_total === undefined) {
                    r.system_mem_total = Number(r.system_memory.total || 0) * 1024
                    r.system_mem_available = Number(r.system_memory.available || 0) * 1024
                    r.system_mem_used = Number(r.system_memory.used || 0) * 1024
                }
                root._patchMachine({ proc: r })
            } catch (e) {}
        })
    }

    // 27 kB of version_info, and a cold call can wait on Moonraker's own update
    // check (past the transport's 5 s cap: the response is dropped rather than
    // arriving late) — so an empty parse leaves the last good report alone
    // instead of blanking the card, and the tick retries while nothing landed.
    function fetchUpdateInfo() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._get("/machine/update/status", function(cfg, raw) {
            try {
                var r = JSON.parse(raw.trim()).result
                if (r && r.version_info) root._patchMachine({ update: r })
            } catch (e) {}
        })
    }

    // `data.machine` is assembled one fetch at a time. Hand back a NEW object
    // each time: re-assigning the same reference is not a property change, so
    // bindings that build themselves from it (the update rows, the endstop
    // list) would be evaluated once — before the data arrives — and stay empty.
    function _patchMachine(patch) {
        root.data.machine = Object.assign({}, root.data.machine || {}, patch)
        root.bucketChanged("machine")
    }

    // Klipper's `query_endstops.last_query` (and `?endstops`, which is not an
    // object at all and answers {}) only moves when something runs a query.
    // Poll the klippy webhook instead: /printer/query_endstops/status queries
    // every registered endstop and answers {<stepper>: "open" | "TRIGGERED"} —
    // names included, and like M119 it never moves an axis.
    function fetchEndstops() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._get("/printer/query_endstops/status", function(cfg, raw) {
            try {
                var r = JSON.parse(raw.trim()).result || {}
                var e = {}
                for (var k in r) e[k] = String(r[k]).toUpperCase() === "TRIGGERED"
                root._patchMachine({ endstops: e })
            } catch (err) {}
        })
    }

    function fetchSysInfo() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._get("/machine/system_info", function(cfg, raw) {
            try {
                var r = JSON.parse(raw.trim()).result || {}
                root._patchMachine({ sysinfo: r })
            } catch (e) {}
        })
    }

    // Macro names come from the object list: Klipper has no bare `gcode_macro`
    // object (querying it returns `{}` silently) — each macro is its own
    // `gcode_macro <NAME>`. Published off the shared object sync rather than a
    // one-shot request of its own: a lone fetch at dashboard open gets dropped
    // by _freeSlot() behind the connect burst, so macros never appeared.
    function fetchMacros() {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        root._syncObjects()
        root._publishMacros()
    }

    function _publishMacros() {
        var objs = root._allObjects || []
        var names = []
        for (var i = 0; i < objs.length; i++) {
            var o = String(objs[i])
            if (o.indexOf("gcode_macro ") === 0) names.push(o.slice(12))
        }
        root.data.macros = names.sort()
        root.bucketChanged("macros")
    }

    function _fileUrl(name) {
        return String(name || "").split("/").map(encodeURIComponent).join("/")
    }

    function fetchFileMetadata(name) {
        if (root.demo) { root._seedDemo(root._activeCfg()); return }
        var n = String(name || "")
        root.data.fileMeta = { name: n, loading: true }
        root.bucketChanged("fileMeta")
        root._get("/server/files/metadata?filename=" + root._fileUrl(n), function(cfg, raw) {
            try {
                var r = JSON.parse(raw.trim()).result || {}
                r.name = n
                r.loading = false
                root.data.fileMeta = r
                root.bucketChanged("fileMeta")
            } catch (e) {
                root.data.fileMeta = { name: n, loading: false }
                root.bucketChanged("fileMeta")
            }
        })
    }

    function restartKlippy() { root._post("/printer/restart", null, root._action("restarting klippy")) }
    function restartFirmware() { root._post("/printer/firmware_restart", null, root._action("firmware restart")) }

    function updateClient(name) {
        var n = String(name)
        if (root.demo) { root.actionDone(true, "updating " + n); return }
        root._post("/machine/update/client/" + encodeURIComponent(n), null, root._action("updating " + n))
    }

    function updateSystem() {
        if (root.demo) { root.actionDone(true, "updating system packages"); return }
        root._post("/machine/update/system", null, root._action("updating system packages"))
    }

    // ── Actions ────────────────────────────────────────────────────────
    signal actionDone(bool ok, string status)

    function pausePrint()   { root._post("/printer/print/pause", null, root._action("paused")) }
    function resumePrint()  { root._post("/printer/print/resume", null, root._action("resumed")) }
    function cancelPrint()  { root._post("/printer/print/cancel", null, root._action("cancelled")) }
    function emergencyStop(){ root._post("/printer/emergency_stop", null, root._action("estop")) }

    // ── Mainsail-style setters (all routed through gcode_script) ────────
    function _prettyName(n) {
        var parts = String(n).split("_")
        var out = ""
        for (var i = 0; i < parts.length; i++)
            out += parts[i].length > 0 ? parts[i].charAt(0).toUpperCase() + parts[i].slice(1) : ""
        return out
    }

    // all fans (plain `fan` + any `heater_fan <name>`), each with live speed.
    // `name` is the Klipper config name (what SET_*_FAN_SPEED takes); `object`
    // is the full object key (`heater_fan controller_fan`) — Klipper matches
    // object queries by that full name, so querying the bare config name
    // returns {} and every heater_fan read as 0%.
    // The object list comes from the shared cache (_syncObjects) — one fetch
    // per poll for both fans and mcus instead of one each.
    function fetchFans() {
        var cfg = root._activeCfg()
        if (!cfg) return
        if (root.demo) { root._seedDemo(cfg); return }
        var objs = root._allObjects || []
        if (objs.length === 0) return
        var fans = []
        for (var i = 0; i < objs.length; i++) {
            var o = String(objs[i])
            if (o === "fan") fans.push({ name: "fan", object: "fan", display: "Fan", kind: "fan" })
            else if (o.indexOf("heater_fan ") === 0) {
                var n = o.slice(11)
                fans.push({ name: n, object: o, display: root._prettyName(n), kind: "heater_fan" })
            }
        }
        if (fans.length === 0) {
            var st0 = root.printerData[cfg.name] || {}
            st0.fans = []
            root._commit(st0)
            return
        }
        var q = ""
        for (var j = 0; j < fans.length; j++)
            q += (j === 0 ? "?" : "&") + encodeURIComponent(String(fans[j].object))
        root._get("/printer/objects/query" + q, function(cfg2, raw2) {
            try {
                var status = JSON.parse(raw2.trim()).result?.status || {}
                for (var k = 0; k < fans.length; k++) {
                    var f = status[fans[k].object] || {}
                    fans[k].speed = Number(f.speed) > 0 ? Number(f.speed) : 0
                }
                var state = root.printerData[cfg2.name] || {}
                state.fans = fans
                root._commit(state)
            } catch (e) {}
        }, cfg)
    }

    property int _mcuListTick: 0
    property var _allObjects: []
    property var _mcuTempSensors: null
    property int _objTick: 0

    // Object list shared by fans + mcus: on connect and every 25 ticks instead
    // of once per poll per consumer (spare slots = fewer dropped requests).
    function _syncObjects() {
        if (root.demo) return
        root._objTick++
        if (root._allObjects.length > 0 && root._objTick % 25 !== 0) return
        root._get("/printer/objects/list", function(cfg, raw) {
            try {
                root._allObjects = JSON.parse(raw.trim()).result?.objects || []
                root._publishMacros()
            } catch (e) {}
        })
    }

    function fetchMcus() {
        var cfg = root._activeCfg()
        if (!cfg || root.demo) return
        root._mcuListTick++
        var objs = root._allObjects || []
        var names = []
        for (var i = 0; i < objs.length; i++) {
            var o = String(objs[i])
            if (o === "mcu" || o.indexOf("mcu ") === 0) names.push(o)
        }
        if (names.length === 0) return
        // MCU temperature (Mainsail getMcuTempSensors/getMcuTempSensor): the
        // config's `temperature_mcu` sensors, matched by the mcu name ENDING
        // WITH their `sensor_mcu` value — a board without one reports no temp.
        // Config keys are lower-cased, so they resolve against the live list.
        if (root._mcuTempSensors === null || root._mcuListTick % 100 === 0) {
            root._get("/printer/objects/query?configfile=settings", function(cfg2, raw) {
                try {
                    var s = JSON.parse(raw.trim()).result?.status?.configfile?.settings || {}
                    var out = []
                    for (var k in s) {
                        var t = String(s[k]?.sensor_type || "")
                        if (t === "temperature_mcu" && typeof s[k]?.sensor_mcu === "string")
                            out.push({ key: k, mcu: s[k].sensor_mcu })
                    }
                    root._mcuTempSensors = out
                } catch (e) {}
            }, cfg)
        }
        var sensors = []
        var known = root._mcuTempSensors || []
        for (var s = 0; s < known.length; s++) {
            var live = root._liveObject(known[s].key)
            if (live) sensors.push({ name: live, mcu: known[s].mcu })
        }
        var all = names.concat(sensors.map(function(x) { return x.name }))
        var q = ""
        for (var i = 0; i < all.length; i++)
            q += (i === 0 ? "?" : "&") + encodeURIComponent(String(all[i]))
        root._get("/printer/objects/query" + q, function(cfg2, raw) {
            try {
                var status = JSON.parse(raw.trim()).result?.status || {}
                var mcus = []
                for (var j = 0; j < names.length; j++) {
                    var st = status[names[j]] || {}
                    var ls = st.last_stats || {}
                    var tAvg = Number(ls.mcu_task_avg || 0)
                    var tStd = Number(ls.mcu_task_stddev || 0)
                    var load = tAvg + (3 * tStd) / 0.0025
                    var temp = null
                    for (var k = 0; k < sensors.length; k++) {
                        if (!String(names[j]).endsWith(sensors[k].mcu)) continue
                        var reading = Number(status[sensors[k].name]?.temperature)
                        if (!Number.isNaN(reading)) temp = reading
                    }
                    mcus.push({
                        name: names[j],
                        chip: String(st.mcu_constants?.MCU || ""),
                        version: String(st.mcu_version || ""),
                        temp: temp,
                        load: Math.min(1, Math.max(0, load)),
                        loadPct: Math.min(100, Math.round(load * 100)),
                        awake: Number(ls.mcu_awake || 0) / 5,
                        freq: Number(ls.freq || 0),
                        state: String(st.state || "?"),
                        received: Number(ls.bytes_read || 0),
                        applied: Number(ls.bytes_write || 0),
                        retransmit: Number(ls.bytes_retransmit || 0)
                    })
                }
                var state = root.printerData[cfg2.name] || {}
                state.mcus = mcus
                root._commit(state)
            } catch (e) {}
        }, cfg)
    }

    function _liveObject(key) {
        var k = String(key).toLowerCase()
        for (var i = 0; i < root._allObjects.length; i++)
            if (String(root._allObjects[i]).toLowerCase() === k) return String(root._allObjects[i])
        return ""
    }

    function setHeaterTemp(name, target) {
        root.sendGcode("SET_HEATER_TEMPERATURE HEATER=" + name + " TARGET=" + target)
    }
    function setFanSpeed(name, pct) {
        var v = Math.max(0, Math.min(1, Number(pct) || 0)).toFixed(2)
        var kind = "fan"
        var fans = root.active?.fans ?? []
        for (var i = 0; i < fans.length; i++)
            if (fans[i].name === name) { kind = fans[i].kind; break }
        if (kind === "heater_fan")
            root.sendGcode("SET_HEATER_FAN_SPEED FAN=" + name + " SPEED=" + v)
        else
            root.sendGcode("SET_FAN_SPEED FAN=" + name + " SPEED=" + v)
    }
    function setFanPercent(pct) {
        root.sendGcode(pct > 0 ? "M106 S" + Math.round(pct * 2.55) : "M107")
    }
    function setSpeedFactor(pct) { root.sendGcode("M220 S" + pct) }
    function setFlowFactor(pct)  { root.sendGcode("M221 S" + pct) }
    function setPressureAdvance(v) { root.sendGcode("SET_PRESSURE_ADVANCE ADVANCE=" + v) }
    function setSmoothTime(v) { root.sendGcode("SET_PRESSURE_ADVANCE SMOOTH_TIME=" + v) }

    function jog(axis, dist, speed) {
        root.sendGcode("G91\nG1 " + axis + dist + " F" + Math.round((Number(speed) || 40) * 60) + "\nG90")
    }
    function moveHomeAll()  { root.sendGcode("G28") }
    function moveHomeXY()   { root.sendGcode("G28 X Y") }
    function moveHomeZ()    { root.sendGcode("G28 Z") }
    function motorsOff()    { root.sendGcode("M84") }
    function quadGantryLevel() { root.sendGcode("QUAD_GANTRY_LEVEL") }

    function zAdjust(delta) { root.sendGcode("SET_GCODE_OFFSET Z_ADJUST=" + delta + " RELATIVE=1") }
    function zOffsetApply(mode) {
        if (mode === "endstop") root.sendGcode("Z_OFFSET_APPLY_ENDSTOP")
        else if (mode === "probe") root.sendGcode("Z_OFFSET_APPLY_PROBE")
        else root.sendGcode("SET_GCODE_OFFSET Z=0")
    }

    function extrude(amount, speed) {
        root.sendGcode("M83\nG1 E" + amount + " F" + Math.round((Number(speed) || 25) * 60) + "\nM82")
    }

    function startPrint(filename) {
        root._post("/printer/print/start", { filename: filename }, root._action("started " + filename))
    }

    function _action(status) {
        return function(cfg, raw) {
            var r = root._postOk(raw)
            root.actionDone(r.ok, r.ok ? status : r.err)
            if (r.ok) {
                root.refresh()
            }
        }
    }

    // GCode send (console + macros).
    signal gcodeSent(bool ok, string err)
    signal gcodeStoreFetched(bool ok, var list)

    function sendGcode(script) {
        if (root.demo) {
            root._demoLines = root._demoLines.concat([{ type: "command", message: String(script), time: 0 }]).slice(-80)
            root.gcodeSent(true, "")
            root.gcodeStoreFetched(true, root._demoLines)
            return
        }
        var body = { script: script }
        root._post("/printer/gcode/script", body, function(cfg, raw) {
            var r = root._postOk(raw)
            if (r.ok) root.fetchGcodeStore(80)
            root.gcodeSent(r.ok, r.err)
            root.refresh()
        })
    }

    // ── G-code body (viewer) ───────────────────────────────────────────
    // G-code bodies are megabytes, so they do not ride the 5 s poll slots: one
    // dedicated Process, a 120 s budget, and the whole body is held in the
    // `gcode` bucket for the viewer to parse.
    property bool gcodeLoading: false
    property string gcodeError: ""
    property string _gcodePath: ""

    function fetchGcodeFile(path) {
        var name = String(path || "")
        if (root.demo) {
            root.gcodeError = ""
            root.gcodeLoading = false
            root.data.gcode = { path: name, text: root._demoGcode(), demo: true }
            root.bucketChanged("gcode")
            return
        }
        var c = root._activeCfg()
        if (!c) return
        if (name === "") return
        var full = name.indexOf("/") >= 0 ? name : "gcodes/" + name
        var url = root._url(c, "/server/files/" + root._encPath(full))
        root._gcodePath = full
        root.gcodeError = ""
        root.gcodeLoading = true
        root.gcodeProc.command = ["bash", "-c",
            "curl -sS --max-time 120 '" + root._sq(url) + "' 2>/dev/null"]
        root.gcodeProc.running = false
        root.gcodeProc.running = true
    }

    function cancelGcodeFetch() {
        root.gcodeProc.running = false
        root.gcodeLoading = false
    }

    function _gcodeLoaded(text) {
        if (!root.gcodeLoading) return
        root.gcodeLoading = false
        var t = String(text || "")
        if (t.length === 0) { root.gcodeError = "no data for " + root._gcodePath; return }
        root.data.gcode = { path: root._gcodePath, text: t, demo: false }
        root.bucketChanged("gcode")
    }

    property var gcodeProc: Process {
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._gcodeLoaded(text) }
    }

    function excludeObject(name) {
        root.sendGcode("EXCLUDE_OBJECT NAME=" + String(name))
    }

    function fetchGcodeStore(count) {
        if (root.demo) { root.gcodeStoreFetched(true, root._demoLines); return }
        root._get("/server/gcode_store?count=" + (count || 80), function(cfg, raw) {
            try {
                var list = JSON.parse(raw.trim()).result?.gcode_store ?? []
                root._scanStore(list)
                root.gcodeStoreFetched(true, list)
            } catch (e) {
                root.gcodeStoreFetched(false, [])
            }
        })
    }

    // ── Process pool ────────────────────────────────────────────────────
    function _pick(slot) {
        return [p0, p1, p2, p3, p4, p5, p6, p7][slot % 8]
    }

    function _dispatch(handler, printerCfg, raw) {
        if (handler) handler(printerCfg, raw)
    }

    property var p0: Process {
        property var _printerCfg: null
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.p0._handler, root.p0._printerCfg, text) }
    }
    property var p1: Process {
        property var _printerCfg: null
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.p1._handler, root.p1._printerCfg, text) }
    }
    property var p2: Process {
        property var _printerCfg: null
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.p2._handler, root.p2._printerCfg, text) }
    }
    property var p3: Process {
        property var _printerCfg: null
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.p3._handler, root.p3._printerCfg, text) }
    }
    property var p4: Process {
        property var _printerCfg: null
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.p4._handler, root.p4._printerCfg, text) }
    }
    property var p5: Process {
        property var _printerCfg: null
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.p5._handler, root.p5._printerCfg, text) }
    }
    property var p6: Process {
        property var _printerCfg: null
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.p6._handler, root.p6._printerCfg, text) }
    }
    property var p7: Process {
        property var _printerCfg: null
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.p7._handler, root.p7._printerCfg, text) }
    }
    // One-shot Process for the settings TEST button — see testPrinter().
    property var pTest: Process {
        property var _handler: null
        command: []; running: false
        stdout: StdioCollector { onStreamFinished: root._dispatch(root.pTest._handler, null, text) }
    }
}