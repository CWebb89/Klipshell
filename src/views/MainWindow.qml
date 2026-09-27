pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell._Window
import Quickshell.Io
import "../theme"
import "../moonraker"
import "../components"
import "../config"
import "."

// klipshell window: left sidebar (brand + view nav + printer selector) over
// a body card. One key catcher owns input: number keys 1-9 / arrow keys /
// Enter switch views, Esc returns to Dashboard, console gets typing.
FloatingWindow {
    id: win

    color: Colors.background
    implicitWidth: 1900
    implicitHeight: 1060
    title: "klipshell — Moonraker"

    readonly property int sidebarWidth: 166

    property string activeView: "dash"
    property bool printerMenuOpen: false
    property bool settingsOpen: false

    readonly property var ordered: [
        { id: "dash", label: "DASHBOARD", icon: Icons.dashboard },
        { id: "console", label: "CONSOLE", icon: Icons.terminal },
        { id: "files", label: "G-CODE FILES", icon: Icons.files },
        { id: "hist", label: "HISTORY", icon: Icons.history },
        { id: "heightmap", label: "HEIGHTMAP", icon: Icons.heightmap },
        { id: "gcodeview", label: "GCODE VIEWER", icon: Icons.viewer },
        { id: "machine", label: "MACHINE", icon: Icons.machine },
        { id: "layermind", label: "LAYERMIND", icon: Icons.layermind }
    ]

    function refreshView(id) {
        if (id === "dash") dashView.refresh()
        else if (id === "console") consoleView.refresh()
        else if (id === "files") filesView.refresh()
        else if (id === "hist") histView.refresh()
        else if (id === "heightmap") heightmapView.refresh()
        else if (id === "gcodeview") gcodeViewerView.refresh()
        else if (id === "machine") machineView.refresh()
        else if (id === "layermind") layermindView.refresh()
    }

    function switchView(id) {
        if (!id || id === win.activeView) {
            refreshView(id || win.activeView)
            return
        }
        win.activeView = id
        refreshView(id)
    }

    function viewIndex(id) {
        for (var i = 0; i < win.ordered.length; i++)
            if (win.ordered[i].id === id) return i
        return 0
    }

    // ── Shared preset store (Dashboard chips + Settings editor) ───────
    property var presetStore: QtObject {
        id: pstore
        property var presets: [
            { name: "PLA", ext: 210, bed: 60, visible: true },
            { name: "PETG", ext: 240, bed: 80, visible: true },
            { name: "ABS", ext: 250, bed: 100, visible: true },
            { name: "TPU", ext: 230, bed: 60, visible: true },
            { name: "ASA", ext: 260, bed: 100, visible: true }
        ]

        function _path() {
            return (Quickshell.env("HOME") || "~") + "/.local/state/klipshell/presets.json"
        }
        function save() {
            var f = pstore._path()
            var dir = f.slice(0, f.lastIndexOf("/"))
            var json = JSON.stringify(pstore.presets).replace(/'/g, "'\\''")
            pstore._saveProc.command = ["bash", "-c",
                "mkdir -p '" + dir + "' && printf '%s' '" + json + "' > '" + f + "'"]
            pstore._saveProc.running = false
            pstore._saveProc.running = true
        }
        function update(i, patch) {
            var arr = JSON.parse(JSON.stringify(pstore.presets))
            if (i < 0 || i >= arr.length) return
            if (patch.name !== undefined) arr[i].name = String(patch.name).trim()
            if (patch.ext !== undefined) arr[i].ext = Math.max(0, Math.min(500, Number(patch.ext) || 0))
            if (patch.bed !== undefined) arr[i].bed = Math.max(0, Math.min(500, Number(patch.bed) || 0))
            if (patch.visible !== undefined) arr[i].visible = !!patch.visible
            pstore.presets = arr
            pstore.save()
        }
        function add(name, ext, bed) {
            var arr = JSON.parse(JSON.stringify(pstore.presets))
            arr.push({ name: String(name), ext: Number(ext), bed: Number(bed), visible: true })
            pstore.presets = arr
            pstore.save()
        }
        function remove(i) {
            var arr = JSON.parse(JSON.stringify(pstore.presets))
            if (i < 0 || i >= arr.length) return
            arr.splice(i, 1)
            pstore.presets = arr
            pstore.save()
        }
        function move(i, dir) {
            var arr = JSON.parse(JSON.stringify(pstore.presets))
            var j = i + dir
            if (i < 0 || j < 0 || j >= arr.length) return
            var swap = arr[i]
            arr[i] = arr[j]
            arr[j] = swap
            pstore.presets = arr
            pstore.save()
        }
        property var _saveProc: Process {
            command: ["true"]
            running: false
        }
        property var _loadProc: Process {
            command: []
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        var t = String(text || "").trim()
                        if (!t) return
                        var d = JSON.parse(t)
                        if (!Array.isArray(d)) return
                        var out = []
                        for (var i = 0; i < d.length; i++) {
                            var nm = String(d[i].name || "").trim()
                            if (nm === "") continue
                            out.push({
                                name: nm,
                                ext: Math.max(0, Math.min(500, Number(d[i].ext) || 0)),
                                bed: Math.max(0, Math.min(500, Number(d[i].bed) || 0)),
                                visible: d[i].visible !== false
                            })
                        }
                        if (out.length > 0) pstore.presets = out
                    } catch (e) {
                        console.error("preset load failed:", e)
                    }
                }
            }
        }
        Component.onCompleted: {
            pstore._loadProc.command = ["bash", "-c", "cat '" + pstore._path() + "' 2>/dev/null"]
            pstore._loadProc.running = false
            pstore._loadProc.running = true
        }
    }

    // ── Confirm dialog (overlays everything) ──────────────────────────
    property var confirmBridge: QtObject {
        id: cb
        property string cbMessage: ""
        property string cbConfirm: "Confirm"
        property bool cbDestructive: false
        property var cbCb: null

        function ask(message, opts) {
            cb.cbMessage = message
            cb.cbConfirm = (opts && opts.confirm) || "Confirm"
            cb.cbDestructive = !!(opts && opts.destructive)
            cb.cbCb = (opts && opts.onConfirm) || null
            confirmDlg.message = cb.cbMessage
            confirmDlg.confirmText = cb.cbConfirm
            confirmDlg.destructive = cb.cbDestructive
            confirmDlg.selectedIndex = 0
            confirmDlg.opened = true
        }
    }

    // The layout mode, its dialog and dashboard.json all belong to the dashboard;
    // this only carries the request there. Leaving settings first matters — the
    // popup's scrim and the layout scrim would otherwise stack.
    function openLayout() {
        win.settingsOpen = false
        win.switchView("dash")
        dashView.customizing = true
    }

    // ── Sidebar ────────────────────────────────────────────────────────
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: win.sidebarWidth
        color: Colors.surfaceContainerLowest

        Item {
            anchors.left: parent.left
            anchors.leftMargin: Metrics.spacing
            anchors.right: parent.right
            anchors.rightMargin: Metrics.spacing
            anchors.top: parent.top
            anchors.topMargin: Metrics.panelPadding
            height: win.ordered.length * 42

            Column {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: win.ordered
                    delegate: Item {
                        id: nrow
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 38
                        Rectangle {
                            anchors.fill: parent
                            radius: Metrics.radiusSmall
                            color: win.activeView === nrow.modelData.id ? Colors.selectedFill
                                 : mouse.containsMouse ? Qt.rgba(Colors.outlineVariant.r,
                                        Colors.outlineVariant.g, Colors.outlineVariant.b, 0.30)
                                 : "transparent"
                        }
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Metrics.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Metrics.sm
                            Text {
                                text: String(nrow.modelData.icon)
                                font.family: Type.family
                                font.pixelSize: Type.iconLead
                                color: win.activeView === nrow.modelData.id ? Colors.accent : Colors.textTertiary
                            }
                            Text {
                                text: nrow.modelData.label
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                color: win.activeView === nrow.modelData.id ? Colors.accent : Colors.surfaceVariantText
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.switchView(nrow.modelData.id)
                        }
                    }
                }
            }
        }

        // ── Global settings gear (opens the tabbed settings popup) ──
        Item {
            id: gearBtn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Metrics.spacing
            anchors.rightMargin: Metrics.spacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.panelPadding + 34 + 6
            height: 30
            Rectangle {
                anchors.fill: parent
                radius: Metrics.radiusSmall
                color: gearMouse.containsMouse ? Colors.hoverFill : Colors.surfaceContainer
                border.width: Metrics.borderWidth
                border.color: Colors.alpha(Colors.outlineVariant, 0.8)
            }
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Text {
                    text: Icons.settings
                    font.family: Type.family
                    font.pixelSize: Type.iconInline
                    color: gearMouse.containsMouse ? Colors.accent : Colors.textSecondary
                }
                Text {
                    text: "SETTINGS"
                    font.family: Type.family
                    font.pixelSize: Type.sizeSmall
                    font.bold: true
                    color: gearMouse.containsMouse ? Colors.accent : Colors.surfaceVariantText
                }
            }
            MouseArea {
                id: gearMouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: win.settingsOpen = true
            }
        }

        // ── Printer selector (moved from the top-right header) ──
        Item {
            id: printerChip
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Metrics.spacing
            anchors.rightMargin: Metrics.spacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.panelPadding
            height: 34
            Rectangle {
                anchors.fill: parent
                radius: Metrics.radiusSmall
                color: pchip.containsMouse ? Colors.hoverFill : Colors.surfaceContainerHigh
                border.width: Metrics.borderWidth
                border.color: Colors.alpha(Colors.outlineVariant, 0.8)
            }
            // Anchored, not a Row: a Row top-aligns its children, so the 7px
            // status dot sat high against the 16px name and looked off. Each
            // child centres itself against the same box instead.
            Item {
                id: chipContent
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: Math.max(7, chipName.implicitHeight)

                Rectangle {
                    id: chipDot
                    width: 7
                    height: 7
                    radius: 3.5
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: MoonrakerService.active
                        ? (MoonrakerService.active.connected ? Colors.success : Colors.error)
                        : Colors.outlineVariant
                }
                Text {
                    id: chipChevron
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.expand
                    font.family: Type.family
                    font.pixelSize: Type.iconInline
                    color: Colors.textTertiary
                }
                Text {
                    id: chipName
                    anchors.left: chipDot.right
                    anchors.leftMargin: Metrics.sm
                    anchors.right: chipChevron.left
                    anchors.rightMargin: Metrics.sm
                    anchors.verticalCenter: parent.verticalCenter
                    text: MoonrakerService.activePrinter || "select printer"
                    font.family: Type.family
                    font.pixelSize: Type.sizeSmall
                    font.bold: true
                    color: MoonrakerService.active?.connected ? Colors.textPrimary : Colors.surfaceVariantText
                    elide: Text.ElideRight
                }
            }
            MouseArea {
                id: pchip
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: win.printerMenuOpen = !win.printerMenuOpen
            }
        }
    }

    // ── Printer selection popup (lists printers; click to switch) ────────
    Rectangle {
        visible: win.printerMenuOpen
        z: 70
        anchors.left: parent.left
        anchors.leftMargin: Metrics.spacing
        y: parent.height - Metrics.panelPadding - 78 - MoonrakerService.printers.length * 30
        width: 250
        height: 34 + MoonrakerService.printers.length * 30 + 6
        radius: 0
        color: Colors.surfaceContainerHigh
        border.width: Metrics.borderWidth
        border.color: Colors.outlineVariant

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Text {
                width: parent.width
                height: 22
                verticalAlignment: Text.AlignVCenter
                text: "SELECT PRINTER"
                font.family: Type.family
                font.pixelSize: Type.sizeCaption
                font.bold: true
                font.letterSpacing: 1.0
                color: Colors.outlineVariant
            }

            Repeater {
                model: MoonrakerService.printers
                delegate: Item {
                    id: prow
                    required property var modelData
                    width: parent.width
                    height: 30
                    Rectangle {
                        anchors.fill: parent
                        radius: Metrics.radiusSmall
                        color: prow.modelData.name === MoonrakerService.activePrinter
                            ? Colors.selectedFill : (pm.containsMouse ? Colors.hoverFill : "transparent")
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Rectangle {
                            // Self-centring so the 7px dot lines up with the
                            // 16px name (a Row parent would top-align it)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 7
                            height: 7
                            radius: 3.5
                            color: prow.modelData.name === MoonrakerService.activePrinter
                                ? (MoonrakerService.active?.connected ? Colors.success : Colors.error)
                                : Colors.outlineVariant
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 13
                            text: prow.modelData.name
                            font.family: Type.family
                            font.pixelSize: Type.sizeSmall
                            color: prow.modelData.name === MoonrakerService.activePrinter
                                ? Colors.accent : Colors.surfaceVariantText
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        id: pm
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MoonrakerService.selectPrinter(prow.modelData.name)
                            win.printerMenuOpen = false
                        }
                    }
                }
            }
        }
    }

    // Click-away overlay to dismiss the printer menu.
    Rectangle {
        visible: win.printerMenuOpen
        z: 65
        anchors.fill: parent
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: win.printerMenuOpen = false
        }
    }

    // ── Body card ──────────────────────────────────────────────────────
    Rectangle {
        id: bodyCard
        // Nothing behind the settings popup should hover, click or scroll —
        // the scrim's MouseArea only covers clicks.
        enabled: !win.settingsOpen
        x: win.sidebarWidth
        y: 0
        width: parent.width - win.sidebarWidth
        height: parent.height
        radius: 0
        color: Colors.surfaceContainerLow
        // Faint top sheen: same 3-stop gradient as Card.qml.
        gradient: Gradient {
            GradientStop { position: 0.0; color: Colors.alpha(Colors.surfaceText, 0.05) }
            GradientStop { position: 0.45; color: Colors.alpha(Colors.surfaceText, 0.0) }
            GradientStop { position: 1.0; color: Colors.alpha(Colors.surfaceText, 0.0) }
        }

        Dashboard { id: dashView;      anchors.fill: parent; moonraker: MoonrakerService; presetStore: win.presetStore; confirmDialog: win.confirmBridge; openView: function(id){ win.switchView(id) }; visible: win.activeView === "dash" }
        Console    { id: consoleView;   anchors.fill: parent; moonraker: MoonrakerService; visible: win.activeView === "console" }
        GcodeFiles { id: filesView;     anchors.fill: parent; moonraker: MoonrakerService; visible: win.activeView === "files" }
        History    { id: histView;      anchors.fill: parent; moonraker: MoonrakerService; visible: win.activeView === "hist" }
        Machine    { id: machineView;   anchors.fill: parent; moonraker: MoonrakerService; visible: win.activeView === "machine" }
        Layermind  { id: layermindView; anchors.fill: parent; moonraker: MoonrakerService; visible: win.activeView === "layermind" }
        Heightmap  { id: heightmapView; anchors.fill: parent; moonraker: MoonrakerService; visible: win.activeView === "heightmap" }
        GcodeViewer { id: gcodeViewerView; anchors.fill: parent; moonraker: MoonrakerService; visible: win.activeView === "gcodeview" }
    }

    // ── No-printer connect overlay: shown only while the active printer is unreachable ──
    Rectangle {
        x: win.sidebarWidth
        y: 0
        width: parent.width - win.sidebarWidth
        height: parent.height
        radius: 0
        color: Colors.surfaceContainerLow
        z: 10
        visible: !MoonrakerService.connected

        Column {
            anchors.centerIn: parent
            width: 360
            spacing: Metrics.xl

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Icons.offline
                font.family: Type.family
                font.pixelSize: Type.sizeXLarge + 6
                color: Colors.textTertiary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: MoonrakerService.printers.length > 0 ? "NO PRINTER CONNECTED" : "NO PRINTERS CONFIGURED"
                font.family: Type.family
                font.pixelSize: Type.sizeHeading
                font.bold: true
                font.letterSpacing: 1.2
                color: Colors.surfaceVariantText
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: MoonrakerService.printers.length > 0
                    ? "Pick a printer on the left, or reconnect. Connection is retried automatically every 2s."
                    : "Add printers to src/config/printers.json."
                font.family: Type.family
                font.pixelSize: Type.sizeSmall
                color: Colors.surfaceVariantText
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200; height: Metrics.controlHeight
                text: "RECONNECT"
                icon: Icons.refresh
                variant: "primary"
                onPressed: MoonrakerService.reconnect()
            }
        }
    }

    ConfirmDialog {
        id: confirmDlg
        anchors.fill: parent
        z: 100
        onConfirmed: {
            confirmDlg.opened = false
            var f = win.confirmBridge.cbCb
            win.confirmBridge.cbCb = null
            if (f) f()
        }
        onCanceled: {
            confirmDlg.opened = false
            win.confirmBridge.cbCb = null
        }
    }

    // ── Global settings popup (gear icon in the sidebar) ────────────
    SettingsPopup {
        id: settingsPopup
        anchors.fill: parent
        z: 90
        moonraker: MoonrakerService
        presetStore: win.presetStore
        opened: win.settingsOpen
        onClosed: win.settingsOpen = false
        onLayoutRequested: win.openLayout()
        onResetRequested: win.confirmBridge.ask("Reset every setting to its default? Jog steps, macro order, units, shell knobs, the IP mask and per-printer API keys all go back to stock.", { confirm: "RESET", destructive: true, onConfirm: function() { Settings.reset() } })
    }

    // ── Keys (single owner) ────────────────────────────────────────────
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem

        // A click into a text field moves active focus there and Qt clears
        // `focus` here, which used to leave the global shortcuts dead for the
        // rest of the session. Claim focus back whenever the field holding it
        // stops being edited — released, disabled, or hidden because its view or
        // its prompt went away. Qt emits nothing when a field goes away while it
        // holds active focus, so this runs on a slow tick: three property reads,
        // one owner of the focus request, and no re-entrancy to race with.
        function _reclaimFocus() {
            var it = Window.activeFocusItem
            if (it && it.visible && it.enabled && it.acceptableInput !== undefined) return
            if (keyCatcher.activeFocus) return
            keyCatcher.forceActiveFocus()
        }

        Timer {
            interval: 200
            running: win.visible
            repeat: true
            onTriggered: keyCatcher._reclaimFocus()
        }

        Component.onCompleted: keyCatcher.forceActiveFocus()

        function moveView(delta) {
            var i = win.viewIndex(win.activeView)
            win.switchView(win.ordered[(i + delta + win.ordered.length) % win.ordered.length].id)
        }

        Keys.onPressed: function(event) {
            var k = event.key
            if (confirmDlg.opened) {
                confirmDlg.handleKey(event)
                event.accepted = true
                return
            }
            if (win.settingsOpen) {
                if (k === Qt.Key_Escape) {
                    win.settingsOpen = false
                } else {
                    settingsPopup.handleKey(event)
                }
                event.accepted = true
                return
            }
            if (win.activeView === "dash" && dashView.consoleActive) {
                dashView.handleKey(event)
                event.accepted = true
                return
            }
            // The notification panel is modal (it dims the dashboard), so Esc
            // dismisses it instead of switching views.
            if (win.activeView === "dash" && dashView.notifOpen) {
                dashView.closeNotifications()
                event.accepted = true
                return
            }
            // Layout mode is modal as well — its scrim covers the dashboard — so
            // it swallows keys rather than letting one switch views underneath it.
            // Esc and the dialog's DONE are the ways out.
            if (win.activeView === "dash" && dashView.customizing) {
                dashView.customizing = false
                event.accepted = true
                return
            }
            if (win.activeView === "console") {
                if (k === Qt.Key_Escape) {
                    if (consoleView.pending !== "") {
                        consoleView.clearPending()
                    } else {
                        win.switchView("dash")
                        event.accepted = true
                        return
                    }
                } else {
                    consoleView.handleKey(event)
                }
                event.accepted = true
                return
            }
            if (k === Qt.Key_1) { win.switchView("dash"); event.accepted = true }
            else if (k === Qt.Key_2) { win.switchView("console"); event.accepted = true }
            else if (k === Qt.Key_3) { win.switchView("files"); event.accepted = true }
            else if (k === Qt.Key_4) { win.switchView("hist"); event.accepted = true }
            else if (k === Qt.Key_5) { win.switchView("heightmap"); event.accepted = true }
            else if (k === Qt.Key_6) { win.switchView("gcodeview"); event.accepted = true }
            else if (k === Qt.Key_7) { win.switchView("machine"); event.accepted = true }
            else if (k === Qt.Key_8) { win.switchView("layermind"); event.accepted = true }
            else if (k === Qt.Key_Up || k === Qt.Key_Left || k === Qt.Key_K || k === Qt.Key_H) {
                keyCatcher.moveView(-1)
                event.accepted = true
            } else if (k === Qt.Key_Down || k === Qt.Key_Right || k === Qt.Key_J || k === Qt.Key_L) {
                keyCatcher.moveView(1)
                event.accepted = true
            } else if (k === Qt.Key_Return) {
                win.refreshView(win.activeView)
                event.accepted = true
            } else if (k === Qt.Key_Escape) {
                win.switchView("dash")
                event.accepted = true
            }
        }
    }
}