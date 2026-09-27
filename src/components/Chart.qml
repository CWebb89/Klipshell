pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../config"

// Line chart for time-series (temp history). Auto y-scale with nice grid
// steps, per-series glow strokes, dashed target lines, hover crosshair.
// Canvas draws vectors only (no fillText in this Canvas) — text labels are
// Item overlays bound to the same geometry.
Item {
    id: root

    required property var series
    property bool showTargets: true

    property int hoverIndex: -1

    readonly property int padL: 8
    readonly property int padR: 8
    readonly property int padT: 10
    readonly property int padB: 10

    readonly property var plot: {
        var maxN = 0
        for (var i = 0; i < (root.series || []).length; i++)
            maxN = Math.max(maxN, (root.series[i].values || []).length)
        return {
            n: maxN,
            x: root.padL,
            w: Math.max(1, width - root.padL - root.padR),
            y: root.padT,
            h: Math.max(1, height - root.padT - root.padB)
        }
    }

    // min/max over every non-null value of every series, padded 12%.
    readonly property var yScale: {
        var lo, hi
        for (var i = 0; i < root.series.length; i++) {
            var vals = root.series[i].values || []
            for (var j = 0; j < vals.length; j++) {
                var v = vals[j]
                if (v === null || Number.isNaN(v)) continue
                if (lo === undefined || v < lo) lo = v
                if (hi === undefined || v > hi) hi = v
            }
        }
        if (lo === undefined) return null
        // enforce a wide-enough window: when standby temps all cluster (e.g.
        // 24.7°±0.2) a tight auto-scale turns the line into a thick band.
        // A ~40° window keeps a realistic thin line like Mainsail.
        var pad = (hi - lo) * 0.12
        if (pad <= 0) pad = 1
        var half = Math.max((hi - lo) / 2 + pad, 20)
        var mid = (hi + lo) / 2
        return { min: mid - half, max: mid + half }
    }

    function yOf(v) {
        return root.padT + root.plot.h * (1 - (v - root.yScale.min) / (root.yScale.max - root.yScale.min))
    }
    function xOf(i) {
        return root.padL + root.plot.w * (root.plot.n > 1 ? i / (root.plot.n - 1) : 0)
    }
    // readout rows while hovering: series + value (+ target) at hoverIndex.
    readonly property var readouts: {
        if (root.hoverIndex < 0) return []
        var out = []
        for (var i = 0; i < root.series.length; i++) {
            var s = root.series[i]
            var vals = s.values || []
            if (root.hoverIndex >= vals.length) continue
            var v = vals[root.hoverIndex]
            if (v === null || Number.isNaN(v)) continue
            var label = s.name + " " + Settings.tempText(v)
            if (s.target !== null && s.target !== undefined && !Number.isNaN(s.target))
                label += " / " + Settings.tempText(s.target)
            out.push({ color: s.color, text: label, y: root.padT + out.length * 14,
                      x: Math.min(root.xOf(root.hoverIndex) + 10, Math.max(root.padL, width - 200)) })
        }
        return out
    }

    property real glowPulse: 1.0

    // smooth path through a series' values: quadratic midpoint interpolation,
    // breaking at null gaps (webb-shell SystemMonitorPopup.trace).
    function traceSmooth(ctx, vals) {
        var n = vals.length
        var runStart = -1
        for (var i = 0; i <= n; i++) {
            var valid = i < n && vals[i] !== null && !Number.isNaN(vals[i])
            if (valid && runStart < 0) {
                runStart = i
                ctx.moveTo(root.xOf(i), root.yOf(vals[i]))
            } else if (!valid && runStart >= 0) {
                for (var k = runStart; k < i - 1; k++) {
                    ctx.quadraticCurveTo(
                        root.xOf(k), root.yOf(vals[k]),
                        (root.xOf(k) + root.xOf(k + 1)) / 2, (root.yOf(vals[k]) + root.yOf(vals[k + 1])) / 2)
                }
                ctx.lineTo(root.xOf(i - 1), root.yOf(vals[i - 1]))
                runStart = -1
            }
        }
    }

    function dashSegments(ctx, x0, x1, y) {
        var dash = 5
        var gap = 4
        var x = x0
        while (x < x1) {
            var xe = Math.min(x + dash, x1)
            ctx.moveTo(x, y)
            ctx.lineTo(xe, y)
            x = xe + gap
        }
    }

    // ── vectors ─────────────────────────────────────────────────────────
    Canvas {
        id: plotCanvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            if (!ctx) return
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            if (!root.yScale || root.plot.n === 0) return

            var px = root.plot.x
            var py = root.plot.y
            var pw = root.plot.w
            var ph = root.plot.h
            var lineJoin = "round"
            var lineCap = "round"

            // per series: smooth spark line (webb-shell stat style) + head dot
            for (var i = 0; i < root.series.length; i++) {
                var s = root.series[i]
                var vals = s.values || []
                if (vals.length === 0) continue
                var hasDraw = false
                for (var j = 0; j < vals.length; j++)
                    if (vals[j] !== null && !Number.isNaN(vals[j])) { hasDraw = true; break }
                if (!hasDraw) continue

                ctx.lineJoin = "round"
                ctx.lineCap = "round"

                // soft neon glow pass keeps the thin core readable on dark bg
                ctx.strokeStyle = Colors.alpha(s.color, 0.28 * root.glowPulse)
                ctx.lineWidth = 6
                root.traceSmooth(ctx, vals)
                ctx.stroke()

                // core solid line
                ctx.strokeStyle = s.color
                ctx.lineWidth = 2.5
                root.traceSmooth(ctx, vals)
                ctx.stroke()

                // latest-point head dot (glow halo + core)
                var last = vals.length - 1
                while (last >= 0 && (vals[last] === null || Number.isNaN(vals[last]))) last--
                if (last >= 0) {
                    var hx = root.xOf(last)
                    var hy = root.yOf(vals[last])
                    ctx.beginPath()
                    ctx.arc(hx, hy, 8, 0, Math.PI * 2)
                    ctx.closePath()
                    ctx.fillStyle = Colors.alpha(s.color, 0.25 * root.glowPulse)
                    ctx.fill()
                    ctx.beginPath()
                    ctx.arc(hx, hy, 3, 0, Math.PI * 2)
                    ctx.closePath()
                    ctx.fillStyle = s.color
                    ctx.fill()
                }
            }

            // dashed target lines (single current target per series)
            if (root.showTargets) {
                for (var ti = 0; ti < root.series.length; ti++) {
                    var ts = root.series[ti]
                    if (ts.target === null || ts.target === undefined || Number.isNaN(ts.target)) continue
                    var ty = root.yOf(ts.target)
                    if (ty < py - 5 || ty > py + ph + 5) continue
                    ctx.strokeStyle = Colors.alpha(ts.color, 0.8)
                    ctx.lineWidth = 1
                    root.dashSegments(ctx, px + 1, px + pw - 1, ty)
                    ctx.stroke()
                }
            }

            // hover crosshair + sample dots
            if (root.hoverIndex >= 0) {
                var hxi = root.hoverIndex
                var hxv = root.xOf(hxi)
                ctx.strokeStyle = Colors.alpha(Colors.surfaceVariantText, 0.55)
                ctx.lineWidth = 1
                ctx.moveTo(hxv, py)
                ctx.lineTo(hxv, py + ph)
                ctx.stroke()
                for (var di = 0; di < root.series.length; di++) {
                    var ds = root.series[di]
                    var dvals = ds.values || []
                    if (hxi >= dvals.length) continue
                    var dv = dvals[hxi]
                    if (dv === null || Number.isNaN(dv)) continue
                    ctx.beginPath()
                    ctx.arc(hxv, root.yOf(dv), 2.4, 0, Math.PI * 2)
                    ctx.closePath()
                    ctx.fillStyle = ds.color
                    ctx.fill()
                }
            }
        }
    }

    // ── hover readouts (stacked under the top pad, right of the line) ──
    Repeater {
        model: root.readouts
        delegate: Text {
            required property var modelData
            x: modelData.x
            y: modelData.y - 6
            width: 190
            height: 14
            maximumLineCount: 1
            elide: Text.ElideRight
            text: modelData.text
            font.family: Type.family
            font.pixelSize: Type.sizeSmall
            font.bold: true
            color: modelData.color
        }
    }

    // ── hover input ─────────────────────────────────────────────────────
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateHover() {
            if (!hover.containsMouse) { root.hoverIndex = -1; return }
            var n = root.plot.n
            if (n === 0) { root.hoverIndex = -1; return }
            var fx = (hover.mouseX - root.padL) / root.plot.w
            root.hoverIndex = Math.max(0, Math.min(n - 1, Math.round(fx * (n > 1 ? n - 1 : 0))))
        }

        onMouseXChanged: updateHover()
        onMouseYChanged: updateHover()
        onContainsMouseChanged: updateHover()
    }

    onSeriesChanged: plotCanvas.requestPaint()
    onShowTargetsChanged: plotCanvas.requestPaint()
    onHoverIndexChanged: plotCanvas.requestPaint()
}