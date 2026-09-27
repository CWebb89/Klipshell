import QtQuick
import "../theme"

// Omarchy PanelSlider port: 4px track, animated fill/knob (140ms OutCubic,
// disabled while dragging), knob grows on hover, wheel + drag input.
// Label + live readout flank the track.
Item {
    id: root

    required property string label
    property real value: 0
    property real minimum: 0
    property real maximum: 100
    property real step: 5
    property bool integer: true
    property string unit: "%"
    property color fillColor: Colors.accent
    property color trackColor: Colors.selectedFill
    signal moved(real v)
    signal released(real v)

    property real liveValue: root.value
    property bool _dragging: false
    readonly property real range: Math.max(0.0001, root.maximum - root.minimum)
    readonly property real progress: Math.max(0, Math.min(1, (root.liveValue - root.minimum) / root.range))

    implicitWidth: 280
    implicitHeight: 26

    onValueChanged: if (!root._dragging) root.liveValue = root.value

    function snap(v) {
        if (root.integer) return Math.round(v)
        var s = Math.max(0.0001, root.step)
        return Math.round(v / s) * s
    }

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 84
        text: root.label.toUpperCase()
        font.family: Type.family
        font.pixelSize: Type.sizeCaption
        font.bold: true
        font.letterSpacing: 1.0
        color: Colors.surfaceVariantText
    }

    Text {
        id: readout
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        text: (root.integer ? Math.round(root.liveValue) : (Math.round(root.liveValue * 10) / 10)) + root.unit
        font.family: Type.family
        font.pixelSize: Type.sizeSmall
        font.bold: true
        color: root.fillColor
        horizontalAlignment: Text.AlignRight
    }

    Item {
        id: trackArea
        anchors.left: labelText.right
        anchors.leftMargin: Metrics.sm
        anchors.right: readout.left
        anchors.rightMargin: Metrics.sm
        anchors.verticalCenter: parent.verticalCenter
        height: 18

        readonly property real knob: Metrics.gaugeKnob
        readonly property real thumbStart: _knob.width / 2
        readonly property real usable: trackArea.width - _knob.width

        Rectangle {
            id: _track
            anchors.left: parent.left
            anchors.leftMargin: trackArea.knob / 2
            anchors.right: parent.right
            anchors.rightMargin: trackArea.knob / 2
            anchors.verticalCenter: parent.verticalCenter
            height: Metrics.gaugeTrack
            radius: Metrics.gaugeTrack / 2
            color: root.trackColor
        }
        Rectangle {
            id: _fill
            anchors.left: parent.left
            anchors.leftMargin: trackArea.knob / 2
            anchors.verticalCenter: parent.verticalCenter
            height: Metrics.gaugeTrack
            radius: Metrics.gaugeTrack / 2
            color: root.fillColor
            width: trackArea.usable * root.progress

            Behavior on width {
                enabled: !root._dragging
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }
        Rectangle {
            id: _knob
            width: trackArea.knob
            height: trackArea.knob
            radius: trackArea.knob / 2
            color: root.fillColor
            border.width: 2
            border.color: Colors.surfaceContainerHigh
            x: trackArea.thumbStart + trackArea.usable * root.progress
            scale: _mouse.containsMouse || root._dragging ? 1.15 : 1.0

            Behavior on x {
                enabled: !root._dragging
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
            }
        }
        MouseArea {
            id: _mouse
            anchors.fill: trackArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function valueFromX(x) {
                var clamped = Math.max(0, Math.min(trackArea.usable, x - trackArea.thumbStart))
                var v = root.minimum + (clamped / trackArea.usable) * root.range
                return root.snap(Math.max(root.minimum, Math.min(root.maximum, v)))
            }
            onPressed: function(mouse) {
                root._dragging = true
                var v = valueFromX(mouse.x)
                root.liveValue = v
                root.moved(v)
            }
            onPositionChanged: function(mouse) {
                if (!root._dragging) return
                var v = valueFromX(mouse.x)
                root.liveValue = v
                root.moved(v)
            }
            onReleased: {
                root._dragging = false
                root.released(root.liveValue)
                root.liveValue = root.value
            }
            onWheel: {
                var d = wheel.angleDelta.y > 0 ? root.step : -root.step
                var v = root.snap(Math.max(root.minimum, Math.min(root.maximum, root.liveValue + d)))
                root.liveValue = v
                root.moved(v)
                root.released(v)
            }
        }
    }
}