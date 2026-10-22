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
    // prominent: acción principal de una vista (tinte de acento, HIG).
    property bool prominent: false
    radius: Theme.radius.md
    antialiasing: true
    color: prominent ? (pressed ? Theme.color.accentFillPressed
            : hovered ? Theme.color.accentFillHover : Theme.color.accentFill)
        : pressed ? Theme.color.pressed
        : checked ? Theme.color.selection
        : hovered ? Theme.color.hover
        : flat ? Theme.color.transparent : Theme.color.controlFill
    border.width: focused ? Theme.metrics.focusWidth : (flat || prominent ? 0 : Theme.space.hairline)
    border.color: focused ? Theme.color.focus : Theme.color.controlBorder
    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
}
