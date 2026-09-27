import QtQuick
import "../theme"

// Omarchy PanelHero port: bold title with a trailing accent detail pill,
// uppercase letter-spaced caption meta below.
Item {
    id: root

    property string title: ""
    property string detail: ""
    property string meta: ""
    property color fg: Colors.textPrimary
    property color detailColor: Colors.accent
    property color metaColor: Colors.surfaceVariantText
    property real titleRightMargin: 0

    implicitHeight: 52

    Row {
        id: titleRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: root.titleRightMargin
        anchors.top: parent.top
        spacing: Metrics.sm

        Text {
            text: root.title
            font.family: Type.family
            font.pixelSize: Type.sizeTitle
            font.bold: true
            color: root.fg
            elide: Text.ElideRight
            width: root.detail !== ""
                ? parent.width - pillChip.width - Metrics.sm
                : parent.width
        }
        Chip {
            id: pillChip
            visible: root.detail !== ""
            pill: true
            text: root.detail
            color: root.detailColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: root.titleRightMargin
        y: titleRow.implicitHeight + 2
        text: root.meta !== "" ? root.meta.toUpperCase() : ""
        font.family: Type.family
        font.pixelSize: Type.sizeCaption
        font.bold: true
        font.letterSpacing: 1.2
        color: root.metaColor
        elide: Text.ElideRight
    }
}