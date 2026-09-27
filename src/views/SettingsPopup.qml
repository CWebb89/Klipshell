pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "../config"

// Global settings popup (opened from the sidebar gear). Tabbed so more
// sections can be added later; today: Printers, Appearance, Presets, Jog,
// Macros, Print.
// Printer list edits persist through the service; preset edits keep the shared
// win.presetStore; everything else is the Settings singleton
// (~/.local/state/klipshell/settings.json). Inline text fields use the
// console-style key capture: click a field, type, Enter commits, Tab/click
// moves focus, Esc drops it. While opened, the MainWindow key catcher routes
// keys here.
Item {
    id: root

    required property QtObject moonraker
    required property QtObject presetStore
    property bool opened: false
    signal closed
    property int tab: 0
    readonly property var tabs: ["PRINTERS", "INTERFACE", "PRESETS", "JOG", "MACROS", "PRINT"]

    readonly property var ps: root.moonraker.active
    readonly property var cfg: (function() {
        for (var i = 0; i < root.moonraker.printers.length; i++)
            if (root.moonraker.printers[i].name === root.moonraker.activePrinter)
                return root.moonraker.printers[i]
        return null
    })()

    // Every macro the printer reports — Settings chooses which of these the
    // dashboard card shows and in what order. The service mutates its `data`
    // map in place (no change signal on a var), so this is copied on the bucket
    // signal rather than bound, exactly like the dashboard does.
    property var allMacros: []
    Connections {
        target: root.moonraker
        function onBucketChanged(bucket) {
            if (bucket === "macros") root.allMacros = root.moonraker.data?.macros ?? []
        }
    }
    Component.onCompleted: root.allMacros = root.moonraker.data?.macros ?? []

    // One field per editable value, addressed by index. 0/1 are the
    // add-printer name and host, 2..5 the jog steps and bed feedrates, 6 the
    // API key of `keyPrinter`.
    property var inputs: ["", "", "", "", "", "", ""]
    property int inputFocus: -1
    // Field index whose last commit was rejected, so it can be shown in error
    // colours instead of silently keeping the old value.
    property int invalid: -1
    // Printer whose API key the inline editor is open for ("" = closed).
    property string keyPrinter: ""
    // Printer name -> "…" | "ok" | failure text, from the TEST button.
    property var testState: ({})
    property int editing: -1
    property string editName: ""
    property string hoverRole: ""
    // The dashboard owns layout mode (its dialog, its dashboard.json); this popup
    // only asks for it to be opened.
    signal layoutRequested()
    signal resetRequested()
    readonly property bool printerReady: String(root.inputs[0] || "").trim() !== ""
        && String(root.inputs[1] || "").trim() !== ""

    visible: root.opened
    onOpenedChanged: {
        if (root.opened) {
            // Fill in what is stored right away: a field that only fills in on
            // focus reads as an empty box.
            for (var i = 2; i <= 5; i++) root.setInput(i, root.seedInput(i))
            return
        }
        root.inputFocus = -1
        root.invalid = -1
        root.keyPrinter = ""
        // Drop half-typed drafts so reopening never shows a stale value.
        root.inputs = ["", "", "", "", "", "", ""]
        root.editing = -1
    }

    // A reset (or any edit made from somewhere else) must not leave the jog
    // fields showing pre-reset values — Enter in one of them would write the old
    // number straight back. The focused field is left alone: it is mid-edit.
    Connections {
        target: Settings
        function onDataChanged() {
            for (var i = 2; i <= 5; i++)
                if (root.inputFocus !== i) root.setInput(i, root.seedInput(i))
        }
    }

    function maskHost(h) {
        var s = String(h || "")
        if (!Settings.maskIps) return s
        return s.length > 0 ? Array(s.length + 1).join("•") : "—"
    }
    function startEdit(i) {
        if (i < 0 || i >= root.presetStore.presets.length) return
        root.editing = i
        root.editName = String(root.presetStore.presets[i].name)
    }
    function commitName() {
        var n = root.editName.trim()
        if (n !== "" && root.editing >= 0) root.presetStore.update(root.editing, { name: n })
        root.editing = -1
    }
    function backspace() {
        var i = root.inputFocus
        if (i < 0) return
        root.invalid = -1
        root.setInput(i, String(root.inputs[i] || "").slice(0, -1))
    }
    function commitPrinter() {
        var n = String(root.inputs[0] || "").trim()
        var h = String(root.inputs[1] || "").trim()
        if (n === "" || h === "") return
        root.moonraker.addPrinter(n, h, 7125)
        root.setInput(0, "")
        root.setInput(1, "")
    }

    // ── Inline fields (indexed) ────────────────────────────────────────
    // Jog and key fields open seeded with the stored value so it can be edited
    // in place; the add-printer fields keep whatever is already typed.
    function seedInput(i) {
        if (i === 2) return Settings.toolheadSteps.join(", ")
        if (i === 3) return Settings.extruderSteps.join(", ")
        if (i === 4) return String(Settings.bedXYRate)
        if (i === 5) return String(Settings.bedZRate)
        if (i === 6) return Settings.apiKey(root.keyPrinter)
        return ""
    }
    // Copy-on-write: `inputs` is a var property, so assigning a fresh array is
    // what re-evaluates the field bindings.
    function setInput(i, v) {
        var a = root.inputs.slice()
        a[i] = v
        root.inputs = a
    }
    function focusInput(i) {
        root.invalid = -1
        root.inputFocus = i
        if (i >= 2 && String(root.inputs[i] || "") === "") root.setInput(i, root.seedInput(i))
    }
    function inputText(i, placeholder) {
        var v = String(root.inputs[i] || "")
        if (v !== "") return v + (root.inputFocus === i ? "▌" : "")
        return root.inputFocus === i ? placeholder + "▌" : placeholder
    }
    // Which fields Tab cycles through on the current tab.
    function tabFields() {
        if (root.tab === 0) return root.keyPrinter !== "" ? [0, 1, 6] : [0, 1]
        if (root.tab === 3) return [2, 3, 4, 5]
        return []
    }
    // Enter. A value that does not parse marks the field rather than quietly
    // keeping the old one.
    function commitInput() {
        var i = root.inputFocus
        if (i === 0 || i === 1) { root.commitPrinter(); root.inputFocus = 0; return }
        if (i === 2 || i === 3) {
            if (Settings.setSteps(i === 2 ? "toolhead" : "extruder", root.inputs[i])) root.setInput(i, root.seedInput(i))
            else root.invalid = i
        } else if (i === 4 || i === 5) {
            if (Settings.setRate(i === 4 ? "bedXY" : "bedZ", root.inputs[i])) root.setInput(i, root.seedInput(i))
            else root.invalid = i
        } else if (i === 6) {
            Settings.setApiKey(root.keyPrinter, String(root.inputs[i] || "").trim())
            root.setInput(i, "")
            root.keyPrinter = ""
        }
        root.inputFocus = -1
    }
    function nextField() {
        var f = root.tabFields()
        var at = f.indexOf(root.inputFocus)
        if (at < 0) return
        var next = f[(at + 1) % f.length]
        root.commitInput()
        root.focusInput(next)
    }

    // ── Printers: test / default / API key ─────────────────────────────
    // /server/info is the cheapest endpoint that proves host, port and — when
    // one is stored — the API key all work.
    function testPrinter(name) {
        var s = Object.assign({}, root.testState)
        s[String(name)] = "…"
        root.testState = s
        root.moonraker.testPrinter(String(name), function(ok, msg) {
            var t = Object.assign({}, root.testState)
            t[String(name)] = ok ? "ok" : msg
            root.testState = t
        })
    }
    function isDefault(name) {
        return Settings.defaultPrinter === String(name)
    }
    // The API key field exists only while `keyPrinter` is set, and it is focused
    // when it opens — this is what it shows once focus moves elsewhere.
    function maskedKey() {
        var k = String(root.inputs[6] || "")
        if (k !== "") return Array(k.length + 1).join("•") + "  (" + k.length + " chars)"
        return Settings.apiKey(root.keyPrinter) === "" ? "no key stored" : "key stored — click to edit"
    }
    function openKey(name) {
        root.keyPrinter = String(name)
        // Clear first so focusInput() re-seeds from THIS printer's key rather
        // than leaving the previously edited printer's key in the field.
        root.setInput(6, "")
        root.focusInput(6)
    }

    // ── Print confirmations ────────────────────────────────────────────
    function confirmFlag(key) {
        if (key === "start") return Settings.confirmStart
        if (key === "cancel") return Settings.confirmCancel
        return Settings.confirmEStop
    }
    function handleKey(event) {
        if (root.inputFocus >= 0) {
            if (event.key === Qt.Key_Escape) {
                if (root.inputFocus >= 2) root.setInput(root.inputFocus, "")
                root.invalid = -1
                root.inputFocus = -1
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.commitInput()
                event.accepted = true
            } else if (event.key === Qt.Key_Tab) {
                root.nextField()
                event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                root.backspace()
                event.accepted = true
            } else if (event.text && event.text.length === 1
                       && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
                root.invalid = -1
                root.setInput(root.inputFocus, String(root.inputs[root.inputFocus] || "") + event.text)
                event.accepted = true
            }
            return
        }
        if (root.editing < 0) {
            // Digits only arrive here when no field holds focus, so typing a jog
            // step never switches tabs underneath the caret.
            if (event.key >= Qt.Key_1 && event.key < Qt.Key_1 + root.tabs.length) {
                root.tab = event.key - Qt.Key_1
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                var step = event.key === Qt.Key_Right ? 1 : root.tabs.length - 1
                root.tab = (root.tab + step) % root.tabs.length
                event.accepted = true
            }
            return
        }
        if (event.key === Qt.Key_Escape) {
            root.editing = -1
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.commitName()
            event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            root.editName = root.editName.slice(0, -1)
            event.accepted = true
        } else if (event.text && event.text.length === 1
                   && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.editName += event.text
            event.accepted = true
        }
    }

    // One row of mutually exclusive choices — the shell knobs. `values` is what
    // the setting stores, `labels` captions each chip. Inline rather than its own
    // file: three uses, all in this popup.
    component OptRow: Row {
        id: optRow
        property string label: ""
        property var values: []
        property var labels: []
        property var current
        signal picked(var value)

        width: parent ? parent.width : 0
        height: Metrics.controlHeight
        spacing: Metrics.sm

        Text {
            width: 156
            text: optRow.label
            font.family: Type.family
            font.pixelSize: Type.sizeCaption
            font.bold: true
            font.letterSpacing: 1.0
            color: Colors.surfaceVariantText
            verticalAlignment: Text.AlignVCenter
        }
        Repeater {
            model: optRow.values
            delegate: Button {
                required property int index
                required property var modelData
                width: 72
                height: Metrics.controlHeight
                text: String(optRow.labels[index] !== undefined ? optRow.labels[index] : modelData)
                variant: optRow.current === modelData ? "primary" : "plain"
                onPressed: optRow.picked(modelData)
            }
        }
    }

    // ── Modal click-away (transparent) ─────────────────────────────────
    // hoverEnabled matters: without it hover passes straight through to the
    // cards behind the scrim and they light up under the popup.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            onClicked: root.closed()
        }
    }

    // ── Card geometry ──────────────────────────────────────────────────
    // The card is as tall as the open tab needs: 46 header + 38 tabs + 1 rule,
    // then that tab's own content, capped so PRINTERS stays a window rather
    // than a wall. Both the box and the body read this one property, so the
    // content follows the resize instead of snapping while the box eases.
    readonly property int chromeH: 46 + 38 + 1
    readonly property int maxContentH: 460
    readonly property var tabCols: [pcol, acol, rs2col, jcol, mcol, printcol]
    readonly property var activeCol: root.tabCols[root.tab] ?? null
    readonly property int contentH: (root.activeCol ? root.activeCol.implicitHeight : 0)
        + Metrics.panelMargin * 2
    property real cardHeight: root.chromeH + Math.min(root.contentH, root.maxContentH)
    Behavior on cardHeight {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    // ── Card ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width: 720
        height: root.cardHeight
        radius: 0
        color: Colors.surfaceContainerHigh
        border.width: Metrics.cardBorderWidth
        border.color: Colors.outline

        Column {
            anchors.fill: parent
            spacing: 0

            // Header
            Item {
                width: parent.width
                height: 46
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Metrics.panelPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.settings + " GLOBAL SETTINGS"
                    font.family: Type.family
                    font.pixelSize: Type.sizeCaption
                    font.bold: true
                    font.letterSpacing: 1.0
                    color: Colors.textTertiary
                }
                Button {
                    anchors.right: parent.right
                    anchors.rightMargin: Metrics.sm
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 28
                    text: Icons.close
                    variant: "plain"
                    onPressed: root.closed()
                }
            }

            // Tabs
            Row {
                width: parent.width
                height: 38
                spacing: Metrics.sm
                leftPadding: Metrics.panelPadding
                rightPadding: Metrics.panelPadding

                Repeater {
                    model: root.tabs
                    delegate: Item {
                        id: trow
                        required property var modelData
                        required property int index
                        width: 106
                        height: parent.height
                        Rectangle {
                            anchors.fill: parent
                            radius: Metrics.radiusSmall
                            color: root.tab === trow.index ? Colors.selectedFill : "transparent"
                            border.width: root.tab === trow.index ? Metrics.borderWidth : 0
                            border.color: Colors.alpha(Colors.accent, 0.5)
                        }
                        Text {
                            anchors.centerIn: parent
                            text: trow.modelData
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            font.bold: true
                            font.letterSpacing: 1.0
                            color: root.tab === trow.index ? Colors.accent : Colors.surfaceVariantText
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = trow.index
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Colors.separator }

            // ── PRINTERS ────────────────────────────────────────────────
            Flickable {
                visible: root.tab === 0
                width: parent.width
                height: root.cardHeight - root.chromeH
                clip: true
                contentWidth: width
                contentHeight: pcol.implicitHeight + Metrics.panelMargin * 2

                Column {
                    id: pcol
                    x: Metrics.panelMargin
                    y: Metrics.panelMargin
                    width: parent.width - Metrics.panelMargin * 2
                    spacing: Metrics.md

                    Row {
                        width: parent.width
                        spacing: Metrics.sm
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.ps?.connected ? Colors.success : Colors.outlineVariant
                        }
                        Text {
                            width: parent.width - 80
                            text: root.moonraker.activePrinter !== ""
                                ? root.moonraker.activePrinter : "no printer selected"
                            font.family: Type.family
                            font.pixelSize: Type.sizeSmall
                            font.bold: true
                            color: root.ps?.connected ? Colors.accent
                                : (root.moonraker.activePrinter !== "" ? Colors.textPrimary : Colors.outlineVariant)
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Item {
                            width: 60
                            height: parent.height
                            Text {
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                text: root.ps?.connected ? "online" : "offline"
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                color: root.ps?.connected ? Colors.success : Colors.outlineVariant
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Repeater {
                        width: parent.width
                        model: root.moonraker.printers
                        delegate: Item {
                            id: crow
                            required property var modelData
                            required property int index
                            width: parent.width
                            height: 38
                            Rectangle {
                                anchors.fill: parent
                                radius: Metrics.radiusSmall
                                color: String(crow.modelData.name) === root.moonraker.activePrinter ? Colors.selectedFill
                                     : (pmrow.containsMouse ? Colors.hoverFill : "transparent")
                            }
                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 226
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Metrics.sm
                                Rectangle {
                                    width: 7
                                    height: 7
                                    radius: 3.5
                                    color: String(crow.modelData.name) === root.moonraker.activePrinter
                                        ? Colors.accent : Colors.outlineVariant
                                }
                                Text {
                                    width: parent.width - 7 - Metrics.sm
                                    text: String(crow.modelData.name)
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeSmall
                                    font.bold: true
                                    color: String(crow.modelData.name) === root.moonraker.activePrinter
                                        ? Colors.accent : Colors.textPrimary
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 38
                                anchors.verticalCenter: parent.verticalCenter
                                width: 180
                                text: root.maskHost(crow.modelData.host)
                                    + (Number(crow.modelData.port) > 0 && Number(crow.modelData.port) !== 7125
                                        ? " :" + String(crow.modelData.port) : "")
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                color: Colors.surfaceVariantText
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                            }
                            Button {
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 26
                                text: Icons.close
                                variant: "plain"
                                onPressed: root.moonraker.removePrinter(crow.index)
                            }
                            MouseArea {
                                id: pmrow
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.moonraker.selectPrinter(String(crow.modelData.name))
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Colors.separator }

                    Row {
                        width: parent.width
                        height: 38
                        spacing: Metrics.sm

                        Item {
                            width: 170
                            height: parent.height
                            Rectangle {
                                anchors.fill: parent
                                radius: Metrics.radiusSmall
                                color: root.inputFocus === 0 ? Colors.alpha(Colors.accent, 0.10) : "transparent"
                                border.width: Metrics.borderWidth
                                border.color: root.invalid === 0 ? Colors.error
                                    : (root.inputFocus === 0 ? Colors.accent : Colors.outlineVariant)
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.inputText(0, "name")
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: String(root.inputs[0] || "") !== "" ? Colors.textPrimary : Colors.outlineVariant
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                hoverEnabled: true
                                cursorShape: Qt.IBeamCursor
                                onClicked: root.focusInput(0)
                            }
                        }
                        Item {
                            width: 250
                            height: parent.height
                            Rectangle {
                                anchors.fill: parent
                                radius: Metrics.radiusSmall
                                color: root.inputFocus === 1 ? Colors.alpha(Colors.accent, 0.10) : "transparent"
                                border.width: Metrics.borderWidth
                                border.color: root.invalid === 1 ? Colors.error
                                    : (root.inputFocus === 1 ? Colors.accent : Colors.outlineVariant)
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.inputText(1, "10.0.0.3 · 7125")
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: String(root.inputs[1] || "") !== "" ? Colors.textPrimary : Colors.outlineVariant
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                hoverEnabled: true
                                cursorShape: Qt.IBeamCursor
                                onClicked: root.focusInput(1)
                            }
                        }
                        Button {
                            width: 96
                            height: parent.height
                            text: "ADD"; icon: Icons.plus
                            variant: root.printerReady ? "primary" : "soft"
                            active: root.printerReady
                            onPressed: root.commitPrinter()
                        }
                    }

                    // Test, default and API key all act on the printer the app is
                    // actually talking to — three more buttons on every list row
                    // would not fit in this width.
                    Row {
                        width: parent.width
                        height: Metrics.controlHeight
                        spacing: Metrics.sm
                        Text {
                            width: 140
                            text: "ACTIVE PRINTER"
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            font.bold: true
                            font.letterSpacing: 1.0
                            color: Colors.surfaceVariantText
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            width: parent.width - 140 - 90 - 67 - 58 - 94 - Metrics.sm * 5
                            text: root.moonraker.activePrinter !== "" ? root.moonraker.activePrinter : "none"
                            font.family: Type.family
                            font.pixelSize: Type.sizeSmall
                            font.bold: true
                            color: Colors.textPrimary
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            width: 90
                            text: root.testState[String(root.moonraker.activePrinter)] || ""
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            font.bold: true
                            color: root.testState[String(root.moonraker.activePrinter)] === "ok"
                                ? Colors.success : Colors.error
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Button {
                            width: 67
                            height: Metrics.controlHeight
                            text: "TEST"
                            variant: "plain"
                            active: root.moonraker.activePrinter !== ""
                            onPressed: root.testPrinter(root.moonraker.activePrinter)
                        }
                        Button {
                            width: 58
                            height: Metrics.controlHeight
                            text: "KEY"
                            variant: Settings.apiKey(root.moonraker.activePrinter) !== "" ? "soft" : "plain"
                            active: root.moonraker.activePrinter !== ""
                            onPressed: root.openKey(root.moonraker.activePrinter)
                        }
                        Button {
                            width: 94
                            height: Metrics.controlHeight
                            text: "DEFAULT"
                            variant: root.isDefault(root.moonraker.activePrinter) ? "primary" : "plain"
                            active: root.moonraker.activePrinter !== ""
                            onPressed: Settings.setDefaultPrinter(root.moonraker.activePrinter)
                        }
                    }

                    // Opened by KEY. Enter saves, Esc drops it; the value is
                    // masked again as soon as the field loses focus. Clearing
                    // the field and pressing Enter removes the key.
                    Row {
                        visible: root.keyPrinter !== ""
                        width: parent.width
                        height: Metrics.controlHeight
                        spacing: Metrics.sm
                        Text {
                            width: 140
                            text: "API KEY"
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            font.bold: true
                            font.letterSpacing: 1.0
                            color: Colors.surfaceVariantText
                            verticalAlignment: Text.AlignVCenter
                        }
                        Item {
                            width: parent.width - 140 - Metrics.sm
                            height: parent.height
                            Rectangle {
                                anchors.fill: parent
                                radius: Metrics.radiusSmall
                                color: root.inputFocus === 6 ? Colors.alpha(Colors.accent, 0.10) : "transparent"
                                border.width: Metrics.borderWidth
                                border.color: root.inputFocus === 6 ? Colors.accent : Colors.outlineVariant
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.inputFocus === 6 ? root.inputText(6, "paste the Moonraker API key")
                                                            : root.maskedKey()
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: Colors.textPrimary
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                hoverEnabled: true
                                cursorShape: Qt.IBeamCursor
                                onClicked: root.focusInput(6)
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Metrics.sm
                        Button {
                            width: 108
                            height: Metrics.controlHeight
                            text: Settings.maskIps ? "SHOW IP" : "MASK IP"; icon: Icons.eye
                            variant: Settings.maskIps ? "soft" : "plain"
                            onPressed: Settings.setMaskIps(!Settings.maskIps)
                        }
                        Text {
                            width: parent.width - 116
                            text: "IPs are " + (Settings.maskIps ? "masked" : "visible")
                            font.family: Type.family
                            font.pixelSize: Type.sizeSmall
                            color: Colors.outlineVariant
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // ── INTERFACE ───────────────────────────────────────────────
            Flickable {
                visible: root.tab === 1
                width: parent.width
                height: root.cardHeight - root.chromeH
                clip: true
                contentWidth: width
                contentHeight: acol.implicitHeight + Metrics.panelMargin * 2

                Column {
                    id: acol
                    x: Metrics.panelMargin
                    y: Metrics.panelMargin
                    width: parent.width - Metrics.panelMargin * 2
                    spacing: Metrics.md

                    KV { key: "theme"; labelWidth: 140; value: "matugen · tonal-spot" }
                    KV { key: "font"; labelWidth: 140; value: Type.family }
                    KV {
                        key: "printer"; labelWidth: 140
                        value: root.moonraker.activePrinter !== "" ? root.moonraker.activePrinter : "none"
                    }
                    KV {
                        key: "endpoint"; labelWidth: 140
                        value: root.cfg ? root.maskHost(root.cfg.host) + (Number(root.cfg.port) > 0
                            ? " :" + Number(root.cfg.port) : "") : "—"
                    }
                    KV { key: "klipper"; labelWidth: 140; value: root.ps?.softwareVersion || "—" }
                    KV {
                        key: "klippy"; labelWidth: 140
                        value: String(root.ps?.klippyState || "—")
                        valueColor: root.ps?.klippyState === "ready" ? Colors.success
                            : (root.ps?.klippyState ? Colors.error : Colors.textPrimary)
                    }

                    Rectangle { width: parent.width; height: 1; color: Colors.separator }

                    Row {
                        width: parent.width
                        height: 30
                        spacing: 8
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "surface", "surfaceContainerLow", "error", "outlineVariant"]
                            delegate: Item {
                                id: swatch
                                required property var modelData
                                width: 34
                                height: 24
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Metrics.radiusSmall
                                    color: Colors[swatch.modelData]
                                    border.width: Metrics.borderWidth
                                    border.color: ma.containsMouse ? Colors.textPrimary : Colors.outlineVariant
                                }
                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onHoveredChanged: {
                                        root.hoverRole = ma.containsMouse ? String(swatch.modelData)
                                            : (root.hoverRole === String(swatch.modelData) ? "" : root.hoverRole)
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        text: root.hoverRole !== "" ? "role: " + root.hoverRole : "hover a swatch for the role name"
                        font.family: Type.family
                        font.pixelSize: Type.sizeSmall
                        color: root.hoverRole !== "" ? Colors.textPrimary : Colors.outlineVariant
                    }

                    Rectangle { width: parent.width; height: 1; color: Colors.separator }

                    OptRow {
                        label: "TEMPERATURE"
                        values: ["C", "F"]
                        labels: ["°C", "°F"]
                        current: Settings.tempUnit
                        onPicked: function(v) { Settings.setUnit("temp", v) }
                    }
                    OptRow {
                        label: "LENGTH"
                        values: ["mm", "in"]
                        current: Settings.lengthUnit
                        onPicked: function(v) { Settings.setUnit("length", v) }
                    }
                    Row {
                        width: parent.width
                        height: Metrics.controlHeight
                        spacing: Metrics.sm
                        Text {
                            width: 140
                            text: "LAYOUT"
                            font.family: Type.family
                            font.pixelSize: Type.sizeCaption
                            font.bold: true
                            font.letterSpacing: 1.0
                            color: Colors.surfaceVariantText
                            verticalAlignment: Text.AlignVCenter
                        }
                        Button {
                            width: 72
                            height: Metrics.controlHeight
                            text: "OPEN"
                            variant: "plain"
                            onPressed: root.layoutRequested()
                        }
                    }
                    OptRow {
                        label: "POLL CADENCE"
                        values: [500, 1000, 2000, 5000]
                        labels: ["0.5s", "1s", "2s", "5s"]
                        current: Settings.pollMs
                        onPicked: function(v) { Settings.setShell("pollMs", v) }
                    }
                    OptRow {
                        label: "CONSOLE LINES"
                        values: [40, 80, 160, 320]
                        current: Settings.consoleLines
                        onPicked: function(v) { Settings.setShell("consoleLines", v) }
                    }
                    OptRow {
                        label: "NOTIFICATION CAP"
                        values: [20, 50, 100, 200]
                        current: Settings.notifCap
                        onPicked: function(v) { Settings.setShell("notifCap", v) }
                    }
                }
            }

            // ── PRESETS ─────────────────────────────────────────────────
            Flickable {
                visible: root.tab === 2
                width: parent.width
                height: root.cardHeight - root.chromeH
                clip: true
                contentWidth: width
                contentHeight: rs2col.implicitHeight + Metrics.panelMargin * 2

                Column {
                    id: rs2col
                    x: Metrics.panelMargin
                    y: Metrics.panelMargin
                    width: parent.width - Metrics.panelMargin * 2
                    spacing: Metrics.md

                    Repeater {
                        width: parent.width
                        model: root.presetStore.presets
                        delegate: Row {
                            id: prow
                            required property var modelData
                            required property int index
                            width: parent ? parent.width : 0
                            height: Metrics.controlHeight
                            spacing: Metrics.sm

                            Item {
                                width: 142
                                height: parent.height
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Metrics.radiusSmall
                                    color: root.editing === prow.index ? Colors.alpha(Colors.accent, 0.12) : "transparent"
                                    border.width: root.editing === prow.index ? 1 : Metrics.borderWidth
                                    border.color: root.editing === prow.index ? Colors.accent : Colors.outlineVariant
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.editing === prow.index ? "> " + root.editName + "▌" : String(prow.modelData.name)
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeSmall
                                    font.bold: true
                                    color: root.editing === prow.index ? Colors.accent : Colors.textPrimary
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    hoverEnabled: true
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: root.startEdit(prow.index)
                                }
                            }
                            Button {
                                text: Icons.up; variant: "plain"; width: 34; height: parent.height
                                active: prow.index > 0
                                onPressed: root.presetStore.move(prow.index, -1)
                            }
                            Button {
                                text: Icons.down; variant: "plain"; width: 34; height: parent.height
                                active: prow.index < root.presetStore.presets.length - 1
                                onPressed: root.presetStore.move(prow.index, 1)
                            }
                            Text {
                                width: 58
                                text: "HOTEND"
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: Colors.textSecondary
                                verticalAlignment: Text.AlignVCenter
                            }
                            Button { text: Icons.minus; variant: "plain"; width: 26; height: parent.height
                                     onPressed: root.presetStore.update(prow.index, { ext: Number(prow.modelData.ext) - 5 }) }
                            Text {
                                width: 44
                                text: Settings.tempText(prow.modelData.ext, 0)
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                font.bold: true
                                color: Colors.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            Button { text: Icons.plus; variant: "plain"; width: 26; height: parent.height
                                     onPressed: root.presetStore.update(prow.index, { ext: Number(prow.modelData.ext) + 5 }) }
                            Text {
                                width: 38
                                text: "BED"
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: Colors.textSecondary
                                verticalAlignment: Text.AlignVCenter
                            }
                            Button { text: Icons.minus; variant: "plain"; width: 26; height: parent.height
                                     onPressed: root.presetStore.update(prow.index, { bed: Number(prow.modelData.bed) - 5 }) }
                            Text {
                                width: 44
                                text: Settings.tempText(prow.modelData.bed, 0)
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                font.bold: true
                                color: Colors.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            Button { text: Icons.plus; variant: "plain"; width: 26; height: parent.height
                                     onPressed: root.presetStore.update(prow.index, { bed: Number(prow.modelData.bed) + 5 }) }
                            Button {
                                text: prow.modelData.visible ? "HIDE" : "SHOW"
                                variant: prow.modelData.visible ? "plain" : "soft"
                                width: 56
                                height: parent.height
                                onPressed: { root.presetStore.update(prow.index, { visible: !prow.modelData.visible }) }
                            }
                            Button { text: Icons.close; variant: "plain"; width: 40; height: parent.height
                                     onPressed: root.presetStore.remove(prow.index) }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Colors.separator }

                    Row {
                        width: parent.width
                        height: Metrics.controlHeight
                        spacing: Metrics.sm
                        Button { text: "ADD PRESET"; icon: Icons.plus; variant: "primary"; height: Metrics.controlHeight;
                                 onPressed: root.presetStore.add("NEW PRESET", 200, 60) }
                    }
                }
            }

            // ── JOG ────────────────────────────────────────────────────
            Flickable {
                visible: root.tab === 3
                width: parent.width
                height: root.cardHeight - root.chromeH
                clip: true
                contentWidth: width
                contentHeight: jcol.implicitHeight + Metrics.panelMargin * 2

                Column {
                    id: jcol
                    x: Metrics.panelMargin
                    y: Metrics.panelMargin
                    width: parent.width - Metrics.panelMargin * 2
                    spacing: Metrics.md

                    Text {
                        width: parent.width
                        text: "Chip steps for the toolhead and extruder, and the feedrates the BED move buttons use."
                        font.family: Type.family
                        font.pixelSize: Type.sizeSmall
                        color: Colors.surfaceVariantText
                        wrapMode: Text.Wrap
                    }

                    Repeater {
                        model: [
                            { i: 2, label: "TOOLHEAD STEPS" },
                            { i: 3, label: "EXTRUDER STEPS" },
                            { i: 4, label: "BED X/Y FEED" },
                            { i: 5, label: "BED Z FEED" }
                        ]
                        delegate: Row {
                            id: jogrow
                            required property var modelData
                            width: parent ? parent.width : 0
                            height: Metrics.controlHeight
                            spacing: Metrics.sm
                            Text {
                                width: 150
                                text: jogrow.modelData.label
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: Colors.surfaceVariantText
                                verticalAlignment: Text.AlignVCenter
                            }
                            Item {
                                width: parent.width - 150 - Metrics.sm
                                height: parent.height
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Metrics.radiusSmall
                                    color: root.inputFocus === jogrow.modelData.i ? Colors.alpha(Colors.accent, 0.10) : "transparent"
                                    border.width: Metrics.borderWidth
                                    border.color: root.invalid === jogrow.modelData.i ? Colors.error
                                        : (root.inputFocus === jogrow.modelData.i ? Colors.accent : Colors.outlineVariant)
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.inputText(jogrow.modelData.i, "")
                                    font.family: Type.family
                                    font.pixelSize: Type.sizeCaption
                                    color: Colors.textPrimary
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    hoverEnabled: true
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: root.focusInput(jogrow.modelData.i)
                                }
                            }
                        }
                    }
                }
            }

            // ── MACROS ─────────────────────────────────────────────────
            Flickable {
                visible: root.tab === 4
                width: parent.width
                height: root.cardHeight - root.chromeH
                clip: true
                contentWidth: width
                contentHeight: mcol.implicitHeight + Metrics.panelMargin * 2

                Column {
                    id: mcol
                    x: Metrics.panelMargin
                    y: Metrics.panelMargin
                    width: parent.width - Metrics.panelMargin * 2
                    spacing: Metrics.md

                    Text {
                        width: parent.width
                        text: Settings.macroOrder(root.allMacros).length === 0
                            ? "no gcode macros found on this printer"
                            : "Order and visibility of the MACROS card. The order is shared by every printer — a name this printer does not have is skipped."
                        font.family: Type.family
                        font.pixelSize: Type.sizeSmall
                        color: Colors.surfaceVariantText
                        wrapMode: Text.Wrap
                    }

                    Repeater {
                        model: Settings.macroOrder(root.allMacros)
                        delegate: Row {
                            id: mrow
                            required property var modelData
                            required property int index
                            width: parent ? parent.width : 0
                            height: 38
                            spacing: Metrics.sm
                            Text {
                                width: 26
                                text: String(mrow.index + 1)
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: Colors.outlineVariant
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                width: parent.width - 26 - 34 - 34 - 72 - Metrics.sm * 4
                                text: String(mrow.modelData)
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                font.bold: true
                                color: Settings.isMacroHidden(String(mrow.modelData))
                                    ? Colors.outlineVariant : Colors.textPrimary
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            Button {
                                width: 34
                                height: 30
                                text: Icons.up
                                variant: "plain"
                                active: mrow.index > 0
                                onPressed: Settings.moveMacro(root.allMacros, String(mrow.modelData), -1)
                            }
                            Button {
                                width: 34
                                height: 30
                                text: Icons.down
                                variant: "plain"
                                active: mrow.index < Settings.macroOrder(root.allMacros).length - 1
                                onPressed: Settings.moveMacro(root.allMacros, String(mrow.modelData), 1)
                            }
                            Button {
                                width: 72
                                height: 30
                                text: Settings.isMacroHidden(String(mrow.modelData)) ? "SHOW" : "HIDE"
                                variant: Settings.isMacroHidden(String(mrow.modelData)) ? "soft" : "plain"
                                onPressed: Settings.toggleMacro(String(mrow.modelData))
                            }
                        }
                    }
                }
            }

            // ── PRINT ──────────────────────────────────────────────────
            Flickable {
                visible: root.tab === 5
                width: parent.width
                height: root.cardHeight - root.chromeH
                clip: true
                contentWidth: width
                contentHeight: printcol.implicitHeight + Metrics.panelMargin * 2

                Column {
                    id: printcol
                    x: Metrics.panelMargin
                    y: Metrics.panelMargin
                    width: parent.width - Metrics.panelMargin * 2
                    spacing: Metrics.md

                    Text {
                        width: parent.width
                        text: "Which destructive actions ask before running. With a confirmation switched off the action fires immediately."
                        font.family: Type.family
                        font.pixelSize: Type.sizeSmall
                        color: Colors.surfaceVariantText
                        wrapMode: Text.Wrap
                    }

                    Repeater {
                        model: [
                            { key: "start", label: "START PRINT", desc: "ask before starting a file from the standby card" },
                            { key: "cancel", label: "CANCEL PRINT", desc: "ask before cancelling the running job" },
                            { key: "estop", label: "E-STOP", desc: "ask before the emergency stop" }
                        ]
                        delegate: Row {
                            id: cfrow
                            required property var modelData
                            width: parent ? parent.width : 0
                            height: Metrics.controlHeight
                            spacing: Metrics.sm
                            Text {
                                width: 130
                                text: cfrow.modelData.label
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: Colors.surfaceVariantText
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                width: parent.width - 130 - 60 - Metrics.sm * 2
                                text: cfrow.modelData.desc
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: Colors.textSecondary
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            Button {
                                width: 60
                                height: Metrics.controlHeight
                                text: root.confirmFlag(cfrow.modelData.key) ? "ON" : "OFF"
                                variant: root.confirmFlag(cfrow.modelData.key) ? "primary" : "plain"
                                onPressed: Settings.setConfirm(cfrow.modelData.key, !root.confirmFlag(cfrow.modelData.key))
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Colors.separator }

                    Row {
                        width: parent.width
                        height: Metrics.controlHeight
                        spacing: Metrics.sm
                        Button {
                            height: Metrics.controlHeight
                            text: "RESET TO DEFAULTS"; icon: Icons.restart; variant: "plain"
                            onPressed: root.resetRequested()
                        }
                    }
                }
            }
        }
    }
}