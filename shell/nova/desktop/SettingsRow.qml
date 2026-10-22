// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.nova.theme

// Fila de ajuste: etiqueta a la izquierda y control a la derecha.
RowLayout {
    id: row
    property string label: ""
    default property alias control: holder.data
    Layout.fillWidth: true
    spacing: Theme.space.md
    Text {
        text: row.label
        color: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.body
        Layout.preferredWidth: Theme.metrics.settingsLabelWidth
        elide: Text.ElideRight
    }
    RowLayout {
        id: holder
        Layout.fillWidth: true
    }
}
