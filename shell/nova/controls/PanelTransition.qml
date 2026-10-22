// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.nova.theme

// Transición solo de transformación: sin capa offscreen ni temporizadores.
// Abrir: aparece y crece un poco desde la barra (OutCubic, normal).
// Cerrar: se retira más rápido (InCubic, fast): en macOS descartar no hace
// esperar; Apple HIG pide movimiento breve e interrumpible. Las Behavior se
// interrumpen solas si el usuario cambia de opinión a mitad.
FocusScope {
    id: transition
    property bool opened: false
    readonly property bool animating: fade.running || resize.running
    visible: opened || opacity > 0
    enabled: opened
    opacity: opened ? 1 : 0
    scale: opened ? 1 : Theme.metrics.panelClosedScale
    transformOrigin: Item.TopRight
    Behavior on opacity {
        enabled: !Theme.reduceMotion
        NumberAnimation {
            id: fade
            duration: transition.opened ? Theme.motion.normal : Theme.motion.fast
            easing.type: transition.opened ? Easing.OutCubic : Easing.InCubic
        }
    }
    Behavior on scale {
        enabled: !Theme.reduceMotion
        NumberAnimation {
            id: resize
            duration: transition.opened ? Theme.motion.normal : Theme.motion.fast
            easing.type: transition.opened ? Easing.OutCubic : Easing.InCubic
        }
    }
}
