// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "theme"

// Vidrio transparente (Liquid Glass) para la pantalla de inicio: deja ver el
// fondo desenfocado, claro en modo claro y negro translúcido en oscuro.
// Volumen con canto de luz y brillo superior; sin capturas ni shaders.
Rectangle {
    id: glass
    property bool strong: false
    property bool menu: false
    property bool hovered: false
    property bool pressed: false
    property bool focused: false

    radius: height / 2
    antialiasing: true
    color: menu ? Theme.color.clearGlassMenu
        : (pressed || hovered || strong) ? Theme.color.clearGlassStrong : Theme.color.clearGlass
    border.width: focused ? Theme.metrics.focusWidth : Theme.space.hairline
    border.color: focused ? Theme.color.focus : Theme.color.clearGlassRim
    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

    // Brillo especular: la luz entra por arriba y se desvanece. Ocupa toda la
    // forma (mismo radio) para no salirse de cápsulas ni círculos.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.space.hairline
        radius: Math.max(0, glass.radius - Theme.space.hairline)
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.color.clearGlassSheen }
            GradientStop { position: Theme.metrics.sheenHeight; color: Theme.color.transparent }
        }
    }
}
