import QtQuick
import "../theme"

// Omarchy ConfirmDialog port: transparent click-away wash (no dimming),
// square card with message +
// Cancel/Confirm pair, keyboard-driven (Esc cancel, arrows/Tab swap,
// Enter confirm). host wires handleKey() into its key catcher. The card
// sizes to its content (implicitHeight from the message + button column)
// and the buttons size to their labels so long confirm text ("START
// PRINT", "CANCEL PRINT") never clips.
Item {
    id: root

    property bool opened: false
    property string message: ""
    property string cancelText: "Cancel"
    property string confirmText: "Confirm"
    property bool destructive: false
    property int selectedIndex: 1

    signal canceled()
    signal confirmed()

    function handleKey(event) {
        if (!root.opened) return false
        if (event.key === Qt.Key_Escape) { root.canceled(); return true }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
            || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.selectedIndex = root.selectedIndex === 0 ? 1 : 0
            return true
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.selectedIndex === 0) root.canceled()
            else root.confirmed()
            return true
        }
        return false
    }

    visible: root.opened
    opacity: root.opened ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        MouseArea { anchors.fill: parent; onClicked: root.canceled() }
    }

    Rectangle {
        id: cardBox
        width: Math.min(parent.width - 64, 400)
        implicitHeight: col.implicitHeight + Metrics.xxl * 2
        anchors.centerIn: parent
        radius: 0
        color: Colors.surfaceContainerHigh
        border.width: Metrics.cardBorderWidth
        border.color: Colors.outline

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Metrics.xxl
            anchors.rightMargin: Metrics.xxl
            anchors.topMargin: Metrics.xxl
            spacing: Metrics.xl

            Row {
                width: parent.width
                spacing: Metrics.md

                Text {
                    text: root.destructive ? Icons.warning : Icons.info
                    font.family: Type.family
                    font.pixelSize: Type.iconStandalone
                    color: root.destructive ? Colors.error : Colors.accent
                }
                Text {
                    width: parent.width - Type.iconStandalone - Metrics.md
                    text: root.message
                    font.family: Type.family
                    font.pixelSize: Type.sizeBody
                    font.bold: true
                    color: Colors.textPrimary
                    wrapMode: Text.WordWrap
                }
            }
            Row {
                anchors.right: parent.right
                spacing: Metrics.md

                Rectangle {
                    id: cancelBtn
                    width: Math.max(96, cancelTxt.implicitWidth + Metrics.xl * 2)
                    height: Metrics.controlHeight
                    radius: Metrics.radiusSmall
                    color: cancelHover.containsMouse && root.selectedIndex !== 0
                        ? Colors.hoverFill
                        : root.selectedIndex === 0 ? Colors.selectedFill : "transparent"
                    border.width: Metrics.borderWidth
                    border.color: root.selectedIndex === 0 ? Colors.accent : Colors.outlineVariant

                    Text {
                        id: cancelTxt
                        anchors.centerIn: parent
                        text: root.cancelText
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        font.bold: true
                        font.letterSpacing: 0.6
                        color: root.selectedIndex === 0 ? Colors.accent : Colors.surfaceVariantText
                    }
                    MouseArea {
                        id: cancelHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.selectedIndex === 0) root.canceled()
                            else root.selectedIndex = 0
                        }
                    }
                }
                Rectangle {
                    id: confirmBtn
                    width: Math.max(96, confirmTxt.implicitWidth + Metrics.xl * 2)
                    height: Metrics.controlHeight
                    radius: Metrics.radiusSmall
                    color: confirmHover.containsMouse && root.selectedIndex !== 1
                        ? Colors.hoverFill
                        : root.destructive
                            ? (root.selectedIndex === 1 ? Colors.errorDim : "transparent")
                            : (root.selectedIndex === 1 ? Colors.selectedFill : "transparent")
                    border.width: Metrics.borderWidth
                    border.color: root.destructive
                        ? (root.selectedIndex === 1 ? Colors.error : Colors.alpha(Colors.error, 0.5))
                        : (root.selectedIndex === 1 ? Colors.accent : Colors.outlineVariant)

                    Text {
                        id: confirmTxt
                        anchors.centerIn: parent
                        text: root.confirmText
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        font.bold: true
                        font.letterSpacing: 0.6
                        color: root.destructive
                            ? (root.selectedIndex === 1 ? Colors.error : Colors.surfaceVariantText)
                            : (root.selectedIndex === 1 ? Colors.accent : Colors.surfaceVariantText)
                    }
                    MouseArea {
                        id: confirmHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.selectedIndex === 1) root.confirmed()
                            else root.selectedIndex = 1
                        }
                    }
                }
            }
        }
    }
}