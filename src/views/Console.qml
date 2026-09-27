pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../config"

// GCode console: scrolled transcript from /server/gcode_store + keyboard-first
// input row (event.text accumulation, Omarchy menu-style). Enter sends,
// Backspace edits, Esc clears the pending buffer.
// Reads as a terminal: a darker bordered viewport holding the transcript (a
// prompt glyph per sent command, output dimmed under it) with a bordered input
// field under it carrying a blinking block cursor.
Item {
    id: root

    required property QtObject moonraker
    property var lines: []
    property string pending: ""
    // Scrollback size from settings; it sizes both the fetch and the slice.
    readonly property int maxLines: Settings.consoleLines
    // Settings land after the first fetch (the console is built at startup, the
    // file is read a moment later), so re-fetch when the stored size arrives.
    onMaxLinesChanged: root.refresh()
    readonly property int lineH: 20
    readonly property int gutterW: 16

    function refresh() {
        root.moonraker.fetchGcodeStore(maxLines)
    }

    function clearPending() {
        pending = ""
    }

    property bool _stickBottom: true
    function _stickToBottom() {
        if (!root._stickBottom) return
        cscroll.contentY = Math.max(0, cscroll.contentHeight - cscroll.height)
    }

    Connections {
        target: root.moonraker
        function onGcodeStoreFetched(ok, list) {
            if (!ok) return
            root.lines = list.slice(-root.maxLines)
            root._stickToBottom()
        }
        function onGcodeSent(ok, err) {
            root.pending = ""
            if (ok) {
                root.refresh()
            } else {
                var state = root.lines.length > 0 ? root.lines : []
                root.lines = state.concat([{ type: "error", message: "send failed: " + (err || "unknown") }]).slice(-root.maxLines)
                root._stickToBottom()
            }
        }
    }

    // The prompt glyph carries the line's identity, so a sent command can be
    // bright like typed input while its answer stays dim underneath it.
    function lineGlyph(type) {
        if (type === "command") return ">"
        if (type === "error") return Icons.error
        return ""
    }

    function glyphColor(type) {
        if (type === "command") return Colors.accent
        if (type === "error") return Colors.error
        return Colors.surfaceVariantText
    }

    function lineColor(type) {
        if (type === "command") return Colors.textPrimary
        if (type === "error") return Colors.error
        return Colors.surfaceVariantText
    }

    // Keyboard input, forwarded by the window key catcher.
    function handleKey(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            var s = root.pending.trim()
            if (s !== "") root.moonraker.sendGcode(s)
            root.pending = ""
            event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            root.pending = root.pending.slice(0, -1)
            event.accepted = true
        } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32
                   && event.text.charCodeAt(0) !== 127) {
            root.pending += event.text
            event.accepted = true
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: Metrics.panelPadding

        // Terminal viewport: darker than the page, bordered, rows inset so the
        // transcript never touches the frame.
        Rectangle {
            id: cbox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: inputBox.top
            anchors.bottomMargin: Metrics.sectionGap
            color: Colors.surfaceContainerLowest
            radius: Metrics.radiusMedium
            border.width: Metrics.borderWidth
            border.color: Colors.outlineVariant
            clip: true

            Flickable {
                id: cscroll
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                contentWidth: width
                contentHeight: Math.max(height, root.lines.length * root.lineH)
                onContentYChanged: {
                    root._stickBottom = cscroll.contentY >= cscroll.contentHeight - cscroll.height - 8
                }

                Column {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: root.lines
                        delegate: Item {
                            id: cline
                            required property var modelData
                            width: parent ? parent.width : 0
                            height: root.lineH

                            Text {
                                id: clineGlyph
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: root.gutterW
                                text: cline.modelData ? root.lineGlyph(cline.modelData.type) : ""
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                font.bold: true
                                color: cline.modelData ? root.glyphColor(cline.modelData.type) : Colors.surfaceVariantText
                            }

                            Text {
                                anchors.left: clineGlyph.right
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: cline.modelData ? cline.modelData.message : ""
                                font.family: Type.family
                                font.pixelSize: Type.sizeSmall
                                color: cline.modelData ? root.lineColor(cline.modelData.type) : Colors.surfaceVariantText
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // Input field: a real bordered box, distinct from the viewport behind it.
        Rectangle {
            id: inputBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Metrics.controlHeight
            color: Colors.surfaceContainerLow
            radius: Metrics.radiusSmall
            border.width: Metrics.borderWidth
            border.color: Colors.outlineVariant
            clip: true

            Text {
                id: promptGlyph
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: ">"
                font.family: Type.family
                font.pixelSize: Type.sizeBody
                font.bold: true
                color: Colors.accent
            }

            Text {
                id: cmdText
                anchors.left: promptGlyph.right
                anchors.leftMargin: Metrics.md
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.pending
                font.family: Type.family
                font.pixelSize: Type.sizeBody
                color: Colors.textPrimary
                elide: Text.ElideRight
            }

            Rectangle {
                id: caret
                anchors.verticalCenter: parent.verticalCenter
                x: cmdText.x + Math.min(cmdText.contentWidth, cmdText.width)
                width: 9
                height: 17
                color: Colors.textPrimary
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: 520 }
                    NumberAnimation { to: 1.0; duration: 520 }
                }
            }
        }
    }
}
