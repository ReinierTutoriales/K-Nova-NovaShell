// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.nova.theme

// Optical finish; background blur is owned by the window/compositor.
// No captured wallpaper, per-frame shaders or offscreen textures.
Rectangle {
    id: root
    property real cornerRadius: Theme.radius.lg
    property bool interactive: false
    property bool pressed: false
    property bool hovered: false
    property bool focused: false
    radius: cornerRadius
    antialiasing: true
    border.width: focused ? Theme.metrics.focusWidth : Theme.space.hairline
    border.color: focused ? Theme.color.focus : Theme.color.border
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.color.glassTop }
        GradientStop { position: 1; color: Theme.color.glassBottom }
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.pressed ? Theme.color.pressed
            : (root.hovered ? Theme.color.hover : Theme.color.transparent)
        visible: root.interactive
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }
}
