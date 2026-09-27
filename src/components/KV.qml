import QtQuick
import "../theme"

// Label/value row: label on the textSecondary rung, value on textPrimary.
// The label used to be accent, which in a tonal matugen scheme sits at the
// same luminance as the value — the two read as one flat run of text.
Row {
    id: root

    required property string key
    required property string value
    property color valueColor: Colors.textPrimary
    property color labelColor: Colors.textSecondary
    property string icon: ""
    property int labelWidth: 120

    Text {
        visible: root.icon !== ""
        width: Type.iconInline + Metrics.xs
        text: root.icon
        font.family: Type.family
        font.pixelSize: Type.iconInline
        color: Colors.textTertiary
        horizontalAlignment: Text.AlignHCenter
    }
    Text {
        width: root.labelWidth - (root.icon !== "" ? Type.iconInline + Metrics.xs : 0)
        text: root.key
        font.family: Type.family
        font.pixelSize: Type.sizeCaption
        font.bold: true
        color: root.labelColor
    }
    Text {
        text: root.value
        font.family: Type.family
        font.pixelSize: Type.sizeSmall
        color: root.valueColor
        elide: Text.ElideRight
    }
}