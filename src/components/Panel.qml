import QtQuick
import "../theme"

// Mainsail Panel.vue card shell: square backdrop + header (title, collapse
// chevron). Content anchors itself below the header with
// `anchors.topMargin: parent.bodyTop` + `visible: parent.bodyVisible`.
// The caller sets `height` (see Dashboard.pHeight for the collapsed-short
// form) — this shell only renders chrome and exposes body geometry.
//
// Drag: on `draggable` panels the header (minus the chevron zone) reports a
// press-and-drag gesture as GLOBAL pointer coordinates via dragMoved/
// dragEnded. The dashboard owns hit-testing + reorder — no Quickshell
// Drag/DropArea machinery here (unverifiable drag semantics on this seat;
// MouseArea motion tracking + globalPosition are the proven path).
Item {
    id: root

    required property string title
    property string icon: ""
    property bool collapsible: true
    property bool collapsed: false
    property bool draggable: false
    property string pid: root.title
    signal toggled()
    signal dragMoved(real gx, real gy)
    signal dragEnded(real gx, real gy)

    readonly property int headerH: 34
    readonly property int bodyTop: root.headerH + 6
    readonly property bool bodyVisible: !root.collapsed

    readonly property bool hovered: hoverHandler.hovered

    clip: true

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Colors.surfaceContainerLow
    }
    // Faint top sheen: same 3-stop gradient as Card.qml, so panels read as
    // lit from the top like the card chrome elsewhere.
    Rectangle {
        anchors.fill: parent
        radius: 0
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Colors.alpha(Colors.surfaceText, 0.05) }
            GradientStop { position: 0.45; color: Colors.alpha(Colors.surfaceText, 0.0) }
            GradientStop { position: 1.0; color: Colors.alpha(Colors.surfaceText, 0.0) }
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: 0
        color: "transparent"
        border.width: Metrics.cardBorderWidth
        border.color: root.hovered ? Colors.edgeStrong : Colors.edge
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    HoverHandler {
        id: hoverHandler
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerH

        // Full-width header band: its border runs the same path as the
        // panel's outer border, so header and card frame read as one piece.
        Rectangle {
            anchors.fill: parent
            radius: 0
            color: Colors.alpha(Colors.accent, 0.12)
            border.width: Metrics.cardBorderWidth
            border.color: Colors.alpha(Colors.accent, 0.40)
        }
        Text {
            id: headerIcon
            visible: root.icon !== ""
            anchors.left: parent.left
            anchors.leftMargin: Metrics.md
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font.family: Type.family
            font.pixelSize: Type.iconLead
            color: Colors.textSecondary
        }

        Text {
            id: headerLabel
            anchors.centerIn: parent
            text: root.title
            font.family: Type.family
            font.pixelSize: Type.sizeSmall
            font.bold: true
            font.letterSpacing: 1.1
            color: Colors.textPrimary
        }

        Text {
            visible: root.collapsible
            anchors.right: parent.right
            anchors.rightMargin: 56
            anchors.verticalCenter: parent.verticalCenter
            text: root.collapsed ? Icons.next : Icons.expand
            font.family: Type.family
            font.pixelSize: Type.iconInline
            color: Colors.textSecondary
        }

        MouseArea {
            id: chevronArea
            visible: root.collapsible
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 84
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { root.collapsed = !root.collapsed; root.toggled() }
        }

        MouseArea {
            id: headerMouse
            visible: root.draggable
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 84
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: Qt.OpenHandCursor
            // Manual drag gesture: track motion from the press point; once
            // past 6px report global pointer coords. Works while the pointer
            // leaves the area (press grab), same as the old resize drag.
            property real _px: -1
            property real _py: -1
            property bool _dm: false
            onPressed: (e) => { headerMouse._px = e.x; headerMouse._py = e.y; headerMouse._dm = false }
            onMouseXChanged: { headerMouse._track(headerMouse.mouseX, headerMouse.mouseY) }
            onMouseYChanged: { headerMouse._track(headerMouse.mouseX, headerMouse.mouseY) }
            function _track(x, y) {
                if (headerMouse._px < 0) return
                if (!headerMouse._dm) {
                    if (Math.abs(x - headerMouse._px) < 6 && Math.abs(y - headerMouse._py) < 6) return
                    headerMouse._dm = true
                }
                var gp = headerMouse.globalPosition
                root.dragMoved(gp.x + x, gp.y + y)
            }
            onReleased: {
                if (headerMouse._dm) {
                    var gp = headerMouse.globalPosition
                    root.dragEnded(gp.x + headerMouse.mouseX, gp.y + headerMouse.mouseY)
                    headerMouse._dm = false
                }
                headerMouse._px = -1
            }
        }
    }
}