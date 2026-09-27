pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

// HISTORY: Mainsail's history tab — a STATISTICS card (session totals, a
// job-status donut, a filament/print-time bar chart over the last jobs) over a
// searchable, sortable PRINT HISTORY table. Data is the history bucket the
// service already polls: every job carries filename, status, start_time,
// print_duration, total_duration, filament_used and the full gcode metadata
// snapshot (slicer, estimated_time, thumbnails) inline.
Item {
    id: root

    required property QtObject moonraker

    property var jobs: []
    property var totals: ({})
    property string query: ""
    property string sortKey: "start"
    property bool sortAsc: false
    property string metric: "filament"
    property var rows: []
    property var chartRows: []

    // 380 tall: the donut + caption + 4-row legend stack is ~291 and has to sit
    // inside the Panel body (statsH - bodyTop 40 - panelPadding 22) with air
    // around it, for the whole block to read as centred rather than crammed.
    readonly property int statsH: 380
    readonly property int rowH: 46
    readonly property int chartN: 19
    readonly property int colGap: Metrics.lg
    readonly property int fontPx: Type.sizeCaption + 1
    readonly property int cStatus: 34
    readonly property int cStart: 180
    readonly property int cEst: 130
    readonly property int cPrint: 130
    readonly property int cFil: 130
    readonly property int cSlicer: 170
    readonly property int tableW: htable.width
    readonly property int nameW: Math.max(220, root.tableW - root.cStatus - root.cStart
        - root.cEst - root.cPrint - root.cFil - root.cSlicer - root.colGap * 6)
    // Natural width of every column — narrower windows scroll sideways rather
    // than clipping SLICER out of reach.
    readonly property int contentW: root.cStatus + root.nameW + root.cStart + root.cEst
        + root.cPrint + root.cFil + root.cSlicer + root.colGap * 6

    function refresh() {
        root.moonraker.fetchHistory()
        root.moonraker.fetchTotals()
    }

    Connections {
        target: root.moonraker
        function onBucketChanged(bucket) {
            if (bucket === "history") root._applyJobs()
            else if (bucket === "totals") { root.totals = root.moonraker.data?.totals ?? ({}); }
        }
    }

    function _applyJobs() {
        root.jobs = root.moonraker.data?.history?.jobs ?? []
        root._rebuild()
    }

    function _rebuild() {
        var q = root.query.toLowerCase()
        var out = []
        for (var i = 0; i < root.jobs.length; i++) {
            var j = root.jobs[i]
            if (q !== "" && String(j.filename ?? "").toLowerCase().indexOf(q) < 0) continue
            out.push(j)
        }
        var sign = root.sortAsc ? 1 : -1
        out.sort(function(a, b) {
            if (root.sortKey === "filename") {
                var an = String(a.filename ?? "").toLowerCase()
                var bn = String(b.filename ?? "").toLowerCase()
                return an < bn ? -sign : (an > bn ? sign : 0)
            }
            return (Number(a.start_time || 0) - Number(b.start_time || 0)) * sign
        })
        root.rows = out
        // Newest-first from Moonraker; the chart reads left-to-right oldest-first.
        root.chartRows = root.jobs.slice(0, root.chartN).reverse()
    }

    function setSort(k) {
        if (root.sortKey === k) root.sortAsc = !root.sortAsc
        else { root.sortKey = k; root.sortAsc = true }
        root._rebuild()
    }

    function dur(v) {
        var t = Math.round(Number(v || 0))
        if (t <= 0) return "—"
        var h = Math.floor(t / 3600)
        var m = Math.floor((t % 3600) / 60)
        var s = t % 60
        return (h > 0 ? h + "h " : "") + ((h > 0 || m > 0) ? m + "m " : "") + s + "s"
    }

    function durShort(v) {
        var t = Math.round(Number(v || 0))
        if (t <= 0) return "—"
        var h = Math.floor(t / 3600)
        var m = Math.round((t % 3600) / 60)
        return h === 0 ? m + "m" : h + "h " + ("0" + m).slice(-2) + "m"
    }

    function dateOf(v) {
        var t = Number(v || 0)
        if (!t) return "—"
        var d = new Date(t * 1000)
        return root.monthNames[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
            + " " + d.getHours() + ":" + ("0" + d.getMinutes()).slice(-2)
    }

    function meters(v) {
        var n = Number(v || 0)
        return n > 0 ? (n / 1000).toFixed(2) + " m" : "—"
    }

    function statusGlyph(s) {
        if (s === "completed") return Icons.ok
        if (s === "cancelled") return Icons.close
        if (s === "error" || s === "klippy_shutdown") return Icons.warning
        if (s === "in_progress") return Icons.refresh
        return Icons.clock
    }

    function statusColor(s) {
        if (s === "completed") return Colors.success
        if (s === "cancelled") return Colors.tempWarm
        if (s === "error" || s === "klippy_shutdown") return Colors.tempHot
        if (s === "in_progress") return Colors.accent
        return Colors.outline
    }

    // Mainsail's donut buckets: completed / cancelled / interrupted / error.
    readonly property var statusSegments: {
        var c = ({ completed: 0, cancelled: 0, interrupted: 0, error: 0 })
        for (var i = 0; i < root.jobs.length; i++) {
            var s = String(root.jobs[i].status ?? "")
            if (s === "completed") c.completed++
            else if (s === "cancelled") c.cancelled++
            else if (s === "error" || s === "klippy_shutdown") c.error++
            else if (s !== "in_progress") c.interrupted++
        }
        return [
            { label: "completed", value: c.completed, color: Colors.success },
            { label: "cancelled", value: c.cancelled, color: Colors.tempWarm },
            { label: "interrupted", value: c.interrupted, color: Colors.outline },
            { label: "error", value: c.error, color: Colors.tempHot }
        ]
    }

    readonly property var chartValues: {
        var out = []
        for (var i = 0; i < root.chartRows.length; i++) {
            var j = root.chartRows[i]
            out.push(root.metric === "filament"
                ? Number(j.filament_used || 0) / 1000
                : Number(j.print_duration || 0) / 60)
        }
        return out
    }

    readonly property var chartLabels: {
        var out = []
        for (var i = 0; i < root.chartRows.length; i++) out.push(i % 2 === 0 ? String(i + 1) : "")
        return out
    }

    function cellText(j, k) {
        if (k === "start") return root.dateOf(j.start_time)
        if (k === "est") return root.dur(j?.metadata?.estimated_time)
        if (k === "print") return root.dur(j.print_duration)
        if (k === "fil") return root.meters(j.filament_used)
        if (k === "slicer") {
            var s = String(j?.metadata?.slicer ?? "")
            var sv = String(j?.metadata?.slicer_version ?? "")
            return s === "" ? "—" : (sv === "" ? s : s + " " + sv)
        }
        return ""
    }

    readonly property var cols: [
        { k: "start", label: "START TIME", w: root.cStart, sort: true },
        { k: "est", label: "EST TIME", w: root.cEst },
        { k: "print", label: "PRINT TIME", w: root.cPrint },
        { k: "fil", label: "FILAMENT USED", w: root.cFil },
        { k: "slicer", label: "SLICER", w: root.cSlicer }
    ]

    readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.panelMargin
        spacing: Metrics.panelMargin

        Panel {
            id: statsCard
            width: parent.width
            height: root.statsH
            title: "STATISTICS"; icon: Icons.chart
            collapsible: false

            Row {
                id: statBody
                anchors.left: parent.left
                anchors.leftMargin: Metrics.panelPadding
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPadding
                anchors.top: parent.top
                anchors.topMargin: parent.bodyTop
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Metrics.panelPadding
                spacing: Metrics.lg

                // Centred: the card is taller than five rows, and a top-anchored
                // list left a dead band under it. Same for the donut stack.
                Column {
                    id: kvs
                    width: 470
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Metrics.lg

                    KV { key: "Total Print Time"; labelWidth: 300;
                         value: root.dur(root.totals?.total_print_time) }
                    KV { key: "Longest Print Time"; labelWidth: 300;
                         value: root.dur(root.totals?.longest_print) }
                    KV { key: "Print Time - Ø"; labelWidth: 300;
                         value: root.durShort(Number(root.totals?.total_print_time || 0)
                             / Math.max(1, Number(root.totals?.total_jobs || 1))) }
                    KV { key: "Total Filament Used"; labelWidth: 300;
                         value: root.meters(root.totals?.total_filament_used) }
                    KV { key: "Total Jobs"; labelWidth: 300;
                         value: String(root.totals?.total_jobs ?? "—") }
                }

                Item {
                    id: donutBox
                    width: 300
                    height: statBody.height

                    Column {
                        id: donutStack
                        width: 172
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Metrics.md

                        Item {
                            width: 172
                            height: 172

                            Donut {
                                id: donut
                                anchors.fill: parent
                                segments: root.statusSegments
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: -9
                                text: String(root.statusSegments[0].value + root.statusSegments[1].value
                                    + root.statusSegments[2].value + root.statusSegments[3].value)
                                font.family: Type.family
                                font.pixelSize: Type.sizeTitle
                                font.bold: true
                                color: Colors.textPrimary
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 15
                                text: "jobs"
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: Colors.textTertiary
                            }
                        }

                        Text {
                            width: 172
                            horizontalAlignment: Text.AlignHCenter
                            text: root.jobs.length + " most recent jobs"
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            color: Colors.surfaceVariantText
                            elide: Text.ElideRight
                        }

                        Column {
                            width: 172
                            spacing: Metrics.xs

                            Repeater {
                                model: root.statusSegments
                                delegate: Row {
                                    id: lrow
                                    required property var modelData
                                    width: 172
                                    height: 18
                                    spacing: Metrics.sm

                                    Rectangle {
                                        width: 9
                                        height: 9
                                        radius: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: lrow.modelData.color
                                        opacity: lrow.modelData.value > 0 ? 1 : 0.3
                                    }
                                    Text {
                                        width: 110
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: lrow.modelData.label
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        color: Colors.surfaceVariantText
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: 41
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: String(lrow.modelData.value)
                                        font.family: Type.family
                                        font.pixelSize: Type.sizeCaption
                                        font.bold: true
                                        color: Colors.textPrimary
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: chartBox
                    width: statBody.width - kvs.width - donutBox.width - Metrics.lg * 2
                    height: statBody.height

                    Text {
                        id: chartTitle
                        // Nudged right to the plot's own left edge (past the
                        // y-axis gutter) instead of hugging the card border.
                        anchors.left: parent.left
                        anchors.leftMargin: chartBars.padL
                        anchors.top: parent.top
                        text: root.metric === "filament" ? "FILAMENT USAGE" : "PRINT TIME"
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        font.bold: true
                        color: Colors.accent
                    }

                    Row {
                        id: metricRow
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Metrics.sm

                        Button {
                            width: 150
                            height: 26
                            text: "FILAMENT USAGE"; icon: Icons.spool
                            variant: root.metric === "filament" ? "primary" : "plain"
                            onPressed: root.metric = "filament"
                        }
                        Button {
                            width: 130
                            height: 26
                            text: "PRINT TIME"; icon: Icons.clock
                            variant: root.metric === "time" ? "primary" : "plain"
                            onPressed: root.metric = "time"
                        }
                    }

                    Bars {
                        id: chartBars
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: chartTitle.bottom
                        anchors.topMargin: Metrics.sm
                        anchors.bottom: parent.bottom
                        values: root.chartValues
                        barLabels: root.chartLabels
                    }
                }
            }
        }

        Panel {
            id: histCard
            width: parent.width
            height: parent.height - root.statsH - Metrics.panelMargin
            title: "PRINT HISTORY"; icon: Icons.history
            collapsible: false

            Item {
                id: hbar
                anchors.left: parent.left
                anchors.leftMargin: Metrics.panelPadding
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPadding
                anchors.top: parent.top
                anchors.topMargin: parent.bodyTop
                height: 34

                Rectangle {
                    id: searchBox
                    width: 340
                    height: parent.height
                    radius: Metrics.radiusSmall
                    color: Colors.surfaceContainerHighest
                    border.width: Metrics.borderWidth
                    border.color: searchIn.activeFocus ? Colors.alpha(Colors.accent, 0.5) : Colors.outlineVariant

                    TextInput {
                        id: searchIn
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 30
                        verticalAlignment: Text.AlignVCenter
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        color: Colors.textPrimary
                        selectionColor: Colors.accentDim
                        selectedTextColor: Colors.textPrimary
                        clip: true
                        text: root.query
                        onTextEdited: { root.query = text; root._rebuild() }
                        onAccepted: focus = false
                        Keys.onEscapePressed: {
                            root.query = ""
                            root._rebuild()
                            focus = false
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 10
                        visible: root.query === ""
                        text: "search"
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        color: Colors.textMuted
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.search
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        color: Colors.textTertiary
                    }
                }

                Text {
                    anchors.left: searchBox.right
                    anchors.leftMargin: Metrics.md
                    anchors.right: hRefresh.left
                    anchors.rightMargin: Metrics.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.rows.length + " of " + root.jobs.length + " jobs"
                        + (root.rows.length < root.jobs.length ? " (filtered)" : "")
                    font.family: Type.family
                    font.pixelSize: root.fontPx
                    color: Colors.surfaceVariantText
                    elide: Text.ElideRight
                }

                Button {
                    id: hRefresh
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 84
                    height: 26
                    text: "REFRESH"; icon: Icons.refresh
                    variant: "soft"
                    onPressed: root.refresh()
                }
            }

            Item {
                id: hhead
                anchors.left: parent.left
                anchors.leftMargin: Metrics.panelPadding
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPadding
                anchors.top: hbar.bottom
                anchors.topMargin: Metrics.md
                height: 22

                Row {
                    x: -htable.contentX
                    width: root.contentW
                    height: parent.height
                    spacing: root.colGap

                    Item {
                        width: root.cStatus
                        height: parent.height
                    }

                    Item {
                        width: root.nameW
                        height: parent.height
                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "FILENAME" + (root.sortKey === "filename" ? (root.sortAsc ? " " + Icons.up : " " + Icons.down) : "")
                            font.family: Type.family
                            font.pixelSize: root.fontPx
                            font.bold: true
                            color: Colors.accent
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setSort("filename")
                        }
                    }

                    Repeater {
                        model: root.cols
                        delegate: Item {
                            id: hcol
                            required property var modelData
                            width: hcol.modelData.w
                            height: 22
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: hcol.modelData.k === "slicer" ? Text.AlignLeft : Text.AlignRight
                                text: hcol.modelData.label + (root.sortKey === hcol.modelData.k
                                    ? (root.sortAsc ? " " + Icons.up : " " + Icons.down) : "")
                                font.family: Type.family
                                font.pixelSize: root.fontPx
                                font.bold: true
                                color: Colors.accent
                            }
                            MouseArea {
                                anchors.fill: parent
                                visible: hcol.modelData.sort === true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setSort(hcol.modelData.k)
                            }
                        }
                    }
                }
            }

            Separator {
                id: hrule
                anchors.left: parent.left
                anchors.leftMargin: Metrics.panelPadding
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPadding
                anchors.top: hhead.bottom
                anchors.topMargin: Metrics.sm
            }

            Flickable {
                id: htable
                anchors.left: parent.left
                anchors.leftMargin: Metrics.panelPadding
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPadding
                anchors.top: hrule.bottom
                anchors.topMargin: Metrics.sm
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Metrics.panelPadding
                clip: true
                contentWidth: root.contentW
                contentHeight: hbody.height

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        var dx = event.angleDelta.x
                        var dy = event.angleDelta.y
                        if (Math.abs(dx) > Math.abs(dy) || htable.contentHeight <= htable.height)
                            htable.contentX = Math.max(0, Math.min(root.contentW - htable.width,
                                htable.contentX - (dx !== 0 ? dx : dy)))
                        else
                            htable.contentY = Math.max(0, Math.min(htable.contentHeight - htable.height,
                                htable.contentY - dy))
                        event.accepted = true
                    }
                }

                Column {
                    id: hbody
                    width: root.contentW
                    spacing: 0

                    Repeater {
                        model: root.rows
                        delegate: Item {
                            id: hrow
                            required property var modelData
                            width: hbody.width
                            height: root.rowH

                            Rectangle {
                                anchors.fill: parent
                                color: hma.containsMouse ? Colors.hoverFill : "transparent"
                            }

                            Row {
                                id: hrowInner
                                anchors.left: parent.left
                                anchors.verticalCenter: hrow.verticalCenter
                                spacing: root.colGap

                                Text {
                                    width: root.cStatus
                                    anchors.verticalCenter: hrowInner.verticalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.statusGlyph(hrow.modelData.status)
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeSmall
                                    color: root.statusColor(hrow.modelData.status)
                                }

                                Item {
                                    width: root.nameW
                                    height: hrow.height

                                    Row {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Metrics.md

                                        Rectangle {
                                            width: 34
                                            height: 34
                                            radius: Metrics.radiusSmall
                                            color: Colors.surfaceContainerHighest
                                            clip: true
                                            anchors.verticalCenter: parent.verticalCenter

                                            Image {
                                                anchors.fill: parent
                                                asynchronous: true
                                                cache: true
                                                fillMode: Image.PreserveAspectCrop
                                                source: root.moonraker.thumbSource(hrow.modelData)
                                                visible: status === Image.Ready
                                            }
                                        }

                                        Text {
                                            width: parent.width - 34 - Metrics.md
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: String(hrow.modelData.filename ?? "")
                                            font.family: Type.family
                                            font.pixelSize: root.fontPx
                                            color: hma.containsMouse ? Colors.accent : Colors.textPrimary
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                }

                                Repeater {
                                    model: root.cols
                                    delegate: Text {
                                        id: hcell
                                        required property var modelData
                                        width: hcell.modelData.w
                                        anchors.verticalCenter: hrowInner.verticalCenter
                                        horizontalAlignment: hcell.modelData.k === "slicer" ? Text.AlignLeft : Text.AlignRight
                                        text: root.cellText(hrow.modelData, hcell.modelData.k)
                                        font.family: Type.family
                                        font.pixelSize: root.fontPx
                                        color: Colors.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: hma
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Metrics.panelPadding
                anchors.top: hrule.bottom
                anchors.topMargin: Metrics.md
                visible: root.rows.length === 0
                text: root.jobs.length === 0
                    ? "no print history (fresh Moonraker, or the printer is unreachable)"
                    : "no job matches \"" + root.query + "\""
                font.family: Type.family
                font.pixelSize: Type.sizeSmall
                color: Colors.textTertiary
            }
        }
    }
}
