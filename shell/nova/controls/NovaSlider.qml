// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import qs.nova.theme

// Slider con los tokens de Theme. El estilo Basic de Qt pinta la parte
// recorrida con el color de texto del sistema, que en modo oscuro queda
// invertido (recorrido oscuro, resto claro); aquí el recorrido es el acento.
Slider {
    id: root
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: Theme.metrics.touchTarget
    padding: 0

    background: Item {
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth
        height: Theme.metrics.sliderTrack
        implicitWidth: Theme.metrics.controlWidth * 2

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.color.sliderTrack
        }
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: height / 2
            color: root.enabled ? Theme.color.accent : Theme.color.textMuted
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        width: Theme.metrics.sliderHandle
        height: Theme.metrics.sliderHandle
        radius: width / 2
        antialiasing: true
        color: root.pressed ? Theme.color.surfaceRaised : Theme.color.surface
        border.width: root.visualFocus ? Theme.metrics.focusWidth : Theme.space.hairline
        border.color: root.visualFocus ? Theme.color.focus : Theme.color.border
        opacity: root.enabled ? 1 : Theme.metrics.disabledOpacity
        scale: root.pressed && !Theme.reduceMotion ? 1.1 : 1
        Behavior on scale { NumberAnimation { duration: Theme.motion.fast } }
    }
}
