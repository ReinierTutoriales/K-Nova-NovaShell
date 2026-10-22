// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

// Intensidad del vidrio Liquid Glass: de más opaco a más transparente. Se ve
// en vivo mientras se arrastra (solo Theme, sin IPC) y se guarda al soltar.
RowLayout {
    id: intensity
    property real value: 0.5
    signal committed(real value)
    Layout.fillWidth: true
    spacing: Theme.space.sm

    Text {
        text: qsTr("Opaco")
        color: Theme.color.textMuted
        font.family: Theme.font.family
        font.pixelSize: Theme.font.small
    }
    NovaSlider {
        id: slider
        Layout.fillWidth: true
        from: 0; to: 1
        value: intensity.value
        Accessible.name: qsTr("Intensidad del vidrio")
        onMoved: Theme.transparency = value
        onPressedChanged: if (!pressed) intensity.committed(value)
    }
    Text {
        text: qsTr("Transparente")
        color: Theme.color.textMuted
        font.family: Theme.font.family
        font.pixelSize: Theme.font.small
    }
}
