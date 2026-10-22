// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell

// Tokens de diseño. Ningún componente escribe un color, radio o duración
// literal: todo sale de aquí, así un tema nuevo es solo otro juego de valores.
Singleton {
    id: theme

    // "auto" sigue el esquema claro/oscuro del sistema (Qt 6.5+).
    property string mode: "auto"
    readonly property bool dark: mode === "dark"
        || (mode === "auto" && Qt.styleHints.colorScheme === Qt.Dark)

    // Accesibilidad: con reduceMotion todas las animaciones duran 0 ms.
    property bool reduceMotion: false

    readonly property QtObject color: QtObject {
        readonly property color barBackground: theme.dark ? Qt.rgba(0.08, 0.09, 0.11, 0.82)
                                                          : Qt.rgba(0.97, 0.97, 0.98, 0.82)
        readonly property color surface: theme.dark ? "#1c1e24" : "#ffffff"
        readonly property color text: theme.dark ? "#eceff4" : "#1b1d22"
        readonly property color textMuted: theme.dark ? "#9aa1ad" : "#5c6370"
        readonly property color accent: "#5b8cff"
        readonly property color ok: "#3fb950"
        readonly property color warn: "#d29922"
        readonly property color error: "#f85149"
        readonly property color border: theme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
    }

    readonly property QtObject radius: QtObject {
        readonly property int sm: 6
        readonly property int md: 10
        readonly property int lg: 16
    }

    readonly property QtObject space: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
    }

    readonly property QtObject font: QtObject {
        readonly property string family: "Inter, Noto Sans, sans-serif"
        readonly property int small: 11
        readonly property int body: 13
        readonly property int title: 15
    }

    readonly property QtObject motion: QtObject {
        readonly property int fast: theme.reduceMotion ? 0 : 120
        readonly property int normal: theme.reduceMotion ? 0 : 200
        readonly property int slow: theme.reduceMotion ? 0 : 320
    }

    readonly property int barHeight: 32
}
