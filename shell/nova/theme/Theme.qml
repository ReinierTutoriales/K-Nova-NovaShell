// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import "AppearancePolicy.mjs" as Policy
import "IconTokens.mjs" as IconTokens

QtObject {
    id: theme
    property string mode: "auto"
    property string material: "frosted"
    property string iconMode: "default"
    property real transparency: 0.5
    property color accent: "#3478f6"
    property bool reduceMotion: false
    property bool reduceTransparency: false
    property bool highContrast: false
    // Opt in after verifying ext-background-effect-v1 on the compositor.
    property bool backgroundBlur: false
    readonly property string effectiveMode: Policy.choice(mode, Policy.modes, "auto")
    readonly property string effectiveMaterial: Policy.choice(material, Policy.materials, "frosted")
    readonly property string effectiveIconMode: Policy.choice(iconMode, Policy.iconModes, "default")
    readonly property bool dark: effectiveMode === "dark"
        || (effectiveMode === "auto" && Qt.styleHints.colorScheme === Qt.Dark)
    readonly property real glassAmount: Policy.unit(transparency, 0.5)
    readonly property bool opaque: reduceTransparency || highContrast
    readonly property bool blurEnabled: backgroundBlur && !opaque && effectiveMaterial !== "solid"
    readonly property real surfaceAlpha: Policy.surfaceAlpha(
        effectiveMaterial, glassAmount, opaque, blurEnabled)

    readonly property QtObject color: QtObject {
        readonly property color transparent: "transparent"
        readonly property color surface: theme.dark ? "#202228" : "#ffffff"
        readonly property color surfaceRaised: theme.dark ? "#303239" : "#f4f5f8"
        readonly property color barBackground: Qt.rgba(surface.r, surface.g, surface.b, theme.surfaceAlpha)
        readonly property color text: theme.dark ? "#f5f6fa" : "#17191e"
        readonly property color textMuted: theme.dark ? "#bec3cf" : "#505662"
        readonly property color accent: theme.accent
        readonly property color accentText: "#ffffff"
        readonly property color ok: theme.dark ? "#6cdb8e" : "#16783b"
        readonly property color warn: theme.dark ? "#ffd176" : "#895500"
        readonly property color error: theme.dark ? "#ff9a95" : "#b42318"
        readonly property color border: theme.highContrast ? text
            : (theme.dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.15))
        readonly property color highlight: theme.dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.85)
        readonly property color glassTop: Qt.rgba(surface.r, surface.g, surface.b,
            Math.min(1, theme.surfaceAlpha + 0.08))
        readonly property color glassBottom: Qt.rgba(surface.r, surface.g, surface.b, theme.surfaceAlpha)
        readonly property color hover: theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.06)
        readonly property color pressed: theme.dark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.12)
        readonly property color focus: theme.dark ? "#9ac2ff" : "#1455c0"
        readonly property color previewTop: theme.dark ? "#16243b" : "#dce9fb"
        readonly property color previewBottom: theme.dark ? "#493556" : "#e6d9ec"
    }
    readonly property QtObject icons: QtObject {
        readonly property int small: 16
        readonly property int normal: 20
        readonly property int large: 24
        readonly property int application: 56
        readonly property int preview: 64
        readonly property int rasterLimit: 256
        readonly property real stroke: 1.7
        readonly property string strokeWidth: String(stroke)
        readonly property string ink: theme.dark ? "#f5f6fa" : "#17191e"
        readonly property string tile: theme.dark ? "#303239" : "#ffffff"
        readonly property string tint: theme.accent.toString()
        readonly property string white: "#ffffff"
        readonly property string darkTile: "#22252e"
        readonly property string darkEdge: "#5c6270"
        readonly property string lightEdge: "#ffffff"
        readonly property string glassHighlight: "#ffffff"
        readonly property real clearOpacity: theme.opaque ? 1 : 0.32
        readonly property var palette: IconTokens.palettes
    }
    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int sm: 6
        readonly property int md: 10
        readonly property int lg: 18
        readonly property int xl: 26
        readonly property int pill: 999
        readonly property int status: 4
    }
    readonly property QtObject space: QtObject {
        readonly property int hairline: 1
        readonly property int xxs: 2
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 24
        readonly property int xxl: 32
    }
    readonly property QtObject font: QtObject {
        readonly property string family: Qt.application.font.family
        readonly property int small: 11
        readonly property int body: 13
        readonly property int title: 16
        readonly property int heading: 25
    }
    readonly property QtObject motion: QtObject {
        readonly property int fast: theme.reduceMotion ? 0 : 120
        readonly property int normal: theme.reduceMotion ? 0 : 200
        readonly property int slow: theme.reduceMotion ? 0 : 320
    }
    readonly property QtObject metrics: QtObject {
        readonly property int statusSize: 8
        readonly property int controlHeight: 36
        readonly property int controlWidth: 100
        readonly property int touchTarget: 32
        readonly property int iconCell: 104
        readonly property int panelWidth: 960
        readonly property int panelHeight: 760
        readonly property int minimumPanelWidth: 480
        readonly property int minimumPanelHeight: 420
        readonly property int focusWidth: 2
        readonly property real disabledOpacity: 0.5
    }
    readonly property int barHeight: 32
}
