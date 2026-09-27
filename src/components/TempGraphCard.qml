pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../config"
import "."

// TempGraphCard: Mainsail-style temperature history panel — series legend
// chips (click to toggle), a target-line toggle, and the time-series Chart.
// Driven by a `store` array of {name, temp[], target[]} from the polled
// /server/temperature_store. Reused by the Dashboard and Temp views.
Item {
    id: root

    required property var store
    property var hidden: ({})
    property bool showTargets: true
    property bool _hiddenInit: false

    function refresh() {}

    // Default to showing only the primary (extruder) as one solid line,
    // like Mainsail; the legend chips toggle other sensors on/off.
    readonly property var _allNames: {
        var names = []
        for (var i = 0; i < root.store.length; i++) {
            var n = root.store[i].name
            if (names.indexOf(n) < 0) names.push(n)
        }
        return names
    }
    on_AllNamesChanged: {
        if (root._hiddenInit || root.store.length === 0) return
        var primary = root._allNames.indexOf("extruder") >= 0 ? "extruder" : root._allNames[0]
        var h = {}
        for (var i = 0; i < root._allNames.length; i++) h[root._allNames[i]] = root._allNames[i] !== primary
        root.hidden = h
        root._hiddenInit = true
    }

    readonly property string emptyText: {
        if (!root.store || root.store.length === 0) return "no temperature history yet"
        return ""
    }

    function seriesColor(name) {
        if (name === "extruder") return Colors.accent
        if (name === "heater_bed") return Colors.tempWarm
        var p = [Colors.success, Colors.tempHot, Colors.tempCool, Colors.tempWarm]
        var h = 0
        var s = String(name)
        for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 997
        return p[h % p.length]
    }

    function lastValue(arr) {
        var a = arr || []
        for (var i = a.length - 1; i >= 0; i--)
            if (a[i] !== null && !Number.isNaN(a[i])) return a[i]
        return null
    }

    function shortName(name) {
        var s = String(name).trim()
        var i = s.lastIndexOf(" ")
        return i >= 0 ? s.slice(i + 1) : s
    }

    function toggle(name) {
        var h = {}
        for (var k in root.hidden) h[k] = root.hidden[k]
        h[name] = !h[name]
        root.hidden = h
    }

    readonly property var chartSeries: {
        var out = []
        for (var i = 0; i < root.store.length; i++) {
            var s = root.store[i]
            if (root.hidden[s.name]) continue
            out.push({
                name: s.name,
                color: root.seriesColor(s.name),
                values: s.temp,
                target: root.showTargets ? root.lastValue(s.target) : null
            })
        }
        return out
    }

    Column {
        anchors.fill: parent
        spacing: Metrics.lg

        Flow {
            id: legend
            width: parent.width
            spacing: Metrics.sm

            Repeater {
                model: root.store
                delegate: Item {
                    id: leg
                    required property var modelData
                    readonly property string chipLabel: root.shortName(leg.modelData.name) + " "
                        + Settings.tempText(root.lastValue(leg.modelData.temp))
                    width: Math.min(240, Math.ceil(leg.chipLabel.length * Type.sizeSmall * 0.65) + 32)
                    height: Metrics.controlHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: Metrics.radiusSmall
                        color: mouse.containsMouse ? Colors.hoverFill
                             : (root.hidden[leg.modelData.name] ? "transparent" : Colors.alpha(root.seriesColor(leg.modelData.name), 0.10))
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.hidden[leg.modelData.name] ? Colors.outlineVariant
                                 : root.seriesColor(leg.modelData.name)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            text: leg.chipLabel
                            font.family: Type.family
                            font.pixelSize: Type.sizeSmall
                            font.bold: true
                            color: root.hidden[leg.modelData.name] ? Colors.outlineVariant
                                 : root.seriesColor(leg.modelData.name)
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggle(leg.modelData.name)
                    }
                }
            }

            Item {
                width: Math.ceil("TARGET".length * Type.sizeSmall * 0.65) + 32
                height: Metrics.controlHeight
                Rectangle {
                    anchors.fill: parent
                    radius: Metrics.radiusSmall
                    color: root.showTargets ? Colors.alpha(Colors.accent, 0.10) : "transparent"
                    border.width: Metrics.borderWidth
                    border.color: root.showTargets ? Colors.alpha(Colors.accent, 0.6) : Colors.outlineVariant
                }
                Text {
                    anchors.centerIn: parent
                    text: "TARGET"
                    font.family: Type.family
                    font.pixelSize: Type.sizeSmall
                    font.bold: true
                    font.letterSpacing: 0.6
                    color: root.showTargets ? Colors.accent : Colors.outlineVariant
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showTargets = !root.showTargets
                }
            }
        }

        Chart {
            width: parent.width
            height: Math.max(120, parent.height - legend.height - Metrics.lg)
            series: root.chartSeries
            showTargets: root.showTargets && root.chartSeries.length > 0
            visible: root.store.length > 0
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 110
            visible: root.store.length === 0
            text: root.emptyText
            font.family: Type.family
            font.pixelSize: Type.sizeBody
            font.bold: true
            color: Colors.surfaceVariantText
        }
    }
}
