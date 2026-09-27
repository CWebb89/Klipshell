pragma Singleton
import QtQuick

// Omarchy-derived type scale (theme fonts are 10-28). Tokens kept verbatim
// where views already consume them; values now match Omarchy density.
QtObject {
    readonly property string family: "JetBrainsMono Nerd Font Mono"
    readonly property int sizeCaption: 14
    readonly property int sizeSmall: 16
    readonly property int sizeBody: 18
    readonly property int sizeTitle: 19
    readonly property int sizeHeading: 22
    readonly property int sizeLarge: 27
    readonly property int sizeMedium: 33
    readonly property int sizeXLarge: 38

    // The Mono Nerd Font variant draws every icon inside a single letter cell,
    // so an icon is set at the size of the text it leads and needs no vertical
    // correction: iconInline next to caption/small text, iconLead for nav rows
    // and card headers.
    readonly property int iconInline: 14
    readonly property int iconLead: 18
    readonly property int iconStandalone: 22
}