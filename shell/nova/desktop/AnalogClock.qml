// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.nova.theme

// Reloj analógico sin Canvas ni shaders: esfera y agujas son rectángulos
// rotados. Recibe la hora desde fuera (SystemClock por minutos).
Item {
    id: clock
    property date time: new Date()
    readonly property real minutes: time.getMinutes()
    readonly property real hours: time.getHours() % 12 + minutes / 60
    implicitWidth: Theme.metrics.clockSize
    implicitHeight: Theme.metrics.clockSize
    Accessible.role: Accessible.Clock
    Accessible.name: time.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.color.clockFace
        border.width: Theme.space.hairline
        border.color: Theme.color.border
    }
    Repeater {
        model: 12
        Item {
            required property int index
            anchors.fill: parent
            rotation: index * 30
            Rectangle {
                x: (parent.width - width) / 2
                y: Theme.space.sm
                width: index % 3 === 0 ? Theme.space.xxs * 1.5 : Theme.space.hairline
                height: index % 3 === 0 ? Theme.space.md : Theme.space.sm
                radius: width / 2
                color: index % 3 === 0 ? Theme.color.text : Theme.color.textMuted
            }
        }
    }
    component Hand: Item {
        property real angle: 0
        property real length: 0.3
        property real thickness: 2
        property color tint: Theme.color.text
        anchors.fill: parent
        rotation: angle
        Rectangle {
            width: parent.thickness
            height: parent.width * parent.length
            x: (parent.width - width) / 2
            y: parent.height / 2 - height + width
            radius: width / 2
            color: parent.tint
            antialiasing: true
        }
    }
    Hand { angle: clock.hours * 30; length: 0.27; thickness: Theme.space.xs }
    Hand { angle: clock.minutes * 6; length: 0.4; thickness: Theme.space.xxs * 1.5 }
    Rectangle {
        anchors.centerIn: parent
        width: Theme.space.sm; height: width; radius: width / 2
        color: Theme.color.accent
    }
}
