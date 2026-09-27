import QtQuick
import "../theme"

// Omarchy PopupCard: solid rounded panel with a 1px border. Adds a soft
// resting shadow (paired offset duplicates, no blur/Shapes/Canvas) and a
// faint top sheen for depth; hovering brightens the border and deepens
// the shadow slightly. Children render above the backdrop.
Item {
    id: root

    property color fill: Colors.surfaceContainer
    property color borderCol: Colors.outlineVariant
    property int radius: Metrics.radiusLarge
    property string header: ""
    property color headerColor: Colors.textPrimary
    property bool elevated: true

    readonly property bool hovered: hoverHandler.hovered

    // Soft resting shadow: two offset, low-opacity duplicates of the card
    // shape, peeking out from behind the bottom edge. No blur/Shapes/Canvas.
    Rectangle {
        visible: root.elevated
        x: 0
        y: Metrics.xs
        width: parent.width
        height: parent.height
        radius: root.radius
        color: Colors.alpha(Colors.shadow, root.hovered ? 0.16 : 0.10)
        Behavior on color { ColorAnimation { duration: 140 } }
    }
    Rectangle {
        visible: root.elevated
        x: 0
        y: Metrics.xxs
        width: parent.width
        height: parent.height
        radius: root.radius
        color: Colors.alpha(Colors.shadow, root.hovered ? 0.22 : 0.16)
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fill
    }

    // Faint top sheen: a hint of glass without a blur effect. Anchored to
    // the full card (not just the top half) so the rounded corners stay
    // correct; the gradient itself fades out well before the bottom edge.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Colors.alpha(Colors.surfaceText, 0.05) }
            GradientStop { position: 0.45; color: Colors.alpha(Colors.surfaceText, 0.0) }
            GradientStop { position: 1.0; color: Colors.alpha(Colors.surfaceText, 0.0) }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: Metrics.cardBorderWidth
        border.color: root.hovered ? Colors.outline : root.borderCol
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    Text {
        visible: root.header !== ""
        anchors.left: parent.left
        anchors.leftMargin: Metrics.panelPadding
        anchors.top: parent.top
        anchors.topMargin: Metrics.xxs
        text: root.header
        font.family: Type.family
        font.pixelSize: Type.sizeCaption
        font.bold: true
        font.letterSpacing: 1.1
        color: root.headerColor
    }

    HoverHandler {
        id: hoverHandler
    }
}
