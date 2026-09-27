import QtQuick
import "../theme"

// Omarchy PanelSeparator: 1px section divider at fg@12% — legible against
// the card without competing with text or borders.
Rectangle {
    id: root

    property color foreground: Colors.textPrimary

    implicitHeight: 1
    height: 1
    width: parent ? parent.width : implicitWidth
    color: Colors.separator
}