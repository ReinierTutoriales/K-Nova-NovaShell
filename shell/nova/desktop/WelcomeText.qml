// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.nova.theme

// Párrafo de la bienvenida: ancho completo, ajuste de línea y tokens de Theme.
Text {
    Layout.fillWidth: true
    color: Theme.color.text
    font.family: Theme.font.family
    font.pixelSize: Theme.font.body
    wrapMode: Text.Wrap
    textFormat: Text.PlainText
}
