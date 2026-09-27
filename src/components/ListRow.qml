pragma ComponentBehavior: Bound
import QtQuick
import "../theme"

// Selectable list row: Omarchy menu selection — accent text on selectedFill
// when selected, hover highlight via a dimmed outline wash. An optional
// leading icon gives the row an identity that survives the colour change.
Item {
    id: root

    required property string text
    property bool selected: false
    property color accent: Colors.accent
    property string icon: ""
    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: Metrics.radiusSmall
        color: root.selected ? Colors.selectedFill
             : mouse.containsMouse ? Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g,
                                       Colors.outlineVariant.b, 0.30)
             : "transparent"
    }
    Text {
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: Metrics.spacing
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        font.family: Type.family
        font.pixelSize: Type.iconInline
        color: root.selected ? root.accent : Colors.textTertiary
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: Metrics.spacing + (root.icon !== "" ? Type.iconInline + Metrics.sm : 0)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.family: Type.family
        font.pixelSize: Type.sizeSmall
        color: root.selected ? root.accent : Colors.surfaceVariantText
        elide: Text.ElideRight
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}