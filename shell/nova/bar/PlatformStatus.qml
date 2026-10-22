// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.nova.services
import qs.nova.theme

// Indicador del servicio nova-platform: verde conectado, rojo caído.
// Solo muestra texto cuando hay un problema; en estado normal es un punto.
RowLayout {
    id: root

    spacing: Theme.space.xs

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Theme.metrics.statusSize
        implicitHeight: Theme.metrics.statusSize
        radius: Theme.radius.status
        color: Platform.connected ? Theme.color.ok : Theme.color.error

        Behavior on color {
            ColorAnimation {
                duration: Theme.motion.normal
            }
        }
    }

    Text {
        visible: !Platform.connected
        text: qsTr("servicio no disponible")
        color: Theme.color.textMuted
        font.family: Theme.font.family
        font.pixelSize: Theme.font.small
    }
}
