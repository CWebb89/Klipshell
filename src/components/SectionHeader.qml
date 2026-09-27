import QtQuick
import "../theme"

// Omarchy PanelSectionHeader: small bold label introducing a section. Not
// accent, not ALL-CAPS — reads as a document heading inside a card. Sits on
// the textTertiary rung (5.6:1) so it never competes with the values it
// introduces (textPrimary, 14.3:1). Optional leading icon at the same size,
// so the two share a baseline.
Row {
    id: root

    required property string text
    property string icon: ""
    property color foreground: Colors.textTertiary

    spacing: Metrics.sm

    height: Math.max(iconText.implicitHeight, label.implicitHeight)

    Text {
        id: iconText
        visible: root.icon !== ""
        text: root.icon
        font.family: Type.family
        font.pixelSize: Type.iconInline
        color: root.foreground
    }
    Text {
        id: label
        text: root.text
        textFormat: Text.PlainText
        font.family: Type.family
        font.pixelSize: Type.sizeCaption
        font.bold: true
        color: root.foreground
    }
}
