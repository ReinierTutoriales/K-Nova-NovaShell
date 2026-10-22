// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.nova.theme

// Acabado óptico de vidrio. El desenfoque del fondo lo aporta el compositor
// (BackgroundEffect en la ventana); aquí solo hay nodos estáticos: degradado
// de cuerpo, brillo especular superior y borde de luz interior. Sin capturas
// del fondo, shaders por frame ni texturas fuera de pantalla.
Rectangle {
    id: root
    property real cornerRadius: Theme.radius.lg
    property bool interactive: false
    property bool pressed: false
    property bool hovered: false
    property bool focused: false
    readonly property real innerRadius: Math.max(0, radius - Theme.space.hairline)

    radius: cornerRadius
    antialiasing: true
    border.width: focused ? Theme.metrics.focusWidth : Theme.space.hairline
    border.color: focused ? Theme.color.focus : Theme.color.border
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.color.glassTop }
        GradientStop { position: 1; color: Theme.color.glassBottom }
    }

    // Brillo especular: la luz entra por el borde superior y se desvanece.
    Rectangle {
        visible: Theme.color.sheenAlpha > 0
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.space.hairline
        }
        height: (parent.height - 2 * Theme.space.hairline) * Theme.metrics.sheenHeight
        radius: root.innerRadius
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.color.sheen }
            GradientStop { position: 1; color: Theme.color.transparent }
        }
    }

    // Borde de luz interior: da el canto refractivo del vidrio.
    Rectangle {
        visible: Theme.color.sheenAlpha > 0 && !root.focused
        anchors.fill: parent
        anchors.margins: Theme.space.hairline
        radius: root.innerRadius
        antialiasing: true
        color: Theme.color.transparent
        border.width: Theme.space.hairline
        border.color: Theme.color.rim
    }

    // Estado interactivo (hover/pulsado); no existe en superficies estáticas.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.interactive
        color: root.pressed ? Theme.color.pressed
            : (root.hovered ? Theme.color.hover : Theme.color.transparent)
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }
}
