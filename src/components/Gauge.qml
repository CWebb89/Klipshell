import QtQuick
import "../theme"

// Omarchy PanelSlider grammar as a bare bar: 4px track, filled width
// animated 140ms OutCubic. color + ratio drive the fill. A soft, wider
// halo sits behind the fill for a bit of glow — decorative only, sized
// off the same width expression so it always matches the fill exactly.
Item {
    id: root

    required property real ratio
    property color color: Colors.textPrimary
    property color track: Colors.selectedFill
    property int barHeight: Metrics.gaugeTrack

    Rectangle {
        anchors.fill: parent
        radius: root.barHeight / 2
        color: root.track
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -3
        height: root.barHeight + 6
        radius: height / 2
        color: Colors.alpha(root.color, 0.22)
        width: root.width * Math.max(0, Math.min(1, root.ratio))

        Behavior on width {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: root.barHeight
        radius: root.barHeight / 2
        color: root.color
        width: root.width * Math.max(0, Math.min(1, root.ratio))

        Behavior on width {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }
}
