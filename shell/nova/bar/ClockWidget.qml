// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.nova.theme
import qs.nova.services

// Reloj de la barra. SystemClock con precisión de minutos: un solo
// despertar por minuto, no un Timer de 1 s.
Text {
    id: root

    // Formato de Qt (QDateTime); el idioma sale de la configuración regional.
    property string format: Platform.preferences.values.showSeconds ? "ddd d MMM  HH:mm:ss" : "ddd d MMM  HH:mm"

    SystemClock {
        id: clock
        precision: Platform.preferences.values.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    text: clock.date.toLocaleString(Qt.locale(), root.format)
    color: Theme.color.text
    font.family: Theme.font.family
    font.pixelSize: Theme.font.body
    font.features: { "tnum": 1 } // cifras tabulares: el ancho no "baila"
}
