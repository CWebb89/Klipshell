import QtQuick
import "../theme"

// Status chip: optional icon + bold caption (non-pill) or bordered pill with
// a dot (pill: true) — Omarchy detail-pill grammar. color drives both. Filled
// pills get a soft halo (glow) by default so an active/live status (e.g.
// "PRINTING") reads as the most prominent thing in the card. An icon replaces
// the dot, so a chip never carries both.
Item {
    id: root

    required property string text
    property color color: Colors.surfaceVariantText
    property string icon: ""
    property bool pill: false
    property bool filled: false
    property bool glow: true

    implicitWidth: (root.pill ? 14 : 12) + textItem.implicitWidth
        + (root.icon !== "" ? Type.iconInline + Metrics.xs : 0)
    implicitHeight: root.pill ? 20 : Math.max(7, textItem.implicitHeight)

    Rectangle {
        visible: root.pill && root.filled && root.glow
        anchors.centerIn: parent
        width: parent.width + 10
        height: parent.height + 10
        radius: Metrics.radiusSmall + 5
        color: Colors.alpha(root.color, 0.16)
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Rectangle {
        visible: root.pill
        anchors.fill: parent
        radius: Metrics.radiusSmall
        color: root.filled ? Colors.alpha(root.color, 0.18) : "transparent"
        border.width: Metrics.borderWidth
        border.color: Colors.alpha(root.color, 0.6)
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
    }
    Rectangle {
        visible: !root.pill && root.icon === ""
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 7
        height: 7
        radius: 3.5
        color: root.color
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    Text {
        visible: !root.pill && root.icon !== ""
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        font.family: Type.family
        font.pixelSize: Type.iconInline
        color: root.color
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    Text {
        id: textItem
        anchors.left: parent.left
        anchors.leftMargin: root.pill ? 7
            : (root.icon !== "" ? 12 + Type.iconInline + Metrics.xs : 12)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.family: Type.family
        font.pixelSize: Type.sizeCaption
        font.bold: true
        font.letterSpacing: 0.6
        color: root.color
        Behavior on color { ColorAnimation { duration: 160 } }
    }
}
