import QtQuick
import "../theme"

// Multi-segment donut for a categorical split (Mainsail's job-status ring).
// `segments` = [{ value, color }]. Vector arcs only — labels and the center
// readout are the caller's overlays (see Chart.qml's note on Canvas text).
Item {
    id: root

    property var segments: []

    readonly property real total: {
        var s = 0
        for (var i = 0; i < root.segments.length; i++)
            s += Math.max(0, Number(root.segments[i].value) || 0)
        return s
    }
    readonly property real stroke: Math.max(9, Math.min(18, width * 0.105))
    // Segments are separated by a 2° gap (clamped on thin slices) so adjacent
    // hues read as segments instead of one continuous sweep.
    readonly property real gapAngle: 0.035

    implicitWidth: 170
    implicitHeight: 170

    Canvas {
        id: donut
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            if (!ctx) return
            ctx.reset()
            var c = Math.min(width, height) / 2
            var lw = root.stroke
            var r = c - lw / 2 - 1
            ctx.lineWidth = lw
            ctx.strokeStyle = Colors.alpha(Colors.surfaceText, 0.10)
            ctx.beginPath()
            ctx.arc(c, c, r, 0, 2 * Math.PI)
            ctx.stroke()

            var t = root.total
            if (t <= 0) return
            var a = -Math.PI / 2
            for (var i = 0; i < root.segments.length; i++) {
                var v = Math.max(0, Number(root.segments[i].value) || 0)
                if (v <= 0) continue
                var sweep = 2 * Math.PI * v / t
                var g = root.segments.length > 1 ? Math.min(root.gapAngle, sweep * 0.3) : 0
                ctx.strokeStyle = root.segments[i].color
                ctx.beginPath()
                ctx.arc(c, c, r, a + g / 2, a + sweep - g / 2)
                ctx.stroke()
                a += sweep
            }
        }
    }

    onSegmentsChanged: donut.requestPaint()
    onWidthChanged: donut.requestPaint()
    onHeightChanged: donut.requestPaint()
}
