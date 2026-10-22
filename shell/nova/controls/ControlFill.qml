// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.nova.theme

// Fondo de un control que vive SOBRE una superficie de vidrio (barra, dock,
// paneles). Apple HIG / Liquid Glass: no apilar vidrio sobre vidrio; los
// elementos encima del vidrio se separan con rellenos y transparencia.
// Por eso aquí no hay degradado, brillo ni canto: solo un relleno de estado.
Rectangle {
    id: fill
    property bool hovered: false
    property bool pressed: false
    property bool checked: false
    property bool focused: false
    // flat: invisible en reposo (barra, dock, iconos); si no, relleno sutil.
    property bool flat: false
    radius: Theme.radius.md
    antialiasing: true
    color: pressed ? Theme.color.pressed
        : checked ? Theme.color.selection
        : hovered ? Theme.color.hover
        : flat ? Theme.color.transparent : Theme.color.controlFill
    border.width: focused ? Theme.metrics.focusWidth : (flat ? 0 : Theme.space.hairline)
    border.color: focused ? Theme.color.focus : Theme.color.controlBorder
    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
}
