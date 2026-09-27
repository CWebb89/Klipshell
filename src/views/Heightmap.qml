pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../config"
import "../components"

// HEIGHTMAP: Mainsail's bed mesh tab. The reference implementation is
// `src/components/charts/HeightmapChart.vue` in Mainsail — an echarts-gl
// `surface` series: three stacked surfaces (probed / computed mesh / flat plane
// at z=0) whose colour comes from a visualMap ramp keyed on Z, framed inside the
// whole motion envelope, with a symmetric z axis of ±scaleZMax, a vertical
// colour legend and an orbitable camera.
//
// Here the surface is a Canvas 2D projection: each mesh cell is projected with
// a hand-rolled perspective camera and painted back-to-front with a linear
// gradient between its lowest and highest corner, so the ramp reads continuous
// and the sheet is solid. It replaced a QtQuick3D/ProceduralMesh implementation
// which — in this Qt 6.11.2 / Quickshell 0.3.1 combination — dropped roughly a
// third of the surface whenever more than one procedural Model was in the scene
// (1.42% enclosed holes with one Model, 12-18% with several, independent of
// material, indexing and visibility flags). Canvas is also the idiom the rest of
// this shell already uses, and it can be verified pixel by pixel.
//
// World axes: X = bed X, Y = height, Z = -bed Y, so the default camera sits in
// front of the bed's low-Y edge. Height is exaggerated: ±zScaleMax of deviation
// maps to ±zHalf world units, which is what makes 0.1 mm visible at all.
Item {
    id: root

    required property QtObject moonraker

    property var bm: ({})
    property bool showProbed: false
    property bool showMesh: true
    property bool showFlat: false
    property bool wireframe: false
    property bool scaleToProfile: true
    property real zScaleMax: 0.5
    property string scheme: "portland"
    property real camAlpha: 25
    property real camBeta: 40
    property real zoom: 1.55

    // Verbatim from Mainsail's heightmap store getters, so a mesh looks the
    // same here as it does there.
    readonly property var palettes: ({
        portland: ["#313695", "#4575b4", "#74add1", "#abd9e9", "#e0f3f8", "#ffffbf",
                   "#fee090", "#fdae61", "#f46d43", "#d73027", "#a50026"],
        spring: ["#ff00ff", "#ffff00"],
        hot: ["#000000", "#ff0000", "#ffff00", "#ffffff"],
        hsv: ["#0000ff", "#00ffff", "#00ff00", "#ffff00", "#ff0000"],
        grayscale: ["#ffffff", "#000000"]
    })
    readonly property var stops: root.palettes[root.scheme] ?? root.palettes.portland

    readonly property var matrix: root.showProbed ? (root.bm.probedMatrix ?? []) : (root.bm.meshMatrix ?? [])
    readonly property int rows: root.matrix.length
    readonly property int cols: root.rows > 0 ? root.matrix[0].length : 0
    readonly property bool hasMesh: root.rows > 1 && root.cols > 1
    readonly property int probedRows: (root.bm.probedMatrix ?? []).length
    readonly property int probedCols: root.probedRows > 0 ? root.bm.probedMatrix[0].length : 0

    // ── Envelope framing (Mainsail frames the motion envelope, not the mesh) ──
    readonly property real envX0: root.bm.axisMin?.[0] ?? 0
    readonly property real envX1: root.bm.axisMax?.[0] ?? 350
    readonly property real envY0: root.bm.axisMin?.[1] ?? 0
    readonly property real envY1: root.bm.axisMax?.[1] ?? 350
    readonly property real envCx: (root.envX0 + root.envX1) / 2
    readonly property real envCy: (root.envY0 + root.envY1) / 2
    readonly property real envSpan: Math.max(root.envX1 - root.envX0, root.envY1 - root.envY0, 1)
    readonly property real zHalf: root.envSpan * 0.25

    // ── visualMap and the colour ramp ─────────────────────────────────────────
    readonly property var meshValues: root._values(root.matrix)

    readonly property var ramp: {
        if (!root.scaleToProfile) return [-0.1, 0.1]
        var v = root.meshValues
        if (v.length === 0) return [-0.1, 0.1]
        // 0 is always inside the range, so the flat plane lands on the ramp
        // instead of falling off its end. Same rule as Mainsail's heightmapLimit.
        var lo = Math.min(0, Math.min.apply(null, v))
        var hi = Math.max(0, Math.max.apply(null, v))
        if (hi - lo < 1e-4) return [-0.1, 0.1]
        return [lo, hi]
    }
    readonly property var meshStats: {
        var v = root.meshValues
        if (v.length === 0) return { lo: 0, hi: 0, variance: 0 }
        var lo = Math.min.apply(null, v)
        var hi = Math.max.apply(null, v)
        return { lo: lo, hi: hi, variance: hi - lo }
    }

    function _values(m) {
        var out = []
        if (!m) return out
        for (var j = 0; j < m.length; j++)
            for (var i = 0; i < m[j].length; i++) out.push(Number(m[j][i]) || 0)
        return out
    }

    function _rgb(hex) {
        return [parseInt(hex.substr(1, 2), 16) / 255,
                parseInt(hex.substr(3, 2), 16) / 255,
                parseInt(hex.substr(5, 2), 16) / 255]
    }

    // Linear interpolation across the palette stops — the same interpolation
    // echarts' visualMap does between its `inRange.color` entries.
    function rampColor(t) {
        var s = root.stops
        var x = Math.max(0, Math.min(1, t)) * (s.length - 1)
        var i = Math.floor(x)
        var f = x - i
        var j = Math.min(i + 1, s.length - 1)
        var a = root._rgb(s[i])
        var b = root._rgb(s[j])
        return Qt.vector4d(a[0] + (b[0] - a[0]) * f,
                           a[1] + (b[1] - a[1]) * f,
                           a[2] + (b[2] - a[2]) * f, 1)
    }

    function colorOf(v) {
        var span = Math.max(1e-6, root.ramp[1] - root.ramp[0])
        return root.rampColor((v - root.ramp[0]) / span)
    }

    // ── Geometry ──────────────────────────────────────────────────────────────
    // Heights are baked already exaggerated (mm / zScaleMax * zHalf) so normals
    // Heights are exaggerated: ±zScaleMax of deviation maps to ±zHalf world
    // units, which is what makes 0.1 mm visible at all.
    readonly property real perMm: root.zHalf / Math.max(1e-6, root.zScaleMax)

    // ── Projection ────────────────────────────────────────────────────────────
    // Hand-rolled orbit camera: eye on a sphere (elevation camAlpha, azimuth
    // camBeta) looking at the bed centre, perspective divide with a 45° vertical
    // field of view. This replaces QtQuick3D, whose procedural geometry dropped
    // roughly a third of the surface in this build (measured by flood-filling
    // enclosed background pixels in grabToImage output: 1.42% holes with a
    // single procedural Model, 12-18% with several, no matter the material,
    // whether the index list was used, or whether the extra models were emptied).
    // A Canvas gives exact control and can be checked pixel by pixel.
    function _world(i, j, v) {
        var mn = root.bm.min ?? [0, 0]
        var mx = root.bm.max ?? [1, 1]
        var dx = root.cols > 1 ? (mx[0] - mn[0]) / (root.cols - 1) : 0
        var dy = root.rows > 1 ? (mx[1] - mn[1]) / (root.rows - 1) : 0
        return [mn[0] + dx * i - root.envCx,
                v * root.perMm,
                -(mn[1] + dy * j - root.envCy)]
    }

    function _cross(a, b) {
        return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
    }

    function _norm(a) {
        var l = Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]) || 1
        return [a[0] / l, a[1] / l, a[2] / l]
    }

    function _camera(W, H) {
        var a = root.camAlpha * Math.PI / 180
        var b = root.camBeta * Math.PI / 180
        var ca = Math.cos(a)
        var sa = Math.sin(a)
        var dist = root.envSpan * root.zoom
        var eye = [dist * ca * Math.sin(b), dist * sa, dist * ca * Math.cos(b)]
        var fwd = _norm([-eye[0], -eye[1], -eye[2]])
        var up = Math.abs(sa) > 0.985 ? [0, 0, -1] : [0, 1, 0]
        var right = _norm(_cross(fwd, up))
        var upv = _cross(right, fwd)
        return { eye: eye, fwd: fwd, right: right, up: upv,
                 focal: (H / 2) / Math.tan(45 * Math.PI / 360) }
    }

    // world -> [screen x, screen y, depth]
    function _screen(cam, p, W, H) {
        var dx = p[0] - cam.eye[0]
        var dy = p[1] - cam.eye[1]
        var dz = p[2] - cam.eye[2]
        var zc = Math.max(1, dx * cam.fwd[0] + dy * cam.fwd[1] + dz * cam.fwd[2])
        return [W / 2 + cam.focal * (dx * cam.right[0] + dy * cam.right[1] + dz * cam.right[2]) / zc,
                H / 2 - cam.focal * (dx * cam.up[0] + dy * cam.up[1] + dz * cam.up[2]) / zc,
                zc]
    }

    function _rgba(v, alpha) {
        return "rgba(" + Math.round(v[0] * 255) + "," + Math.round(v[1] * 255) + ","
            + Math.round(v[2] * 255) + "," + (alpha === undefined ? 1 : alpha) + ")"
    }

    // ── Camera presets (echarts viewControl alpha/beta, per Mainsail) ─────────
    function setOrientation(name) {
        if (name === "leftFront") { root.camAlpha = 25; root.camBeta = -40 }
        else if (name === "front") { root.camAlpha = 25; root.camBeta = 0 }
        else if (name === "top") { root.camAlpha = 90; root.camBeta = 0 }
        else { root.camAlpha = 25; root.camBeta = 40 }
    }

    function orientationName() {
        if (root.camAlpha === 90) return "top"
        if (root.camBeta === 0) return "front"
        return root.camBeta < 0 ? "leftFront" : "rightFront"
    }

    function profileNames() {
        return Object.keys(root.bm.profiles ?? {})
    }

    function profileVariance(name) {
        var p = (root.bm.profiles ?? {})[name]
        if (!p || !p.points) return null
        var v = root._values(p.points)
        if (v.length === 0) return null
        return Math.max.apply(null, v) - Math.min.apply(null, v)
    }

    function fmt(v, digits) {
        if (v === null || v === undefined || !isFinite(v)) return "—"
        var n = Settings.lengthValue(v)
        return (n > 0 ? "+" : "") + Number(n).toFixed(digits === undefined ? 3 : digits)
    }

    function repaint() {
        if (view) view.requestPaint()
    }

    function refresh() {
        root.moonraker.fetchBedMesh()
    }

    Component.onCompleted: root.refresh()

    Connections {
        target: root.moonraker
        function onBucketChanged(bucket) {
            if (bucket === "bedmesh") {
                root.bm = root.moonraker.data?.bedmesh ?? ({})
                root.repaint()
            }
        }
    }

    Panel {
        anchors.fill: parent
        anchors.margins: Metrics.panelMargin
        title: "HEIGHTMAP"; icon: Icons.heightmap
        collapsible: false

        Item {
            id: emptyState
            anchors.fill: parent
            anchors.topMargin: parent.bodyTop
            visible: !root.hasMesh

            Text {
                anchors.centerIn: parent
                width: parent.width * 0.6
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: "No bed mesh loaded. Run a calibration on the printer to populate this view."
                font.family: Type.family
                font.pixelSize: Type.sizeSmall
                color: Colors.textTertiary
            }
        }

        Row {
            id: body
            anchors.left: parent.left
            anchors.leftMargin: Metrics.panelPadding
            anchors.right: parent.right
            anchors.rightMargin: Metrics.panelPadding
            anchors.top: parent.top
            anchors.topMargin: parent.bodyTop
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.panelPadding
            spacing: Metrics.lg

            // ── The surface ────────────────────────────────────────────────
            Rectangle {
                id: viewBox
                width: parent.width - side.width - Metrics.lg
                height: parent.height
                color: Colors.surfaceContainerLowest
                radius: Metrics.radiusMedium
                border.width: Metrics.borderWidth
                border.color: Colors.outlineVariant
                clip: true

                Canvas {
                    id: view
                    anchors.fill: parent
                    visible: root.hasMesh
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    // Painter's algorithm over the mesh cells. Colour is per cell
                    // (a linear gradient between its lowest and highest corner, so
                    // the ramp reads continuous), plus optional wireframe and the
                    // flat z=0 reference quad, all sorted far-to-near together.
                    onPaint: {
                        var ctx = view.getContext("2d")
                        ctx.reset()
                        if (!root.hasMesh) return
                        var W = view.width
                        var H = view.height
                        var cam = root._camera(W, H)
                        var quads = []
                        var i = 0
                        var j = 0
                        var m = root.matrix

                        for (j = 0; j < root.rows - 1; j++) {
                            for (i = 0; i < root.cols - 1; i++) {
                                var v00 = Number(m[j][i]) || 0
                                var v10 = Number(m[j][i + 1]) || 0
                                var v11 = Number(m[j + 1][i + 1]) || 0
                                var v01 = Number(m[j + 1][i]) || 0
                                var pts = [
                                    root._screen(cam, root._world(i, j, v00), W, H),
                                    root._screen(cam, root._world(i + 1, j, v10), W, H),
                                    root._screen(cam, root._world(i + 1, j + 1, v11), W, H),
                                    root._screen(cam, root._world(i, j + 1, v01), W, H)
                                ]
                                var vals = [v00, v10, v11, v01]
                                var lo = 0
                                var hi = 0
                                for (var k = 1; k < 4; k++) {
                                    if (vals[k] < vals[lo]) lo = k
                                    if (vals[k] > vals[hi]) hi = k
                                }
                                quads.push({ pts: pts, lo: lo, hi: hi,
                                             va: vals[lo], vb: vals[hi],
                                             depth: (pts[0][2] + pts[1][2] + pts[2][2] + pts[3][2]) / 4,
                                             kind: "mesh" })
                            }
                        }

                        if (root.showFlat) {
                            var f = [
                                root._screen(cam, root._world(0, 0, 0), W, H),
                                root._screen(cam, root._world(root.cols - 1, 0, 0), W, H),
                                root._screen(cam, root._world(root.cols - 1, root.rows - 1, 0), W, H),
                                root._screen(cam, root._world(0, root.rows - 1, 0), W, H)
                            ]
                            quads.push({ pts: f, lo: 0, hi: 0, va: 0, vb: 0,
                                         depth: (f[0][2] + f[1][2] + f[2][2] + f[3][2]) / 4,
                                         kind: "flat" })
                        }

                        quads.sort(function(p, q) { return q.depth - p.depth })

                        for (var n = 0; n < quads.length; n++) {
                            var Q = quads[n]
                            var p0 = Q.pts[0]
                            var p1 = Q.pts[1]
                            var p2 = Q.pts[2]
                            var p3 = Q.pts[3]
                            ctx.beginPath()
                            ctx.moveTo(p0[0], p0[1])
                            ctx.lineTo(p1[0], p1[1])
                            ctx.lineTo(p2[0], p2[1])
                            ctx.lineTo(p3[0], p3[1])
                            ctx.closePath()
                            if (Q.kind === "flat") {
                                ctx.fillStyle = "rgba(216,194,186,0.18)"
                                ctx.fill()
                                continue
                            }
                            var ca = Q.pts[Q.lo]
                            var cb = Q.pts[Q.hi]
                            var colLo = root.colorOf(Q.va)
                            var colHi = root.colorOf(Q.vb)
                            var grad = ctx.createLinearGradient(ca[0], ca[1], cb[0], cb[1])
                            grad.addColorStop(0, root._rgba([colLo.x, colLo.y, colLo.z]))
                            grad.addColorStop(1, root._rgba([colHi.x, colHi.y, colHi.z]))
                            ctx.fillStyle = grad
                            ctx.fill()
                            // Hairline of the mean colour: hides the anti-aliased
                            // seam between neighbouring cells sharing an edge.
                            ctx.strokeStyle = grad
                            ctx.lineWidth = 1
                            ctx.stroke()
                        }

                        if (root.wireframe) {
                            ctx.strokeStyle = "rgba(241,223,217,0.45)"
                            ctx.lineWidth = 1
                            for (j = 0; j < root.rows; j++) {
                                ctx.beginPath()
                                for (i = 0; i < root.cols; i++) {
                                    var wp = root._screen(cam, root._world(i, j, Number(m[j][i]) || 0), W, H)
                                    if (i === 0) ctx.moveTo(wp[0], wp[1])
                                    else ctx.lineTo(wp[0], wp[1])
                                }
                                ctx.stroke()
                            }
                            for (i = 0; i < root.cols; i++) {
                                ctx.beginPath()
                                for (j = 0; j < root.rows; j++) {
                                    var wq = root._screen(cam, root._world(i, j, Number(m[j][i]) || 0), W, H)
                                    if (j === 0) ctx.moveTo(wq[0], wq[1])
                                    else ctx.lineTo(wq[0], wq[1])
                                }
                                ctx.stroke()
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.hasMesh
                    cursorShape: Qt.OpenHandCursor
                    property real lastX: 0
                    property real lastY: 0
                    property bool dragging: false
                    onPressed: function(e) {
                        dragging = true
                        lastX = e.x
                        lastY = e.y
                        cursorShape = Qt.ClosedHandCursor
                    }
                    onReleased: cursorShape = Qt.OpenHandCursor
                    onPositionChanged: function(e) {
                        if (!dragging) return
                        root.camBeta = root.camBeta - (e.x - lastX) * 0.4
                        root.camAlpha = Math.max(5, Math.min(90, root.camAlpha + (e.y - lastY) * 0.4))
                        lastX = e.x
                        lastY = e.y
                        view.requestPaint()
                    }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        root.zoom = Math.max(0.8, Math.min(4, root.zoom * (1 - event.angleDelta.y * 0.001)))
                        view.requestPaint()
                        event.accepted = true
                    }
                }

                Item {
                    id: legend
                    visible: root.hasMesh
                    anchors.left: parent.left
                    anchors.leftMargin: Metrics.md + Metrics.xs
                    anchors.verticalCenter: parent.verticalCenter
                    width: 92
                    height: parent.height * 0.66

                    Canvas {
                        id: legendBar
                        anchors.left: parent.left
                        width: 22
                        height: parent.height
                        onPaint: {
                            var ctx = legendBar.getContext("2d")
                            ctx.reset()
                            var g = ctx.createLinearGradient(0, 0, 0, legendBar.height)
                            var s = root.stops
                            for (var i = 0; i < s.length; i++)
                                g.addColorStop(i / (s.length - 1), s[s.length - 1 - i])
                            ctx.fillStyle = g
                            ctx.fillRect(0, 0, legendBar.width, legendBar.height)
                        }
                        Connections {
                            target: root
                            function onStopsChanged() { legendBar.requestPaint() }
                        }
                        Component.onCompleted: legendBar.requestPaint()
                    }

                    Text {
                        anchors.left: legendBar.right
                        anchors.leftMargin: Metrics.sm
                        anchors.top: parent.top
                        anchors.topMargin: -2
                        text: root.fmt(root.ramp[1])
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        color: Colors.textPrimary
                    }
                    Text {
                        anchors.left: legendBar.right
                        anchors.leftMargin: Metrics.sm
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fmt((root.ramp[0] + root.ramp[1]) / 2)
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        color: Colors.surfaceVariantText
                    }
                    Text {
                        anchors.left: legendBar.right
                        anchors.leftMargin: Metrics.sm
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -2
                        text: root.fmt(root.ramp[0])
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        color: Colors.textPrimary
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -22
                        text: Settings.lengthSuffix()
                        font.family: Type.family
                        font.pixelSize: Type.sizeCaption
                        color: Colors.surfaceVariantText
                    }
                }

                Text {
                    visible: root.hasMesh
                    anchors.right: parent.right
                    anchors.rightMargin: Metrics.md
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Metrics.sm
                    text: "drag to orbit · wheel to zoom"
                    font.family: Type.family
                    font.pixelSize: Type.sizeCaption
                    color: Colors.textTertiary
                }
            }

            // ── Side rail ──────────────────────────────────────────────────
            Flickable {
                id: side
                width: 322
                height: parent.height
                clip: true
                contentHeight: sideCol.height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sideCol
                    width: side.width
                    spacing: Metrics.sm

                    SectionHeader { text: "CURRENT MESH"; icon: Icons.target }

                    KV { key: "Profile"; labelWidth: 104; value: root.bm.profile ?? "—" }
                    KV {
                        key: "Mesh area"
                        labelWidth: 104
                        value: root.hasMesh
                            ? (root.bm.min[0] + "–" + root.bm.max[0] + " × " + root.bm.min[1] + "–" + root.bm.max[1] + " mm")
                            : "—"
                    }
                    KV {
                        key: "Range"
                        labelWidth: 104
                        value: root.hasMesh ? (root.fmt(root.meshStats.lo) + " … " + root.fmt(root.meshStats.hi) + " " + Settings.lengthSuffix()) : "—"
                    }
                    KV {
                        key: "Variance"
                        labelWidth: 104
                        value: root.hasMesh ? (root.meshStats.variance.toFixed(3) + " mm") : "—"
                    }
                    KV {
                        key: "Grid"
                        labelWidth: 104
                        value: root.hasMesh
                            ? (root.probedCols + " × " + root.probedRows + " probes → "
                               + root.cols + " × " + root.rows)
                            : "—"
                    }

                    Separator { width: parent.width }

                    SectionHeader { text: "PROFILES"; icon: Icons.folder }

                    Repeater {
                        model: root.profileNames()
                        delegate: Item {
                            id: prow
                            required property string modelData
                            width: sideCol.width
                            height: 22
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: prow.modelData
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: prow.modelData === root.bm.profile ? Colors.accent : Colors.surfaceVariantText
                                elide: Text.ElideRight
                                width: parent.width - 74
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    var v = root.profileVariance(prow.modelData)
                                    return v === null ? "—" : v.toFixed(3) + " mm"
                                }
                                font.family: Type.family
                                font.pixelSize: Type.sizeCaption
                                color: Colors.textSecondary
                            }
                        }
                    }

                    Separator { width: parent.width }

                    SectionHeader { text: "DISPLAY"; icon: Icons.eye }

                    Flow {
                        width: parent.width
                        spacing: Metrics.sm

                        Button {
                            height: 26
                            text: "PROBED"; icon: Icons.target
                            variant: root.showProbed ? "primary" : "soft"
                            onPressed: { root.showProbed = !root.showProbed; root.repaint() }
                        }
                        Button {
                            height: 26
                            text: "MESH"; icon: Icons.grid
                            variant: root.showMesh ? "primary" : "soft"
                            onPressed: { root.showMesh = !root.showMesh; root.repaint() }
                        }
                        Button {
                            height: 26
                            text: "FLAT"
                            variant: root.showFlat ? "primary" : "soft"
                            onPressed: { root.showFlat = !root.showFlat; root.repaint() }
                        }
                        Button {
                            height: 26
                            text: "WIREFRAME"
                            variant: root.wireframe ? "primary" : "soft"
                            onPressed: { root.wireframe = !root.wireframe; root.repaint() }
                        }
                        Button {
                            height: 26
                            text: "SCALE TO PROFILE"
                            variant: root.scaleToProfile ? "primary" : "soft"
                            onPressed: { root.scaleToProfile = !root.scaleToProfile; root.repaint() }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Metrics.xs

                        SectionHeader { text: "COLOUR SCHEME"; icon: Icons.palette }

                        Repeater {
                            model: [
                                { key: "portland", label: "BLUE → RED" },
                                { key: "spring", label: "MAGENTA → YELLOW" },
                                { key: "hot", label: "FIRE" },
                                { key: "hsv", label: "RAINBOW" },
                                { key: "grayscale", label: "GRAY" }
                            ]
                            delegate: Row {
                                id: srow
                                required property var modelData
                                width: sideCol.width
                                height: 24
                                spacing: Metrics.sm

                                Button {
                                    width: 164
                                    height: 24
                                    text: srow.modelData.label
                                    variant: root.scheme === srow.modelData.key ? "primary" : "soft"
                                    onPressed: { root.scheme = srow.modelData.key; root.repaint() }
                                }

                                Canvas {
                                    id: swatch
                                    width: 130
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    onPaint: {
                                        var ctx = swatch.getContext("2d")
                                        ctx.reset()
                                        var g = ctx.createLinearGradient(0, 0, swatch.width, 0)
                                        var s = root.palettes[srow.modelData.key]
                                        for (var i = 0; i < s.length; i++)
                                            g.addColorStop(i / (s.length - 1), s[i])
                                        ctx.fillStyle = g
                                        ctx.fillRect(0, 0, swatch.width, swatch.height)
                                    }
                                    Component.onCompleted: swatch.requestPaint()
                                }
                            }
                        }
                    }

                    Separator { width: parent.width }

                    SectionHeader { text: "ORIENTATION"; icon: Icons.swap }

                    Flow {
                        width: parent.width
                        spacing: Metrics.sm

                        Repeater {
                            model: [
                                { id: "rightFront", label: "RIGHT FRONT" },
                                { id: "leftFront", label: "LEFT FRONT" },
                                { id: "front", label: "FRONT" },
                                { id: "top", label: "TOP" }
                            ]
                            delegate: Button {
                                id: orow
                                required property var modelData
                                height: 26
                                text: orow.modelData.label
                                variant: root.orientationName() === orow.modelData.id ? "primary" : "soft"
                                onPressed: { root.setOrientation(orow.modelData.id); root.repaint() }
                            }
                        }
                    }

                    Separator { width: parent.width }

                    Slider {
                        width: parent.width
                        label: "Z SCALE"
                        minimum: 0.05
                        maximum: 2
                        step: 0.05
                        integer: false
                        unit: " mm"
                        value: root.zScaleMax
                        onMoved: function(v) { root.zScaleMax = v; root.repaint() }
                        onReleased: function(v) { root.zScaleMax = v; root.repaint() }
                    }
                }
            }
        }
    }
}
