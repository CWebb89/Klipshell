import QtQuick
import "../theme"

// Omarchy-style action button: flat, state-driven fills (fg@8% hover,
// fg@22% pressed) + caption-bold label, with an optional leading icon
// glyph and a small tactile press-scale. variant: primary (accent),
// danger (urgent — error text on an error wash), plain (outline),
// soft (accent text, no fill). `solid` turns danger into a filled red
// (errorContainer + errorContainerText) for a true stop control.
// rounded/bold/iconPixelSize exist for the chrome buttons (dashboard
// transport + bell), which are square, always bold and lead with a
// larger glyph than the inline icons. The icon is centred in a box the
// label's height, so its ink sits level with the label's.
Item {
    id: root

    required property string text
    property string variant: "plain"
    property bool active: true
    property string icon: ""
    property bool solid: false
    property bool rounded: true
    property bool bold: root.act
    property int iconPixelSize: Type.iconInline
    signal pressed()

    readonly property bool dangerSolid: root.solid && root.variant === "danger"
    readonly property bool act: variant === "primary" || variant === "danger" || variant === "soft"
    readonly property color fg: !root.active
        ? Colors.textMuted
        : root.dangerSolid ? Colors.errorContainerText
        : root.variant === "danger" ? Colors.error
        : (root.variant === "primary" || root.variant === "soft") ? Colors.accent
        : Colors.surfaceVariantText

    implicitWidth: Math.ceil(root.text.length * Type.sizeCaption * 0.62) + Metrics.controlPaddingX * 2
        + (root.icon !== "" ? root.iconPixelSize + Metrics.xs : 0)
    implicitHeight: Metrics.controlHeight

    // Purely a render transform (Item.scale), not a layout property, so
    // Row/Column/Flow siblings never see the button's size actually change.
    scale: mouse.pressed && root.active ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: root.rounded ? Metrics.radiusSmall : 0
        color: !root.active ? "transparent"
             : mouse.pressed ? Colors.pressedFill
             : mouse.containsMouse ? Colors.hoverFill
             : root.variant === "primary" ? Colors.selectedFill
             : root.dangerSolid ? Colors.errorContainer
             : root.variant === "danger" ? Colors.errorDim
             : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }
    Rectangle {
        anchors.fill: parent
        radius: root.rounded ? Metrics.radiusSmall : 0
        color: "transparent"
        border.width: Metrics.borderWidth
        border.color: !root.active ? Colors.alpha(Colors.outlineVariant, 0.5)
             : root.dangerSolid ? Colors.error
             : root.variant === "danger" ? Colors.alpha(Colors.error, mouse.containsMouse ? 1.0 : 0.55)
             : root.variant === "plain" ? (mouse.containsMouse || mouse.pressed ? Colors.edgeStrong : Colors.edge)
             : Colors.alpha(Colors.accent, 0.4)
        Behavior on border.color { ColorAnimation { duration: 100 } }
    }
    Row {
        id: content
        anchors.centerIn: parent
        spacing: Metrics.xs
        Item {
            visible: root.icon !== ""
            width: iconText.implicitWidth
            height: root.text !== "" ? labelText.height : iconText.height
            Text {
                id: iconText
                anchors.centerIn: parent
                text: root.icon
                font.family: Type.family
                font.pixelSize: root.iconPixelSize
                color: root.fg
            }
        }
        Text {
            id: labelText
            visible: root.text !== ""
            text: root.text
            font.family: Type.family
            font.pixelSize: Type.sizeCaption
            font.bold: root.bold
            font.letterSpacing: 0.8
            color: root.fg
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.active
        onClicked: root.pressed()
    }
}
