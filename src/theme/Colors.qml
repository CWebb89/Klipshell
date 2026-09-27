pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property color primary: "#ffb597"
    property color primaryText: "#552107"
    property color primaryContainer: "#71361b"
    property color primaryContainerText: "#ffdbcd"
    property color secondary: "#e7beae"
    property color secondaryText: "#442a1f"
    property color secondaryContainer: "#5d4034"
    property color secondaryContainerText: "#ffdbcd"
    property color tertiary: "#d3c78f"
    property color tertiaryText: "#373106"
    property color tertiaryContainer: "#4f471b"
    property color tertiaryContainerText: "#efe3a8"
    property color error: "#ffb4ab"
    property color errorText: "#690005"
    property color errorContainer: "#93000a"
    property color errorContainerText: "#ffdad6"
    property color background: "#1a110e"
    property color backgroundText: "#f1dfd9"
    property color surface: "#1a110e"
    property color surfaceText: "#f1dfd9"
    property color surfaceVariant: "#53433e"
    property color surfaceVariantText: "#d8c2ba"
    property color surfaceDim: "#1a110e"
    property color surfaceBright: "#423733"
    property color surfaceContainerLowest: "#140c09"
    property color surfaceContainerLow: "#231a16"
    property color surfaceContainer: "#271e1a"
    property color surfaceContainerHigh: "#322824"
    property color surfaceContainerHighest: "#3d322e"
    property color outline: "#a08d86"
    property color outlineVariant: "#53433e"
    property color inverseSurface: "#f1dfd9"
    property color inverseOnSurface: "#382e2a"
    property color inversePrimary: "#8e4d30"
    property color shadow: "#000000"
    property color scrim: "#000000"

    readonly property color textPrimary: surfaceText
    readonly property color accent: primary

    // ── Text ladder ────────────────────────────────────────────────────
    // matugen schemes are frequently tonal: in the live palette
    // primary/secondary/tertiary/onSurface all land within 1% of the same
    // luminance, so hue cannot separate a label from a value and accent
    // text is indistinguishable from body text. Hierarchy is therefore an
    // explicit lightness ladder, every rung derived from the live palette
    // (no hardcoded values). Measured contrast against surface /
    // surfaceContainerLow with the installed palette:
    //   textPrimary   14.3:1  values, panel titles
    //   textSecondary 10.9:1  labels, body copy
    //   textTertiary   5.6:1  section headers, units, metadata (AA body text)
    //   textMuted      2.9:1  disabled and placeholder only — never body copy
    readonly property color textSecondary: surfaceVariantText
    readonly property color textTertiary: Qt.rgba(surfaceVariantText.r,
                                                  surfaceVariantText.g,
                                                  surfaceVariantText.b, 0.70)
    readonly property color textMuted: Qt.rgba(surfaceVariantText.r,
                                               surfaceVariantText.g,
                                               surfaceVariantText.b, 0.42)

    // ── Structural edges ──────────────────────────────────────────────
    // Containers sit at 1.04-1.50:1 against surface, so the border — not the
    // fill — is what makes a card read as a card. `edgeStrong` is the hover/
    // focus step (outline, 5.8:1).
    readonly property color edge: outlineVariant
    readonly property color edgeStrong: outline

    // Status green: matugen's tertiary is a tonal beige in this scheme, so
    // "ready/connected/complete" has no hue to borrow. Fixed hex follows the
    // tempWarm/tempHot precedent below (~11:1 on surface).
    readonly property color success: "#4ade80"

    // Omarchy grammar tokens (shell/Ui + shell.toml): selection is accent
    // text on a fg@8% fill, separators are fg@12% hairlines, pressed is
    // fg@22%, hover fg@8%.
    readonly property color selectedFill: Qt.rgba(surfaceText.r, surfaceText.g,
                                                  surfaceText.b, 0.08)
    readonly property color hoverFill: Qt.rgba(surfaceText.r, surfaceText.g,
                                               surfaceText.b, 0.08)
    readonly property color pressedFill: Qt.rgba(surfaceText.r, surfaceText.g,
                                                 surfaceText.b, 0.22)
    readonly property color separator: Qt.rgba(surfaceText.r, surfaceText.g,
                                               surfaceText.b, 0.12)
    readonly property color accentDim: Qt.rgba(primary.r, primary.g, primary.b, 0.16)
    readonly property color errorDim: Qt.rgba(error.r, error.g, error.b, 0.16)
    readonly property color urgent: error

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    // thermal ramp: cool = matugen primary (theme-reactive), mid/hot fixed
    // (matugen has no yellow; webb-shell precedent)
    readonly property color tempCool: primary
    readonly property color tempWarm: "#f59e0b"
    readonly property color tempHot: "#dc2626"

    // category accent hues: alias themed MD3 roles
    readonly property color accentBlue: primary
    readonly property color accentCyan: secondary
    readonly property color accentPurple: tertiary
    readonly property color accentRose: error

    signal themeChanged()

    function applyColors(data) {
        for (const key in data) {
            if (root.hasOwnProperty(key))
                root[key] = data[key]
        }
        root.themeChanged()
    }

    property FileView colorsFile: FileView {
        path: (function() {
            var e = Quickshell.env("HOME")
            return (e && e !== "null") ? e + "/.cache/matugen/klipshell-colors.json" : ""
        })()
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.applyColors(JSON.parse(text()))
            } catch (e) {
                console.warn("matugen colors parse failed:", e)
            }
        }
    }
}