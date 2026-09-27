pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// Machine health, gcode files, and update manager — Mainsail machine-tab
// parity in klipshell grammar: files on the left-ish list, system + updates
// beside them. Rings mirror Mainsail's SystemLoad panel (reading inside,
// label under the ring, a dim detail line under that).
Item {
    id: root

    required property QtObject moonraker
    readonly property var ps: moonraker.active
    property var machine: ({})
    property var sysinfo: ({})

    // ── CONFIG FILES card: file manager state ───────────────────────────
    property var roots: []
    property var dirInfo: ({})
    property var dirRows: []
    property var selected: ({})
    property string sortKey: "name"
    property bool sortAsc: true
    property bool showBackups: false
    property string promptKind: ""
    property string promptText: ""
    property string opMsg: ""
    property color opColor: Colors.success
    onShowBackupsChanged: root._rebuildRows()
    // Every root chip is selectable — logs/, docs/, config_examples/ are perfectly
    // readable. Only the write actions care about the root's `w` bit.
    readonly property bool writable: (function() {
        var name = String(root.dirInfo?.root ?? "")
        for (var i = 0; i < root.rootChips.length; i++)
            if (String(root.rootChips[i].name) === name)
                return String(root.rootChips[i].permissions ?? "rw").indexOf("w") >= 0
        return true
    })()
    readonly property var rootChips: root.roots.length > 0 ? root.roots
        : [{ name: "config", permissions: "rw" }, { name: "gcodes", permissions: "rw" }, { name: "logs", permissions: "r" }]
    readonly property string dirBase: String(root.dirInfo?.root ?? "config")
        + ((root.dirInfo?.path ?? "") !== "" ? "/" + String(root.dirInfo.path) : "")
    readonly property int selCount: root.selEntries().length
    // Columns measured against JetBrainsMono Nerd Font @14px (8.406px/char):
    // "1023.9 MB" = 75.7px so SIZE needs 78; "Sep 15, 2025" = 101px so MODIFIED
    // needs 106. Undersized boxes overlap the next column.
    readonly property int fmSizeW: 78
    readonly property int fmDateW: 106
    // Air between the SIZE and MODIFIED columns. The two boxes are packed edge
    // to edge, so without it the size figures sit hard against the dates.
    readonly property int fmColGap: Metrics.lg
    readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property int endstopRows: root.endstopNames().length
    // ENDSTOPS: 62px of panel chrome (34 header + 6 + 22 padding), the REFRESH
    // row, then 34px per endstop with Metrics.xs between them. Never bind a
    // panel height to a Column that sizes itself from its children: that cycle
    // resolved to 0 / -162 and both cards disappeared.
    readonly property int endstopPanelH: 62 + 26 + Metrics.sm
        + Math.max(1, root.endstopRows) * 34 + Math.max(0, root.endstopRows - 1) * Metrics.xs
    readonly property int railCardH: 150
    // Right rail: ENDSTOPS beside LOG FILES on one row (the taller of the two
    // sets the row height, so the two cards always end level), UPDATE MANAGER
    // under both. CONFIG FILES fills the left at the rail's height.
    readonly property int railTopH: Math.max(root.endstopPanelH, root.railCardH)
    readonly property int railH: root.railTopH + Metrics.lg + root.updateRowH
    // CONFIG FILES: 171px of chrome (head + footer + padding, measured) + rows,
    // capped at 14 so a 93-entry config dir stays a card instead of a scroll of
    // 2600px.
    readonly property int fmVisibleRows: Math.max(3, Math.min(14, root.dirRows.length))
    readonly property int fmPanelH: 171 + root.fmVisibleRows * 28
    // UPDATE MANAGER: two-line rows (name + version), one per component the
    // printer's updater reports, plus System. UPDATE ALL / CHECK live in the
    // header row: body = header + rows + the Column's own spacing + padding.
    // Charge that spacing per row — 10 rows carry 54px of it, and leaving it out
    // is what sliced the last row off the card (618 tall vs 672 measured).
    readonly property int updateRows: root._updateKeys().length + (root._sysPkgs() > 0 ? 1 : 0)
    readonly property int updateRowH: Math.max(180,
        62 + 30 + root.updateRows * (52 + Metrics.sm))
    // CONFIG FILES and the rail share one row: the row is as tall as the taller
    // side, so the two columns end level.
    readonly property int manageRowH: Math.max(root.fmPanelH, root.railH)
    // Moonraker refuses component updates while printing; don't offer them.
    readonly property bool printing: root.ps?.printState === "printing" || root.ps?.printState === "paused"
    readonly property bool canUpdate: !root.printing && !root.machine?.update?.busy
    readonly property var cfg: (function() {
        for (var i = 0; i < moonraker.printers.length; i++)
            if (moonraker.printers[i].name === moonraker.activePrinter)
                return moonraker.printers[i]
        return null
    })()
    readonly property bool klippyReady: (root.ps?.klippyState ?? "ready") === "ready"

    property real _demoCpu: 45
    property real _demoMemPct: 55
    property real _demoTemp: 60
    // Endstop state only moves when something queries it, so poll the klippy
    // webhook (which queries) while this view is on screen — 1s cadence for the
    // rest of the tab, and nothing at all once the view is hidden.
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && !root.moonraker.demo
        onTriggered: root.moonraker.fetchEndstops()
    }

    Timer {
        interval: 250
        repeat: true
        running: root.moonraker.demo && root.visible
        onTriggered: {
            var t = Date.now()
            root._demoCpu = 15 + 80 * (0.5 + 0.5 * Math.sin(t / 9000))
            root._demoMemPct = 25 + 70 * (0.5 + 0.5 * Math.sin(t / 12000 + 1.7))
            root._demoTemp = 42 + 48 * (0.5 + 0.5 * Math.sin(t / 15000 + 3.1))
        }
    }

    // Mainsail SystemPanel parity: one row per device — the host first (its CPU
    // and MEM boxes), then every mcu discovered from /printer/objects/list.
    // Row text copies Mainsail's wording: MCU rows carry version + load/awake/
    // freq/temp, the host row carries version/OS/load/mem/temp + interfaces.
    readonly property var sysRows: (function() {
        var dem = root.moonraker.demo
        var proc = root.machine?.proc || {}
        var info = root.sysinfo?.system_info || {}
        var ps = root.ps || {}
        var memTotal = Number(proc.system_mem_total || 0)
        var memUsed = dem ? root._demoMemPct / 100 * (memTotal || 16e9) : Number(proc.system_mem_used || 0)
        var cpuPct = Math.min(100, Math.round(dem ? root._demoCpu : Number(proc.system_cpu_usage?.cpu || 0)))
        var memPct = memTotal > 0 ? Math.min(100, Math.round(memUsed / memTotal * 100)) : 0
        var temp = dem ? root._demoTemp : Number(proc.cpu_temp || 0)
        var lines = [
            "Version: " + (dem ? "v0.13.0-745-gf0892d82-dirty" : (ps.softwareVersion || "—")),
            "OS: " + (info.distribution?.name ?? "—"),
            "Load: " + Number(ps.sysload || 0).toFixed(2) + ", Mem: " + root.filesize(memUsed)
                + " / " + root.filesize(memTotal) + ", Temp: " + temp.toFixed(0) + "°C"
        ]
        var stats = proc.network || {}
        var details = info.network || {}
        for (var n in stats) {
            if (n === "lo") continue
            if (!(n in details) && n.indexOf("can") !== 0) continue
            lines.push(root.netLine(n, stats[n], details[n] || {}))
        }
        var out = [{
            title: "Host",
            chip: String(info.cpu_info?.processor ?? "") + (info.cpu_info?.bits ? ", " + info.cpu_info.bits : ""),
            lines: lines,
            boxes: [
                { label: "CPU", value: String(cpuPct) + "%", ratio: cpuPct / 100 },
                { label: "MEM", value: String(memPct) + "%", ratio: memPct / 100 }
            ]
        }]
        var mcus = ps.mcus || []
        for (var i = 0; i < mcus.length; i++) {
            var mc = mcus[i]
            var detail = "Load: " + Number(mc.load || 0).toFixed(2) + ", Awake: " + Number(mc.awake || 0).toFixed(2)
            if (Number(mc.freq || 0) > 0) detail += ", Freq: " + (Number(mc.freq) / 1e6).toFixed(0) + " MHz"
            if (typeof mc.temp === "number") detail += ", Temp: " + mc.temp.toFixed(0) + "°C"
            out.push({
                title: String(mc.name || ""),
                chip: String(mc.chip || ""),
                lines: ["Version: " + (mc.version ? String(mc.version) : "—"), detail],
                boxes: [{ label: "", value: String(Number(mc.loadPct || 0)) + "%", ratio: Number(mc.load || 0) }]
            })
        }
        return out
    })()

    function refresh() {
        moonraker.fetchMachine()
        moonraker.fetchSysInfo()
        moonraker.fetchRoots()
        moonraker.fetchDir(root.dirInfo?.root ?? "config", root.dirInfo?.path ?? "")
    }

    Timer {
        id: opTimer
        interval: 5000
        onTriggered: root.opMsg = ""
    }

    Connections {
        target: root.moonraker
        function onActionDone(ok, msg) {
            root.status(ok, msg)
        }
        function onBucketChanged(bucket) {
            if (bucket === "machine") {
                root.machine = root.moonraker.data?.machine ?? ({})
                root.sysinfo = root.machine?.sysinfo ?? ({})
            } else if (bucket === "roots") {
                root.roots = root.moonraker.data?.roots ?? []
            } else if (bucket === "dir") {
                root.dirInfo = root.moonraker.data?.dir ?? ({})
                root._rebuildRows()
            }
        }
    }

    function status(ok, msg) {
        root.opMsg = String(msg || "")
        root.opColor = ok ? Colors.success : Colors.error
        opTimer.restart()
    }
    function _rebuildRows() {
        var d = root.dirInfo || {}
        var rows = []
        var dirs = d.dirs || []
        for (var i = 0; i < dirs.length; i++)
            rows.push({ name: String(dirs[i].dirname || ""), isDir: true,
                        size: Number(dirs[i].size || 0), modified: Number(dirs[i].modified || 0) })
        var files = d.files || []
        for (var j = 0; j < files.length; j++) {
            var fname = String(files[j].filename || "")
            if (!root.showBackups && root.isBackupFile(fname)) continue
            rows.push({ name: fname, isDir: false,
                        size: Number(files[j].size || 0), modified: Number(files[j].modified || 0) })
        }
        var key = root.sortKey
        var asc = root.sortAsc
        rows.sort(function(a, b) {
            if (a.isDir !== b.isDir) return a.isDir ? -1 : 1
            var an = a.name.toLowerCase()
            var bn = b.name.toLowerCase()
            var r = key === "size" ? a.size - b.size
                : key === "modified" ? a.modified - b.modified
                : (an < bn ? -1 : (an > bn ? 1 : 0))
            return asc ? r : -r
        })
        root.dirRows = rows
    }
    // Klippain writes printer-YYYYMMDD_HHMMSS.cfg before every config change,
    // and loose *.bkp/*.bak copies pile up beside it — 80-odd rows of noise in
    // /config. Hidden unless the BACKUPS toggle in the root row is on.
    function isBackupFile(name) {
        return /^printer-\d{8}_\d{6}\.cfg$/i.test(name) || /\.(bkp|bak)(-|$)/i.test(name)
    }
    function dateOf(row) {
        if (!row.modified) return "—"
        var d = new Date(row.modified * 1000)
        var h = d.getHours() < 10 ? "0" + d.getHours() : String(d.getHours())
        var mins = d.getMinutes() < 10 ? "0" + d.getMinutes() : String(d.getMinutes())
        var day = root.monthNames[d.getMonth()] + " " + d.getDate()
        // This year the time matters, the year is noise. 24h keeps the column at
        // 12 chars ("Sep 15 18:54" = 101px), which the 55%-wide card needs.
        return d.getFullYear() === new Date().getFullYear()
            ? day + " " + h + ":" + mins
            : day + ", " + d.getFullYear()
    }
    function endstopNames() {
        var keys = Object.keys(root.machine?.endstops ?? ({}))
        keys.sort()
        return keys
    }
    function endstopLabel(key) {
        return String(key).replace(/^stepper_/, "").toUpperCase()
    }
    function endstopTriggered(key) {
        return root.machine?.endstops?.[key] === true
    }
    function setSort(key) {
        if (root.sortKey === key) root.sortAsc = !root.sortAsc
        else { root.sortKey = key; root.sortAsc = true }
        root._rebuildRows()
    }
    function fetchDirNow(rootName, path) {
        root.selected = ({})
        root.promptKind = ""
        root.moonraker.fetchDir(rootName, path)
    }
    function setRoot(name) { root.fetchDirNow(name, "") }
    function refreshDir() { root.moonraker.fetchDir(root.dirInfo?.root ?? "config", root.dirInfo?.path ?? "") }
    function enterDir(name) {
        var p = String(root.dirInfo?.path ?? "")
        root.fetchDirNow(root.dirInfo?.root ?? "config", p !== "" ? p + "/" + name : name)
    }
    function upDir() {
        var p = String(root.dirInfo?.path ?? "")
        if (p === "") return
        var parts = p.split("/")
        parts.pop()
        root.fetchDirNow(root.dirInfo?.root ?? "config", parts.join("/"))
    }
    function openFile(name) { root.moonraker.editRemoteFile(root.dirBase + "/" + name) }
    function toggleSel(name) {
        var s = {}
        for (var k in root.selected) s[k] = root.selected[k]
        if (s[name]) delete s[name]
        else s[name] = true
        root.selected = s
    }
    function selectAll(flag) {
        var s = {}
        if (flag) for (var i = 0; i < root.dirRows.length; i++) s[root.dirRows[i].name] = true
        root.selected = s
    }
    function selEntries() {
        var out = []
        for (var i = 0; i < root.dirRows.length; i++) {
            var r = root.dirRows[i]
            if (root.selected[r.name])
                out.push({ name: r.name, isDir: r.isDir, path: root.dirBase + "/" + r.name })
        }
        return out
    }
    function promptLabel() {
        if (root.promptKind === "mkdir") return "NEW FOLDER"
        if (root.promptKind === "rename") return "MOVE TO"
        if (root.promptKind === "copy") return "COPY TO"
        return "DELETE " + root.selCount + (root.selCount === 1 ? " ITEM?" : " ITEMS?")
    }
    function openPrompt(kind) {
        var e = root.selEntries()
        root.promptKind = kind
        root.promptText = kind === "mkdir" ? ""
            : (kind === "rename" || kind === "copy") && e.length === 1
                ? (kind === "copy" ? e[0].path + ".copy" : e[0].path) : ""
    }

    // The prompt field cannot own focus through a binding: Qt clears the value
    // when focus moves, and a cleared binding never comes back. Claim it here
    // instead, one turn later so the row is already visible.
    onPromptKindChanged: if (root.promptKind !== "" && root.promptKind !== "delete")
                             Qt.callLater(() => fmPrompt.forceActiveFocus())
    // RENAME/MOVE and COPY share one prompt: typing a different directory in
    // the pre-filled remote path is a move.
    function commitPrompt() {
        var kind = root.promptKind
        var text = String(root.promptText).trim()
        var e = root.selEntries()
        root.promptKind = ""
        if (kind === "delete") {
            for (var i = 0; i < e.length; i++) root.moonraker.removeEntry(e[i].path, e[i].isDir)
            root.selected = ({})
            return
        }
        if (text === "") return
        if (kind === "mkdir") root.moonraker.makeDir(root.dirBase + "/" + text)
        else if (kind === "rename" && e.length === 1) root.moonraker.moveEntry(e[0].path, text)
        else if (kind === "copy" && e.length === 1) root.moonraker.copyEntry(e[0].path, text)
        root.selected = ({})
    }

    function _heatColor(ratio) {
        var r = Math.max(0, Math.min(1, Number(ratio) || 0))
        if (r < 0.6) return Colors.tempCool
        if (r < 0.85) return Colors.accent
        return Colors.tempWarm
    }
    // Mainsail formatFilesize: 1024-based, one decimal (986.9 MB, 0.4 kB/s).
    function filesize(v) {
        var b = Number(v)
        if (Number.isNaN(b)) return "—"
        if (b < 1024) return b.toFixed(0) + " B"
        if (b < 1048576) return (b / 1024).toFixed(1) + " kB"
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB"
        return (b / 1073741824).toFixed(2) + " GB"
    }
    // "can0: Bandwidth: 0.4 kB/s, Received: 1.9 MB, Transmitted: 199.8 kB"
    function netLine(name, stats, details) {
        var addrs = details?.ip_addresses || []
        var ip = ""
        for (var i = 0; i < addrs.length; i++)
            if (addrs[i].family === "ipv4" && !addrs[i].is_link_local) { ip = String(addrs[i].address); break }
        return name + (ip ? " (" + ip + ")" : "")
            + ": Bandwidth: " + root.filesize(Number(stats.bandwidth || 0)) + "/s"
            + ", Received: " + root.filesize(Number(stats.rx_bytes || 0))
            + ", Transmitted: " + root.filesize(Number(stats.tx_bytes || 0))
    }
    function _needsUpdate(item) {
        return !!item && !!item.remote_version && String(item.remote_version) !== String(item.version)
    }
    function _updateCount() {
        var vi = root.machine?.update?.version_info || {}
        var n = 0
        for (var k in vi) if (k !== "system" && root._needsUpdate(vi[k])) n++
        return n
    }
    function _sysPkgs() {
        return Number(root.machine?.update?.version_info?.system?.package_count || 0)
    }
    function _updateKeys() {
        var vi = root.machine?.update?.version_info || {}
        var keys = []
        for (var k in vi) if (k !== "system") keys.push(k)
        return keys.sort()
    }
    // Mainsail's row label is the updater's own display name; fall back to key.
    function _updateName(key) {
        var item = root.machine?.update?.version_info?.[key] || {}
        return String(item.name || key)
    }
    // Updatable components read "v0.13.0-745 > v0.13.0-770" (sync glyph + old >
    // new); the rest show just their version.
    function _updateLine(key) {
        var item = root.machine?.update?.version_info?.[key] || {}
        var v = String(item.version || "?")
        if (root._needsUpdate(item)) return Icons.refresh + " " + v + " > " + String(item.remote_version)
        return v + (item.dirty ? " (dirty)" : "")
    }
    function _updateColor(key) {
        var item = root.machine?.update?.version_info?.[key] || {}
        if (item.is_valid === false) return Colors.error
        return root._needsUpdate(item) ? Colors.accent : Colors.surfaceVariantText
    }
    // Same per-component and system endpoints the individual buttons use.
    function updateAll() {
        var keys = root._updateKeys()
        for (var i = 0; i < keys.length; i++)
            if (root._needsUpdate(root.machine?.update?.version_info?.[keys[i]]))
                root.moonraker.updateClient(keys[i])
        if (root._sysPkgs() > 0) root.moonraker.updateSystem()
    }
    function _summaryText() {
        var u = root.machine?.update
        if (u?.busy) return "UPDATING…"
        var n = root._updateCount()
        if (n > 0) return n + " AVAILABLE"
        return "UP TO DATE"
    }
    function _summaryColor() {
        var u = root.machine?.update
        if (u?.busy) return Colors.tempWarm
        if (root._updateCount() > 0) return Colors.accent
        return Colors.success
    }

    Flickable {
        id: mscroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, mbody.implicitHeight + Metrics.panelMargin * 2)

        Column {
            id: mbody
            x: Metrics.panelMargin
            y: Metrics.panelMargin
            width: parent.width - Metrics.panelMargin * 2
            spacing: Metrics.lg

            Card {
                visible: root.ps !== null && !root.klippyReady
                width: parent.width
                height: 116
                fill: Colors.alpha(Colors.error, 0.10)
                borderCol: Colors.alpha(Colors.error, 0.5)

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: Metrics.panelPadding
                    anchors.right: parent.right
                    anchors.rightMargin: Metrics.panelPadding
                    anchors.top: parent.top
                    anchors.topMargin: Metrics.panelPadding - 2
                    spacing: Metrics.md

                    Text {
                        width: parent.width
                        text: "KLIPPY " + String(root.ps?.klippyState ?? "").toUpperCase()
                            + (root.ps?.klippyMessage ? " — " + String(root.ps.klippyMessage) : "")
                        font.family: Type.family
                        font.pixelSize: Type.sizeBody
                        font.bold: true
                        color: Colors.error
                        wrapMode: Text.Wrap
                    }
                    Item {
                        width: parent.width
                        height: 34
                        Row {
                            anchors.left: parent.left
                            spacing: Metrics.sm
                            Button { text: "RESTART"; icon: Icons.restart; variant: "primary"; width: 120; height: parent.height;
                                     onPressed: root.moonraker.restartKlippy() }
                            Button { text: "FIRMWARE RESTART"; icon: Icons.power; variant: "danger"; width: 170; height: parent.height;
                                     onPressed: root.moonraker.restartFirmware() }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "restart via Moonraker JSON-RPC"
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            color: Colors.textTertiary
                        }
                    }
                }
            }

            Panel {
                width: parent.width
                height: collapsed ? 34 : Math.round(sysBody.y + sysBody.height + Metrics.panelPadding)
                title: "SYSTEM"; icon: Icons.chip

                Column {
                    id: sysBody
                    visible: parent.bodyVisible
                    anchors.left: parent.left
                    anchors.leftMargin: Metrics.panelPadding
                    anchors.right: parent.right
                    anchors.rightMargin: Metrics.panelPadding
                    anchors.top: parent.top
                    anchors.topMargin: parent.bodyTop
                    spacing: Metrics.md

                    Repeater {
                        model: root.sysRows
                        delegate: Item {
                            id: srow
                            required property var modelData
                            required property int index
                            width: sysBody.width
                            implicitHeight: (srow.index > 0 ? 21 : 0)
                                + Math.max(srowText.implicitHeight, srowBoxes.implicitHeight)

                            Separator {
                                visible: srow.index > 0
                                y: 10
                            }

                            Column {
                                id: srowText
                                anchors.left: parent.left
                                anchors.right: srowBoxes.left
                                anchors.rightMargin: Metrics.xl
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Metrics.xxs

                                Row {
                                    spacing: Metrics.sm
                                    Text {
                                        text: srow.modelData.title
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeBody
                                        font.bold: true
                                        color: Colors.accent
                                    }
                                    Text {
                                        visible: text !== ""
                                        text: srow.modelData.chip ? "(" + srow.modelData.chip + ")" : ""
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        color: Colors.surfaceVariantText
                                    }
                                }
                                Repeater {
                                    model: srow.modelData.lines
                                    delegate: Text {
                                        id: sline
                                        required property string modelData
                                        width: srowText.width
                                        text: sline.modelData
                                        wrapMode: Text.Wrap
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeSmall
                                        color: Colors.surfaceVariantText
                                    }
                                }
                            }

                            Row {
                                id: srowBoxes
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Metrics.lg
                                Repeater {
                                    model: srow.modelData.boxes
                                    delegate: Column {
                                        id: sbox
                                        required property var modelData
                                        property color fillColor: root._heatColor(modelData.ratio)
                                        spacing: Metrics.xs

                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 76
                                            height: 76
                                            color: Colors.surfaceContainerLow
                                            border.width: Metrics.borderWidth
                                            border.color: Colors.outlineVariant
                                            clip: true

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                                height: parent.height * sbox.modelData.ratio
                                                Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.Linear } }
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: Colors.alpha(sbox.fillColor, 0.05) }
                                                    GradientStop { position: 0.6; color: Colors.alpha(sbox.fillColor, 0.18) }
                                                    GradientStop { position: 1.0; color: Colors.alpha(sbox.fillColor, 0.5) }
                                                }
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                text: sbox.modelData.value
                                                font.family: Type.family
                                                font.pixelSize: Type.sizeLarge
                                                font.bold: true
                                                color: Colors.textPrimary
                                            }
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            visible: text !== ""
                                            text: sbox.modelData.label
                                            font.family: Type.family
                                            font.pixelSize: Type.sizeCaption
                                            color: Colors.surfaceVariantText
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: root.manageRowH
                spacing: Metrics.lg

                Panel {
                    width: (parent.width - Metrics.lg) * 0.55
                    height: collapsed ? 34 : parent.height
                    title: "CONFIG FILES"; icon: Icons.files

                    Column {
                        id: fmHead
                        visible: parent.bodyVisible
                        anchors.left: parent.left
                        anchors.leftMargin: Metrics.panelPadding
                        anchors.right: parent.right
                        anchors.rightMargin: Metrics.panelPadding
                        anchors.top: parent.top
                        anchors.topMargin: parent.bodyTop
                        spacing: Metrics.sm

                        Flow {
                            width: parent.width
                            spacing: Metrics.xs
                            Repeater {
                                model: root.rootChips
                                delegate: Button {
                                    required property var modelData
                                    height: 22
                                    text: String(modelData.name).replace("_", " ")
                                    variant: root.dirInfo?.root === modelData.name ? "primary" : "plain"
                                    onPressed: root.setRoot(String(modelData.name))
                                }
                            }
                            Button {
                                height: 22
                                text: "BACKUPS"; icon: Icons.folder
                                variant: root.showBackups ? "primary" : "plain"
                                onPressed: root.showBackups = !root.showBackups
                            }
                        }

                        Row {
                            width: parent.width
                            height: 18
                            spacing: Metrics.sm
                            Button {
                                width: 30
                                height: 18
                                text: Icons.up
                                variant: "plain"
                                active: (root.dirInfo?.path ?? "") !== ""
                                onPressed: root.upDir()
                            }
                            Text {
                                width: parent.width - 30 - 130 - Metrics.sm * 3
                                anchors.verticalCenter: parent.verticalCenter
                                text: "/" + root.dirBase
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: Colors.textPrimary
                                elide: Text.ElideLeft
                            }
                            Text {
                                width: 130
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.opMsg !== "" ? root.opMsg
                                    : (root.dirInfo?.disk ? root.filesize(root.dirInfo.disk.free) + " free" : "")
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: root.opMsg !== "" ? root.opColor : Colors.surfaceVariantText
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                            }
                        }

                        Separator { width: parent.width }

                        Item {
                            width: parent.width
                            height: 20

                            Row {
                                anchors.fill: parent
                                spacing: 0
                                Rectangle {
                                    width: 14
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 3
                                    color: root.selCount > 0 && root.selCount === root.dirRows.length
                                        ? Colors.accent : "transparent"
                                    border.width: Metrics.borderWidth
                                    border.color: Colors.outline
                                }
                                Text {
                                width: parent.width - 14 - root.fmSizeW - root.fmDateW - root.fmColGap
                                anchors.verticalCenter: parent.verticalCenter
                                leftPadding: Metrics.sm
                                text: "NAME" + (root.sortKey === "name" ? (root.sortAsc ? " ▴" : " ▾") : "")
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                color: root.sortKey === "name" ? Colors.accent : Colors.surfaceVariantText
                            }
                            Text {
                                width: root.fmSizeW
                                anchors.verticalCenter: parent.verticalCenter
                                text: "SIZE" + (root.sortKey === "size" ? (root.sortAsc ? " ▴" : " ▾") : "")
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                color: root.sortKey === "size" ? Colors.accent : Colors.surfaceVariantText
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                width: root.fmDateW + root.fmColGap
                                anchors.verticalCenter: parent.verticalCenter
                                text: "MODIFIED" + (root.sortKey === "modified" ? (root.sortAsc ? " ▴" : " ▾") : "")
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                color: root.sortKey === "modified" ? Colors.accent : Colors.surfaceVariantText
                                horizontalAlignment: Text.AlignRight
                            }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    root.setSort(mouse.x > parent.width - root.fmDateW ? "modified"
                                        : (mouse.x > parent.width - root.fmDateW - root.fmColGap - root.fmSizeW ? "size" : "name"))
                                }
                            }
                        }
                    }

                    Flickable {
                        id: fmList
                        visible: parent.bodyVisible
                        anchors.left: parent.left
                        anchors.leftMargin: Metrics.panelPadding
                        anchors.right: parent.right
                        anchors.rightMargin: Metrics.panelPadding
                        anchors.top: fmHead.bottom
                        anchors.topMargin: Metrics.sm
                        anchors.bottom: fmFoot.top
                        anchors.bottomMargin: Metrics.sm
                        clip: true
                        contentWidth: width
                        contentHeight: fmCol.height

                        Column {
                            id: fmCol
                            width: fmList.width
                            spacing: 0

                            Repeater {
                                model: root.dirRows
                                delegate: Item {
                                    id: frow
                                    required property var modelData
                                    width: fmCol.width
                                    height: 28

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Metrics.radiusSmall
                                        border.width: fma.containsMouse ? Metrics.borderWidth : 0
                                        border.color: Colors.outlineVariant
                                        color: fma.containsMouse ? Colors.hoverFill
                                            : (root.selected[frow.modelData.name] ? Colors.selectedFill : "transparent")
                                    }
                                    Rectangle {
                                        width: 14
                                        height: 14
                                        anchors.left: parent.left
                                        anchors.leftMargin: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 3
                                        color: root.selected[frow.modelData.name] ? Colors.accent : "transparent"
                                        border.width: Metrics.borderWidth
                                        border.color: Colors.outline
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleSel(frow.modelData.name)
                                        }
                                    }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 20 - root.fmSizeW - root.fmDateW - root.fmColGap - Metrics.sm
                                        text: (frow.modelData.isDir ? "▸ " : "   ") + frow.modelData.name
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        color: frow.modelData.isDir ? Colors.accent
                                            : (fma.containsMouse ? Colors.accent : Colors.textPrimary)
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: root.fmSizeW
                                        anchors.right: frowDate.left
                                        anchors.rightMargin: root.fmColGap
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: frow.modelData.isDir ? "–" : root.filesize(frow.modelData.size)
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        color: Colors.surfaceVariantText
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        id: frowDate
                                        width: root.fmDateW
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.dateOf(frow.modelData)
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        color: Colors.surfaceVariantText
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }
                                    MouseArea {
                                        id: fma
                                        anchors.left: parent.left
                                        anchors.leftMargin: 20
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        acceptedButtons: Qt.LeftButton
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: frow.modelData.isDir
                                            ? root.enterDir(frow.modelData.name) : root.openFile(frow.modelData.name)
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: fmFoot
                        visible: parent.bodyVisible
                        anchors.left: parent.left
                        anchors.leftMargin: Metrics.panelPadding
                        anchors.right: parent.right
                        anchors.rightMargin: Metrics.panelPadding
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Metrics.panelPadding - 8
                        height: 26

                        Text {
                            visible: root.promptKind === "delete"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 132 - Metrics.sm * 2
                            text: root.promptLabel()
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            font.bold: true
                            color: Colors.error
                            elide: Text.ElideRight
                        }
                        Row {
                            visible: root.promptKind !== "" && root.promptKind !== "delete"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Metrics.sm
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.promptLabel()
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                color: Colors.surfaceVariantText
                            }
                            Rectangle {
                                width: 168
                                height: 26
                                radius: Metrics.radiusSmall
                                color: Colors.surfaceContainerHighest
                                border.width: Metrics.borderWidth
                                border.color: Colors.alpha(Colors.accent, 0.5)
                                TextInput {
                                    id: fmPrompt
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeCaption
                                    color: Colors.textPrimary
                                    selectionColor: Colors.accentDim
                                    selectedTextColor: Colors.textPrimary
                                    text: root.promptText
                                    onTextEdited: root.promptText = text
                                    onAccepted: root.commitPrompt()
                                }
                            }
                        }
                        Row {
                            visible: root.promptKind !== ""
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Metrics.sm
                            Button {
                                width: 56
                                height: 26
                                text: "OK"; icon: Icons.check
                                variant: root.promptKind === "delete" ? "danger" : "primary"
                                active: root.writable
                                onPressed: root.commitPrompt()
                            }
                            Button {
                                width: 74
                                height: 26
                                text: "CANCEL"; icon: Icons.close
                                variant: "plain"
                                onPressed: root.promptKind = ""
                            }
                        }

                        Row {
                            visible: root.promptKind === "" && root.selCount > 0
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Metrics.sm
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.selCount + " selected"
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: Colors.accent
                            }
                            Button {
                                visible: root.selCount === 1
                                width: 84
                                height: 26
                                text: "RENAME"; icon: Icons.edit
                                variant: "plain"
                                active: root.writable
                                onPressed: root.openPrompt("rename")
                            }
                            Button {
                                visible: root.selCount === 1
                                width: 72
                                height: 26
                                text: "COPY"; icon: Icons.copy
                                variant: "plain"
                                active: root.writable
                                onPressed: root.openPrompt("copy")
                            }
                            Button {
                                width: 84
                                height: 26
                                text: "DELETE"; icon: Icons.trash
                                variant: "danger"
                                active: root.writable
                                onPressed: root.openPrompt("delete")
                            }
                        }
                        Row {
                            visible: root.promptKind === "" && root.selCount === 0
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Metrics.sm
                            Button {
                                // 106px of content (icon + 10 glyphs at 14px with
                                // 0.8px tracking) did not fit the 100 it had here.
                                width: 112
                                height: 26
                                text: "NEW FOLDER"; icon: Icons.plus
                                variant: "plain"
                                active: root.writable
                                onPressed: root.openPrompt("mkdir")
                            }
                            Button {
                                width: 78
                                height: 26
                                text: "UPLOAD"; icon: Icons.upload
                                variant: "plain"
                                active: root.writable
                                onPressed: root.moonraker.pickAndUpload(root.dirInfo?.root ?? "config", root.dirInfo?.path ?? ".")
                            }
                            Button {
                                width: 84
                                height: 26
                                text: "REFRESH"; icon: Icons.refresh
                                variant: "soft"
                                onPressed: root.refreshDir()
                            }
                        }
                    }
                }

                Column {
                    width: (parent.width - Metrics.lg) * 0.45
                    height: parent.height
                    spacing: Metrics.lg

                    Row {
                        width: parent.width
                        height: root.railTopH
                        spacing: Metrics.lg

                        Panel {
                            id: endstopsPanel
                            width: (parent.width - Metrics.lg) / 2
                            height: parent.height
                            title: "ENDSTOPS"; icon: Icons.target

                            Column {
                                visible: parent.bodyVisible
                                anchors.left: parent.left
                                anchors.leftMargin: Metrics.panelPadding
                                anchors.right: parent.right
                                anchors.rightMargin: Metrics.panelPadding
                                anchors.top: parent.top
                                anchors.topMargin: parent.bodyTop
                                spacing: Metrics.sm

                                Item {
                                    width: parent.width
                                    height: 26
                                    Button {
                                        anchors.right: parent.right
                                        width: 84
                                        height: 26
                                        text: "REFRESH"; icon: Icons.refresh
                                        variant: "soft"
                                        onPressed: root.moonraker.fetchEndstops()
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: Metrics.xs

                                    Repeater {
                                        model: root.endstopNames()
                                        delegate: Item {
                                            id: erow
                                            required property var modelData
                                            width: parent.width
                                            height: 34
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: Metrics.radiusSmall
                                                color: Colors.surfaceContainerLow
                                            }
                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: Metrics.md
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.endstopLabel(erow.modelData)
                                                font.family: Type.family
                                                font.pixelSize: Type.sizeCaption
                                                font.bold: true
                                                font.letterSpacing: 1.0
                                                color: Colors.surfaceVariantText
                                            }
                                            Chip {
                                                anchors.right: parent.right
                                                anchors.rightMargin: Metrics.md
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.endstopTriggered(erow.modelData) ? "TRIGGERED" : "open"
                                                color: root.endstopTriggered(erow.modelData) ? Colors.error : Colors.success
                                            }
                                        }
                                    }
                                }

                                Text {
                                    visible: root.endstopRows === 0
                                    width: parent.width
                                    text: "no endstops reported"
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeCaption
                                    color: Colors.textTertiary
                                }
                            }
                        }

                        Panel {
                            id: logPanel
                            width: (parent.width - Metrics.lg) / 2
                            height: parent.height
                            title: "LOG FILES"; icon: Icons.file

                            Column {
                                id: logCol
                                visible: parent.bodyVisible
                                anchors.left: parent.left
                                anchors.leftMargin: Metrics.panelPadding
                                anchors.right: parent.right
                                anchors.rightMargin: Metrics.panelPadding
                                anchors.top: parent.top
                                anchors.topMargin: parent.bodyTop
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Metrics.panelPadding
                                spacing: Metrics.sm

                                Repeater {
                                    model: [{ name: "klippy.log", label: "KLIPPY" },
                                            { name: "moonraker.log", label: "MOONRAKER" },
                                            { name: "crowsnest.log", label: "CROWSNEST" }]
                                    delegate: Button {
                                        required property var modelData
                                        width: logCol.width
                                        height: (logCol.height - logCol.spacing * 2) / 3
                                        text: modelData.label
                                        variant: "soft"
                                        onPressed: root.moonraker.downloadLog(modelData.name)
                                    }
                                }
                            }
                        }
                    }

                    Panel {
                        width: parent.width
                        height: collapsed ? 34 : root.updateRowH
                        title: "UPDATE MANAGER"; icon: Icons.restart

                        Column {
                            visible: parent.bodyVisible
                            anchors.left: parent.left
                            anchors.leftMargin: Metrics.panelPadding
                            anchors.right: parent.right
                            anchors.rightMargin: Metrics.panelPadding
                            anchors.top: parent.top
                            anchors.topMargin: parent.bodyTop
                            spacing: Metrics.sm

                            Item {
                                width: parent.width
                                height: 30
                                Chip {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    pill: true
                                    filled: true
                                    text: root._summaryText()
                                    color: root._summaryColor()
                                }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Metrics.sm
                                    Button {
                                        width: 236
                                        height: 26
                                        text: "UPDATE ALL COMPONENTS"; icon: Icons.refresh
                                        variant: "primary"
                                        active: root.canUpdate
                                            && (root._updateCount() > 0 || root._sysPkgs() > 0)
                                        onPressed: root.updateAll()
                                    }
                                    Button {
                                        width: 88
                                        height: 26
                                        text: "CHECK"; icon: Icons.search
                                        variant: "soft"
                                        active: root.canUpdate
                                        onPressed: root.moonraker.fetchMachine()
                                    }
                                }
                            }

                            // A printer with 9 components and 13 pending system
                            // packages overflows any window, so System — the row the
                            // user actually acts on — leads instead of trailing, and
                            // the component list is whatever scrolls off the bottom.
                            Item {
                                visible: root._sysPkgs() > 0
                                width: parent.width
                                height: 52
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Metrics.radiusSmall
                                    color: Colors.alpha(Colors.accent, 0.08)
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 130
                                    anchors.top: parent.top
                                    anchors.topMargin: 7
                                    text: "System"
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeCaption
                                    font.bold: true
                                    color: Colors.textPrimary
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 0
                                    anchors.top: parent.top
                                    anchors.topMargin: 27
                                    text: root._sysPkgs() + " package" + (root._sysPkgs() === 1 ? "" : "s") + " can be upgraded"
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeCaption
                                    color: Colors.accent
                                    elide: Text.ElideRight
                                }
                                Button {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 116
                                    height: 28
                                    text: "UPGRADE"; icon: Icons.refresh
                                    variant: "primary"
                                    active: root.canUpdate
                                    onPressed: root.canUpdate ? root.moonraker.updateSystem() : null
                                }
                            }

                            Repeater {
                                model: root._updateKeys()
                                delegate: Item {
                                    id: urow
                                    required property var modelData
                                    width: parent.width
                                    height: 52
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Metrics.radiusSmall
                                        color: root._needsUpdate(root.machine?.update?.version_info?.[urow.modelData])
                                            ? Colors.alpha(Colors.accent, 0.08) : "transparent"
                                    }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.rightMargin: 130
                                        anchors.top: parent.top
                                        anchors.topMargin: 7
                                        text: root._updateName(urow.modelData)
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        font.bold: true
                                        color: Colors.textPrimary
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.topMargin: 27
                                        text: root._updateLine(urow.modelData)
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        color: root._updateColor(urow.modelData)
                                        elide: Text.ElideRight
                                    }
                                    Chip {
                                        visible: root.machine?.update?.version_info?.[urow.modelData]?.is_valid !== false
                                            && !root._needsUpdate(root.machine?.update?.version_info?.[urow.modelData])
                                        anchors.right: parent.right
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "UP-TO-DATE"; icon: Icons.ok
                                        color: Colors.success
                                    }
                                    Button {
                                        visible: root.machine?.update?.version_info?.[urow.modelData]?.is_valid === false
                                            || root._needsUpdate(root.machine?.update?.version_info?.[urow.modelData])
                                        anchors.right: parent.right
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 116
                                        height: 28
                                        text: root.machine?.update?.version_info?.[urow.modelData]?.is_valid === false
                                            ? "INVALID" : "UPDATE"
                                        variant: root.machine?.update?.version_info?.[urow.modelData]?.is_valid === false
                                            ? "danger" : "primary"
                                        active: root.canUpdate
                                        onPressed: root.canUpdate ? root.moonraker.updateClient(urow.modelData) : null
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                visible: root._updateKeys().length === 0 && root._sysPkgs() === 0
                                text: "no components reported (printer unreachable or updater disabled)"
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                color: Colors.surfaceVariantText
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}