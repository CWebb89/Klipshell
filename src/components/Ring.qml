import QtQuick
import "../theme"

// Circular progress ring: fills by `ratio` (0..1) with `color` on a faint
// track, the reading `value` (bold) centered inside. The name/label is
// rendered by the caller above the ring.
Item {
    id: root

    property real ratio: 0
    property color color: Colors.accent
    property string value: "—"
    readonly property real stroke: Math.max(5, Math.min(9, width * 0.09))

    implicitWidth: 100
    implicitHeight: 100

    Canvas {
        id: ring
        anchors.fill: parent
        onPaint: function() {
            var ctx = getContext("2d")
            ctx.reset()
            var c = width / 2
            var lw = root.stroke
            var r = c - lw
            ctx.lineWidth = lw
            ctx.lineCap = "round"
            ctx.strokeStyle = Colors.alpha(Colors.surfaceText, 0.13)
            ctx.beginPath()
            ctx.arc(c, c, r, 0, 2 * Math.PI)
            ctx.stroke()
            var p = Math.max(0, Math.min(1, root.ratio))
            ctx.strokeStyle = root.color.toString()
            ctx.beginPath()
            ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * p)
            ctx.stroke()
        }
    }
    onRatioChanged: ring.requestPaint()
    onColorChanged: ring.requestPaint()

    Text {
        anchors.centerIn: parent
        text: root.value
        font.family: Type.family
        font.pixelSize: Type.sizeTitle
        font.bold: true
        color: Colors.textPrimary
    }
}
