pragma Singleton
import QtQuick

// Structural spacing + geometry tokens (Omarchy Style.spacing grammar).
QtObject {
    readonly property int hairline: 1
    readonly property int spacing: 8
    readonly property int sectionGap: 8
    readonly property int panelPadding: 22
    readonly property int panelMargin: 20

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 13
    readonly property int radiusLarge: 17
    readonly property int borderWidth: 1
    readonly property int cardBorderWidth: 2

    readonly property int controlHeight: 38
    readonly property int rowHeight: 40
    readonly property int controlGap: 8
    readonly property int controlPaddingX: 16
    readonly property int controlPaddingY: 8

    // spacing ladder (xxs..huge)
    readonly property int xxs: 2
    readonly property int xs: 4
    readonly property int sm: 6
    readonly property int md: 8
    readonly property int lg: 12
    readonly property int xl: 16
    readonly property int xxl: 20
    readonly property int huge: 24

    // gauge/slider (PanelSlider: track 11% of control height, knob 38%)
    readonly property int gaugeTrack: 5
    readonly property int gaugeKnob: 19

    // Shell window on a 1920x1080 seat, leaving the Hyprland gap visible.
    readonly property int windowWidth: 1900
    readonly property int windowHeight: 1060
}