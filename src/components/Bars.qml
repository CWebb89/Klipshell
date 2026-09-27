pragma ComponentBehavior: Bound
import QtQuick
import "../theme"

// Vertical bar chart for a per-job metric (Mainsail's usage chart): one bar per
// value, "nice" y-axis with five gridlines, integer labels above each bar.
// Vectors in the Canvas, text as Item overlays — Canvas text does not render
// here (Chart.qml hit the same wall).
Item {
    id: root

    required property var values
    property var barLabels: []
    property color barColor: Colors.accent
    property string unit: ""

    readonly property int padL: 46
    readonly property int padR: 10
    readonly property int padT: 20
    readonly property int padB: 24
    readonly property int n: (root.values || []).length
    readonly property real slotW: Math.max(1, (width - root.padL - root.padR) / Math.max(1, root.n))
    readonly property real barW: Math.max(3, Math.min(44, root.slotW * 0.62))

    readonly property real axisMax: {
        var m = 0
        for (var i = 0; i < root.n; i++) m = Math.max(m, Number(root.values[i]) || 0)
        return root.niceMax(m)
    }
    readonly property var ticks: {
        var out = []
        for (var i = 0; i <= 4; i++) out.push(root.axisMax * i / 4)
        return out
    }

    // 1/1.5/2/3/5/7.5/10 × 10^n — Mainsail's axis lands on 30/60/…/210 the same way.
    function niceMax(v) {
        if (!(v > 0)) return 1
        var exp = Math.pow(10, Math.floor(Math.log(v) / Math.LN10))
        var f = v / exp
        var m = f <= 1 ? 1 : f <= 1.5 ? 1.5 : f <= 2 ? 2 : f <= 3 ? 3 : f <= 5 ? 5 : f <= 7.5 ? 7.5 : 10
        return m * exp
    }

    function yOf(v) {
        return root.padT + (height - root.padT - root.padB) * (1 - v / root.axisMax)
    }

    function xOf(i) {
        return root.padL + (i + 0.5) * root.slotW
    }

    function tickText(v) {
        return v >= 1000 ? (v / 1000).toFixed(v >= 10000 ? 0 : 1) + "k" : String(Math.round(v))
    }

    Canvas {
        id: cv
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            if (!ctx) return
            ctx.reset()
            var plotH = height - root.padT - root.padB
            var plotW = width - root.padL - root.padR
            if (plotH <= 0 || plotW <= 0) return

            ctx.lineWidth = 1
            ctx.strokeStyle = Colors.alpha(Colors.surfaceText, 0.10)
            for (var t = 0; t < root.ticks.length; t++) {
                var gy = Math.round(root.yOf(root.ticks[t])) + 0.5
                ctx.beginPath()
                ctx.moveTo(root.padL, gy)
                ctx.lineTo(root.padL + plotW, gy)
                ctx.stroke()
            }

            ctx.strokeStyle = Colors.alpha(Colors.surfaceText, 0.22)
            var by = Math.round(root.yOf(0)) + 0.5
            ctx.beginPath()
            ctx.moveTo(root.padL, by)
            ctx.lineTo(root.padL + plotW, by)
            ctx.stroke()

            var base = root.yOf(0)
            for (var i = 0; i < root.n; i++) {
                var v = Math.max(0, Number(root.values[i]) || 0)
                if (v <= 0) continue
                var h = Math.max(1, base - root.yOf(v))
                var x = root.xOf(i) - root.barW / 2
                ctx.fillStyle = root.barColor
                ctx.fillRect(x, base - h, root.barW, h)
            }
        }
    }

    onValuesChanged: cv.requestPaint()
    onBarColorChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()

    Repeater {
        model: root.ticks
        delegate: Text {
            required property var modelData
            x: 0
            width: root.padL - 8
            y: root.yOf(modelData) - height / 2
            horizontalAlignment: Text.AlignRight
            text: root.tickText(modelData)
            font.family: Type.family
            font.pixelSize: Type.sizeCaption - 2
            color: Colors.outlineVariant
        }
    }

    Repeater {
        model: root.barLabels
        delegate: Text {
            id: xlbl
            required property var modelData
            required property int index
            visible: String(modelData) !== ""
            width: root.slotW
            x: root.xOf(xlbl.index) - root.slotW / 2
            y: root.yOf(0) + 5
            horizontalAlignment: Text.AlignHCenter
            text: String(modelData)
            font.family: Type.family
            font.pixelSize: Type.sizeCaption - 2
            color: Colors.outlineVariant
        }
    }

    Repeater {
        model: root.values
        delegate: Text {
            id: vlbl
            required property var modelData
            required property int index
            visible: root.barW >= 16 && Number(modelData) > 0
            width: root.slotW
            x: root.xOf(vlbl.index) - root.slotW / 2
            y: Math.max(0, root.yOf(Number(modelData)) - height - 2)
            horizontalAlignment: Text.AlignHCenter
            text: root.tickText(Number(modelData))
            font.family: Type.family
            font.pixelSize: Type.sizeCaption - 2
            color: Colors.surfaceVariantText
        }
    }
}
