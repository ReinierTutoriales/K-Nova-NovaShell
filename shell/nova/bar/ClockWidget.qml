// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.nova.theme
import qs.nova.controls
import qs.nova.services

// Fecha y hora de la barra. Como en macOS, pulsarla abre el panel "Hoy"
// (calendario y uso del sistema). SystemClock por minutos: un solo
// despertar por minuto salvo que el usuario pida segundos.
AbstractButton {
    id: root
    signal activated()
    // Formato de Qt (QDateTime); el idioma sale de la configuración regional.
    property string format: Platform.preferences.values.showSeconds ? "ddd d MMM  HH:mm:ss" : "ddd d MMM  HH:mm"

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: Theme.metrics.touchTarget
    implicitWidth: label.implicitWidth + 2 * Theme.space.sm
    Accessible.name: clock.date.toLocaleString(Qt.locale(), Locale.LongFormat)
    Accessible.description: qsTr("Abre el panel Hoy")
    onClicked: activated()

    SystemClock {
        id: clock
        precision: Platform.preferences.values.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    background: ControlFill {
        flat: true
        radius: Theme.radius.sm
        hovered: root.hovered
        pressed: root.down
        focused: root.visualFocus
    }
    contentItem: Item {
        Text {
            id: label
            anchors.centerIn: parent
            text: clock.date.toLocaleString(Qt.locale(), root.format)
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            font.features: { "tnum": 1 } // cifras tabulares: el ancho no "baila"
        }
    }
}
