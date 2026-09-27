pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"

// LayerMind diagnostics: reads the daemon's per-printer context snapshot at
// ~/.local/state/layermind/<printer>.json (matching klip-tui's naming where
// "Voron V2.4" -> voron24.json). Rendered defensively — the schema lives in
// the layermind-shared crate, so we surface scalars as key/value rows and
// the first array-of-strings field as a colored diagnostic feed (color is
// a keyword guess — error/warn/ok — not a schema-declared severity).
Item {
    id: root

    required property QtObject moonraker
    property var context: null
    property bool haveFile: false
    property var rows: []

    readonly property string printer: moonraker.activePrinter

    function snapshotPath() {
        var e = Quickshell.env("HOME")
        var home = (e && e !== "null") ? e : ""
        var stem = root.printer.toLowerCase().replace(/[^a-z0-9]/g, "")
        return home + "/.local/state/layermind/" + stem + ".json"
    }

    function refresh() { root._read() }

    function _read() {
        if (!root.printer) return
        var safe = root.snapshotPath().replace(/'/g, "'\\''")
        proc.command = ["bash", "-c", "cat '" + safe + "' 2>/dev/null || echo '{}'"]
        proc.running = false
        proc.running = true
    }

    property var proc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                root.haveFile = t !== "" && t !== "{}" && t !== "null"
                try {
                    root.context = JSON.parse(t)
                } catch (e) {
                    root.context = null
                    root.haveFile = false
                }
                root.render()
            }
        }
    }

    // Keyword guess only — LayerMind's schema doesn't declare a severity
    // field, so this reads the message text itself. Falls back to the
    // neutral text color for anything it doesn't recognize.
    function _lineColor(s) {
        var t = String(s).toLowerCase()
        if (t.indexOf("error") >= 0 || t.indexOf("fail") >= 0 || t.indexOf("critical") >= 0) return Colors.error
        if (t.indexOf("warn") >= 0 || t.indexOf("caution") >= 0 || t.indexOf("clog") >= 0) return Colors.tempWarm
        if (t.indexOf(" ok") >= 0 || t.indexOf("pass") >= 0 || t.indexOf("good") >= 0 || t.indexOf("complete") >= 0) return Colors.success
        return Colors.textPrimary
    }

    function render() {
        var out = []
        var c = root.context
        if (!c) { root.rows = out; return }
        for (var k in c) {
            var v = c[k]
            if (k === "type" || k === "schema") continue
            if (typeof v === "string" || typeof v === "number") {
                out.push({ kind: "kv", key: k, value: String(v) })
            }
        }
        var listKey = ""
        for (var kk in c) {
            var vv = c[kk]
            if (Array.isArray(vv) && vv.length > 0 && typeof vv[0] === "string") {
                listKey = kk
                break
            }
        }
        if (listKey !== "") {
            var arr = c[listKey]
            for (var i = 0; i < arr.length; i++) {
                var s = String(arr[i])
                var clean = s.charAt(0) === "-" ? s.slice(1).trim() : s
                out.push({ kind: "line", text: clean, color: root._lineColor(s) })
            }
        }
        root.rows = out
    }

    property var reTimer: Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: { if (root.visible) root._read() }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Metrics.panelMargin

        Card {
            width: parent.width
            height: parent.height
            header: Icons.layermind + " LAYERMIND · DIAGNOSTICS"

            Column {
                anchors.left: parent.left
                anchors.leftMargin: Metrics.panelPadding
                anchors.right: parent.right
                anchors.rightMargin: Metrics.panelPadding
                anchors.top: parent.top
                anchors.topMargin: Metrics.panelPadding + 6
                spacing: Metrics.md

                Row {
                    width: parent.width
                    spacing: Metrics.sm
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.haveFile ? Colors.success : Colors.outlineVariant
                    }
                    Text {
                        text: root.printer || "no active printer"
                        font.family: Type.family
                        font.pixelSize: Type.sizeSmall
                        font.bold: true
                        color: Colors.textPrimary
                    }
                    Text {
                        text: root.haveFile ? "· snapshot live" : "· no snapshot"
                        font.family: Type.family
                        font.pixelSize: Type.sizeSmall
                        color: Colors.surfaceVariantText
                    }
                }

                Separator { visible: root.haveFile }

                Item {
                    visible: !root.haveFile
                    width: parent.width
                    height: 90
                    Rectangle {
                        anchors.fill: parent
                        radius: Metrics.radiusSmall
                        color: Colors.surfaceContainerLow
                        border.width: Metrics.borderWidth
                        border.color: Colors.outlineVariant
                    }
                    Text {
                        anchors.fill: parent
                        anchors.margins: Metrics.md
                        text: root.printer
                            ? "No LayerMind snapshot for '" + root.printer + "'\nExpected at:\n    "
                                + root.snapshotPath() + "\nStart the daemon and re-read with Enter."
                            : "No active printer."
                        font.family: Type.family
                        font.pixelSize: Type.sizeBody
                        color: Colors.surfaceVariantText
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                    }
                }

                Repeater {
                    model: root.rows
                    delegate: Item {
                        id: rowItem
                        required property var modelData
                        width: parent ? parent.width : 0
                        height: rowItem.modelData.kind === "line" ? 26 : 22

                        Row {
                            visible: rowItem.modelData.kind === "kv"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Metrics.sm
                            Text {
                                width: 160
                                text: rowItem.modelData.key ?? ""
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                color: Colors.surfaceVariantText
                            }
                            Text {
                                width: Math.max(60, (rowItem.width || 0) - 160 - Metrics.sm)
                                text: rowItem.modelData.value ?? ""
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                font.bold: true
                                color: Colors.textPrimary
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: rowItem.modelData.kind === "line"
                            anchors.fill: parent
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            radius: Metrics.radiusSmall
                            color: Colors.alpha(rowItem.modelData.color, 0.08)
                        }
                        Row {
                            visible: rowItem.modelData.kind === "line"
                            anchors.left: parent.left
                            anchors.leftMargin: Metrics.sm
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Metrics.sm
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: rowItem.modelData.color
                            }
                            Text {
                                width: (rowItem.width || 0) - Metrics.sm * 2 - 6 - Metrics.panelPadding * 2
                                text: rowItem.modelData.text ?? ""
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                color: rowItem.modelData.color
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
