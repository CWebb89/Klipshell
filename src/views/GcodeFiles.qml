pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../config"
import "../components"

// G-CODE FILES: the CONFIG FILES card at full-tab size — one row per print,
// every column Mainsail shows, scrolled sideways because the table is wider
// than any window. All of it rides one request:
// /server/files/directory?extended=true returns the slicer metadata inline per
// file, and the actual print/total durations are joined from the history bucket
// we already fetch (by filename), so there is no per-row fetch behind this.
Item {
    id: root

    required property QtObject moonraker

    property var files: []
    property var dirs: []
    property var disk: null
    property string path: ""
    property var totals: ({})
    property var hist: ({})
    property string sortKey: "name"
    property bool sortAsc: true
    property var rows: []

    readonly property int rowH: 30
    readonly property int headH: 24
    readonly property int cellGap: Metrics.md
    readonly property int fontPx: Type.sizeCaption + 1

    function refresh() {
        root.moonraker.fetchGcodeFiles(root.path)
        root.moonraker.fetchHistory()
        root.moonraker.fetchTotals()
    }

    Connections {
        target: root.moonraker
        function onBucketChanged(bucket) {
            if (bucket === "gcodes") root._apply()
            else if (bucket === "history") root._applyHist()
            else if (bucket === "totals") { root.totals = root.moonraker.data?.totals ?? ({}); }
        }
    }

    function _apply() {
        var g = root.moonraker.data?.gcodes ?? ({})
        if (String(g.path ?? "") !== root.path) return
        root.dirs = g.dirs ?? []
        root.files = g.files ?? []
        root.disk = g.disk ?? null
        root._rebuild()
    }

    // History is newest-first, so the first hit per filename is the last print.
    function _applyHist() {
        var jobs = root.moonraker.data?.history?.jobs ?? []
        var m = ({})
        for (var i = 0; i < jobs.length; i++) {
            var f = String(jobs[i].filename ?? "")
            if (f !== "" && m[f] === undefined) m[f] = jobs[i]
        }
        root.hist = m
        root._rebuild()
    }

    function _rebuild() {
        var prefix = root.path === "" ? "" : root.path + "/"
        var out = []
        for (var i = 0; i < root.dirs.length; i++)
            out.push({ kind: "dir", name: String(root.dirs[i].dirname ?? ""), key: "",
                       size: Number(root.dirs[i].size || 0), modified: Number(root.dirs[i].modified || 0), meta: null })
        for (var j = 0; j < root.files.length; j++) {
            var name = String(root.files[j].filename ?? "")
            out.push({ kind: "file", name: name, key: prefix + name,
                       size: Number(root.files[j].size || 0), modified: Number(root.files[j].modified || 0),
                       meta: root.files[j] })
        }
        var key = root.sortKey
        var sign = root.sortAsc ? 1 : -1
        out.sort(function(a, b) {
            if (a.kind !== b.kind) return a.kind === "dir" ? -1 : 1
            if (key === "size") return (a.size - b.size) * sign
            if (key === "modified") return (a.modified - b.modified) * sign
            var an = a.name.toLowerCase()
            var bn = b.name.toLowerCase()
            return an < bn ? -sign : (an > bn ? sign : 0)
        })
        root.rows = out
    }

    function setSort(k) {
        if (root.sortKey === k) root.sortAsc = !root.sortAsc
        else { root.sortKey = k; root.sortAsc = true }
        root._rebuild()
    }

    function enterDir(name) {
        root.path = root.path === "" ? name : root.path + "/" + name
        root.moonraker.fetchGcodeFiles(root.path)
    }

    function goUp() {
        if (root.path === "") return
        var cut = root.path.lastIndexOf("/")
        root.path = cut < 0 ? "" : root.path.slice(0, cut)
        root.moonraker.fetchGcodeFiles(root.path)
    }

    // One array drives the header and every row, so the two cannot drift. Widths
    // are sized to the widest value each column can hold at fontPx (mono advance
    // is ~0.6em), NAME to a fixed 340 so the table always overflows and the
    // sideways scroll is always available.
    readonly property int nameW: 340
    readonly property var fixedCols: [
        { k: "size", label: "SIZE", w: 100, right: true, sort: true },
        { k: "modified", label: "MODIFIED", w: 172, right: true, sort: true },
        { k: "printed", label: "LAST PRINTED", w: 172, right: true },
        { k: "est", label: "EST TIME", w: 108, right: true },
        { k: "actual", label: "PRINT TIME", w: 112, right: true },
        { k: "total", label: "TOTAL TIME", w: 112, right: true },
        { k: "filament", label: "FILAMENT", w: 108, right: true },
        { k: "weight", label: "WEIGHT", w: 100, right: true },
        { k: "layerH", label: "LAYER H", w: 96, right: true },
        { k: "firstLayer", label: "1ST LAYER", w: 104, right: true },
        { k: "height", label: "OBJECT H", w: 104, right: true },
        { k: "nozzle", label: "NOZZLE", w: 96, right: true },
        { k: "temps", label: "1ST TEMPS", w: 120, right: true },
        { k: "type", label: "TYPE", w: 88 },
        { k: "filName", label: "FILAMENT NAME", w: 160 },
        { k: "slicer", label: "SLICER", w: 190 },
        { k: "uuid", label: "UUID", w: 250 }
    ]
    readonly property int fixedW: (function() {
        var s = root.cellGap * root.fixedCols.length
        for (var i = 0; i < root.fixedCols.length; i++) s += root.fixedCols[i].w
        return s
    })()
    readonly property int tableW: root.nameW + root.fixedW

    function colFmt(v) {
        var kb = Number(v || 0) / 1024
        if (kb < 1000) return kb.toFixed(kb < 10 ? 1 : 0) + " kB"
        var mb = kb / 1024
        if (mb < 1000) return mb.toFixed(1) + " MB"
        return (mb / 1024).toFixed(2) + " GB"
    }

    function dateOf(v) {
        var t = Number(v || 0)
        if (!t) return "—"
        var d = new Date(t * 1000)
        var day = root.monthNames[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
        return day + " " + d.getHours() + ":" + ("0" + d.getMinutes()).slice(-2)
    }

    // Durations here run to tens of hours, so h/m, not the console's mm:ss.
    function durLong(v) {
        var t = Math.round(Number(v || 0))
        if (t <= 0) return "—"
        var h = Math.floor(t / 3600)
        var m = Math.round((t % 3600) / 60)
        if (h === 0) return m + "m"
        return h + "h " + ("0" + m).slice(-2) + "m"
    }

    function mm(v) {
        var n = Number(v || 0)
        return n > 0 ? Settings.lengthText(n, 2) : "—"
    }

    function jobOf(row) {
        return row.key === "" ? null : (root.hist[row.key] ?? null)
    }

    function cellText(row, k) {
        var m = row.meta
        if (row.kind === "dir") {
            if (k === "size") return root.colFmt(row.size)
            if (k === "modified") return root.dateOf(row.modified)
            return ""
        }
        if (k === "size") return root.colFmt(row.size)
        if (k === "modified") return root.dateOf(row.modified)
        if (k === "printed") return root.dateOf(m?.print_start_time)
        if (k === "est") return root.durLong(m?.estimated_time)
        if (k === "actual") return root.durLong(root.jobOf(row)?.print_duration)
        if (k === "total") return root.durLong(root.jobOf(row)?.total_duration)
        if (k === "filament") {
            var f = Number(m?.filament_total || 0)
            return f > 0 ? (f / 1000).toFixed(1) + " m" : "—"
        }
        if (k === "weight") {
            var w = Number(m?.filament_weight_total || 0)
            return w > 0 ? w.toFixed(1) + " g" : "—"
        }
        if (k === "layerH") return root.mm(m?.layer_height)
        if (k === "firstLayer") return root.mm(m?.first_layer_height)
        if (k === "height") return root.mm(m?.object_height)
        if (k === "nozzle") return root.mm(m?.nozzle_diameter)
        if (k === "temps") {
            var e = Number(m?.first_layer_extr_temp || 0)
            var b = Number(m?.first_layer_bed_temp || 0)
            return (e > 0 || b > 0)
                ? Number(Settings.tempValue(e)).toFixed(0) + "/" + Number(Settings.tempValue(b)).toFixed(0)
                    + " " + Settings.tempSuffix()
                : "—"
        }
        if (k === "type") return String(m?.filament_type ?? "") || "—"
        if (k === "filName") return String(m?.filament_name ?? "") || "—"
        if (k === "slicer") {
            var s = String(m?.slicer ?? "")
            var sv = String(m?.slicer_version ?? "")
            return s === "" ? "—" : (sv === "" ? s : s + " " + sv)
        }
        if (k === "uuid") return String(m?.uuid ?? "") || "—"
        return ""
    }

    readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    function totalsLine() {
        var t = root.totals || {}
        var parts = [root.rows.length + " entries"]
        if (Number(t.total_jobs || 0) > 0) parts.push(Number(t.total_jobs) + " jobs")
        if (Number(t.total_print_time || 0) > 0) parts.push(root.durLong(t.total_print_time) + " printed")
        if (Number(t.longest_print || 0) > 0) parts.push("longest " + root.durLong(t.longest_print))
        return parts.join(" · ")
    }

    Card {
        anchors.fill: parent
        anchors.margins: Metrics.panelMargin

        // Card header and breadcrumb were removed on request: the tab is the
        // whole card now, with the totals line and REFRESH as its only chrome.
        Item {
            id: gbar
            anchors.left: parent.left
            anchors.leftMargin: Metrics.panelPadding
            anchors.right: parent.right
            anchors.rightMargin: Metrics.panelPadding
            anchors.top: parent.top
            anchors.topMargin: Metrics.panelPadding
            height: 26

            Button {
                id: gUp
                visible: root.path !== ""
                width: 30
                height: 26
                text: Icons.up
                variant: "plain"
                onPressed: root.goUp()
            }

            Row {
                id: gTools
                anchors.left: gUp.visible ? gUp.right : parent.left
                anchors.leftMargin: gUp.visible ? Metrics.sm : 0
                anchors.right: gRefresh.left
                anchors.rightMargin: Metrics.sm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Metrics.sm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.totalsLine()
                    font.family: Type.family
                    font.pixelSize: root.fontPx
                    color: Colors.textTertiary
                }
            }

            Button {
                id: gRefresh
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 84
                height: 26
                text: "REFRESH"; icon: Icons.refresh
                variant: "soft"
                onPressed: root.refresh()
            }
        }

        // Header strip: clipped, with its Row offset by the table's scroll so
        // labels stay over their columns.
        Item {
            id: ghead
            anchors.left: parent.left
            anchors.leftMargin: Metrics.panelPadding
            anchors.right: parent.right
            anchors.rightMargin: Metrics.panelPadding
            anchors.top: gbar.bottom
            anchors.topMargin: Metrics.sm
            height: root.headH
            clip: true

            Row {
                x: -gtable.contentX
                height: parent.height
                spacing: root.cellGap

                Item {
                    width: root.nameW
                    height: parent.height
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "NAME" + (root.sortKey === "name" ? (root.sortAsc ? " " + Icons.up : " " + Icons.down) : "")
                        font.family: Type.family
                        font.pixelSize: root.fontPx
                        font.bold: true
                        color: Colors.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setSort("name")
                    }
                }

                Repeater {
                    model: root.fixedCols
                    delegate: Item {
                        id: gcol
                        required property var modelData
                        width: gcol.modelData.w
                        height: root.headH
                        Text {
                            anchors.right: gcol.modelData.right ? parent.right : undefined
                            anchors.left: gcol.modelData.right ? undefined : parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: gcol.modelData.right ? Text.AlignRight : Text.AlignLeft
                            text: gcol.modelData.label + (root.sortKey === gcol.modelData.k
                                ? (root.sortAsc ? " " + Icons.up : " " + Icons.down) : "")
                            font.family: Type.family
                            font.pixelSize: root.fontPx
                            font.bold: true
                            color: Colors.accent
                        }
                        MouseArea {
                            anchors.fill: parent
                            visible: gcol.modelData.sort === true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setSort(gcol.modelData.k)
                        }
                    }
                }
            }
        }

        Separator {
            id: grule
            anchors.left: parent.left
            anchors.leftMargin: Metrics.panelPadding
            anchors.right: parent.right
            anchors.rightMargin: Metrics.panelPadding
            anchors.top: ghead.bottom
            anchors.topMargin: Metrics.sm
        }

        Flickable {
            id: gtable
            anchors.left: parent.left
            anchors.leftMargin: Metrics.panelPadding
            anchors.right: parent.right
            anchors.rightMargin: Metrics.panelPadding
            anchors.top: grule.bottom
            anchors.topMargin: Metrics.sm
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.panelPadding
            clip: true
            contentWidth: root.tableW
            contentHeight: gcolbody.height

            // A plain wheel has to move this table sideways — it is almost always
            // wider than the viewport and only rarely taller.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    var dx = event.angleDelta.x
                    var dy = event.angleDelta.y
                    if (Math.abs(dx) > Math.abs(dy) || gtable.contentHeight <= gtable.height)
                        gtable.contentX = Math.max(0, Math.min(root.tableW - gtable.width,
                            gtable.contentX - (dx !== 0 ? dx : dy)))
                    else
                        gtable.contentY = Math.max(0, Math.min(gtable.contentHeight - gtable.height,
                            gtable.contentY - dy))
                    event.accepted = true
                }
            }

            Column {
                id: gcolbody
                width: root.tableW
                spacing: 0

                Repeater {
                    model: root.rows
                    delegate: Item {
                        id: grow
                        required property var modelData
                        width: root.tableW
                        height: root.rowH

                        Rectangle {
                            anchors.fill: parent
                            color: gma.containsMouse ? Colors.hoverFill : "transparent"
                        }

                        Row {
                            id: growRow
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.cellGap

                            Text {
                                width: root.nameW
                                anchors.verticalCenter: growRow.verticalCenter
                                text: (grow.modelData.kind === "dir" ? "▸ " : "   ") + grow.modelData.name
                                font.family: Type.family
                                font.pixelSize: root.fontPx
                                color: grow.modelData.kind === "dir" ? Colors.accent
                                    : (gma.containsMouse ? Colors.accent : Colors.textPrimary)
                                elide: Text.ElideMiddle
                            }

                            Repeater {
                                model: root.fixedCols
                                delegate: Text {
                                    id: gcell
                                    required property var modelData
                                    width: gcell.modelData.w
                                    // The Repeater creates its delegate without a
                                    // parent, so anchoring to `parent` here evaluates
                                    // against null on every layout pass.
                                    anchors.verticalCenter: growRow.verticalCenter
                                    horizontalAlignment: gcell.modelData.right ? Text.AlignRight : Text.AlignLeft
                                    text: root.cellText(grow.modelData, gcell.modelData.k)
                                    font.family: Type.family
                                    font.pixelSize: root.fontPx
                                    color: Colors.surfaceVariantText
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: gma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (grow.modelData.kind === "dir") root.enterDir(grow.modelData.name)
                            }
                        }
                    }
                }
            }
        }

        // Scroll position has to be visible, or a wide table reads as broken.
        Rectangle {
            id: gsbar
            visible: root.tableW > gtable.width
            anchors.left: gtable.left
            anchors.right: gtable.right
            anchors.top: gtable.bottom
            anchors.topMargin: Metrics.xs
            height: 4
            radius: 2
            color: Colors.alpha(Colors.textPrimary, 0.10)

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: Math.max(28, gsbar.width * (gtable.width / root.tableW))
                x: (gsbar.width - width) * (gtable.contentX / Math.max(1, root.tableW - gtable.width))
                color: Colors.alpha(Colors.textPrimary, 0.38)
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Metrics.panelPadding
            anchors.right: parent.right
            anchors.rightMargin: Metrics.panelPadding
            anchors.top: grule.bottom
            anchors.topMargin: Metrics.md
            visible: root.rows.length === 0
            text: root.path === ""
                ? "no gcode files on the printer"
                : "empty folder (or the printer is unreachable)"
            font.family: Type.family
            font.pixelSize: Type.sizeSmall
            color: Colors.textTertiary
        }
    }
}
