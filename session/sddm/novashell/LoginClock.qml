// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "theme"

// Fecha y hora grandes. Se despierta una vez por minuto, alineado al cambio
// de minuto, en lugar de cada segundo.
Column {
    id: clock
    property date now: new Date()
    spacing: Theme.space.xxs

    Timer {
        running: true
        repeat: false
        // +50 ms: dispara ya dentro del minuto nuevo, nunca justo antes.
        interval: (60 - clock.now.getSeconds()) * 1000 - clock.now.getMilliseconds() + 50
        onTriggered: { clock.now = new Date(); restart(); }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        // Formato largo del idioma sin el año final ("jueves, 22 de octubre").
        readonly property string format: Qt.locale().dateFormat(Locale.LongFormat)
            .replace(/\s*(,|'[^']*')?\s*y+\.?\s*$/, "")
        text: clock.now.toLocaleDateString(Qt.locale(), format)
        color: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.title
        font.weight: Font.DemiBold
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: clock.now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
        color: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.hero
        font.weight: Font.DemiBold
    }
}
